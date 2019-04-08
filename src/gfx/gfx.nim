#~~
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#~~

import colors

import window
import ../lib/glad/gl
import ../math/vectors

#~~
# Shaders
#~~

type
  RShader* = distinct GLuint
  RShaderKind* = enum
    shVertex
    shFragment
  ShaderError* = object of Exception

proc newShader*(kind: RShaderKind, source: string): RShader =
  ## Creates a new vertex or fragment shader, as specified by ``kind``, and
  ## compiles it. Raises a ``ShaderError`` when compiling fails.
  result = RShader(glCreateShader(
    case kind
    of shVertex:   GL_VERTEX_SHADER
    of shFragment: GL_FRAGMENT_SHADER
  ))
  let cstr = allocCStringArray([source])
  glShaderSource(GLuint(result), 1, cstr, nil)
  deallocCStringArray(cstr)
  glCompileShader(GLuint(result))
  var isuccess: GLint
  glGetShaderiv(GLuint(result), GL_COMPILE_STATUS, addr isuccess)
  let success = bool(isuccess)
  if not success:
    var logLength: GLint
    glGetShaderiv(GLuint(result), GL_INFO_LOG_LENGTH, addr logLength)
    var log = cast[ptr GLchar](alloc(logLength))
    glGetShaderInfoLog(GLuint(result), logLength, addr logLength, log)
    raise newException(ShaderError, $log)

type
  RProgram* = ref object
    id: GLuint
    shaders: seq[RShader]
    vPosLoc: GLint
  ProgramError* = object of Exception

proc newProgram*(): RProgram =
  ## Creayes a new shader program.
  result = RProgram(id: glCreateProgram())

proc attach*(program: RProgram, shader: RShader): RProgram =
  ## Attaches a shader to a program.
  ## The ``RProgram`` is not a ``var RProgram``, because without it being \
  ## ``var`` we can easily chain calls together.
  glAttachShader(program.id, GLuint(shader))
  result = program
  result.shaders.add(shader)

proc attach*(program: RProgram,
             shaderKind: RShaderKind, source: string): RProgram =
  ## Alias for ``program.attach(newShader(shaderKind, source))``.
  program.attach(newShader(shaderKind, source))

proc link*(program: RProgram): RProgram =
  ## Links the program, and destroys all attached shaders.
  glLinkProgram(program.id)
  for sh in program.shaders:
    glDeleteShader(GLuint(sh))
  # Error checking
  var isuccess: GLint
  glGetProgramiv(program.id, GL_LINK_STATUS, addr isuccess)
  let success = bool(isuccess)
  if not success:
    var logLength: GLint
    glGetProgramiv(GLuint(program.id), GL_INFO_LOG_LENGTH, addr logLength)
    var log = cast[ptr GLchar](alloc(logLength))
    glGetProgramInfoLog(GLuint(program.id), logLength, addr logLength, log)
    raise newException(ShaderError, $log)
  result = program

#~~
# Gfx
#~~

const
  RDefaultVshSrc = """
    #version 330 core

    layout (location = 0) in vec2 r_vPos;

    void main(void) {
      gl_Position = vec4(r_vPos.x, r_vPos.y, 0.0, 1.0);
    }
  """
  RDefaultFshSrc = """
    #version 330 core

    out vec4 fColor;

    void main(void) {
      fColor = vec4(1.0, 1.0, 1.0, 1.0);
    }
  """

type
  RGfx* = ref object
    win: RWindow
    width*, height*: int
    # Default state
    defaultProgram: RProgram
    # Buffer objects
    fboID, vaoID, vboID, eboID: GLuint
    vboSize, eboSize: int
    vbo: seq[float32]
    ebo: seq[int32]
  RPrimitive* = enum
    prPoints
    prLines, prLineStrip, prLineLoop
    prTris, prTriStrip, prTriFan
    prShape

proc reallocVbo(gfx: RGfx) =
  glBufferData(GL_ARRAY_BUFFER,
    gfx.vboSize,
    nil,
    GL_DYNAMIC_DRAW)

proc reallocEbo(gfx: RGfx) =
  glBufferData(GL_ELEMENT_ARRAY_BUFFER,
    gfx.eboSize,
    nil,
    GL_DYNAMIC_DRAW)

proc updateVbo(gfx: RGfx) =
  let dataSize = sizeof(float32) * gfx.vbo.len
  if gfx.vboSize < dataSize:
    gfx.vboSize = dataSize
    gfx.reallocVbo()
  glBufferSubData(GL_ARRAY_BUFFER,
    0, dataSize,
    gfx.vbo[0].unsafeAddr)

proc updateEbo(gfx: RGfx) =
  let dataSize = sizeof(int32) * gfx.ebo.len
  if gfx.eboSize < dataSize:
    gfx.eboSize = dataSize
    gfx.reallocEbo()
  glBufferSubData(GL_ELEMENT_ARRAY_BUFFER,
    0, dataSize,
    gfx.ebo[0].unsafeAddr)

proc init(gfx: RGfx) =
  # Default program
  gfx.defaultProgram = newProgram()
    .attach(shVertex,   RDefaultVshSrc)
    .attach(shFragment, RDefaultFshSrc)
    .link()
  # Vertex attributes
  const Stride = sizeof(float32) * 2
  glGenVertexArrays(1, addr gfx.vaoID)
  glBindVertexArray(gfx.vaoID)
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(
    0, 2, cGL_FLOAT, false, Stride, cast[pointer](0))
  # Allocate buffers
  glGenBuffers(1, addr gfx.vboID)
  glBindBuffer(GL_ARRAY_BUFFER, gfx.vboID)
  gfx.vboSize = 8
  gfx.reallocVbo()
  glGenBuffers(1, addr gfx.eboID)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gfx.eboID)
  gfx.eboSize = 8
  gfx.reallocEbo()

proc initRoot(gfx: RGfx) =
  gfx.win.onResize do (win: RWindow, width, height: Natural):
    glViewport(0, 0, GLsizei(width), GLsizei(height))
    gfx.width = width
    gfx.height = height

proc openGfx*(win: RWindow): RGfx =
  result = RGfx(
    win: win,
    fboID: 0,
    width: win.width,
    height: win.height
  )
  result.init()
  result.initRoot()

proc draw(gfx: var RGfx, primitive = prShape) =
  gfx.updateVbo()
  if primitive == prShape:
    gfx.updateEbo()
    glDrawElements(GL_TRIANGLES, GLsizei gfx.ebo.len, GL_UNSIGNED_INT, nil)
  else:
    # glDrawArrays(
    #   case primitive
    #   of prPoints:   GL_POINTS
    #   of prLines:    GL_LINES
    #   of prTriStrip: GL_TRIANGLE_STRIP
    #   of prTriFan:   GL_TRIANGLE_FAN
    #   else:          GL_TRIANGLES,
    #   0, GLsizei(gfx.vbo.len / 2)
    # )
    discard

#~~
# Gfx context
#~~

type
  RGfxContext* = object
    gfx: RGfx
    # Shapes
    vertexCount: int
  RVertexIndex* = distinct int

proc program*(ctx: var RGfxContext, program: RProgram) =
  glUseProgram(program.id)

proc program*(ctx: var RGfxContext) =
  ctx.program(ctx.gfx.defaultProgram)

proc clear*(ctx: var RGfxContext, col: Color) =
  glClearColor(
    col.red.norm32, col.green.norm32, col.blue.norm32, col.alpha.norm32)
  glClear(GL_COLOR_BUFFER_BIT)

proc begin*(ctx: var RGfxContext) =
  ctx.vertexCount = 0
  ctx.gfx.vbo.setLen(0)
  ctx.gfx.ebo.setLen(0)

proc vertex*(ctx: var RGfxContext,
             point: RPoint): RVertexIndex {.discardable.} =
  result = RVertexIndex(ctx.vertexCount)
  ctx.gfx.vbo.add([float32 point.x, point.y])
  inc(ctx.vertexCount)

proc index*(ctx: var RGfxContext, indices: varargs[RVertexIndex]) =
  for idx in indices: ctx.gfx.ebo.add(int32(idx))

proc tri*(ctx: var RGfxContext, a, b, c: RPoint) =
  ctx.index(ctx.vertex(a))
  ctx.index(ctx.vertex(b))
  ctx.index(ctx.vertex(c))

proc quad*(ctx: var RGfxContext, a, b, c, d: RPoint) =
  let
    i = ctx.vertex(a)
    j = ctx.vertex(b)
    k = ctx.vertex(c)
    l = ctx.vertex(d)
  ctx.index(i, j, k, k, l, i)

proc draw*(ctx: var RGfxContext, primitive = prShape) =
  ctx.gfx.draw(primitive)

proc ctx*(gfx: RGfx): RGfxContext =
  result = RGfxContext(
    gfx: gfx
  )
  result.program()
  glBindVertexArray(gfx.vaoID)

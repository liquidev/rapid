#~~
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#~~

import colors
import tables

import glm

import window
import ../data/data
import ../lib/glad/gl

#~~
# Shaders
#~~

type
  RShader* = distinct GLuint
  RShaderKind* = enum
    shVertex
    shFragment
  ShaderError* = object of Exception

const
  RDefaultVshSrc = """
    #version 330 core

    layout (location = 0) in vec2 vPos;
    layout (location = 1) in vec4 vCol;
    layout (location = 2) in vec2 vUV;

    out vec4 vfCol;
    out vec2 vfUV;

    void main(void) {
      gl_Position = vec4(vPos.x, vPos.y, 0.0, 1.0);
      vfCol = vCol;
      vfUV = vUV;
    }
  """
  RDefaultFshSrc = """
    #version 330 core

    in vec4 vfCol;
    in vec2 vfUV;

    uniform bool rTextureEnabled;
    uniform sampler2D tex;

    out vec4 fCol;

    void main(void) {
      if (rTextureEnabled) {
        fCol = texture(tex, vfUV);
      } else {
        fCol = vec4(vfUV.x, vfUV.y, 0.0, 1.0);
      }
    }
  """

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
    uniformLocations: Table[string, GLint]
    vPosLoc: GLint
  ProgramError* = object of Exception

proc newProgram*(): RProgram =
  ## Creayes a new shader program.
  result = RProgram(
    id: glCreateProgram(),
    uniformLocations: initTable[string, GLint]()
  )

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

var currentProgram: GLuint

template with*(prog: RProgram, body: untyped): untyped =
  let previousProgram = currentProgram
  glUseProgram(prog.id)
  currentProgram = prog.id
  body
  glUseProgram(previousProgram)
  currentProgram = previousProgram

template uniformCheck(): untyped {.dirty.} =
  if not prog.uniformLocations.hasKey(name):
    prog.uniformLocations[name] = glGetUniformLocation(prog.id, name)

proc uniform*(prog: RProgram, name: string, val: float) =
  uniformCheck()
  with(prog): glUniform1f(prog.uniformLocations[name], val)
proc uniform*(prog: RProgram, name: string, val: Vec2f) =
  uniformCheck()
  with(prog): glUniform2f(prog.uniformLocations[name], val.x, val.y)
proc uniform*(prog: RProgram, name: string, val: Vec3f) =
  uniformCheck()
  with(prog): glUniform3f(prog.uniformLocations[name], val.x, val.y, val.z)
proc uniform*(prog: RProgram, name: string, val: Vec4f) =
  uniformCheck()
  with(prog): glUniform4f(prog.uniformLocations[name], val.x, val.y, val.z, val.w)

proc uniform*(prog: RProgram, name: string, val: int) =
  uniformCheck()
  with(prog): glUniform1i(prog.uniformLocations[name], GLint val)


#~~
# Textures
#~~

var currentTexture: GLuint = 0

template with*(tex: RTexture, body: untyped) =
  let previousTexture = currentTexture
  glBindTexture(GL_TEXTURE_2D, tex.id)
  currentTexture = tex.id
  body
  glBindTexture(GL_TEXTURE_2D, previousTexture)
  currentTexture = previousTexture

template use*(tex: RTexture) =
  glBindTexture(GL_TEXTURE_2D, tex.id)
  currentTexture = tex.id

proc GLenum*(flt: RTextureFilter): GLenum =
  case flt
  of fltNearest: GL_NEAREST
  of fltLinear:  GL_LINEAR

proc GLenum*(wrap: RTextureWrap): GLenum =
  case wrap
  of wrapRepeat:         GL_REPEAT
  of wrapMirroredRepeat: GL_MIRRORED_REPEAT
  of wrapClampToEdge:    GL_CLAMP_TO_EDGE
  of wrapClampToBorder:  GL_CLAMP_TO_BORDER

proc newTexture*(img: RImage): RTexture =
  result = RTexture()
  glGenTextures(1, addr result.id)
  with(result):
    glTexParameteri(GL_TEXTURE_2D,
      GL_TEXTURE_MIN_FILTER, GLint GLenum(img.textureConf.minFilter))
    glTexParameteri(GL_TEXTURE_2D,
      GL_TEXTURE_MAG_FILTER, GLint GLenum(img.textureConf.magFilter))
    glTexParameteri(GL_TEXTURE_2D,
      GL_TEXTURE_WRAP_S, GLint GLenum(img.textureConf.wrap))
    glTexParameteri(GL_TEXTURE_2D,
      GL_TEXTURE_WRAP_T, GLint GLenum(img.textureConf.wrap))
    glTexImage2D(GL_TEXTURE_2D,
      0,
      GLint GL_RGBA8, GLsizei img.width, GLsizei img.height,
      0,
      GL_RGBA, GL_UNSIGNED_BYTE,
      img.data[0].unsafeAddr)
    glGenerateMipmap(GL_TEXTURE_2D)

#~~
# Gfx
#~~

type
  RGfx* = ref object
    win: RWindow
    width*, height*: int
    # Default state
    defaultProgram: RProgram
    # Buffer objects
    fboID, vaoID, vboID, eboID: GLuint
    vboSize, eboSize: int
    # Data
    data: RData
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

proc updateVbo(gfx: RGfx, data: seq[float32]) =
  let dataSize = sizeof(float32) * data.len
  if gfx.vboSize < dataSize:
    gfx.vboSize = dataSize
    gfx.reallocVbo()
  glBufferSubData(GL_ARRAY_BUFFER,
    0, dataSize,
    data[0].unsafeAddr)

proc updateEbo(gfx: RGfx, data: seq[int32]) =
  let dataSize = sizeof(int32) * data.len
  if gfx.eboSize < dataSize:
    gfx.eboSize = dataSize
    gfx.reallocEbo()
  glBufferSubData(GL_ELEMENT_ARRAY_BUFFER,
    0, dataSize,
    data[0].unsafeAddr)

proc init(gfx: RGfx) =
  # Default program
  gfx.defaultProgram = newProgram()
    .attach(shVertex,   RDefaultVshSrc)
    .attach(shFragment, RDefaultFshSrc)
    .link()
  # Allocate buffers
  glGenBuffers(1, addr gfx.vboID)
  glBindBuffer(GL_ARRAY_BUFFER, gfx.vboID)
  gfx.vboSize = 8
  gfx.reallocVbo()
  glGenBuffers(1, addr gfx.eboID)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gfx.eboID)
  gfx.eboSize = 8
  gfx.reallocEbo()
  # Vertex attributes
  const Stride = (2 + 4 + 2) * sizeof(float32)
  glGenVertexArrays(1, addr gfx.vaoID)
  glBindVertexArray(gfx.vaoID)

  glEnableVertexAttribArray(0)
  glVertexAttribPointer(
    0, 2, cGL_FLOAT, false, Stride, cast[pointer](0 * sizeof(float32)))
  glEnableVertexAttribArray(1)
  glVertexAttribPointer(
    1, 4, cGL_FLOAT, false, Stride, cast[pointer](2 * sizeof(float32)))
  glEnableVertexAttribArray(2)
  glVertexAttribPointer(
    2, 2, cGL_FLOAT, false, Stride, cast[pointer](6 * sizeof(float32)))
  # Textures
  glActiveTexture(GL_TEXTURE0)

proc initRoot(gfx: RGfx) =
  gfx.win.onResize do (win: RWindow, width, height: Natural):
    glViewport(0, 0, GLsizei(width), GLsizei(height))
    gfx.width = width
    gfx.height = height

proc `data=`*(gfx: var RGfx, data: RData) =
  gfx.data = data

proc openGfx*(win: RWindow): RGfx =
  result = RGfx(
    win: win,
    fboID: 0,
    width: win.width,
    height: win.height
  )
  result.init()
  result.initRoot()

#~~
# Gfx context
#~~

type
  RGfxContext* = object
    gfx: RGfx
    # Shapes
    shape: seq[float32]
    indices: seq[int32]
    vertexCount: int
    # Painting
    program: RProgram
    color: Color
    textureEnabled: bool
    texture: RTexture
    transform: Mat4f
  RVertex* = tuple
    x, y: float
    color: Color
    u, v: float
  RPointVertex* = tuple
    x, y: float
  RTexVertex* = tuple
    x, y: float
    u, v: float
  RColVertex* = tuple
    x, y: float
    color: Color
  SomeVertex = RPointVertex | RColVertex | RTexVertex | RVertex
  RVertexIndex* = distinct int32

converter toRVertex*(vert: RPointVertex): RVertex =
  (vert.x, vert.y, colWhite, 0.0, 0.0)

converter toRVertex*(vert: RTexVertex): RVertex =
  (vert.x, vert.y, colWhite, vert.u, vert.v)

converter toRVertex*(vert: RColVertex): RVertex =
  (vert.x, vert.y, vert.color, 0.0, 0.0)

proc `program=`*(ctx: var RGfxContext, program: RProgram) =
  glUseProgram(program.id)
  ctx.program = program

proc defaultProgram*(ctx: var RGfxContext) =
  ctx.`program=`(ctx.gfx.defaultProgram)

template uniformProc(T: typedesc): untyped {.dirty.} =
  proc uniform*(ctx: var RGfxContext, name: string, val: T) =
    ctx.program.uniform(name, val)
uniformProc(float)
uniformProc(Vec2f)
uniformProc(Vec3f)
uniformProc(Vec4f)
uniformProc(int)

proc clear*(ctx: var RGfxContext, col: Color) =
  glClearColor(
    col.red.norm32, col.green.norm32, col.blue.norm32, col.alpha.norm32)
  glClear(GL_COLOR_BUFFER_BIT)

proc `color=`*(ctx: var RGfxContext, col: Color) =
  ctx.color = col

proc `texture=`*(ctx: var RGfxContext, tex: RTexture) =
  if not ctx.textureEnabled:
    ctx.textureEnabled = true
    ctx.uniform("rTextureEnabled", 1)
  ctx.texture = tex

proc `texture=`*(ctx: var RGfxContext, tex: string) =
  assert not isNil(ctx.gfx.data),
    "A data object must be bound to the RGfx"
  assert ctx.gfx.data.images.hasKey(tex),
    "The texture \"" & tex & "\" doesn't exist"
  if not ctx.gfx.data.textures.hasKey(tex):
    ctx.gfx.data.textures[tex] = newTexture(ctx.gfx.data.images[tex])
  ctx.`texture=`(ctx.gfx.data.textures[tex])

proc noTexture*(ctx: var RGfxContext) =
  if ctx.textureEnabled:
    ctx.textureEnabled = false
    ctx.uniform("rTextureEnabled", 0)

proc begin*(ctx: var RGfxContext) =
  ctx.vertexCount = 0
  ctx.shape.setLen(0)
  ctx.indices.setLen(0)

proc mapX(gfx: RGfx, x: float): float32 =
  result = x / float(gfx.width) * 2 - 1

proc mapY(gfx: RGfx, y: float): float32 =
  result = y / float(gfx.height) * -2 + 1

proc vertex*(ctx: var RGfxContext,
             vert: RVertex): RVertexIndex {.discardable.} =
  result = RVertexIndex(ctx.vertexCount)
  ctx.shape.add([
    # Position
    ctx.gfx.mapX(vert.x), ctx.gfx.mapY(vert.y),
    # Color
    vert.color.red.norm32, vert.color.green.norm32, vert.color.blue.norm32,
    vert.color.alpha.norm32,
    # Texture coordinates
    vert.u, 1.0 - vert.v
  ])
  inc(ctx.vertexCount)

proc vertex*(ctx: var RGfxContext,
             vert: RPointVertex): RVertexIndex {.discardable.} =
  ctx.vertex((vert.x, vert.y, ctx.color, 0.0, 0.0))

proc vertex*(ctx: var RGfxContext,
             vert: RTexVertex): RVertexIndex {.discardable.} =
  ctx.vertex((vert.x, vert.y, ctx.color, vert.u, vert.v))

proc index*(ctx: var RGfxContext, indices: varargs[RVertexIndex]) =
  for idx in indices: ctx.indices.add(int32(idx))

proc tri*[T: SomeVertex](ctx: var RGfxContext, a, b, c: T) =
  ctx.index(ctx.vertex(a))
  ctx.index(ctx.vertex(b))
  ctx.index(ctx.vertex(c))

proc quad*[T: SomeVertex](ctx: var RGfxContext, a, b, c, d: T) =
  let
    i = ctx.vertex(a)
    j = ctx.vertex(b)
    k = ctx.vertex(c)
    l = ctx.vertex(d)
  ctx.index(i, j, l, j, k, l)

proc rect*(ctx: var RGfxContext,
           x, y, w, h: float,
           tx, ty = 0.0, tw, th = 1.0) =
  ctx.quad(
    (x,     y,     tx,      ty),
    (x + w, y,     tx + tw, ty),
    (x + w, y + h, tx + tw, ty + th),
    (x,     y + h, tx,      ty + th))

proc draw*(ctx: var RGfxContext, primitive = prShape) =
  if ctx.shape.len > 0:
    ctx.texture.use()
    ctx.gfx.updateVbo(ctx.shape)
    if primitive == prShape:
      ctx.gfx.updateEbo(ctx.indices)
      glDrawElements(GL_TRIANGLES, GLsizei ctx.indices.len, GL_UNSIGNED_INT, nil)
    else:
      glDrawArrays(
        case primitive
        of prPoints:   GL_POINTS
        of prLines:    GL_LINES
        of prTriStrip: GL_TRIANGLE_STRIP
        of prTriFan:   GL_TRIANGLE_FAN
        else:          GL_TRIANGLES,
        0, GLsizei ctx.vertexCount)

proc ctx*(gfx: RGfx): RGfxContext =
  result = RGfxContext(
    gfx: gfx,
    color: col(colWhite)
  )
  result.defaultProgram()
  glBindVertexArray(gfx.vaoID)
  glBindBuffer(GL_ARRAY_BUFFER, gfx.vboID)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gfx.eboID)

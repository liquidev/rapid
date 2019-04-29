#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import colors
import tables

import glm

import opengl
import window
import ../data/storage
import ../lib/glad/gl

export glm

#--
# Shaders
#--

type
  RShader* = distinct GLuint
  RShaderKind* = enum
    shVertex
    shFragment
  ShaderError* = object of Exception



const
  RVshLibSrc = """
    #version 330 core

    layout (location = 0) in vec2 rapid_vPos;
    layout (location = 1) in vec4 rapid_vCol;
    layout (location = 2) in vec2 rapid_vUV;

    uniform mat4 rapid_transform;

    out vec4 rapid_vfCol;
    out vec2 rapid_vfUV;

    vec4 rVertex(vec4 pos, mat4 transform);

    void main(void) {
      gl_Position =
        rVertex(vec4(rapid_vPos.x, rapid_vPos.y, 0.0, 1.0), rapid_transform);
      rapid_vfCol = rapid_vCol;
      rapid_vfUV = rapid_vUV;
    }
  """
  RFshLibSrc = """
    #version 330 core

    in vec4 rapid_vfCol;
    in vec2 rapid_vfUV;

    uniform bool rapid_textureEnabled;
    uniform sampler2D rapid_texture;

    out vec4 rapid_fCol;

    vec4 rTexel(sampler2D tex, vec2 uv) {
      if (rapid_textureEnabled) {
        return texture(tex, uv);
      } else {
        return vec4(1.0, 1.0, 1.0, 1.0);
      }
    }

    vec4 rFragment(vec4 col, sampler2D tex, vec2 uv);

    void main(void) {
      rapid_fCol = rFragment(rapid_vfCol, rapid_texture, rapid_vfUV);
    }
  """
  RDefaultVshSrc = """
    vec4 rVertex(vec4 pos, mat4 transform) {
      return pos * transform;
    }
  """
  RDefaultFshSrc = """
    vec4 rFragment(vec4 col, sampler2D tex, vec2 uv) {
      return rTexel(tex, uv) * col;
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
    uniformLocations: Table[string, GLint]
    vPosLoc: GLint
  ProgramError* = object of Exception

proc newProgram(): RProgram =
  ## Creates a new ``RProgram``.
  result = RProgram(
    id: glCreateProgram(),
    uniformLocations: initTable[string, GLint]()
  )

proc attach(program: var RProgram, shader: RShader) =
  ## Attaches a shader to a program.
  ## The ``RProgram`` is not a ``var RProgram``, because without it being \
  ## ``var`` we can easily chain calls together.
  glAttachShader(program.id, GLuint(shader))

proc link(program: var RProgram) =
  ## Links the program. This does not destroy attached shaders!
  glLinkProgram(program.id)
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

template uniformCheck(): untyped {.dirty.} =
  glUseProgram(prog.id)
  if not prog.uniformLocations.hasKey(name):
    prog.uniformLocations[name] = glGetUniformLocation(prog.id, name)
  var val = val

proc uniform(prog: RProgram, name: string, val: float) =
  ## Sets a uniform in the specified program.
  uniformCheck()
  glUniform1f(prog.uniformLocations[name], val)
proc uniform(prog: RProgram, name: string, val: Vec2f) =
  uniformCheck()
  glUniform2fv(prog.uniformLocations[name], 1, val.caddr)
proc uniform(prog: RProgram, name: string, val: Vec3f) =
  uniformCheck()
  glUniform3fv(prog.uniformLocations[name], 1, val.caddr)
proc uniform(prog: RProgram, name: string, val: Vec4f) =
  uniformCheck()
  glUniform4fv(prog.uniformLocations[name], 1, val.caddr)

proc uniform(prog: RProgram, name: string, val: int) =
  uniformCheck()
  glUniform1i(prog.uniformLocations[name], GLint val)

proc uniform(prog: RProgram, name: string, val: Mat4) =
  uniformCheck()
  glUniformMatrix4fv(prog.uniformLocations[name], 1, false, val.caddr)

#--
# Gfx
#--

type
  RGfx* = ref object
    win: RWindow
    width*, height*: int
    # Default state
    vertexLibSh, fragmentLibSh: RShader
    defaultProgram: RProgram
    # Framebuffer
    fbo: GLuint
    target: RTexture
    # Buffer objects
    vaoID, vboID, eboID: GLuint
    vboSize, eboSize: int
    # Data
    data: RData
  RPrimitive* = enum
    prPoints
    prLines, prLineStrip, prLineLoop
    prTris, prTriStrip, prTriFan
    prShape

proc newRProgram*(gfx: RGfx, vertexSrc, fragmentSrc: string): RProgram =
  ## Creates a new ``RProgram`` from the specified shaders.
  result = newProgram()
  if int(gfx.vertexLibSh) == 0:
    gfx.vertexLibSh = newShader(shVertex, RVshLibSrc)
  if int(gfx.fragmentLibSh) == 0:
    gfx.fragmentLibSh = newShader(shFragment, RFshLibSrc)
  let
    vsh = newShader(shVertex, vertexSrc)
    fsh = newShader(shFragment, """
    vec4 rTexel(sampler2D tex, vec2 uv);

    """ & fragmentSrc)
  result.attach(gfx.vertexLibSh)
  result.attach(vsh)
  result.attach(gfx.fragmentLibSh)
  result.attach(fsh)
  result.link()
  glDeleteShader(GLuint(vsh))
  glDeleteShader(GLuint(fsh))

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
  # Settings
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  # Default program
  gfx.defaultProgram = gfx.newRProgram(RDefaultVshSrc, RDefaultFshSrc)
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
  ## Makes the ``RGfx`` use data from the specified container.
  gfx.data = data

proc texture*(gfx: RGfx): RTexture =
  ## Returns the texture the Gfx is drawing to. This is ``nil`` if the \
  ## Gfx's target is a window!
  result = gfx.target

proc openGfx*(win: RWindow): RGfx =
  ## Opens a Gfx for a window.
  result = RGfx(
    win: win,
    fbo: 0,
    width: win.width,
    height: win.height
  )
  result.init()
  result.initRoot()

proc newGfx*(width, height: int, texConf: RTextureConfig): RGfx =
  ## Creates a new, blank Gfx, with the specified size and texture config.
  ## The implementation uses framebuffers.
  result = RGfx(
    width: width,
    height: height
  )
  glGenFramebuffers(1, addr result.fbo)
  glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)
  result.target = newRTexture(width, height, nil, texConf)
  glFramebufferTexture2D(
    GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.target.id, 0)
  result.init()

#--
# Gfx context
#--

type
  RGfxContext* = ref object
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
    # Transformations
    # TODO: implement transformations
    projection, transform: Mat4f
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

template uniformProc(T: typedesc): untyped {.dirty.} =
  proc uniform*(ctx: var RGfxContext, name: string, val: T) =
    ## Sets a uniform in the currently bound program.
    ctx.program.uniform(name, val)
uniformProc(float)
uniformProc(Vec2f)
uniformProc(Vec3f)
uniformProc(Vec4f)
uniformProc(int)
uniformProc(Mat4f)

proc updateTransform(ctx: var RGfxContext) =
  ctx.uniform("rapid_transform", ctx.transform)

proc `program=`*(ctx: var RGfxContext, program: RProgram) =
  ## Binds a shader program for drawing operations.
  glUseProgram(program.id)
  ctx.program = program
  ctx.updateTransform()

proc defaultProgram*(ctx: var RGfxContext) =
  ## Binds the default shader program.
  ctx.`program=`(ctx.gfx.defaultProgram)

proc clear*(ctx: var RGfxContext, col: Color) =
  ## Clears the Gfx with the specified color.
  glClearColor(
    col.red.norm32, col.green.norm32, col.blue.norm32, col.alpha.norm32)
  glClear(GL_COLOR_BUFFER_BIT)

proc `color=`*(ctx: var RGfxContext, col: Color) =
  ## Sets a 'default' vertex color. This vertex color is used when no explicit \
  ## color is specified in the vertex.
  ctx.color = col

proc `texture=`*(ctx: var RGfxContext, tex: RTexture) =
  ## Sets the texture to draw with.
  if not ctx.textureEnabled:
    ctx.textureEnabled = true
    ctx.uniform("rapid_textureEnabled", 1)
  ctx.texture = tex

proc `texture=`*(ctx: var RGfxContext, tex: string) =
  ## Sets the texture to draw with, pulling it from the Gfx's ``RData``.
  assert not (isNil(ctx.gfx.data)),
    "A data object must be bound to the RGfx"
  assert ctx.gfx.data.images.hasKey(tex),
    "The texture \"" & tex & "\" doesn't exist"
  if not ctx.gfx.data.textures.hasKey(tex):
    ctx.gfx.data.textures[tex] = newRTexture(ctx.gfx.data.images[tex])
  ctx.`texture=`(ctx.gfx.data.textures[tex])

proc noTexture*(ctx: var RGfxContext) =
  ## Disables the texture, and draws with plain colors.
  if ctx.textureEnabled:
    ctx.textureEnabled = false
    ctx.uniform("rapid_textureEnabled", 0)

proc begin*(ctx: var RGfxContext) =
  ## Begins a new shape.
  ctx.vertexCount = 0
  ctx.shape.setLen(0)
  ctx.indices.setLen(0)

# TODO: replace this with a projection matrix
proc mapX(gfx: RGfx, x: float): float32 =
  result = x / float(gfx.width) * 2 - 1

proc mapY(gfx: RGfx, y: float): float32 =
  result =
    # ugh
    if gfx.fbo == 0: y / float(gfx.height) * -2 + 1
    else: y / float(gfx.height) * 2 - 1

proc vertex*(ctx: var RGfxContext,
             vert: RVertex): RVertexIndex {.discardable.} =
  ## Adds a vertex to the shape.
  result = RVertexIndex(ctx.vertexCount)
  ctx.shape.add([
    # Position
    float32 ctx.gfx.mapX(vert.x), ctx.gfx.mapY(vert.y),
    # Color
    vert.color.red.norm32, vert.color.green.norm32, vert.color.blue.norm32,
    vert.color.alpha.norm32,
    # Texture coordinates
    vert.u, vert.v
  ])
  inc(ctx.vertexCount)

proc vertex*(ctx: var RGfxContext,
             vert: RPointVertex): RVertexIndex {.discardable.} =
  ctx.vertex((vert.x, vert.y, ctx.color, 0.0, 0.0))

proc vertex*(ctx: var RGfxContext,
             vert: RTexVertex): RVertexIndex {.discardable.} =
  ctx.vertex((vert.x, vert.y, ctx.color, vert.u, vert.v))

proc index*(ctx: var RGfxContext, indices: varargs[RVertexIndex]) =
  ## Adds a vertex index to the shape. This is only required when the
  ## ``prShape`` primitive is used.
  for idx in indices: ctx.indices.add(int32(idx))

proc tri*[T: SomeVertex](ctx: var RGfxContext, a, b, c: T) =
  ## Adds a triangle, together with its indices.
  ctx.index(ctx.vertex(a))
  ctx.index(ctx.vertex(b))
  ctx.index(ctx.vertex(c))

proc quad*[T: SomeVertex](ctx: var RGfxContext, a, b, c, d: T) =
  ## Adds a quad, together with its indices.
  let
    i = ctx.vertex(a)
    j = ctx.vertex(b)
    k = ctx.vertex(c)
    l = ctx.vertex(d)
  ctx.index(i, j, l, j, k, l)

proc rect*(ctx: var RGfxContext,
           x, y, w, h: float,
           uv: tuple[x, y, w, h: float] = (0.0, 0.0, 1.0, 1.0)) =
  ## Adds a rectangle, at the specified coordinates, with the specified
  ## dimensions and texture coordinates.
  ## The texture coordinates are a tuple for easy usage with tile atlases \
  ## (see ``rapid/gfx/atlas``)
  ctx.quad(
    (x,     y,     uv.x,        uv.y),
    (x + w, y,     uv.x + uv.w, uv.y),
    (x + w, y + h, uv.x + uv.w, uv.y + uv.h),
    (x,     y + h, uv.x,        uv.y + uv.h))

proc draw*(ctx: var RGfxContext, primitive = prShape) =
  ## Draws the previously built shape.
  if ctx.shape.len > 0:
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, ctx.texture.id)
    ctx.gfx.updateVbo(ctx.shape)
    if primitive == prShape:
      ctx.gfx.updateEbo(ctx.indices)
      glDrawElements(
        GL_TRIANGLES, GLsizei ctx.indices.len, GL_UNSIGNED_INT, nil)
    else:
      glDrawArrays(
        case primitive
        of prPoints:   GL_POINTS
        of prLines:    GL_LINES
        of prTriStrip: GL_TRIANGLE_STRIP
        of prTriFan:   GL_TRIANGLE_FAN
        else:          GL_TRIANGLES,
        0, GLsizei ctx.vertexCount)

proc activate*(ctx: var RGfxContext) =
  ## Activates the Gfx context for drawing. This is only required when using \
  ## multiple Gfx objects.
  glBindFramebuffer(GL_FRAMEBUFFER, ctx.gfx.fbo)
  ctx.defaultProgram()
  glBindVertexArray(ctx.gfx.vaoID)
  glBindBuffer(GL_ARRAY_BUFFER, ctx.gfx.vboID)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ctx.gfx.eboID)

proc ctx*(gfx: RGfx): RGfxContext =
  ## Creates a Gfx context for the specified Gfx.
  result = RGfxContext(
    gfx: gfx,
    color: col(colWhite),
    transform: mat4(vec4(1.0'f32, 1.0, 1.0, 1.0))
  )

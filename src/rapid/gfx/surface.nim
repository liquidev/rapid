#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module handles drawing basic graphics. Other modules from the gfx \
## directory provide more advanced drawing, like texture atlases and text.

import macros
import math
import tables

import glm

import opengl
import ../res/textures
import ../lib/glad/gl
from ../lib/glfw import nil

export glm
export opengl.GLError

include rcolor
include window

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
    uniform bool rapid_renderText;
    uniform sampler2D rapid_texture;

    out vec4 rapid_fCol;

    vec4 rTexel(sampler2D tex, vec2 uv) {
      if (rapid_textureEnabled) {
        if (rapid_renderText) {
          return vec4(1.0, 1.0, 1.0, texture(tex, uv).r);
        } else {
          return texture(tex, uv);
        }
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
      return transform * pos;
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
  if not prog.uniformLocations.hasKey(name):
    prog.uniformLocations[name] = glGetUniformLocation(prog.id, name)
  var val = val

proc uniform(prog: RProgram, name: string, val: float) =
  ## Sets a uniform in the specified program.
  uniformCheck()
  glProgramUniform1f(prog.id, prog.uniformLocations[name], val)
proc uniform(prog: RProgram, name: string, val: Vec2f) =
  uniformCheck()
  glProgramUniform2fv(prog.id, prog.uniformLocations[name], 1, val.caddr)
proc uniform(prog: RProgram, name: string, val: Vec3f) =
  uniformCheck()
  glProgramUniform3fv(prog.id, prog.uniformLocations[name], 1, val.caddr)
proc uniform(prog: RProgram, name: string, val: Vec4f) =
  uniformCheck()
  glProgramUniform4fv(prog.id, prog.uniformLocations[name], 1, val.caddr)

proc uniform(prog: RProgram, name: string, val: int) =
  uniformCheck()
  glProgramUniform1i(prog.id, prog.uniformLocations[name], GLint val)

proc uniform(prog: RProgram, name: string, val: Mat4) =
  uniformCheck()
  glProgramUniformMatrix4fv(prog.id, prog.uniformLocations[name], 1, false, val.caddr)

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
    # Projection
    projection: Mat4f

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
  # Projection
  gfx.projection = ortho(0'f32, gfx.width.float, gfx.height.float, 0, -1, 1)

proc initRoot(gfx: RGfx) =
  gfx.win.onResize do (win: RWindow, width, height: Natural):
    glViewport(0, 0, GLsizei(width), GLsizei(height))
    gfx.width = width
    gfx.height = height
    gfx.projection = ortho(0'f32, width.float, height.float, 0, -1, 1)

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
    height: height,
  )
  echo result.projection
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
    color: RColor
    textureEnabled: bool
    texture: RTexture
    # Transformations
    transform*: Mat3f
  RVertex* = tuple
    x, y: float
    color: RColor
    u, v: float
  RPointVertex* = tuple
    x, y: float
  RTexVertex* = tuple
    x, y: float
    u, v: float
  RColVertex* = tuple
    x, y: float
    color: RColor
  SomeVertex = RPointVertex | RColVertex | RTexVertex | RVertex
  RVertexIndex* = distinct int32
  RPrimitive* = enum
    prPoints
    prLines, prLineStrip, prLineLoop
    prTris, prTriStrip, prTriFan
    prTriShape, prLineShape

converter toRVertex*(vert: RPointVertex): RVertex =
  (vert.x, vert.y, gray(255), 0.0, 0.0)

converter toRVertex*(vert: RTexVertex): RVertex =
  (vert.x, vert.y, gray(255), vert.u, vert.v)

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
  ctx.uniform("rapid_transform", ctx.gfx.projection)

proc `program=`*(ctx: var RGfxContext, program: RProgram) =
  ## Binds a shader program for drawing operations.
  glUseProgram(program.id)
  ctx.program = program
  ctx.updateTransform()

proc defaultProgram*(ctx: var RGfxContext) =
  ## Binds the default shader program.
  ctx.`program=`(ctx.gfx.defaultProgram)

proc translate*(ctx: var RGfxContext, x, y: float) =
  ctx.transform = ctx.transform * mat3f(
    vec3f(1.0, 0.0, 0.0),
    vec3f(0.0, 1.0, 0.0),
    vec3f(x, y, 1.0)
  )

proc scale*(ctx: var RGfxContext, x, y: float) =
  ctx.transform = ctx.transform * mat3f(
    vec3f(x, 0.0, 0.0),
    vec3f(0.0, y, 0.0),
    vec3f(0.0, 0.0, 1.0)
  )

proc rotate*(ctx: var RGfxContext, angle: float) =
  ctx.transform = ctx.transform * mat3f(
    vec3f(cos(angle), sin(angle), 0.0),
    vec3f(-sin(angle), cos(angle), 0.0),
    vec3f(0.0, 0.0, 1.0)
  )

template transform*(ctx: var RGfxContext, body: untyped): untyped =
  let prevTransform = ctx.transform
  body
  ctx.transform = prevTransform

proc clear*(ctx: var RGfxContext, col: RColor) =
  ## Clears the Gfx with the specified color.
  glClearColor(
    col.red, col.green, col.blue, col.alpha)
  glClear(GL_COLOR_BUFFER_BIT)

proc `color=`*(ctx: var RGfxContext, col: RColor) =
  ## Sets a 'default' vertex color. This vertex color is used when no explicit \
  ## color is specified in the vertex.
  ctx.color = col

proc noTexture*(ctx: var RGfxContext) =
  ## Disables the texture, and draws with plain colors.
  if ctx.textureEnabled:
    ctx.textureEnabled = false
    ctx.uniform("rapid_textureEnabled", 0)

proc `texture=`*(ctx: var RGfxContext, tex: RTexture) =
  ## Sets the texture to draw with.
  if tex.isNil:
    ctx.noTexture()
  else:
    if not ctx.textureEnabled:
      ctx.textureEnabled = true
      ctx.uniform("rapid_textureEnabled", 1)
    ctx.texture = tex

proc texture*(ctx: RGfxContext): RTexture =
  ## Returns the currently bound texture.
  if ctx.textureEnabled: result = ctx.texture
  else: result = nil

proc `lineWidth=`*(ctx: var RGfxContext, width: float) =
  glLineWidth(width)

proc `lineSmooth=`*(ctx: var RGfxContext, enable: bool) =
  if enable: glEnable(GL_LINE_SMOOTH)
  else: glDisable(GL_LINE_SMOOTH)

proc begin*(ctx: var RGfxContext) =
  ## Begins a new shape.
  ctx.vertexCount = 0
  ctx.shape.setLen(0)
  ctx.indices.setLen(0)

proc vertex*(ctx: var RGfxContext,
             vert: RVertex): RVertexIndex {.discardable.} =
  ## Adds a vertex to the shape.
  result = RVertexIndex(ctx.vertexCount)
  let p = ctx.transform * vec3f(vert.x, vert.y, 1.0)
  ctx.shape.add([
    # Position
    p.x, p.y,
    # Color
    vert.color.red, vert.color.green, vert.color.blue,
    vert.color.alpha,
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
  ## (see ``rapid/gfx/atlas``) and texture packing (see ``rapid/gfx/texpack``).
  ctx.quad(
    (x,     y,     uv.x,        uv.y),
    (x + w, y,     uv.x + uv.w, uv.y),
    (x + w, y + h, uv.x + uv.w, uv.y + uv.h),
    (x,     y + h, uv.x,        uv.y + uv.h))

proc circle*(ctx: var RGfxContext, x, y, r: float, points = 32) =
  ## Adds a circle, with the specified center and radius. An amount of points \
  ## can be specified to create an equilateral polygon.
  ## This proc does not use texture coordinates, since there are many ways of \
  ## specifying them for a circle (convert to cartesian, or use polar?)
  let center = ctx.vertex((x, y))
  var rim: seq[RVertexIndex]
  for i in 0..<points:
    let angle = i / (points - 1) * (2 * PI)
    rim.add(ctx.vertex((x + cos(angle) * r, y + sin(angle) * r)))
  for n, i in rim:
    ctx.index(center, i, rim[(n + 1) mod rim.len])

proc pie*(ctx: var RGfxContext, x, y, r, start, fin: float, points = 16) =
  ## Adds a pie, with the specified center, radius, and start and finish \
  ## angles. All angles should be expressed in radians.
  let center = ctx.vertex((x, y))
  var rim: seq[RVertexIndex]
  for i in 0..<points:
    let angle = start + i / (points - 1) * (fin - start)
    rim.add(ctx.vertex((x + cos(angle) * r, y + sin(angle) * r)))
  for n, i in rim:
    ctx.index(center, i, rim[(n + 1) mod rim.len])

proc line*[T: SomeVertex](ctx: var RGfxContext, a, b: T) =
  ## Adds a line with the specified points, for use with ``prLineShape``.
  ctx.index(ctx.vertex(a))
  ctx.index(ctx.vertex(b))

proc lquad*[T: SomeVertex](ctx: var RGfxContext, a, b, c, d: T) =
  ## Adds a quad outline, together with its indices.
  let
    i = ctx.vertex(a)
    j = ctx.vertex(b)
    k = ctx.vertex(c)
    l = ctx.vertex(d)
  ctx.index(i, j, j, k, k, l, l, i)

proc lrect*(ctx: var RGfxContext, x, y, w, h: float) =
  ## Adds a rectangle outline, at the specified coordinates, with the \
  ## specified dimensions.
  ## This isn't to be used with texturing; for rendering textures, see \
  ## ``rect()``.
  ctx.lquad(
    (x,     y),     (x + w, y),
    (x + w, y + h), (x,     y + h))

proc lcircle*(ctx: var RGfxContext, x, y, r: float, points = 32) =
  ## Adds a circle outline, with the specified center and radius. An amount of \
  ## points can be specified to create an equilateral polygon.
  var rim: seq[RVertexIndex]
  for i in 0..<points:
    let angle = i / (points - 1) * (2 * PI)
    rim.add(ctx.vertex((x + cos(angle) * r, y + sin(angle) * r)))
  for n, i in rim:
    ctx.index(i, rim[(n + 1) mod rim.len])

proc arc*(ctx: var RGfxContext, x, y, r, start, fin: float, points = 16) =
  ## Adds an arc, with the specified center, radius, and start and finish \
  ## angles. All angles should be expressed in radians.
  var rim: seq[RVertexIndex]
  for i in 0..<points:
    let angle = start + i / (points - 1) * (fin - start)
    rim.add(ctx.vertex((x + cos(angle) * r, y + sin(angle) * r)))
  for n in 0..<rim.len - 1:
    ctx.index(rim[n], rim[n + 1])

proc draw*(ctx: var RGfxContext, primitive = prTriShape) =
  ## Draws the previously built shape.
  if ctx.shape.len > 0:
    glActiveTexture(GL_TEXTURE0)
    if not ctx.texture.isNil: glBindTexture(GL_TEXTURE_2D, ctx.texture.id)
    ctx.updateTransform()
    ctx.gfx.updateVbo(ctx.shape)
    case primitive
    of prTriShape, prLineShape:
      ctx.gfx.updateEbo(ctx.indices)
      glDrawElements(
        case primitive
        of prTriShape: GL_TRIANGLES
        else: GL_LINES, GLsizei ctx.indices.len, GL_UNSIGNED_INT, nil)
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
  ## Creates a Gfx context for the specified Gfx.
  ## This should not be used by itself unless you know what you're doing!
  ## Use ``render`` and ``loop`` instead. This proc is exported because they \
  ## would not work without it.
  result = RGfxContext(
    gfx: gfx,
    color: gray(255),
    transform: mat3(vec3(1.0'f32, 1.0, 1.0))
  )

#--
# Rendering
#--

template render*(gfx: RGfx, ctx, body: untyped): untyped =
  ## Renders a single frame onto the specified window.
  with(gfx.win):
    var ctx {.inject.} = gfx.ctx()
    glBindFramebuffer(GL_FRAMEBUFFER, gfx.fbo)
    ctx.defaultProgram()
    glBindVertexArray(gfx.vaoID)
    glBindBuffer(GL_ARRAY_BUFFER, gfx.vboID)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gfx.eboID)
    body
    glfw.swapBuffers(gfx.win.handle)
    glfw.pollEvents()

proc calcMillisPerFrame(): float =
  let
    mon = glfw.getPrimaryMonitor()
    mode = glfw.getVideoMode(mon)
  result = 1 / mode.refreshRate

macro loop*(gfx: RGfx, body: untyped): untyped =
  ## Runs a game loop on the specified window. A ``draw`` and ``update`` event \
  ## must be provided (see example).
  ## The game loop is responsible for running the game at a constant speed, \
  ## independent of the hardware the game's running on.
  runnableExamples:
    var
      win = initRWindow()
        .size(800, 600)
        .open()
      gfx = win.openGfx
      x = 0.0
    gfx.loop:
      draw ctx, step:
        # The ctx should *never* be assigned to a variable outside of this
        # block's scope. Doing so is undefined behavior, and will cause problems
        # when rendering to multiple windows if special care is not taken.
        ctx.clear(col(colWhite))
        ctx.color = col(colBlack)
        ctx.rect(0, x, 32, 32)
      update step:
        x += step
  # What this macro does can technically be done using a proc, but for some
  # reason doing so causes a segmentation fault under Windows.
  var
    drawBody, updateBody: NimNode
    drawCtxName, drawStepName, updateStepName: NimNode
  body.expectKind(nnkStmtList)
  for st in body:
    st.expectKind(nnkCommand)
    st[1].expectKind(nnkIdent)
    if st[0].eqIdent("draw"):
      st[2].expectKind(nnkIdent)
      st[3].expectKind(nnkStmtList)
      drawCtxName = st[1]
      drawStepName = st[2]
      drawBody = st[3]
    elif st[0].eqIdent("update"):
      st[2].expectKind(nnkStmtList)
      updateStepName = st[1]
      updateBody = st[2]
    else:
      error("Invalid loop event! Must be 'draw' or 'update'", st)
  if drawBody.isNil: error("Missing draw event", body)
  if updateBody.isNil: error("Missing update event", body)
  result = quote do:
    glfw.swapInterval(1)

    let millisPerUpdate = calcMillisPerFrame()
    const millisPer60fps = 1 / 60
      # 60 fps is an arbitrary number, but gives a more natural time step to
      # work with in update functions, because this is the typical monitor
      # refresh rate
    var
      previous = float(glfw.getTime())
      lag = 0.0
    while glfw.windowShouldClose(`gfx`.win.handle) == 0:
      let
        current = float(glfw.getTime())
        elapsed = current - previous
      previous = current
      lag += elapsed

      while lag >= millisPerUpdate:
        block update:
          let `updateStepName` = elapsed / millisPer60fps
          `updateBody`
        lag -= millisPerUpdate

      block draw:
        let `drawStepName` = lag / millisPerUpdate
        `gfx`.render `drawCtxName`:
          `drawBody`

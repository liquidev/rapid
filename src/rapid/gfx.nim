#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module handles drawing basic graphics. Other modules from the gfx
## directory provide more advanced drawing, like texture atlases and text.

import macros
import math
import tables

import glm

import gfx/opengl
import gfx/shaders
import res/textures
import lib/glad/gl
from lib/glfw import nil

export glm
export opengl # unfortunate export, but it must be done
export shaders

export GLint, GLuint, GLsizei

include gfx/rcolor
include gfx/window

#--
# Default shaders
#--

const
  RVshLibSrc = """
    #version 330 core

    layout (location = 0) in vec2 rapid_vPos;
    layout (location = 1) in vec4 rapid_vCol;
    layout (location = 2) in vec2 rapid_vUV;

    uniform mat4 rapid_projection;

    out vec4 rapid_vfCol;
    out vec2 rapid_vfUV;

    vec4 rVertex(vec4 pos, mat4 projection);

    void main(void) {
      gl_Position =
        rVertex(vec4(rapid_vPos.x, rapid_vPos.y, 0.0, 1.0), rapid_projection);
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

    uniform float rapid_width;
    uniform float rapid_height;

    out vec4 rapid_fCol;

    vec4 rTexel(sampler2D tex, vec2 uv) {
      if (rapid_textureEnabled) {
        if (rapid_renderText) {
          return vec4(vec3(1.0), texture(tex, uv).r);
        } else {
          return texture(tex, uv);
        }
      } else {
        return vec4(1.0);
      }
    }

    vec4 rFragment(vec4 col, sampler2D tex, vec2 pos, vec2 uv);

    void main(void) {
      rapid_fCol = rFragment(rapid_vfCol, rapid_texture,
                             gl_FragCoord.xy, rapid_vfUV);
    }
  """
  RDefaultVshSrc* = """
    vec4 rVertex(vec4 pos, mat4 projection) {
      return projection * pos;
    }
  """
  RDefaultFshSrc* = """
    vec4 rFragment(vec4 col, sampler2D tex, vec2 pos, vec2 uv) {
      return rTexel(tex, uv) * col;
    }
  """

#--
# Canvas
#--

type
  RCanvasResizeFn* = proc (canvas: RCanvas, width, height: float)
  RCanvas* = ref object
    fWidth, fHeight: int
    fWindow: RWindow
    fb, rb: GLuint
    target: RTexture
    texConf: RTextureConfig
    cOnResize: seq[RCanvasResizeFn]

proc id*(canvas: RCanvas): GLuint =
  ## Retrieve a unique ID of the canvas. This ID is also a handle to the
  ## underlying OpenGL framebuffer.
  canvas.fb

proc width*(canvas: RCanvas): float =
  ## Get the width of the canvas.
  canvas.fWidth.float
proc height*(canvas: RCanvas): float =
  ## Get the height of the canvas.
  canvas.fHeight.float

proc window*(canvas: RCanvas): RWindow =
  ## Get the window bound to the canvas. For canvases that are not window-bound,
  ## this value is nil.
  canvas.fWindow

proc onResize*(canvas: RCanvas, callback: RCanvasResizeFn) =
  ## Add a callback to be called when the canvas is resized.
  canvas.cOnResize.add(callback)

proc updateFb(canvas: RCanvas) =
  if canvas.fb != 0:
    glDeleteFramebuffers(1, addr canvas.fb)
    canvas.target.unload()
  if canvas.rb != 0:
    glDeleteRenderbuffers(1, addr canvas.rb)
  glCreateFramebuffers(1, addr canvas.fb)
  canvas.target = newRTexture(canvas.fWidth, canvas.fHeight, nil,
                              canvas.texConf)
  glNamedFramebufferTexture(canvas.fb, GL_COLOR_ATTACHMENT0,
                            canvas.target.id, 0)
  glCreateRenderbuffers(1, addr canvas.rb)
  glNamedRenderbufferStorage(canvas.rb, GL_DEPTH24_STENCIL8,
                             canvas.width.GLsizei, canvas.height.GLsizei)
  glNamedFramebufferRenderbuffer(canvas.fb, GL_DEPTH_STENCIL_ATTACHMENT,
                                 GL_RENDERBUFFER, canvas.rb)
  withFramebuffer(currentGlc, canvas.fb):
    glClearColor(0.0, 0.0, 0.0, 0.0)
    glClearStencil(255)
    glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

proc resize*(canvas: RCanvas, width, height: float) =
  ## Resize the canvas.
  canvas.fWidth = width.int
  canvas.fHeight = height.int
  canvas.updateFb()
  for cb in canvas.cOnResize:
    cb(canvas, width.float, height.float)

proc init(canvas: RCanvas, width, height: int, conf: RTextureConfig) =
  canvas.fWidth = width
  canvas.fHeight = height
  canvas.texConf = conf
  canvas.updateFb()

proc newRCanvas*(width, height: float, conf = DefaultTextureConfig): RCanvas =
  ## Creates a new RCanvas with the specified dimensions.
  new(result)
  result.init(width.int, height.int, conf)

proc init(canvas: RCanvas, window: RWindow, conf: RTextureConfig) =
  canvas.init(window.width, window.height, conf)
  window.onResize do (win: RWindow, width, height: Natural):
    canvas.resize(width.float, height.float)

proc newRCanvas*(window: RWindow, conf = DefaultTextureConfig): RCanvas =
  ## Creates a new RCanvas bound to the dimensions of the specified window.
  result = RCanvas()
  result.init(window, conf)

#--
# Gfx
#--

type
  RGfx* = ref object
    win: RWindow
    fWidth, fHeight: int
    fCanvas: RCanvas
    # Default state
    vertexLibSh, fragmentLibSh: RShader
    defaultProgram: RProgram
    # Buffer objects
    vaoID, vboID, eboID: GLuint
    vboSize, eboSize: int
    # Projection
    projection: Mat4f
    # Rendering
    fVsync: bool

proc newRProgram*(gfx: RGfx, vertexSrc, fragmentSrc: string): RProgram =
  ## Creates a new ``RProgram`` from the specified shaders.
  ## See example for more details.
  runnableExamples:
    # Creates a new program, equivalent to the default.
    let myDefaultProgram = gfx.newRProgram(
      # Vertex shader
      """
        vec4 rVertex(vec4 pos, mat4 transform) {
          return transform * pos;
        }
      """,
      # Fragment shader
      """
        vec4 rFragment(vec4 col, sampler2D tex, vec2 pos, vec2 uv) {
          return rTexel(tex, uv) * col;
        }
      """)
    # A few extra variables are available for both shaders:
    let colors = gfx.newRProgram(
      # The default vertex shader source is public, the default fragment shader
      # has its source under the ``RDefaultFshSrc`` const.
      RDefaultVshSrc,
      """
        vec4 rFragment(vec4 col, sampler2D tex, vec2 pos, vec2 uv) {
          // ``rapid_width`` and ``rapid_height`` contain the width and height
          // of the drawing surface, be it a window or a canvas;
          // the ``pos`` argument contains the fragment's position on the screen
          vec4 myColor =
            // get normalized fragment coordinates
            // pos.(0, 0) is at the bottom left
            vec4(pos.x / rapid_width, pos.y / rapid_height, 1.0, 1.0);
          return rTexel(tex, uv) * col * myColor;
        }
      """)
  result = newRProgram()
  if int(gfx.vertexLibSh) == 0:
    gfx.vertexLibSh = newRShader(shVertex, RVshLibSrc)
  if int(gfx.fragmentLibSh) == 0:
    gfx.fragmentLibSh = newRShader(shFragment, RFshLibSrc)
  let
    vsh = newRShader(shVertex, """
      uniform float rapid_width;
      uniform float rapid_height;
    """ & vertexSrc)
    fsh = newRShader(shFragment, """
      uniform float rapid_width;
      uniform float rapid_height;

      vec4 rTexel(sampler2D tex, vec2 uv);
    """ & fragmentSrc)
  result.attach(gfx.vertexLibSh)
  result.attach(vsh)
  result.attach(gfx.fragmentLibSh)
  result.attach(fsh)
  result.link()
  glDeleteShader(vsh.GLuint)
  glDeleteShader(fsh.GLuint)
  result.uniform("rapid_texture", 0)

proc width*(gfx: RGfx): float =
  ## Get the width of a Gfx.
  gfx.fWidth.float
proc height*(gfx: RGfx): float =
  ## Get the height of a Gfx.
  gfx.fHeight.float

proc canvas*(gfx: RGfx): RCanvas =
  ## Get a special gfx-bound canvas.
  ## This canvas does not have a proper framebuffer bound to it; the canvas's
  ## ID is 0 pointing to the window's framebuffer.
  gfx.fCanvas

proc vsync*(gfx: RGfx): bool =
  ## Get whether VSync is enabled for the Gfx's window.
  gfx.fVsync
proc `vsync=`*(gfx: RGfx, enabled: bool) =
  ## Set whether VSync should be enabled for the Gfx's window. This must be done
  ## outside of the draw loop.
  gfx.fVsync = enabled

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

proc updateUniforms(prog: RProgram, proj: Mat4f, width, height: float) =
  prog.uniform("rapid_projection", proj)
  prog.uniform("rapid_width", width)
  prog.uniform("rapid_height", height)

proc init(gfx: RGfx) =
  # Settings
  glEnable(GL_BLEND)
  currentGlc.blendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glEnable(GL_STENCIL_TEST)
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
  # Projection
  currentGlc.viewport = (0.GLint, 0.GLint, gfx.width.GLsizei, gfx.height.GLsizei)
  gfx.projection = ortho(0'f32, gfx.width.float, gfx.height.float, 0, -1, 1)
  # Root canvas
  gfx.fCanvas = RCanvas(fWidth: gfx.fWidth, fHeight: gfx.fHeight, fb: 0)
  # Resizing
  gfx.win.onResize do (win: RWindow, width, height: Natural):
    currentGlc.viewport = (0.GLint, 0.GLint, width.GLsizei, height.GLsizei)
    gfx.fWidth = width
    gfx.fHeight = height
    gfx.canvas.fWidth = width
    gfx.canvas.fHeight = height
    for cb in gfx.canvas.cOnResize: cb(gfx.canvas, width.float, height.float)
    gfx.projection = ortho(0'f32, width.float, height.float, 0, -1, 1)

proc openGfx*(win: RWindow, fxTexConfig = DefaultTextureConfig): RGfx =
  ## Opens a Gfx for a window.
  result = RGfx(
    win: win,
    fWidth: win.width,
    fHeight: win.height,
    fVsync: true
  )
  result.init()

#--
# Gfx context
#--

type
  RGfxContext* = ref object
    fGfx: RGfx
    fCanvas: RCanvas
    # Shapes
    shape: seq[float32]
    indices: seq[int32]
    vertexCount: int
    # Painting
    # I hate prefixes, but this has to be done as a workaround to Nim/#11279
    sProgram: RProgram
    sColor: RColor
    sTextureEnabled: bool
    sTexture: RTexture
    sLineWidth: float
    sLineSmooth: bool
    # Transformations
    fTransform: Mat3[float]
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
  RStencilAction* = enum
    saReplace
    saInc, saDec
    saIncWrap, saDecWrap
    saInvert
  RStencilCondition* = enum
    scLess
    scLessEq
    scGreater
    scGreaterEq
    scEq
    scNotEq

proc gfx*(ctx: RGfxContext): RGfx =
  ## Get the context's parent Gfx.
  ctx.fGfx

converter toRVertex*(vert: RPointVertex): RVertex =
  (vert.x, vert.y, gray(255), 0.0, 0.0)

converter toRVertex*(vert: RTexVertex): RVertex =
  (vert.x, vert.y, gray(255), vert.u, vert.v)

converter toRVertex*(vert: RColVertex): RVertex =
  (vert.x, vert.y, vert.color, 0.0, 0.0)

template uniformProc(T: typedesc): untyped {.dirty.} =
  proc uniform*(ctx: RGfxContext, name: string, val: T) =
    ## Sets a uniform in the currently bound program.
    ctx.sProgram.uniform(name, val)
uniformProc(float)
uniformProc(Vec2f)
uniformProc(Vec3f)
uniformProc(Vec4f)
uniformProc(int)
uniformProc(Mat4f)

proc program*(ctx: RGfxContext): RProgram =
  ## Retrieves the currently bound shader program.
  result = ctx.sProgram

proc `program=`*(ctx: RGfxContext, program: RProgram) =
  ## Binds a shader program for drawing operations.
  glUseProgram(program.id)
  ctx.sProgram = program
  program.updateUniforms(ctx.fGfx.projection,
                         ctx.fCanvas.width, ctx.fCanvas.height)

proc defaultProgram*(ctx: RGfxContext) =
  ## Binds the default shader program.
  ctx.`program=`(ctx.fGfx.defaultProgram)

proc `transform=`*(ctx: RGfxContext, transform: Mat3[float]) =
  ## Set the affine transform to be used for drawing.
  ctx.fTransform = transform
proc transform*(ctx: RGfxContext): Mat3[float] =
  ## Get the affine transform used for drawing.
  ctx.fTransform

proc translate*(ctx: RGfxContext, x, y: float) =
  ## Translates the transform matrix.
  ctx.transform = ctx.transform * mat3(
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, 1.0, 0.0),
    vec3(x, y, 1.0)
  )

proc scale*(ctx: RGfxContext, x, y: float) =
  ## Scales the transform matrix.
  ctx.transform = ctx.transform * mat3(
    vec3(x, 0.0, 0.0),
    vec3(0.0, y, 0.0),
    vec3(0.0, 0.0, 1.0)
  )

proc rotate*(ctx: RGfxContext, angle: float) =
  ## Rotates the transform matrix.
  ctx.transform = ctx.transform * mat3(
    vec3(cos(angle), sin(angle), 0.0),
    vec3(-sin(angle), cos(angle), 0.0),
    vec3(0.0, 0.0, 1.0)
  )

proc resetTransform*(ctx: RGfxContext) =
  ## Resets the transform matrix.
  ctx.transform = mat3(1.0)

template transform*(ctx: RGfxContext, body: untyped): untyped =
  ## Isolates the current transform matrix, returning to the previous one
  ## after the block.
  let prevTransform = ctx.transform
  body
  ctx.transform = prevTransform

proc clear*(ctx: RGfxContext, col: RColor) =
  ## Clears the Gfx with the specified color.
  glClearColor(col.red, col.green, col.blue, col.alpha)
  glClear(GL_COLOR_BUFFER_BIT)

proc `color=`*(ctx: RGfxContext, col: RColor) =
  ## Sets a 'default' vertex color. This vertex color is used when no explicit
  ## color is specified in the vertex.
  ctx.sColor = col

proc noTexture*(ctx: RGfxContext) =
  ## Disables the texture, and draws with plain colors.
  currentGlc.blendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  if ctx.sTextureEnabled:
    ctx.sTextureEnabled = false
    ctx.uniform("rapid_textureEnabled", 0)

proc setTextureImpl(ctx: RGfxContext, tex: RTexture) =
  if tex.isNil:
    ctx.noTexture()
  else:
    if not ctx.sTextureEnabled:
      ctx.sTextureEnabled = true
      ctx.uniform("rapid_textureEnabled", 1)
    ctx.sTexture = tex

proc `texture=`*(ctx: RGfxContext, tex: RTexture) =
  ## Sets the texture to draw with.
  currentGlc.blendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  ctx.setTextureImpl(tex)

proc `texture=`*(ctx: RGfxContext, canvas: RCanvas) =
  ## Draws using a canvas as a texture.
  currentGlc.blendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA)
  ctx.setTextureImpl(canvas.target)

proc texture*(ctx: RGfxContext): RTexture =
  ## Returns the currently bound texture.
  if ctx.sTextureEnabled: result = ctx.sTexture
  else: result = nil

proc `lineWidth=`*(ctx: RGfxContext, width: float) =
  ## Sets the line width.
  ctx.sLineWidth = width
  glLineWidth(width)

proc `lineSmooth=`*(ctx: RGfxContext, enable: bool) =
  ## Sets if lines should be anti-aliased.
  ctx.sLineSmooth = enable
  if enable: glEnable(GL_LINE_SMOOTH)
  else: glDisable(GL_LINE_SMOOTH)

proc begin*(ctx: RGfxContext) =
  ## Begins a new shape.
  ctx.vertexCount = 0
  ctx.shape.setLen(0)
  ctx.indices.setLen(0)

proc vertex*(ctx: RGfxContext,
             vert: RVertex): RVertexIndex {.discardable.} =
  ## Adds a vertex to the shape.
  result = RVertexIndex(ctx.vertexCount)
  let p = ctx.transform * vec3(vert.x, vert.y, 1.0)
  ctx.shape.add([
    # Position
    p.x.float32, p.y.float32,
    # Color
    vert.color.red, vert.color.green, vert.color.blue,
    vert.color.alpha,
    # Texture coordinates
    vert.u, 1.0 - vert.v
  ])
  inc(ctx.vertexCount)

proc vertex*(ctx: RGfxContext,
             vert: RPointVertex): RVertexIndex {.discardable.} =
  ctx.vertex((vert.x, vert.y, ctx.sColor, 0.0, 0.0))

proc vertex*(ctx: RGfxContext,
             vert: RTexVertex): RVertexIndex {.discardable.} =
  ctx.vertex((vert.x, vert.y, ctx.sColor, vert.u, vert.v))

proc index*(ctx: RGfxContext, indices: varargs[RVertexIndex]) =
  ## Adds a vertex index to the shape. This is only required when the
  ## ``prShape`` primitive is used.
  for idx in indices: ctx.indices.add(int32(idx))

proc tri*[T: SomeVertex](ctx: RGfxContext, a, b, c: T) =
  ## Adds a triangle, together with its indices.
  ctx.index(ctx.vertex(a))
  ctx.index(ctx.vertex(b))
  ctx.index(ctx.vertex(c))

proc quad*[T: SomeVertex](ctx: RGfxContext, a, b, c, d: T) =
  ## Adds a quad, together with its indices.
  let
    i = ctx.vertex(a)
    j = ctx.vertex(b)
    k = ctx.vertex(c)
    l = ctx.vertex(d)
  ctx.index(i, j, l, j, k, l)

proc rect*(ctx: RGfxContext,
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

proc circle*(ctx: RGfxContext, x, y, r: float, points = 32) =
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

proc pie*(ctx: RGfxContext, x, y, r, start, fin: float, points = 16) =
  ## Adds a pie, with the specified center, radius, and start and finish \
  ## angles. All angles should be expressed in radians.
  let center = ctx.vertex((x, y))
  var rim: seq[RVertexIndex]
  for i in 0..<points:
    let angle = start + i / (points - 1) * (fin - start)
    rim.add(ctx.vertex((x + cos(angle) * r, y + sin(angle) * r)))
  for n in 0..<rim.len - 1:
    ctx.index(center, rim[n], rim[n + 1])

proc rrect*(ctx: RGfxContext, x, y, w, h, r: float, points = 8) =
  ## Adds a rounded rectangle, at the specified posision, with the specified
  ## size and corner radius.
  const HPi = PI / 2
  ctx.rect(x + r,     y,     w - r * 2, h)
  ctx.rect(x,         y + r, r,         h - r * 2)
  ctx.rect(x + w - r, y + r, r,         h - r * 2)
  ctx.pie(x + w - r, y + h - r, r, 0,       1 * HPi, points)
  ctx.pie(x + r,     y + h - r, r, 1 * HPi, 2 * HPi, points)
  ctx.pie(x + r,     y + r,     r, 2 * HPi, 3 * HPi, points)
  ctx.pie(x + w - r, y + r,     r, 3 * HPi, 4 * HPi, points)

proc point*[T: SomeVertex](ctx: RGfxContext, a: T) =
  ## Adds a point, for use with ``prPoints``.
  ctx.index(ctx.vertex(a))

template lineAux(body) =
  ## Make lines pixel-perfect by offsetting them by 0.5px when line width is odd
  let offset = ctx.sLineWidth mod 2 / 2
  ctx.translate(offset, offset)
  body
  ctx.translate(-offset, -offset)

proc line*[T: SomeVertex](ctx: RGfxContext, a, b: T) =
  ## Adds a line with the specified points, for use with ``prLineShape``.
  lineAux:
    ctx.index(ctx.vertex(a))
    ctx.index(ctx.vertex(b))

proc ltri*[T: SomeVertex](ctx: RGfxContext, a, b, c: T) =
  ## Adds a triangle outline, together with its indices.
  lineAux:
    let
      i = ctx.vertex(a)
      j = ctx.vertex(b)
      k = ctx.vertex(c)
    ctx.index(i, j, j, k, k, i)

proc lquad*[T: SomeVertex](ctx: RGfxContext, a, b, c, d: T) =
  ## Adds a quad outline, together with its indices.
  lineAux:
    let
      i = ctx.vertex(a)
      j = ctx.vertex(b)
      k = ctx.vertex(c)
      l = ctx.vertex(d)
    ctx.index(i, j, j, k, k, l, l, i)

proc lrect*(ctx: RGfxContext, x, y, w, h: float) =
  ## Adds a rectangle outline, at the specified coordinates, with the \
  ## specified dimensions.
  ## This isn't to be used with texturing; for rendering textures, see \
  ## ``rect()``.
  let
    w = w - 1
    h = h - 1
  ctx.line((x,     y),     (x + w, y))
  ctx.line((x + w, y),     (x + w, y + h))
  ctx.line((x + w, y + h), (x,     y + h))
  ctx.line((x,     y + h), (x,     y))

proc lcircle*(ctx: RGfxContext, x, y, r: float, points = 32) =
  ## Adds a circle outline, with the specified center and radius. An amount of \
  ## points can be specified to create an equilateral polygon.
  lineAux:
    var rim: seq[RVertexIndex]
    for i in 0..<points:
      let angle = i / (points - 1) * (2 * PI)
      rim.add(ctx.vertex((x + cos(angle) * r, y + sin(angle) * r)))
    for n, i in rim:
      ctx.index(i, rim[(n + 1) mod rim.len])

proc arc*(ctx: RGfxContext, x, y, r, start, fin: float, points = 16) =
  ## Adds an arc, with the specified center, radius, and start and finish \
  ## angles. All angles should be expressed in radians.
  lineAux:
    var rim: seq[RVertexIndex]
    for i in 0..<points:
      let angle = start + i / (points - 1) * (fin - start)
      rim.add(ctx.vertex((x + cos(angle) * r, y + sin(angle) * r)))
    for n in 0..<rim.len - 1:
      ctx.index(rim[n], rim[n + 1])

proc lrrect*(ctx: RGfxContext, x, y, w, h, r: float, points = 8) =
  ## Adds a rounded rectangle outline, at the specified posision, with the \
  ## specified size and corner radius.
  const HPi = PI / 2
  let
    w = w - 1
    h = h - 1
  ctx.line((x + r, y),     (x + w - r,     y))
  ctx.line((x + w, y + r), (x + w,         y + h - r))
  ctx.line((x + r, y + h), (x + w - r + 1, y + h))
  ctx.line((x,     y + r), (x,             y + h - r + 1))
  ctx.arc(x + w - r, y + h - r, r, 0,       1 * HPi, points)
  ctx.arc(x + r,     y + h - r, r, 1 * HPi, 2 * HPi, points)
  ctx.arc(x + r,     y + r,     r, 2 * HPi, 3 * HPi, points)
  ctx.arc(x + w - r, y + r,     r, 3 * HPi, 4 * HPi, points)

proc draw*(ctx: RGfxContext, primitive = prTriShape) =
  ## Draws the previously built shape.
  if ctx.shape.len > 0:
    if not ctx.texture.isNil:
      currentGlc.tex2D = ctx.texture.id
    ctx.fGfx.updateVbo(ctx.shape)
    case primitive
    of prTriShape, prLineShape:
      ctx.fGfx.updateEbo(ctx.indices)
      glDrawElements(case primitive
                     of prTriShape: GL_TRIANGLES
                     else: GL_LINES, GLsizei ctx.indices.len, GL_UNSIGNED_INT,
                     nil)
    else:
      glDrawArrays(case primitive
                   of prPoints:   GL_POINTS
                   of prLines:    GL_LINES
                   of prTriStrip: GL_TRIANGLE_STRIP
                   of prTriFan:   GL_TRIANGLE_FAN
                   else:          GL_TRIANGLES, 0, GLsizei ctx.vertexCount)

proc clearStencil*(ctx: RGfxContext, value = 255) =
  ## Clear the stencil buffer.
  glClearStencil(value.GLint)
  glClear(GL_STENCIL_BUFFER_BIT)

template stencil*(ctx: RGfxContext, action: RStencilAction, value: int,
                  body) =
  ## Draw to the stencil buffer. Color operations are disabled in the body.
  ## Use the ``stencilTest=`` proc to set the stencil test.
  ## This should not be nested!
  glColorMask(false, false, false, false)
  withStencilFunc(currentGlc, (GL_ALWAYS, value.GLint, 0xffffffff.GLuint)):
    withStencilOp(currentGlc, (GL_KEEP, GL_KEEP,
                  case action
                  of saReplace: GL_REPLACE
                  of saDec: GL_DECR
                  of saDecWrap: GL_DECR_WRAP
                  of saInc: GL_INCR
                  of saIncWrap: GL_INCR_WRAP
                  of saInvert: GL_INVERT)):
      body
  glColorMask(true, true, true, true)

proc `stencilTest=`*(ctx: RGfxContext,
                     test: tuple[condition: RStencilCondition, value: int]) =
  ## Sets the stencil test.
  ## The stencil test is used to restrict the rendering of fragments to only a
  ## specified shape, as specified by the stencil buffer's contents.
  ## For each fragment, if the stencil buffer's value meets the specified
  ## condition, the fragment is drawn. Otherwise it's discarded.
  ## This should not be used inside of ``stencil()``.
  currentGlc.stencilFunc = (
    (case test.condition
     of scEq: GL_EQUAL
     of scNotEq: GL_NOTEQUAL
     of scLess: GL_GREATER
     of scLessEq: GL_GEQUAL
     of scGreater: GL_LESS
     of scGreaterEq: GL_LEQUAL), test.value.GLint, 0xffffffff.GLuint)
  currentGlc.stencilOp = (GL_KEEP, GL_KEEP, GL_KEEP)

proc noStencilTest*(ctx: RGfxContext) =
  ## Disables the stencil test.
  currentGlc.stencilFunc = (GL_ALWAYS, 0.GLint, 255.GLuint)
  currentGlc.stencilOp = (GL_KEEP, GL_KEEP, GL_KEEP)

proc updateUniforms(ctx: RGfxContext) =
  ctx.program.updateUniforms(ctx.fGfx.projection,
                             ctx.fCanvas.width, ctx.fCanvas.height)

proc ctx*(gfx: RGfx): RGfxContext =
  ## Creates a Gfx context for the specified Gfx.
  ## This should not be used by itself unless you know what you're doing!
  ## Use ``render`` and ``loop`` instead. This proc is exported because they
  ## would not work without it.
  result = RGfxContext(
    fGfx: gfx,
    fCanvas: gfx.canvas,
    sColor: gray(255),
    sLineWidth: 1,
    fTransform: mat3(vec3(1.0, 1.0, 1.0))
  )
  result.defaultProgram()
  result.updateUniforms()

#--
# Rendering
#--

template renderTo*(ctx: RGfxContext, canvas: RCanvas, body) =
  ## Sets the target of rendering operations to the specified canvas, for the
  ## duration of the block.
  withFramebuffer(currentGlc, canvas.fb):
    let
      prevProj = ctx.gfx.projection
      prevCanvas = ctx.fCanvas
    ctx.fCanvas = canvas
    currentGlc.withViewport((0.GLint, 0.GLint,
                             canvas.width.GLsizei, canvas.height.GLsizei)):
      ctx.fGfx.projection = ortho(0'f32, canvas.width, canvas.height, 0, -1, 1)
      ctx.updateUniforms()
      body
    ctx.fCanvas = prevCanvas
    ctx.fGfx.projection = prevProj
    ctx.updateUniforms()

template render*(gfx: RGfx, ctxVar, body: untyped): untyped =
  ## Renders a single frame onto the specified window.
  with(gfx.win):
    var ctxVar {.inject.} = gfx.ctx()
    glfw.swapBuffers(gfx.win.handle)
    glfw.pollEvents()
    withFramebuffer(currentGlc, 0):
      glBindVertexArray(gfx.vaoID)
      glBindBuffer(GL_ARRAY_BUFFER, gfx.vboID)
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gfx.eboID)
      body

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
    initBody = newNimNode(nnkStmtList)
    initCtxName = ident"ctx"
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
    elif st[0].eqIdent("init"):
      st[2].expectKind(nnkStmtList)
      initCtxName = st[1]
      initBody = st[2]
    else:
      error("Invalid loop event! Must be 'init', 'draw' or 'update'", st)
  if drawBody.isNil: error("Missing draw event", body)
  if updateBody.isNil: error("Missing update event", body)
  result = quote do:
    glfw.swapInterval(int32(`gfx`.vsync))

    block init:
      # Render 2 frames to fill both buffers
      for frame in 1..2:
        `gfx`.render(`initCtxName`):
          `initBody`

    let millisPerUpdate = calcMillisPerFrame()
    const millisPer60fps = 1 / 60
      # 60 fps is an arbitrary number, but gives a more natural time step to
      # work with in update functions, because this is the typical monitor
      # refresh rate
    var
      previous = float(time())
      lag = 0.0
    while glfw.windowShouldClose(`gfx`.win.handle) == 0:
      let
        current = float(time())
        delta = current - previous
      previous = current
      lag += delta

      while lag >= millisPerUpdate:
        block update:
          let `updateStepName` = delta / millisPer60fps
          `updateBody`
        lag -= millisPerUpdate

      block draw:
        let `drawStepName` = delta / millisPer60fps
        `gfx`.render(`drawCtxName`):
          `drawBody`

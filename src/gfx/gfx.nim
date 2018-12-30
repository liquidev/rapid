import math, tables, deques

import ../lib/glad/gl

import ../data/data
import globjects
import color
import ../rmath
import ../scripting/autowren

const rDefaultVsh* = """
#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec4 color;
layout (location = 2) in vec2 texUV;

out vec4 vertexColor;
out vec2 uv;

void main() {
  gl_Position = vec4(position, 1.0);
  vertexColor = color;
  uv = texUV;
}
"""

const rDefaultFsh* = """
#version 330 core

in vec4 vertexColor;
in vec2 uv;

uniform int texEnabled;
uniform sampler2D tex;

out vec4 color;

void main() {
  vec4 texColor = vec4(1.0);
  if (texEnabled == 1) texColor = texture(tex, uv);
  color = texColor * vertexColor;
}
"""

var rDefaultProgram*: Program

type
  RGfx* = object
    width*, height*: int
    data: RData
    vao: VertexArray
    vbo: VertexBuffer
    ebo: ElementBuffer

    defaultProgram: Program
    textures: TableRef[string, Texture2D]
  RPrimitive* = enum
    rpIndexedTris, rpIndexedLines,
    rpLines, rpLineStrip, rpLineLoop,
    rpTris, rpTriStrip, rpTriFan

###
# Gfx Context
###

type
  RGfxContext* = object
    gfx: RGfx
    vao: VertexArray
    vbo: VertexBuffer
    ebo: ElementBuffer
    # Vertex properties
    index: uint32
    space: RGfxCoordSpace
    colVertex, colTint: RColor
    colVertq: Deque[RColor]
    texUV: tuple[u, v: float32]
    texUVq: Deque[tuple[u, v: float32]]
    # Shader properties
    program: Program
    textureEnabled: bool
    texture: Texture2D
  RGfxCoordSpace* = enum
    csNormalized, csAbsolute

proc width*(ctx: RGfxContext): int =
  ## Returns the context's RGfx's width.
  result = ctx.gfx.width

proc height*(ctx: RGfxContext): int =
  ## Returns the context's RGfx's height.
  result = ctx.gfx.height

proc clear*(ctx: RGfxContext, color: RColor) =
  ## Clears the RGfx with the specified color.
  glClearColor(color.rf, color.gf, color.bf, color.af)
  glClear(GL_COLOR_BUFFER_BIT)

proc shader*(ctx: var RGfxContext, shader: Program) =
  ## Uses the specified shader program.
  ctx.program = shader

proc uniform*(ctx: RGfxContext, name: string, value: Scalar[float32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec2[float32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec3[float32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec4[float32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Scalar[int32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec2[int32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec3[int32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec4[int32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Scalar[uint32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec2[uint32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec3[uint32]) = ctx.program.uniform(name, value)
proc uniform*(ctx: RGfxContext, name: string, value: Vec4[uint32]) = ctx.program.uniform(name, value)

proc color*(ctx: var RGfxContext, color: RColor) =
  ## Sets the vertex color for subsequent `vertex()` calls.
  ctx.colVertex = color

proc colors*(ctx: var RGfxContext, colors: varargs[RColor]) =
  ## Queues colors for vertices.
  for col in colors: ctx.colVertq.addLast(col)

proc tint*(ctx: var RGfxContext, color: RColor) =
  ## Sets the tint color for subsequent `draw()` calls.
  ## The tint is different from the vertex color, because unlike the vertex color, it's passed to the fragment shader.
  ctx.colTint = color

proc texture*(ctx: var RGfxContext, texture: string) =
  ## Sets the active texture to draw with.
  ctx.texture = ctx.gfx.textures[texture]
  glActiveTexture(GL_TEXTURE0)
  ctx.texture.use()
  ctx.uniform("texEnabled", 1'i32)

proc texture*(ctx: var RGfxContext) =
  ## Disables textures and draws with white.
  glActiveTexture(GL_TEXTURE0)
  ctx.uniform("texEnabled", 0'i32)

proc uv*(ctx: var RGfxContext, u, v: float32) =
  ## Sets the UV coordinates for subsequent vertex calls.
  ctx.texUV = (u, v)

proc uvs*(ctx: var RGfxContext, uvs: varargs[tuple[u, v: float]]) =
  ## Queues UV coordinates for vertices.
  for uv in uvs: ctx.texUVq.addLast((float32 uv.u, float32 uv.v))

proc coordSpace*(ctx: var RGfxContext, space: RGfxCoordSpace) =
  ## Sets the vertex coordinate space.
  ## If set to ``csAbsolute`` (default), the vertices will be drawn in absolute coordinates ``{ 0..width/height }``.
  ## If set to ``csNormalized``, the vertices will be drawn in normalized device coordinates ``{ -1..1 }``.
  ctx.space = space

proc begin*(ctx: var RGfxContext) =
  ## Begins a new shape. This should be called every time when a new primitive is to be drawn.
  ctx.vbo.clear()
  ctx.ebo.clear()
  ctx.index = 0

proc vertex*(ctx: var RGfxContext, x, y: float32, z: float32 = 0.0): uint32 =
  ## Adds a vertex with the specified coordinates, and returns its index.
  # get coords
  var dx, dy, dz: float32
  case ctx.space
  of csNormalized: dx = x; dy = y; dz = z
  of csAbsolute:
    dx = mapr(x, 0, ctx.gfx.width.float, -1, 1)
    dy = mapr(y, 0, ctx.gfx.height.float, 1, -1)
    dz = z # 3D operations should use the ``csNormalized`` coord space
  # get color
  let col = if ctx.colVertq.len > 0: ctx.colVertq.popFirst()
    else: ctx.colVertex
  # get UV
  let uv = if ctx.texUVq.len > 0: ctx.texUVq.popFirst()
    else: ctx.texUV
  ctx.vbo.add(
    # position
    dx, dy, dz,
    # color
    col.rf.float32, col.gf.float32, col.bf.float32, col.af.float32,
    # uv
    uv.u, uv.v)
  result = ctx.index
  ctx.index += 1

proc indices*(ctx: var RGfxContext, indices: varargs[uint32]) =
  for i in indices:
    ctx.ebo.add(i)

proc tri*(ctx: var RGfxContext,
    ax, ay, az, bx, by, bz, cx, cy, cz: float32): tuple[a, b, c: uint32] {.discardable.} =
  ## Adds a triangle.
  let
    a = ctx.vertex(ax, ay, az)
    b = ctx.vertex(bx, by, bz)
    c = ctx.vertex(cx, cy, cz)
  ctx.indices(a, b, c)
  result = (a, b, c)

proc tri*(ctx: var RGfxContext,
    ax, ay, bx, by, cx, cy: float32): tuple[a, b, c: uint32] {.discardable.} =
  ## 2D alias for ``tri()``.
  let
    a = ctx.vertex(ax, ay)
    b = ctx.vertex(bx, by)
    c = ctx.vertex(cx, cy)
  ctx.indices(a, b, c)
  result = (a, b, c)

proc quad*(ctx: var RGfxContext,
    ax, ay, az, bx, by, bz,
    cx, cy, cz, dx, dy, dz: float32): tuple[a, b, c, l: uint32] {.discardable.} =
  ## Adds a quad. Remembet that vertices must go clockwise, otherwise the quad will get distorted!
  let
    a = ctx.vertex(ax, ay, az)
    b = ctx.vertex(bx, by, bz)
    c = ctx.vertex(cx, cy, cz)
    d = ctx.vertex(dx, dy, dz)
  ctx.indices(a, b, c, c, d, a)
  result = (a, b, c, d)

proc quad*(ctx: var RGfxContext,
    ax, ay, bx, by, cx, cy, dx, dy: float32): tuple[a, b, c, d: uint32] {.discardable.} =
  ## 2D alias for ``quad()``.
  let
    a = ctx.vertex(ax, ay)
    b = ctx.vertex(bx, by)
    c = ctx.vertex(cx, cy)
    d = ctx.vertex(dx, dy)
  ctx.indices(a, b, c, c, d, a)
  result = (a, b, c, d)

proc rect*(ctx: var RGfxContext, x, y, width, height: float32): tuple[a, b, c, d: uint32] {.discardable.} =
  ## Draws a 2D rectangle, with the top-left corner at the specified coordinates, with the specified size.
  result = ctx.quad(x, y, x + width, y, x + width, y + height, x, y + height)

proc circle*(ctx: var RGfxContext, x, y, r: float32, precision: int = 0) =
  ## Draws a 2D circle, with the center at the specified coordinates, with the specified size.
  var p = precision
  if precision == 0: p = int(6.28 * r / 8) # this is supposed to be an estimate, that's why PI isn't used here
  let center = ctx.vertex(x, y)
  var rim: seq[uint32]
  for pt in 0..<p:
    let
      theta = pt.float / p.float * (2 * PI)
    rim.add(ctx.vertex(x + cos(theta) * r, y + sin(theta) * r))
  for i, v in rim:
    ctx.indices(center, v, rim[(i + 1) mod rim.len])

proc draw*(ctx: RGfxContext, primitive: RPrimitive = rpIndexedTris) =
  ## Draws the primitive currently stored in the buffer.
  ## To draw a new primitive after calling this function, use ``begin()``.
  ctx.vbo.update(0, ctx.vbo.len)
  with(ctx.vao):
    with(ctx.program):
      case primitive
      of rpTris, rpTriFan, rpTriStrip, rpLines, rpLineStrip, rpLineLoop:
        glDrawArrays(case primitive:
          of rpTris: GL_TRIANGLES
          of rpTriFan: GL_TRIANGLE_FAN
          of rpTriStrip: GL_TRIANGLE_STRIP
          of rpLines: GL_LINES
          of rpLineLoop: GL_LINE_LOOP
          of rpLineStrip: GL_LINE_STRIP
          else: GL_TRIANGLES, 0, GLsizei(ctx.vbo.len / 9))
      of rpIndexedTris, rpIndexedLines:
        ctx.ebo.update(0, ctx.ebo.len)
        ctx.ebo.use()
        glDrawElements(case primitive:
          of rpIndexedTris: GL_TRIANGLES
          of rpIndexedLines: GL_LINES
          else: GL_TRIANGLES, ctx.ebo.len.GLsizei, GL_UNSIGNED_INT, cast[pointer](0))

proc openContext(gfx: RGfx): RGfxContext =
  var ctx = RGfxContext(
    gfx: gfx,
    vao: gfx.vao, vbo: gfx.vbo, ebo: gfx.ebo,
    colVertex: color(255, 255, 255), colTint: color(255, 255, 255),
    texUVq: initDeque[tuple[u, v: float32]](),
    space: csAbsolute
  )
  glViewport(0, 0, gfx.width.GLint, gfx.height.GLint)
  return ctx

###
# Gfx
###

proc newRGfx*(width, height: int): RGfx =
  var gfx = RGfx(
    width: width, height: height,
  )
  return gfx

proc resize*(self: var RGfx, width, height: int) =
  self.width = width
  self.height = height

proc load*(self: var RGfx, data: RData) =
  self.data = data
  self.textures = newTable[string, Texture2D]()
  for name, img in data.images:
    var tex = newTexture2D(
      (img.width, img.height), img.data,
      pfRgba, pfRgba, GL_UNSIGNED_BYTE
    )
    var conf = img.config
    tex.minFilter = conf.interpMin
    tex.magFilter = conf.interpMag
    tex.wrap = conf.wrap
    if conf.mipmaps: tex.genMipmap()
    self.textures.add(name, tex)

proc start*(self: var RGfx) =
  self.defaultProgram = newProgram(rDefaultVsh, rDefaultFsh).link()
  var vao = newVAO()
  var vbo = newVBO(8196, bufDynamic)
  var ebo = newEBO(1024, bufDynamic)
  with(vao):
    ebo.use()
    with(vbo):
      vbo.attribs(
        (vaFloat, vaVec3),
        (vaFloat, vaVec4),
        (vaFloat, vaVec2)
      )
  self.vao = vao
  self.vbo = vbo
  self.ebo = ebo

  glFrontFace(GL_CW) # more convenient to work with

  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

proc render*(self: var RGfx, f: proc (ctx: var RGfxContext)) =
  var ctx = openContext(self)
  shader(ctx, self.defaultProgram)
  texture(ctx)
  f(ctx)

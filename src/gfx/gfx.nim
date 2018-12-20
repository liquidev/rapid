import math, tables

import ../lib/glad/gl

import ../data/data
import globjects
import color
import ../rmath

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

uniform bool texEnabled;
uniform sampler2D tex;

out vec4 color;

void main() {
  vec4 texColor = vec4(1.0);
  if (texEnabled) texColor = texture(tex, uv);
  color = texColor * vertexColor;
}
"""

var rDefaultProgram*: Program

type
  RGfx* = object
    width, height: int
    data: RData
    vao: VertexArray
    vbo: VertexBuffer

    defaultProgram: Program
    textures: TableRef[string, Texture2D]

###
# Gfx Context
###

type
  RGfxContext* = object
    gfx: RGfx
    vao: VertexArray
    vbo: VertexBuffer
    # Vertex properties
    space: RGfxCoordSpace
    colVertex, colTint: RColor
    texUV: tuple[u, v: float32]
    # Shader properties
    program: Program
    textureEnabled: bool
    texture: Texture2D # this is called texture0 because of naming conflicts
  RGfxCoordSpace* = enum
    csNormalized, csAbsolute

proc width*(ctx: RGfxContext): int =
  result = ctx.gfx.width

proc height*(ctx: RGfxContext): int =
  result = ctx.gfx.height

proc clear*(ctx: RGfxContext, color: RColor) =
  ## Clears the Gfx with the specified color.
  glClearColor(color.rf, color.gf, color.bf, color.af)
  glClear(GL_COLOR_BUFFER_BIT)

proc shader*(ctx: var RGfxContext, shader: Program) =
  ## Uses the specified shader program.
  ctx.program = shader

proc color*(ctx: var RGfxContext, color: RColor) =
  ## Sets the vertex color for subsequent `vertex()` calls.
  ctx.colVertex = color

proc tint*(ctx: var RGfxContext, color: RColor) =
  ## Sets the tint color for subsequent `draw()` calls.
  ## The tint is different from the vertex color, because unlike the vertex color, it doesn't affect the next vertex,
  ## but the whole rendered primitive.
  ctx.colTint = color

proc texture*(ctx: var RGfxContext, texture: string) =
  ## Sets the active texture to draw with.
  ctx.texture = ctx.gfx.textures[texture]
  ctx.textureEnabled = true

proc texture*(ctx: var RGfxContext) =
  ## Disables textures and draws with white.
  ctx.textureEnabled = false

proc uv*(ctx: var RGfxContext, u, v: float32) =
  ## Sets the UV coordinates for subsequent vertex calls.
  ctx.texUV = (u, v)

proc coordSpace*(ctx: var RGfxContext, space: RGfxCoordSpace) =
  ## Sets the vertex coordinate space.
  ## If set to `csAbsolute` (default), the vertices will be drawn in absolute coordinates `{ 0..width/height }`.
  ## If set to `csNormalized`, the vertices will be drawn in normalized device coordinates `{ -1..1 }`.
  ctx.space = space

proc begin*(ctx: var RGfxContext) =
  ## Begins a new shape. This should be called every time when a new primitive is to be drawn.
  var vbo = ctx.vbo
  vbo.clear()

proc vertex*(ctx: var RGfxContext, x, y: float32, z: float32 = 0.0) =
  ## Adds a vertex with the specified coordinates.
  let col = ctx.colVertex
  var dx, dy, dz: float32
  case ctx.space
  of csNormalized: dx = x; dy = y; dz = z
  of csAbsolute:
    dx = mapr(x, 0, ctx.gfx.width.float, -1, 1)
    dy = mapr(y, 0, ctx.gfx.height.float, 1, -1)
    dz = z # 3D operations should use the `csNormalized` coord space
  ctx.vbo.add(
    # position
    dx, dy, dz,
    # color
    col.rf.float32, col.gf.float32, col.bf.float32, col.af.float32,
    # uv
    ctx.texUV.u, ctx.texUV.v)

proc tri*(ctx: var RGfxContext,
    ax, ay, az, bx, by, bz, cx, cy, cz: float32) =
  ## Adds a triangle.
  ctx.vertex(ax, ay, az)
  ctx.vertex(bx, by, bz)
  ctx.vertex(cx, cy, cz)

proc tri*(ctx: var RGfxContext,
    ax, ay, bx, by, cx, cy: float32) =
  ## 2D alias for `tri()`.
  ctx.vertex(ax, ay)
  ctx.vertex(bx, by)
  ctx.vertex(cx, cy)

proc quad*(ctx: var RGfxContext,
    ax, ay, az, bx, by, bz,
    cx, cy, cz, dx, dy, dz: float32) =
  ## Adds a quad.
  ctx.tri(ax, ay, az, bx, by, bz, cx, cy, cz)
  ctx.tri(ax, ay, az, cx, cy, cz, dx, dy, dz)

proc quad*(ctx: var RGfxContext,
    ax, ay, bx, by, cx, cy, dx, dy: float32) =
  ## 2D alias for `quad()`.
  ctx.tri(ax, ay, bx, by, cx, cy)
  ctx.tri(ax, ay, cx, cy, dx, dy)

proc rect*(ctx: var RGfxContext, x, y, width, height: float32) =
  ## Draws a 2D rectangle, with the top-left corner at the specified coordinates, with the specified size.
  ctx.quad(x, y, x + width, y, x + width, y + height, x, y + height)

proc circle*(ctx: var RGfxContext, x, y, r: float32, precision: int = 0) =
  ## Draws a 2D circle, with the center at the specified coordinates, with the specified size.
  var p = precision
  if precision == 0: p = int(6.28 * r / 8) # this is supposed to be an estimate, that's why PI isn't used here
  for pt in 0..<p:
    let
      alpha = pt.float / p.float * (2 * PI)
      beta = (pt.float + 1) / p.float * (2 * PI)
    ctx.tri(
      x, y,
      x + cos(alpha) * r, y + sin(alpha) * r,
      x + cos(beta) * r, y + sin(beta) * r)

proc draw*(ctx: RGfxContext, primitive: Primitive = prTris) =
  ## Draws the primitive currently stored in the buffer.
  ## To draw a new primitive after calling this function, use `begin()`.
  ctx.vbo.update(0, ctx.vbo.len)
  with(ctx.vao):
    with(ctx.program):
      glDrawArrays(primitive.toGLenum, 0, GLsizei(ctx.vbo.len / 9))

proc openContext(gfx: RGfx): RGfxContext =
  var ctx = RGfxContext(
    gfx: gfx,
    vao: gfx.vao, vbo: gfx.vbo,
    colVertex: color(255, 255, 255), colTint: color(255, 255, 255),
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
    self.textures.add(name, tex)

proc start*(self: var RGfx) =
  self.defaultProgram = newProgram(rDefaultVsh, rDefaultFsh).link()
  var vao = newVAO()
  var vbo = newVBO(8196, vboDynamic)
  with(vao):
    with(vbo):
      vbo.attribs(
        (vaFloat, vaVec3),
        (vaFloat, vaVec4),
        (vaFloat, vaVec2)
      )
  self.vao = vao
  self.vbo = vbo
  glFrontFace(GL_CW)

proc render*(self: var RGfx, f: proc (ctx: var RGfxContext)) =
  var ctx = openContext(self)
  ctx.shader(self.defaultProgram)
  f(ctx)

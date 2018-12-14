import ../glad/gl

import globjects
import color

const rDefaultVsh* = """
#version 330 core

layout (location = 0) in vec3 position;

void main() {
  gl_Position = vec4(position, 1.0);
}
"""

const rDefaultFsh* = """
#version 330 core

out vec4 color;

void main() {
  color = vec4(1.0, 1.0, 1.0, 1.0);
}
"""

var rDefaultProgram*: Program

type
  RGfx* = object
    width, height: int
    defaultProgram: Program
    vao: VertexArray
    vbo: VertexBuffer
  RGfxContext* = object
    gfx: RGfx
    vao: VertexArray
    vbo: VertexBuffer

###
# Gfx Context
###

proc clear*(ctx: RGfxContext, color: RColor) =
  glClearColor(color.redf, color.greenf, color.bluef, color.alphaf)
  glClear(GL_COLOR_BUFFER_BIT)

proc shader*(ctx: RGfxContext, shader: Program) =
  glUseProgram(shader.id)

proc begin*(ctx: var RGfxContext) =
  var vbo = ctx.vbo
  vbo.clear(0)

proc vertex*(ctx: var RGfxContext, x, y, z: float) =
  ctx.vbo.add(x, y, z)

template vertex*(ctx: var RGfxContext, x, y: float): untyped =
  ctx.vertex(x, y, 0.0)

proc draw*(ctx: RGfxContext, primitive: Primitive) =
  ctx.vbo.update(0, ctx.vbo.len)
  with(ctx.vao):
    glDrawArrays(primitive.toGLenum, 0, GLsizei(ctx.vbo.len / 3))

proc openContext(gfx: RGfx): RGfxContext =
  var ctx = RGfxContext(
    gfx: gfx,
    vao: gfx.vao,
    vbo: gfx.vbo
  )

  return ctx

###
# Gfx
###

proc newRGfx*(width, height: int): RGfx =
  var gfx = RGfx(
    width: width, height: height
  )
  return gfx

proc resize*(self: var RGfx, width, height: int) =
  self.width = width
  self.height = height

proc start*(self: var RGfx) =
  glViewport(0, 0, self.width.GLint, self.height.GLint)
  self.defaultProgram = newProgram(rDefaultVsh, rDefaultFsh)
  var vao = newVAO()
  var vbo = newVBO(2048, vboDynamic)
  with(vao):
    with(vbo):
      vbo.attribs(
        (vaFloat, vaVec3)
      )
  self.vao = vao
  self.vbo = vbo

proc render*(self: var RGfx, f: proc (ctx: var RGfxContext)) =
  var ctx = openContext(self)
  ctx.shader(self.defaultProgram)
  f(ctx)

#~~
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#~~

import colors

import opengl
import window
import ../lib/glad/gl
import ../math/vectors

#~~
# Shaders
#~~

const
  RDefaultVsh* = """
    #version 330 core

    layout (location = 0) in vec2 vPos;

    void main(void) {
      gl_Position = vec4(vPos.x, vPos.y, 0.0, 1.0);
    }
  """
  RDefaultFsh* = """
    #version 330 core

    out vec4 color;

    void main(void) {
      color = vec4(1.0, 1.0, 1.0, 1.0);
    }
  """

type
  RShader* = object
    id: GLuint
  RShaderKind* = enum
    shVertex
    shFragment
  RProgram* = ref object
    id: GLuint
    attachedShaders: seq[RShader]

converter GLenum(shKind: RShaderKind): GLenum =
  case shKind
  of shVertex:   GL_VERTEX_SHADER
  of shFragment: GL_FRAGMENT_SHADER

proc newShader*(kind: RShaderKind, source: string): RShader =
  result.id = glCreateShader(kind)
  glShaderSource(result.id, 1, allocCStringArray([source]), nil)
  glCompileShader(result.id)
  # TODO: check for errors

proc newProgram*(): RProgram =
  new(result)
  result.id = glCreateProgram()

proc attach*(prog: RProgram, sh: RShader): RProgram =
  glAttachShader(prog.id, sh.id)
  prog.attachedShaders.add(sh)
  result = prog

proc attach*(prog: RProgram, shKind: RShaderKind, source: string): RProgram =
  result = prog.attach(newShader(shKind, source))

proc link*(prog: RProgram): RProgram =
  glLinkProgram(prog.id)
  # TODO: check for errors
  for sh in prog.attachedShaders:
    glDeleteShader(sh.id)
  prog.attachedShaders.setLen(0)
  result = prog

#~~
# Gfx
#~~

type
  RGfx = ref object
    win: RWindow
    id: GLuint

proc drawExample*(gfx: RGfx) =
  let vertices = @[
    float32 0.0, 0.5,
    0.5, -0.5,
    -0.5, -0.5
  ]
  var
    vao: GLuint
    vbo: ArrayBuffer[float32]
    program: RProgram

  glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)

  vbo = newArrayBuffer[float32](abkVertex, abuStatic)
  vbo.data = vertices
  vbo.update()

  program = newProgram()
    .attach(shVertex, RDefaultVsh)
    .attach(shFragment, RDefaultFsh)
    .link()

  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0, 2, cGL_FLOAT, false, 2 * sizeof(float32), cast[pointer](0))

  glUseProgram(program.id)
  glBindVertexArray(vao)
  vbo.use()
  glDrawArrays(GL_TRIANGLES, 0, 3)

proc openGfx*(win: RWindow): RGfx =
  new(result)
  result.win = win

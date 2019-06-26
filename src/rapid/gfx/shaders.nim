#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Shaders and shader programs.
## **Do not import this directly, it's included by the gfx module.**

import tables

import glm

import ../lib/glad/gl

type
  RShader* = distinct GLuint
  RShaderKind* = enum
    shVertex
    shFragment
  ShaderError* = object of Exception

proc newRShader*(kind: RShaderKind, source: string): RShader =
  ## Creates a new vertex or fragment shader, as specified by ``kind``, and
  ## compiles it. Raises a ``ShaderError`` when compiling fails.
  result = RShader(glCreateShader(case kind
                                  of shVertex:   GL_VERTEX_SHADER
                                  of shFragment: GL_FRAGMENT_SHADER))
  let cstr = allocCStringArray([source])
  glShaderSource(result.GLuint, 1, cstr, nil)
  deallocCStringArray(cstr)
  glCompileShader(result.GLuint)
  var isuccess: GLint
  glGetShaderiv(result.GLuint, GL_COMPILE_STATUS, addr isuccess)
  let success = isuccess.bool
  if not success:
    var logLength: GLint
    glGetShaderiv(result.GLuint, GL_INFO_LOG_LENGTH, addr logLength)
    var log = cast[ptr GLchar](alloc(logLength))
    glGetShaderInfoLog(result.GLuint, logLength, addr logLength, log)
    raise newException(ShaderError, $log)

type
  RProgram* = ref object
    id*: GLuint
    uniformLocations: Table[string, GLint]
  ProgramError* = object of Exception

proc newRProgram*(): RProgram =
  ## Creates a new ``RProgram``.
  result = RProgram(
    id: glCreateProgram(),
    uniformLocations: initTable[string, GLint]()
  )

proc attach*(program: var RProgram, shader: RShader) =
  ## Attaches a shader to a program.
  ## The ``RProgram`` is not a ``var RProgram``, because without it being \
  ## ``var`` we can easily chain calls together.
  glAttachShader(program.id, GLuint(shader))

proc link*(program: var RProgram) =
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

template uniformCheck() {.dirty.} =
  if not prog.uniformLocations.hasKey(name):
    prog.uniformLocations[name] = glGetUniformLocation(prog.id, name)
  var val = val

template progUniform(T: typedesc, body) {.dirty.} =
  proc uniform*(prog: RProgram, name: string, val: T) =
    uniformCheck()
    let
      p = prog.id
      l = prog.uniformLocations[name]
    body

template progPrimitiveUniform(T, suffix) {.dirty.} =
  progUniform(T):
    `glProgramUniform1 suffix`(p, l, val)
  progUniform(`Vec2 suffix`):
    `glProgramUniform2 suffix`(p, l, val.x, val.y)
  progUniform(`Vec3 suffix`):
    `glProgramUniform3 suffix`(p, l, val.x, val.y, val.z)
  progUniform(`Vec4 suffix`):
    `glProgramUniform4 suffix`(p, l, val.x, val.y, val.z, val.w)

progPrimitiveUniform(float, f)
progUniform(int): glProgramUniform1i(p, l, val.GLint)
progUniform(Mat4): glProgramUniformMatrix4fv(p, l, 1, false, val.caddr)

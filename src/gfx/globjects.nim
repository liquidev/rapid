import sequtils

import ../glad/gl

###
# Base OpenGL object
###

type
  GLObject = object of RootObj
    id*: GLuint

###
# Vertex Buffers
###

type
  VertexBuffer* = object of GLObject
    usage: VBOType
    vertices*: seq[float32]
    capacity, initcap: int
  VBOType* = enum
    vboStatic, vboDynamic, vboStream
  VertexAttrType* = enum
    vaFloat
  VertexAttrSize* = enum
    vaSingle = 1, vaVec2 = 2, vaVec3 = 3, vaVec4 = 4

var currentVBO*: GLuint

template with*(buf: VertexBuffer, stmts: untyped) =
  let previousVBO = currentVBO
  currentVBO = buf.id
  glBindBuffer(GL_ARRAY_BUFFER, currentVBO)
  stmts
  currentVBO = previousVBO
  glBindBuffer(GL_ARRAY_BUFFER, currentVBO)

proc realloc*(buf: var VertexBuffer, usage: VBOType) =
  buf.usage = usage
  with(buf):
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * buf.capacity, nil, case usage:
      of vboStream: GL_STREAM_DRAW
      of vboStatic: GL_STATIC_DRAW
      of vboDynamic: GL_DYNAMIC_DRAW)

proc update*(buf: VertexBuffer, offset: int, size: int) =
  with(buf):
    glBufferSubData(GL_ARRAY_BUFFER,
      sizeof(float) * offset, sizeof(float) * size,
      buf.vertices[0].unsafeAddr)
    discard

proc len*(buf: VertexBuffer): int =
  ## Returns the length of an attribute's data.
  result = buf.vertices.len

proc add*(buf: var VertexBuffer, vertices: varargs[float32]) =
  ## Adds values to a specified parameter in the VBO.
  # expand the buffer if necessary
  if buf.len + vertices.len > buf.capacity:
    buf.capacity += buf.initcap
    buf.realloc(buf.usage)
  # put the data into the array
  for i, v in vertices:
    buf.vertices.add(v)

proc attribs*(buf: var VertexBuffer, attribs: varargs[tuple[attrType: VertexAttrType, size: VertexAttrSize]]) =
  proc typesize(t: VertexAttrType): int =
    result = case t:
      of vaFloat: sizeof(float32)

  var stride = 0
  for a in attribs:
    stride += a.size.int * typesize(a.attrType)
  var offset = 0
  for i, a in attribs:
    glEnableVertexAttribArray(i.GLuint)
    glVertexAttribPointer(i.GLuint, a.size.int.GLint, case a.attrType:
      of vaFloat: cGL_FLOAT,
      false, stride.GLsizei, cast[pointer](offset))
    offset += a.size.int * typesize(a.attrType)

proc clear*(buf: var VertexBuffer) =
  buf.vertices.setLen(0)

proc newVBO*(capacity: int, usage: VBOType): VertexBuffer =
  var vbo_id: GLuint
  glGenBuffers(1, addr vbo_id)
  var buf = VertexBuffer(
    id: vbo_id, usage: usage,
    initcap: capacity,
    vertices: @[]
  )
  buf.realloc(usage)
  result = buf

###
# Vertex Attributes
###

type
  VertexArray* = object of GLObject

proc newVAO*(): VertexArray =
  var vao_id: GLuint
  glGenVertexArrays(1, addr vao_id)
  return VertexArray(
    id: vao_id
  )

var currentVAO*: GLuint

template with*(arr: VertexArray, stmts: untyped) =
  let previousVAO = currentVAO
  currentVAO = arr.id
  glBindVertexArray(currentVAO)
  stmts
  currentVAO = previousVAO
  glBindVertexArray(currentVAO)

template use*(arr: VertexArray) =
  currentVAO = arr.id
  glBindVertexArray(currentVAO)

###
# Shaders
###

type
  Shader* = object of GLObject
  VertexShader* = object of Shader
  FragmentShader* = object of Shader

proc newVertexShader*(sourceCode: string): VertexShader =
  ## Creates a new vertex shader from source code.

  # compile the shader
  let csrc = allocCStringArray([sourceCode])
  let sh_id = glCreateShader(GL_VERTEX_SHADER)
  glShaderSource(sh_id, 1, csrc, nil)
  deallocCStringArray(csrc)
  glCompileShader(sh_id)
  # check for errors
  var success: GLint; glGetShaderiv(sh_id, GL_COMPILE_STATUS, addr success)
  if success == 0:
    var len: GLint; glGetShaderiv(sh_id, GL_INFO_LOG_LENGTH, addr len)
    var err = cast[ptr GLchar](alloc(len))
    glGetShaderInfoLog(sh_id, len, addr len, err)
    raise newException(LibraryError, $err)
  # return the shader
  return VertexShader(id: sh_id)

proc newFragmentShader*(sourceCode: string): FragmentShader =
  ## Creates a new fragment shader from source code.

  # compile the shader
  let csrc = allocCStringArray([sourceCode])
  let sh_id = glCreateShader(GL_FRAGMENT_SHADER)
  glShaderSource(sh_id, 1, csrc, nil)
  deallocCStringArray(csrc)
  glCompileShader(sh_id)
  # check for errors
  var success: GLint; glGetShaderiv(sh_id, GL_COMPILE_STATUS, addr success)
  if success == 0:
    var len: GLint; glGetShaderiv(sh_id, GL_INFO_LOG_LENGTH, addr len)
    var err = cast[ptr GLchar](alloc(len))
    glGetShaderInfoLog(sh_id, len, addr len, err)
    raise newException(LibraryError, $err)
  # return the shader
  return FragmentShader(id: sh_id)

###
# Shader programs
###

type
  Program* = object of GLObject

proc newProgram*(vsh: VertexShader, fsh: FragmentShader): Program =
  ## Creates a new shader program.
  ## Note that this destroys the shaders in the process, so they can't be reused after that.

  # create the program
  let prog_id = glCreateProgram()
  glAttachShader(prog_id, vsh.id)
  glAttachShader(prog_id, fsh.id)
  glLinkProgram(prog_id)
  # check for errors
  var success: GLint
  glGetProgramiv(prog_id, GL_LINK_STATUS, addr success)
  if success != 1:
    var len: GLint; glGetProgramiv(prog_id, GL_INFO_LOG_LENGTH, addr len)
    var err = cast[ptr GLchar](alloc(len))
    glGetProgramInfoLog(prog_id, len, addr len, err)
    raise newException(LibraryError, $err)
  # destroy the shaders
  glDeleteShader(vsh.id)
  glDeleteShader(fsh.id)
  # return the program
  return Program(id: prog_id)

proc newProgram*(vertSource, fragSource: string): Program =
  ## Creates a new shader program.
  ## This is an overload that accepts strings as parameters, to simplify coding and remove unneccessary \
  ## type conversions.
  return newProgram(
    newVertexShader(vertSource),
    newFragmentShader(fragSource)
  )

###
# Primitives
###

type
  Primitive* = enum
    prPoints, prLineStrip, prLineLoop, prLines,
    prTriStrip, prTriFan, prTris

template toGLenum*(primitive: Primitive): untyped =
  case primitive:
    of prPoints: GL_POINTS
    of prLineStrip: GL_LINE_STRIP
    of prLineLoop: GL_LINE_LOOP
    of prLines: GL_LINES
    of prTriStrip: GL_TRIANGLE_STRIP
    of prTriFan: GL_TRIANGLE_FAN
    of prTris: GL_TRIANGLES

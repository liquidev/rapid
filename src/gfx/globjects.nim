## rapid - OpenGL wrapper
## copyright (c) iLiquid, 2018
## This module contains some OOP wrappers for OpenGL objects, to simplify coding.

import sequtils

import ../lib/glad/gl

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
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * buf.capacity, nil, case usage
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
    result = case t
      of vaFloat: sizeof(float32)

  var stride = 0
  for a in attribs:
    stride += a.size.int * typesize(a.attrType)
  var offset = 0
  for i, a in attribs:
    glEnableVertexAttribArray(i.GLuint)
    glVertexAttribPointer(i.GLuint, a.size.int.GLint, case a.attrType
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
  ShaderType* = enum
    stVert, stFrag

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
    vertShaders, fragShaders: seq[GLuint]
  UniformPrimitive =
    float32 | int32 | uint32
  UniformVec =
    tuple[x, y: UniformPrimitive] | tuple[x, y, z: UniformPrimitive] | tuple[x, y, z, w: UniformPrimitive]
  UniformType =
    UniformPrimitive | UniformVec

var currentProgram*: GLuint

template with*(program: Program, stmts: untyped) =
  let previousProgram = currentProgram
  currentProgram = program.id
  glUseProgram(currentProgram)
  stmts
  currentProgram = previousProgram
  glUseProgram(currentProgram)

proc use*(program: Program) =
  currentProgram = program.id
  glUseProgram(currentProgram)

proc newProgram*(): Program =
  ## Creates a new shader program.
  let prog_id = glCreateProgram()
  return Program(id: prog_id)

proc attach*(program: Program, vsh: VertexShader): Program =
  ## Attaches a vertex shader to the program.
  var program = program
  glAttachShader(program.id, vsh.id)
  program.vertShaders.add(vsh.id)
  program

proc attach*(program: Program, fsh: FragmentShader): Program =
  ## Attaches a fragment shader to the program.
  var program = program
  glAttachShader(program.id, fsh.id)
  program.fragShaders.add(fsh.id)
  program

proc attach*(program: Program, shaderType: ShaderType, source: string): Program =
  ## Creates and attaches a shader of type ``shaderType`` from ``source``.
  case shaderType
  of stVert: result = program.attach(newVertexShader(source))
  of stFrag: result = program.attach(newFragmentShader(source))

proc link*(program: Program): Program =
  ## Links the program. Note that this destroys all of its attached shaders in the process, and they can't be reused.
  glLinkProgram(program.id)
  var success: GLint
  glGetProgramiv(program.id, GL_LINK_STATUS, addr success)
  if success != 1:
    var len: GLint; glGetProgramiv(program.id, GL_INFO_LOG_LENGTH, addr len)
    var err = cast[ptr GLchar](alloc(len))
    glGetProgramInfoLog(program.id, len, addr len, err)
    raise newException(LibraryError, $err)
  for v in program.vertShaders: glDeleteShader(v)
  for f in program.fragShaders: glDeleteShader(f)
  result = program

proc uniform*[T: UniformType](program: Program, name: string, value: T) =
  let loc = glGetUniformLocation(program.id, name.cstring)
  case T
  of float32: glUniform1f(loc, value)
  of tuple[x, y: float32]: glUniform2f(loc, value.x, value.y)
  of tuple[x, y, z: float32]: glUniform3f(loc, value.x, value.y, value.z)
  of tuple[x, y, z, w: float32]: glUniform4f(loc, value.x, value.y, value.z, value.w)
  of int32: glUniform1i(loc, value)
  of tuple[x, y: int32]: glUniform2i(loc, value.x, value.y)
  of tuple[x, y, z: int32]: glUniform3i(loc, value.x, value.y, value.z)
  of tuple[x, y, z, w: int32]: glUniform4i(loc, value.x, value.y, value.z, value.w)
  of uint32: glUniform1i(loc, value)
  of tuple[x, y: uint32]: glUniform2ui(loc, value.x, value.y)
  of tuple[x, y, z: uint32]: glUniform3ui(loc, value.x, value.y, value.z)
  of tuple[x, y, z, w: uint32]: glUniform4ui(loc, value.x, value.y, value.z, value.w)

# TODO: Array uniforms

proc newProgram*(vertSource, fragSource: string): Program =
  ## Creates a new shader program with pre-attached vertex and fragment shaders,
  ## which are built from ``vertSource`` and ``fragSource``.
  ## Note that the shader still must be manually linked afterwards.
  return newProgram()
    .attach(newVertexShader(vertSource))
    .attach(newFragmentShader(fragSource))

###
# Primitives
###

type
  Primitive* = enum
    prPoints, prLineStrip, prLineLoop, prLines,
    prTriStrip, prTriFan, prTris

template toGLenum*(primitive: Primitive): untyped =
  case primitive
    of prPoints: GL_POINTS
    of prLineStrip: GL_LINE_STRIP
    of prLineLoop: GL_LINE_LOOP
    of prLines: GL_LINES
    of prTriStrip: GL_TRIANGLE_STRIP
    of prTriFan: GL_TRIANGLE_FAN
    of prTris: GL_TRIANGLES

###
# Textures
###

type
  Texture2D* = object of GLObject
  PixFormat* = enum
    pfRgb = GL_RGB
    pfRgba = GL_RGBA
  TexWrap* = enum
    twRepeat, twMirrorRepeat, twClampEdge, twClampBorder
  TexInterp* = enum
    tiNearest, tiLinear

var currentTexture*: GLuint

template with*(texture: Texture2D, stmts: untyped) =
  let previousTexture = currentTexture
  currentTexture = texture.id
  glBindTexture(GL_TEXTURE_2D, currentTexture)
  stmts
  currentTexture = previousTexture
  glBindTexture(GL_TEXTURE_2D, currentTexture)

proc newTexture2D*(
    size: tuple[width, height: int], data: string,
    internalFmt: PixFormat, fmt: PixFormat, dataType: GLenum): Texture2D =
  var texture_id: GLuint
  glGenTextures(1, addr texture_id)
  var texture = Texture2D(id: texture_id)
  with(texture):
    glTexImage2D(
      GL_TEXTURE_2D, 0, internalFmt.GLint,
      size.width.GLsizei, size.height.GLsizei, 0,
      fmt.GLenum, dataType, data.cstring)
  result = texture

proc genMipmap*(tex: Texture2D) =
  with(tex):
    glGenerateMipmap(GL_TEXTURE_2D)

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
    usage: BufferUsage
    vertices: seq[float32]
    capacity, initcap: int
  BufferUsage* = enum
    bufStatic, bufDynamic, bufStream
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

proc realloc*(buf: var VertexBuffer, usage: BufferUsage) =
  ## Reallocates the buffer's memory.
  buf.usage = usage
  with(buf):
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * buf.capacity, nil, case usage
      of bufStream: GL_STREAM_DRAW
      of bufStatic: GL_STATIC_DRAW
      of bufDynamic: GL_DYNAMIC_DRAW)

proc update*(buf: VertexBuffer, offset: int, size: int) =
  ## Updates a chunk of the buffer's memory.
  with(buf):
    glBufferSubData(GL_ARRAY_BUFFER,
      sizeof(float) * offset, sizeof(float) * size,
      buf.vertices[0].unsafeAddr)

proc len*(buf: VertexBuffer): int =
  ## Returns the length of the buffer's data.
  result = buf.vertices.len

proc add*(buf: var VertexBuffer, vertices: varargs[float32]) =
  ## Adds values to the VBO. This doesn't update any GPU memory!
  # expand the buffer if necessary
  if buf.len + vertices.len > buf.capacity:
    buf.capacity += buf.initcap
    buf.realloc(buf.usage)
  # put the data into the array
  for i, v in vertices:
    buf.vertices.add(v)

proc attribs*(buf: var VertexBuffer, attribs: varargs[tuple[attrType: VertexAttrType, size: VertexAttrSize]]) =
  ## Sets the vertex attributes for this VBO.
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
  ## Clears the vertex buffer. This doesn't update any GPU memory!
  buf.vertices.setLen(0)

proc newVBO*(capacity: int, usage: BufferUsage): VertexBuffer =
  ## Creates a new VBO with the specified capacity, and allocates memory for it.
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
# Element Buffers
###

type
  ElementBuffer* = object of GLObject
    usage: BufferUsage
    indices: seq[uint32]
    initcap, capacity: int

var currentEBO*: GLuint

template with*(buf: ElementBuffer, stmts: untyped) =
  let previousEBO = currentEBO
  currentEBO = buf.id
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, currentEBO)
  stmts
  currentEBO = previousEBO
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, currentEBO)

proc use*(buf: ElementBuffer) =
  currentEBO = buf.id
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, currentEBO)

proc realloc*(buf: var ElementBuffer, usage: BufferUsage) =
  ## Reallocates the buffer's memory.
  buf.usage = usage
  with(buf):
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(uint32) * buf.capacity, nil, case usage
      of bufStream: GL_STREAM_DRAW
      of bufStatic: GL_STATIC_DRAW
      of bufDynamic: GL_DYNAMIC_DRAW)

proc update*(buf: ElementBuffer, offset: int, size: int) =
  ## Updates a chunk of the buffer's memory.
  with(buf):
    glBufferSubData(GL_ELEMENT_ARRAY_BUFFER,
      sizeof(float) * offset, sizeof(float) * size,
      buf.indices[0].unsafeAddr)

proc len*(buf: ElementBuffer): int =
  ## Returns the length of the buffer's data.
  result = buf.indices.len

proc add*(buf: var ElementBuffer, indices: varargs[uint32]) =
  ## Adds values to the EBO. This doesn't send anything to the GPU!
  # expand the buffer if necessary
  if buf.len + indices.len > buf.capacity:
    buf.capacity += buf.initcap
    buf.realloc(buf.usage)
  # put the data into the array
  for i, e in indices:
    buf.indices.add(e)

proc clear*(buf: var ElementBuffer) =
  ## Clears the EBO. This doesn't send anything to the GPU!
  buf.indices.setLen(0)

proc newEBO*(capacity: int, usage: BufferUsage): ElementBuffer =
  ## Creates a new EBO with the specified capacity, and allocates memory for it.
  var ebo_id: GLuint
  glGenBuffers(1, addr ebo_id)
  var buf = ElementBuffer(
    id: ebo_id, usage: usage,
    initcap: capacity,
    indices: @[]
  )
  buf.realloc(usage)
  result = buf

###
# Vertex Arrays
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

template uloc() {.dirty.} =
  let loc = glGetUniformLocation(prog.id, name)

# TODO: use macros for this
proc uniform*(prog: Program, name: string, v: float32) =
  uloc(); with(prog): glUniform1f(loc, v)
proc uniform*(prog: Program, name: string, v: tuple[x, y: float32]) =
  uloc(); with(prog): glUniform2f(loc, v.x, v.y)
proc uniform*(prog: Program, name: string, v: tuple[x, y, z: float32]) =
  uloc(); with(prog): glUniform3f(loc, v.x, v.y, v.z)
proc uniform*(prog: Program, name: string, v: tuple[x, y, z, w: float32]) =
  uloc(); with(prog): glUniform4f(loc, v.x, v.y, v.z, v.w)
proc uniform*(prog: Program, name: string, v: int32) =
  uloc(); with(prog): glUniform1i(loc, v)
proc uniform*(prog: Program, name: string, v: tuple[x, y: int32]) =
  uloc(); with(prog): glUniform2i(loc, v.x, v.y)
proc uniform*(prog: Program, name: string, v: tuple[x, y, z: int32]) =
  uloc(); with(prog): glUniform3i(loc, v.x, v.y, v.z)
proc uniform*(prog: Program, name: string, v: tuple[x, y, z, w: int32]) =
  uloc(); with(prog): glUniform4i(loc, v.x, v.y, v.z, v.w)
proc uniform*(prog: Program, name: string, v: uint32) =
  uloc(); with(prog): glUniform1ui(loc, v)
proc uniform*(prog: Program, name: string, v: tuple[x, y: uint32]) =
  uloc(); with(prog): glUniform2ui(loc, v.x, v.y)
proc uniform*(prog: Program, name: string, v: tuple[x, y, z: uint32]) =
  uloc(); with(prog): glUniform3ui(loc, v.x, v.y, v.z)
proc uniform*(prog: Program, name: string, v: tuple[x, y, z, w: uint32]) =
  uloc(); with(prog): glUniform4ui(loc, v.x, v.y, v.z, v.w)

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

proc `wrap=`*(tex: Texture2D, wrapping: TexWrap) =
  with(tex):
    let enumWrapping = case wrapping:
      of twRepeat: GL_REPEAT
      of twMirrorRepeat: GL_MIRRORED_REPEAT
      of twClampEdge: GL_CLAMP_TO_EDGE
      of twClampBorder: GL_CLAMP_TO_BORDER
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, enumWrapping.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, enumWrapping.GLint)

proc toGLenum(e: TexInterp): GLenum =
  result = case e:
    of tiNearest: GL_NEAREST
    of tiLinear: GL_LINEAR

proc `minFilter=`*(tex: Texture2D, filter: TexInterp) =
  with(tex):
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter.toGLenum.GLint)

proc `magFilter=`*(tex: Texture2D, filter: TexInterp) =
  with(tex):
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter.toGLenum.GLint)

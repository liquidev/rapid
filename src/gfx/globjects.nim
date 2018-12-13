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
    vertices: seq[float]
    length, cap, icap: uint
    usage: VBOType
  VBOType* = enum
    vboStatic, vboDynamic, vboStream

var currentVBO*: GLuint

template with*(buf: VertexBuffer, stmts: untyped) =
  let previousVBO = currentVBO
  currentVBO = buf.id
  glBindBuffer(GL_ARRAY_BUFFER, currentVBO)
  stmts
  currentVBO = previousVBO
  echo "end: " & $previousVBO
  glBindBuffer(GL_ARRAY_BUFFER, currentVBO)

proc realloc*(buf: VertexBuffer) =
  with(buf):
    glBufferData(GL_ARRAY_BUFFER, sizeof(float) * buf.cap.int, nil, case buf.usage:
      of vboStatic: GL_STATIC_DRAW
      of vboDynamic: GL_DYNAMIC_DRAW
      of vboStream: GL_STREAM_DRAW)

proc update*(buf: VertexBuffer, index, length: int) =
  ## Updates a fragment of the buffer's data.
  with(buf):
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(float) * index, sizeof(float) * length, buf.vertices[index].unsafeAddr)
    echo currentVBO

proc add*[T](buf: var VertexBuffer, values: varargs[T]) =
  ## Adds a vertex to the buffer. If the buffer is overflown, its size will be
  ## increased by its initial capacity (but the buffer will not be reallocated).
  if buf.length.int + values.len > buf.cap.int:
    buf.cap += buf.icap
    buf.vertices.setLen(buf.cap)
  for i, v in values:
    buf.vertices[buf.length.int] = values[i]
    buf.length += 1

proc clear*(buf: var VertexBuffer) =
  ## Clears any vertices from the buffer.
  for i, v in buf.vertices:
    buf.vertices[i] = 0.0
  buf.length = 0

proc len*(buf: VertexBuffer): uint =
  return buf.length

proc newVBO*(size: uint, usage: VBOType): VertexBuffer =
  ## Creates a new VBO with the initial capacity of `size`.
  ## The `usage` should be chosen accordingly to the usage of the VBO:
  ##  - `vboStatic`, if the VBO's data isn't going to change, and the VBO's going to be used many times;
  ##  - `vboStream`, if the VBO's data isn't going to change, and the VBO's going to be used a few times;
  ##  - `vboDraw`, if the VBO's data is going to be modified repeatedly and used many times.
  ## If usage is not chosen correctly, low performance may occur due to how OpenGL allocates memory for the buffer.
  var vbo_id: GLuint
  glGenBuffers(GLsizei(1), addr vbo_id)
  var buf = VertexBuffer(
    id: vbo_id,
    vertices: newSeq[float](size),
    cap: size, icap: size,
    usage: usage
  )
  buf.realloc()

  return buf

###
# Vertex Attributes
###

type
  VertexArray* = object of GLObject
    atts: seq[tuple[loc: uint, number, size: int]]
  VertexAttributeType* = enum
    vaFloat, vaInt

proc newVAO*(): VertexArray =
  var vao_id: GLuint
  glGenVertexArrays(1, addr vao_id)
  return VertexArray(
    id: vao_id, atts: @[]
  )

proc add*(arr: var VertexArray, attribType: VertexAttributeType, location: uint, number: int) =
  let glType = case attribType:
    of vaInt: cGL_INT
    of vaFloat: cGL_FLOAT
  var offset = 0
  for att in arr.atts: offset += att.size
  arr.atts.add((location, number, number * sizeof(float)))
  glBindVertexArray(arr.id)
  glVertexAttribPointer(location.GLuint, number.GLint, glType, false, (number * sizeof(float)).GLsizei, cast[pointer](offset))
  glEnableVertexAttribArray(location.GLuint)
  glBindVertexArray(0)

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

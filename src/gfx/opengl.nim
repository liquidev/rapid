#~~
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#~~

import ../lib/glad/gl

type
  GLError* = object of Exception

type
  ArrayBuffer*[T] = ref object
    id*: GLuint
    kind: ArrayBufferKind
    usage: ArrayBufferUsage
    data*: seq[T]
    capacity: int
  ArrayBufferKind* = enum
    abkVertex
    abkElement
  ArrayBufferUsage* = enum
    abuStatic
    abuStream
    abuDynamic

converter GLenum*(abk: ArrayBufferKind): GLenum =
  case abk
  of abkVertex:  GL_ARRAY_BUFFER
  of abkElement: GL_ELEMENT_ARRAY_BUFFER

converter GLenum*(abu: ArrayBufferUsage): GLenum =
  case abu
  of abuStatic: GL_STATIC_DRAW
  of abuStream: GL_STREAM_DRAW
  of abuDynamic: GL_DYNAMIC_DRAW

var buffers*: array[low(ArrayBufferKind)..high(ArrayBufferKind), GLuint]
template with*(buf: ArrayBuffer, body: untyped): untyped =
  let previous = buffers[buf.kind]
  glBindBuffer(buf.kind, buf.id)
  buffers[buf.kind] = buf.id
  body
  glBindBuffer(buf.kind, previous)
  buffers[buf.kind] = previous

template use*(buf: ArrayBuffer): untyped =
  buffers[buf.kind] = buf.id
  glBindBuffer(buf.kind, buf.id)

proc realloc*[T](buf: var ArrayBuffer[T]) =
  with(buf):
    glBufferData(buf.kind, sizeof(T) * buf.capacity, nil, buf.usage)

proc update*[T](buf: var ArrayBuffer[T]) =
  with(buf):
    if buf.data.len > buf.capacity:
      buf.realloc()
    glBufferSubData(
      buf.kind,
      0, sizeof(T) * buf.data.len,
      buf.data[0].unsafeAddr)

proc newArrayBuffer*[T](kind: ArrayBufferKind,
                        usage: ArrayBufferUsage): ArrayBuffer[T] =
  result = ArrayBuffer[T](
    kind: kind,
    usage: usage,
    capacity: 8
  )
  glGenBuffers(1, addr result.id)
  result.realloc()

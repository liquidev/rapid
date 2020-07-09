## Generic RGBA image buffer.

import aglet/pixeltypes
import aglet/rect

import ../math as rmath

type
  Image* = object
    width*, height*: int32
    data*: seq[uint8]

proc `[]`*(image: Image, position: Vec2i): Rgba8 {.inline.} =
  ## Returns the pixel at the given position.

  let
    redIndex = position.x + position.y * image.width * 4
    greenIndex = redIndex + 1
    blueIndex = greenIndex + 1
    alphaIndex = blueIndex + 1
  result = rgba8(
    image.data[redIndex],
    image.data[greenIndex],
    image.data[blueIndex],
    image.data[alphaIndex],
  )

proc `[]`*(image: Image, x, y: int32): Rgba8 {.inline.} =
  ## Shortcut for querying a pixel with a vector.
  image[vec2i(x, y)]

proc `[]=`*(image: var Image, position: Vec2i, pixel: Rgba8) {.inline.} =
  ## Sets the pixel at the given position.

  let
    redIndex = position.x + position.y * image.width * 4
    greenIndex = redIndex + 1
    blueIndex = greenIndex + 1
    alphaIndex = blueIndex + 1
  image.data[redIndex] = pixel.r
  image.data[greenIndex] = pixel.g
  image.data[blueIndex] = pixel.b
  image.data[alphaIndex] = pixel.a

proc `[]=`*(image: var Image, x, y: int32, pixel: Rgba8) {.inline.} =
  ## Shortcut for setting a pixel with a vector.

  image[vec2i(x, y)] = pixel

proc `[]`*(image: Image, rect: Recti): Image =
  ## Copies a subsection of the given image and returns it.

  assert rect.x >= 0 and rect.y >= 0, "rect coordinates must be inbounds"
  assert rect.x + rect.width < image.width and
         rect.y + rect.height < image.height,
         "rect must not extend beyond the image's size"

  result.data.setLen(rect.width * rect.height * 4)
  for y in rect.top..rect.bottom:
    for x in rect.left..rect.right:
      let resultPosition = vec2i(x - rect.x, y - rect.y)
      result[resultPosition] = image[x, y]

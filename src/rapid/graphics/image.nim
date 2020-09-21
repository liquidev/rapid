## Generic RGBA image buffer.

import aglet/pixeltypes
import aglet/rect
from nimPNG import decodePng32
import nimPNG/results

import ../math as rmath

type
  Image* {.byref.} = object
    width*, height*: int32
    data*: seq[uint8]

proc `[]`*(image: Image, position: Vec2i): Rgba8 {.inline.} =
  ## Returns the pixel at the given position.

  let
    redIndex = (position.x + position.y * image.width) * 4
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

proc debugRepr*(image: Image): string =
  ## Returns a string containing the image represented in ASCII. For debugging
  ## purposes only.

  for y in 0..<image.height:
    if y > 0: result.add('\n')
    for x in 0..<image.width:
      const Intensities = " .:=+*#"
      let
        pixel = image[x, y]
        intensity = (pixel.r.int / 255 +
                     pixel.g.int / 255 +
                     pixel.b.int / 255) / 3 *
                    (pixel.a.int / 255)
      result.add(Intensities[int(intensity * Intensities.len.float)])

proc `[]=`*(image: var Image, position: Vec2i, pixel: Rgba8) {.inline.} =
  ## Sets the pixel at the given position.

  let
    redIndex = (position.x + position.y * image.width) * 4
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
  assert rect.x + rect.width <= image.width and
         rect.y + rect.height <= image.height,
         "rect must not extend beyond the image's size"

  result.width = rect.width
  result.height = rect.height
  result.data.setLen(rect.width * rect.height * 4)
  for y in rect.top..<rect.bottom:
    for x in rect.left..<rect.right:
      let resultPosition = vec2i(x - rect.x, y - rect.y)
      result[resultPosition] = image[x, y]

proc init*(image: var Image, size: Vec2i) =
  ## Initializes an empty image buffer.

  image.width = size.x
  image.height = size.y
  image.data.setLen(image.width * image.height * 4)

proc readPng*(image: var Image, data: string) =
  ## Reads a PNG image from the given string containing a PNG image.

  let png = decodePng32(data)
  image.width = png.width.int32
  image.height = png.height.int32
  image.data.setLen(png.data.len)
  copyMem(image.data[0].addr, png.data[0].addr, png.data.len)

proc loadPng*(image: var Image, filename: string) =
  ## Loads a PNG image from the given path.
  image.readPng(readFile(filename))

proc initImage*(size: Vec2i): Image {.inline.} =
  ## Creates and initializes an empty image buffer.
  result.init(size)

proc readPngImage*(data: string): Image {.inline.} =
  ## Creates and reads a PNG image from the given string containing a PNG image.
  result.readPng(data)

proc loadPngImage*(filename: string): Image {.inline.} =
  ## Creates and loads a PNG image from the given path.
  result.loadPng(filename)

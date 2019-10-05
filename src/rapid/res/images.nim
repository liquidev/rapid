#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Basic image loading and manipulation.

import nimPNG

type
  RImage* = ref object
    width*, height*: int
    data*: string

proc area*(img: RImage): int = img.width * img.height

proc newRImage*(width, height: int, data: string, colorChannels = 4): RImage =
  ## Create a new image, with the specified size, data, and amount of color
  ## channels. The resulting image will be flipped in the Y axis, so it can be
  ## used in OpenGL.
  result = RImage(
    width: width, height: height,
    data: ""
  )
  for y in countdown(height - 1, 0):
    let offset = y * width * colorChannels
    result.data.add(data[offset..<offset + width * colorChannels])

proc newRImage*(width, height: int, data: pointer, colorChannels = 4): RImage =
  ## Create a new image with data specified by where ``data`` points to.
  ## Exactly ``width * height * colorChannels`` bytes will be copied from the
  ## destination of ``data``.
  var dataStr = newString(width * height * colorChannels)
  if width * height > 0:
    copyMem(dataStr[0].unsafeAddr, data, width * height * colorChannels)
  result = newRImage(width, height, dataStr, colorChannels)

proc loadRImage*(path: string): RImage =
  ## Load an RGBA PNG image from the specified path.
  let png = loadPNG32(path)
  result = newRImage(png.width, png.height, png.data)

proc readRImagePng*(png: string): RImage =
  ## Reads a PNG image from memory. This is most useful when used in conjunction
  ## with ``slurp``/``staticRead``, and allows for embedding resources in the
  ## executable itself.
  let png = decodePNG32(png)
  result = newRImage(png.width, png.height, png.data)

proc caddr*(img: RImage): ptr char =
  ## Get a pointer to raw image data.
  result = img.data[0].unsafeAddr

proc subimg*(img: RImage, x, y, w, h: int): RImage =
  ## Grabs an area of an image and creates a new image out of it.
  result = RImage(
    width: w, height: h
  )
  let trueY = img.height - y - h
  for y in trueY..<trueY + h:
    let offset = y * img.width * 4
    result.data.add(img.data[offset + x * 4..<offset + (x + w) * 4])

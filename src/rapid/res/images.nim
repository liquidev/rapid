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

proc newRImage*(width, height: int, data: string, colorChannels = 4): RImage =
  result = RImage(
    width: width, height: height,
    data: ""
  )
  for y in countdown(height - 1, 0):
    let offset = y * width * colorChannels
    result.data.add(data[offset..<offset + width * colorChannels])

proc newRImage*(width, height: int, data: pointer, colorChannels = 4): RImage =
  var dataStr = newString(width * height)
  if width * height > 0:
    copyMem(dataStr[0].unsafeAddr, data, width * height)
  result = newRImage(width, height, dataStr, colorChannels)

proc loadRImage*(path: string): RImage =
  let png = loadPNG32(path)
  result = newRImage(png.width, png.height, png.data)

proc caddr*(img: RImage): ptr char =
  result = img.data[0].unsafeAddr

proc subimg*(img: RImage, x, y, w, h: int): RImage =
  result = RImage(
    width: w, height: h
  )
  let trueY = img.height - y - h
  for y in trueY..<trueY + h:
    let offset = y * img.width * 4
    result.data.add(img.data[offset + x * 4..<offset + (x + w) * 4])

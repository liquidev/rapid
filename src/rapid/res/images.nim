#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## Basic image loading and manipulation.

import nimPNG

type
  RImage* = ref object
    width*, height*: int
    data*: string

proc newRImage*(path: string): RImage =
  let png = loadPNG32(path)
  result = RImage(
    width: png.width, height: png.height,
    data: png.data
  )

proc caddr*(img: RImage): ptr char =
  result = img.data[0].unsafeAddr

proc subimg*(img: RImage, x, y, w, h: int): RImage =
  result = RImage(
    width: w, height: h
  )
  for y in y..<y + h:
    let offset = y * img.width * 4
    result.data.add(img.data[offset + x * 4..<offset + (x + w) * 4])

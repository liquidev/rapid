#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module has some utility color manipulation procs.
## **Do not import this directly, it's included by the surface module.**

type
  ColorCh* = range[0..255]
  RColor* = tuple
    red, green, blue, alpha: float

proc rgb*(r, g, b: float): RColor =
  (r, g, b, 1.0)

proc rgba*(r, g, b, a: float): RColor =
  (r, g, b, a)

proc rgb*(r, g, b: ColorCh): RColor =
  (r / 255, g / 255, b / 255, 1.0)

proc rgba*(r, g, b, a: ColorCh): RColor =
  (r / 255, g / 255, b / 255, a / 255)

proc gray*(gray: ColorCh, a = 255.ColorCh): RColor =
  result = rgba(gray, gray, gray, a)

proc ired*(col: RColor): ColorCh = int(col.red * 255)
proc igreen*(col: RColor): ColorCh = int(col.green * 255)
proc iblue*(col: RColor): ColorCh = int(col.blue * 255)
proc ialpha*(col: RColor): ColorCh = int(col.alpha * 255)

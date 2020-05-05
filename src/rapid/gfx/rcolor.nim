#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module implements a basic OpenGL color class. This differs from Nim's
## ``colors`` module, because colors are stored as 4 floats instead of a single
## integer.
## **Do not import this directly, it's included by the gfx module.**

import parseutils

import glm/vec

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

proc hex*(str: string): RColor =
  ## Parses a hex code into a color.
  ## Possible combinations are RGB, RGBA, RRGGBB, or RRGGBBAA.
  ## An extra # is allowed at the beginning.
  ## Anything else triggers an assertion.
  var str = str
  if str.len > 0 and str[0] == '#':
    str = str[1..^1]
  assert str.len in [3, 4, 6, 8]
  var
    r, g, b: int
    a = 255
  case str.len
  of 3, 4:
    assert parseHex(str[0] & str[0], r) != 0
    assert parseHex(str[1] & str[1], g) != 0
    assert parseHex(str[2] & str[2], b) != 0
    if str.len == 4:
      assert parseHex(str[3] & str[3], a) != 0
  of 6, 7:
    assert parseHex(str[0..1], r) != 0
    assert parseHex(str[2..3], g) != 0
    assert parseHex(str[4..5], b) != 0
    if str.len == 7:
      assert parseHex(str[6..7], a) != 0
  else: discard # unreachable
  result = rgba(r, g, b, a)

proc ired*(col: RColor): ColorCh = int(col.red * 255)
proc igreen*(col: RColor): ColorCh = int(col.green * 255)
proc iblue*(col: RColor): ColorCh = int(col.blue * 255)
proc ialpha*(col: RColor): ColorCh = int(col.alpha * 255)

proc mix*(a, b: RColor, t: float): RColor =
  result = (
    mix(a.red, b.red, t),
    mix(a.green, b.green, t),
    mix(a.blue, b.blue, t),
    mix(a.alpha, b.alpha, t)
  )

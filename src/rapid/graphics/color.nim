## Color handling utilities.

import std/colors
import std/strutils

import aglet/pixeltypes

export colors except Color, rgb

type
  Color* = Rgba32f
    ## Alias for colors.

converter rgba32f*(color: colors.Color): Color {.inline.} =
  ## Converts an stdlib color to a rapid color.

  let (r, g, b) = color.extractRgb
  result = rgba32f(r / 255, g / 255, b / 255, 1)

proc hex*(hex: string): Color =
  ## Parses a hexadecimal color.
  ##
  ## Syntax:
  ##
  ## .. code-block::
  ##  hexDigit <- [0-9a-fA-F]
  ##  color <- '#'? (hexDigit{6} hexDigit{2}? / hexDigit{3} hexDigit?)
  ##
  ## Examples:
  ##
  ## - ``ffffff`` == ``fff``
  ## - ``#ffffff`` == ``#fff``
  ## - ``#09aaff``
  ## - ``#1af`` == ``#11aaff``
  ## - ``00000033`` == ``0003``

  var hex = hex
  if hex[0] == '#':
    hex = hex[1..^1]

  assert hex.len in {3, 4, 6, 8},
    "hex color must be formatted as #RGB, #RGBA, #RRGGBB, or #RRGGBBAA"

  var r, g, b, a: int

  case hex.len
  of 3, 4:
    r = parseHexInt(hex[0] & hex[0])
    g = parseHexInt(hex[1] & hex[1])
    b = parseHexInt(hex[2] & hex[2])
    a =
      if hex.len == 4: parseHexInt(hex[3] & hex[3])
      else: 255
  of 6, 8:
    r = parseHexInt(hex[0..1])
    g = parseHexInt(hex[2..3])
    b = parseHexInt(hex[4..5])
    a =
      if hex.len == 8: parseHexInt(hex[6..7])
      else: 255
  else: doAssert false, "unreachable"

  result = rgba(r / 255, g / 255, b / 255, a / 255)

template hex*(lit: static string): Color =
  ## Optimization for parsing constant colors at compile time.

  const compileTimeColor = hex(lit)
  compileTimeColor

proc withRed*(color: Color, red: float32): Color =
  ## Copies the color with a different red channel.
  rgba(red, color.g, color.b, color.a)

proc withGreen*(color: Color, green: float32): Color =
  ## Copies the color with a different green channel.
  rgba(color.r, green, color.b, color.a)

proc withBlue*(color: Color, blue: float32): Color =
  ## Copies the color with a different blue channel.
  rgba(color.r, color.g, blue, color.a)

proc withAlpha*(color: Color, alpha: float32): Color =
  ## Copies the color with a different alpha channel.
  rgba(color.r, color.g, color.b, alpha)

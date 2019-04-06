#~~
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2018, iLiquid
#~~

import strutils
import terminal

proc debug*(text: varargs[string]) =
  styledEcho(
    fgWhite, styleDim, styleBright, "debug: ",
    resetStyle, text.join(" ")
  )

proc warn*(text: varargs[string]) =
  styledEcho(
    fgYellow, styleBright, "warn: ",
    resetStyle, text.join(" ")
  )

proc error*(text: varargs[string]) =
  styledEcho(
    fgRed, styleBright, "err: ",
    resetStyle, text.join(" ")
  )

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

import strutils
import terminal

proc debug*(text: varargs[string, `$`]) =
  styledEcho(
    fgWhite, styleDim, "rapid/Debug: ",
    resetStyle, text.join()
  )

proc info*(text: varargs[string, `$`]) =
  styledEcho(
    fgBlue, styleBright, "rapid/Info: ",
    resetStyle, text.join()
  )

proc warn*(text: varargs[string, `$`]) =
  styledEcho(
    fgYellow, styleBright, "rapid/Warning: ",
    resetStyle, text.join()
  )

proc error*(text: varargs[string, `$`]) =
  styledEcho(
    fgRed, styleBright, "rapid/Error: ",
    resetStyle, text.join()
  )

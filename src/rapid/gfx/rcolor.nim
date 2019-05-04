#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module has some utility color manipulation procs.
## **Do not import this directly, it's included by the surface module.**

import std/colors

export colors except rgb

type
  ColorChannel* = range[0..255]

proc rgba*(r, g, b, a: ColorChannel): Color =
  ## Creates an RGBA color.
  result = Color(
    a shl 24 or
    r shl 16 or
    g shl 8 or
    b
  )

proc rgb*(r, g, b: ColorChannel): Color =
  ## Creates an RGB color, with 100% alpha (255).
  result = rgba(r, g, b, 255)

proc gray*(gray: ColorChannel, a = 255.ColorChannel): Color =
  result = rgba(gray, gray, gray, a)

proc col*(col: Color): Color =
  ## Sets a color's alpha to 255. This is made to be used with Nim's built-in \
  ## color constants, which, unfortunately, do not contain an alpha channel.
  runnableExamples:
    let greenWithAlpha = col(colGreen)
  result = Color(int(col) or 0xff000000)

proc alpha*(col: Color): ColorChannel = (0xff000000 and int(col)) shr 24
proc red*(col: Color): ColorChannel   = (0x00ff0000 and int(col)) shr 16
proc green*(col: Color): ColorChannel = (0x0000ff00 and int(col)) shr 8
proc blue*(col: Color): ColorChannel  = (0x000000ff and int(col))

proc norm32*(ch: ColorChannel): float32 =
  ## Utility method for sending colors to the GPU. Divides the given channel
  ## by 255, resulting in a normalized ``float32``, which can be used by OpenGL.
  ch / 255

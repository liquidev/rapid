import std/colors

export colors except rgb

type
  ColorChannel = range[0..255]

proc rgba*(r, g, b, a: ColorChannel): Color =
  result = Color(
    a shl 24 or
    r shl 16 or
    g shl 8 or
    b
  )

proc rgb*(r, g, b: ColorChannel): Color =
  result = rgba(r, g, b, 255)

proc col*(col: Color): Color =
  result = Color(int(col) or 0xff000000)

proc alpha*(col: Color): ColorChannel = (0xff000000 and int(col)) shr 24
proc red*(col: Color): ColorChannel   = (0x00ff0000 and int(col)) shr 16
proc green*(col: Color): ColorChannel = (0x0000ff00 and int(col)) shr 8
proc blue*(col: Color): ColorChannel  = (0x000000ff and int(col))

# Used for sending colors to the GPU
proc norm32*(ch: ColorChannel): float32 = ch / 255

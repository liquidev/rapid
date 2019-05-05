#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module implements a simple texture packer.

import ../gfx/opengl
import ../lib/glad/gl
import ../res/textures

type
  RTexturePacker* = ref object
    texture*: RTexture
    occupied: seq[seq[bool]]
    fmt: RTexturePixelFormat
  RTextureRect* = tuple
    x, y, w, h: float

proc occupyArea(tp: RTexturePacker, x, y, w, h: int) =
  for i in y..<y + h:
    for j in x..<x + w:
      tp.occupied[i][j] = true

proc areaFree(tp: RTexturePacker, x, y, w, h: int): bool =
  for i in y..<y + h:
    for j in x..<x + w:
      if tp.occupied[i][j]: return false
  return true

proc rawPlace(tp: RTexturePacker, x, y, w, h: int, data: pointer) =
  currentGlc.withTex2D(tp.texture.id):
    glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, y.GLint, w.GLsizei, h.GLsizei,
                    tp.fmt.color, GL_UNSIGNED_BYTE, data)
    tp.occupyArea(x, y, w, h)

proc place*(tp: RTexturePacker,
            width, height: int, data: pointer): RTextureRect =
  for y in 0..<tp.texture.height - height:
    for x in 0..<tp.texture.width - width:
      if tp.areaFree(x, y, width, height):
        tp.rawPlace(x, y, width, height, data)
        return (x / tp.texture.width, y / tp.texture.height,
                width / tp.texture.width, height / tp.texture.height)

proc newRTexturePacker*(width, height: Natural,
                        conf = DefaultTextureConfig,
                        fmt = fmtRGBA8): RTexturePacker =
  result = RTexturePacker(
    texture: newRTexture(width, height, nil, conf, fmt),
    fmt: fmt
  )
  result.occupied = @[]
  for row in 0..<height:
    var row: seq[bool]
    for col in 0..<width:
      row.add(false)
    result.occupied.add(row)

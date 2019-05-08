#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module implements a simple texture packer.

import glm

import ../gfx/opengl
import ../lib/glad/gl
import ../res/textures
import ../world/aabb

type
  RTexturePacker* = ref object
    texture*: RTexture
    occupied: seq[RAABounds]
    fmt: RTexturePixelFormat
  RTextureRect* = tuple
    x, y, w, h: float

proc occupyArea(tp: RTexturePacker, x, y, w, h: int) =
  tp.occupied.add(newRAABB(x.float, y.float, w.float, h.float))

proc areaFree(tp: RTexturePacker, x, y, w, h: int): bool =
  let area = newRAABB(x.float, y.float, w.float, h.float)
  for i in countdown(tp.occupied.len - 1, 0):
    if area.intersects(tp.occupied[i]): return false
  return true

proc rawPlace(tp: RTexturePacker, x, y, w, h: int, data: pointer) =
  currentGlc.withTex2D(tp.texture.id):
    glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, y.GLint, w.GLsizei, h.GLsizei,
                    tp.fmt.color, GL_UNSIGNED_BYTE, data)

proc place*(tp: RTexturePacker,
            width, height: int, data: pointer): RTextureRect =
  var x, y = 0
  while y <= tp.texture.height - height:
    while x <= tp.texture.width - width:
      for i in countdown(tp.occupied.len - 1, 0):
        let area = tp.occupied[i]
        if area.has(vec2f(x.float, y.float)):
          x = int(area.x + area.width)
      if tp.areaFree(x, y, width, height):
        tp.rawPlace(x, y, width, height, data)
        tp.occupyArea(x, y, width, height)
        return (x / tp.texture.width, y / tp.texture.height,
                width / tp.texture.width, height / tp.texture.height)
      inc(x)
    inc(y)

proc newRTexturePacker*(width, height: Natural,
                        conf = DefaultTextureConfig,
                        fmt = fmtRGBA8): RTexturePacker =
  result = RTexturePacker(
    texture: newRTexture(width, height, nil, conf, fmt),
    fmt: fmt
  )

proc unload*(pack: var RTexturePacker) =
  pack.texture.unload()

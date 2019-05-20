#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module implements a simple texture packer.

import glm

import ../gfx/opengl
import ../lib/glad/gl
import ../res/images
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
  glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, GLint(tp.texture.height - y - h),
                  w.GLsizei, h.GLsizei, tp.fmt.color, GL_UNSIGNED_BYTE, data)

proc pack(tp: RTexturePacker, image: RImage): RTextureRect =
  if image.width * image.height > 0:
    var x, y = 1
    while y <= tp.texture.height - image.height - 1:
      while x <= tp.texture.width - image.width - 1:
        block placeTex:
          for area in tp.occupied:
            if area.has(vec2f(x.float, y.float)):
              x = int(area.x + area.width)
              break placeTex
          if tp.areaFree(x, y, image.width + 1, image.height + 1):
            tp.rawPlace(x, y, image.width, image.height, image.caddr)
            tp.occupyArea(x, y, image.width + 1, image.height + 1)
            let
              hp = 1 / tp.texture.width / tp.texture.width.float
              vp = 1 / tp.texture.height / tp.texture.height.float
            return (x / tp.texture.width + hp, y / tp.texture.height + vp,
                    image.width / tp.texture.width - hp * 2,
                    image.height / tp.texture.height - vp * 2)
          inc(x)
      x = 0
      inc(y)

proc place*(tp: RTexturePacker, image: RImage): RTextureRect =
  currentGlc.withTex2D(tp.texture.id):
    result = tp.pack(image)

proc place*(tp: RTexturePacker, images: openarray[RImage]): seq[RTextureRect] =
  currentGlc.withTex2D(tp.texture.id):
    for img in images:
      result.add(tp.pack(img))

proc newRTexturePacker*(width, height: Natural,
                        conf = DefaultTextureConfig,
                        fmt = fmtRGBA8): RTexturePacker =
  result = RTexturePacker(
    texture: newRTexture(width, height, nil, conf, fmt),
    fmt: fmt
  )

proc unload*(tp: var RTexturePacker) =
  tp.texture.unload()

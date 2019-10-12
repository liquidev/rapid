#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module implements a simple texture packer.

import algorithm

import glm/vec

import ../gfx/opengl
import ../lib/glad/gl
import ../res/images
import ../res/textures
import ../world/aabb

type
  RTexturePackerMode* = enum
    tpmEfficient
    tpmFast
  RTexturePacker* = ref object
    texture*: RTexture
    fmt: RTexturePixelFormat
    x, y: int
    case mode: RTexturePackerMode
    of tpmEfficient:
      occupied: seq[RAABounds]
    of tpmFast:
      lineMaxY: int
  RTextureRect* = tuple
    x, y, w, h: float

proc occupyArea(tp: RTexturePacker, x, y, w, h: int) =
  let aabb = newRAABB(x.float, y.float, w.float, h.float)
  tp.occupied.add(aabb)

proc areaFree(tp: RTexturePacker, x, y, w, h: int): bool =
  let area = newRAABB(x.float, y.float, w.float, h.float)
  for i in countdown(tp.occupied.len - 1, 0):
    if area.intersects(tp.occupied[i]): return false
  return true

proc rawPlace(tp: RTexturePacker, x, y, w, h: int, data: pointer) =
  glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, GLint(tp.texture.height - y - h),
                  w.GLsizei, h.GLsizei, tp.fmt.color, GL_UNSIGNED_BYTE, data)

proc getRect(tp: RTexturePacker, x, y, w, h: int): RTextureRect =
  let
    hp = 1 / tp.texture.width / tp.texture.width.float / 2
    vp = 1 / tp.texture.height / tp.texture.height.float / 2
  result = (x / tp.texture.width + hp, y / tp.texture.height + vp,
            w / tp.texture.width - hp * 2, h / tp.texture.height - vp * 2)

proc packEfficient(tp: RTexturePacker, image: RImage): RTextureRect =
  var
    x = tp.x
    y = tp.y
  while y <= tp.texture.height - image.height:
    while x <= tp.texture.width - image.width:
      block placeTex:
        for area in tp.occupied:
          if area.has(vec2(x.float, y.float)):
            x = int area.x + area.width
            break placeTex
        if tp.areaFree(x, y, image.width, image.height):
          tp.rawPlace(x, y, image.width, image.height, image.caddr)
          tp.occupyArea(x, y, image.width, image.height)
          return tp.getRect(x, y, image.width, image.height)
        inc(x)
    x = 0
    inc(y)
  tp.x = x
  tp.y = y

proc packFast(tp: RTexturePacker, image: RImage): RTextureRect =
  if tp.x + image.width >= tp.texture.width:
    tp.x = 0
    tp.y = tp.lineMaxY
  tp.rawPlace(tp.x, tp.y, image.width, image.height, image.caddr)
  result = tp.getRect(tp.x, tp.y, image.width, image.height)
  tp.x += image.width
  if tp.lineMaxY < tp.y + image.height:
    tp.lineMaxY = tp.y + image.height

proc pack(tp: RTexturePacker, image: RImage): RTextureRect =
  if image.width > 0 and image.height > 0:
    result =
      case tp.mode
      of tpmEfficient: tp.packEfficient(image)
      of tpmFast: tp.packFast(image)

proc place*(tp: RTexturePacker, image: RImage): RTextureRect =
  ## Place an image onto the texture packer's target.
  currentGlc.withTex2D(tp.texture.id):
    result = tp.pack(image)

proc place*(tp: RTexturePacker, images: openarray[RImage]): seq[RTextureRect] =
  ## Place an array of images onto the texture packer's target. This should be
  ## preferred over the single-image version, as this binds the texture only one
  ## time, thus saving performance. It is also more efficient, since it sorts
  ## the images by area.
  currentGlc.withTex2D(tp.texture.id):
    let sorted = images.sorted(proc (a, b: RImage): int =
                                 cmp(a.width * a.height, b.width * b.height),
                               Descending)
    for img in sorted:
      result.add(tp.pack(img))

proc newRTexturePacker*(width, height: Natural,
                        conf = DefaultTextureConfig,
                        fmt = fmtRGBA8, mode = tpmEfficient): RTexturePacker =
  ## Creates a new texture packer.
  result = RTexturePacker(
    texture: newRTexture(width, height, nil, conf, fmt),
    fmt: fmt,
    mode: mode
  )

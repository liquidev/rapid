#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

import glm/vec

import ../gfx

type
  RSprite* = ref object of RootObj
    width*, height*: float
    pos*, vel*, acc*: Vec2[float]
    friction*: float
    delete*: bool

method draw*(spr: RSprite, ctx: RGfxContext, step: float) {.base.} =
  ## The base draw implementation. It just draws a rectangle at the sprite's \
  ## position, with the sprite's dimensions.
  ctx.rect(spr.pos.x, spr.pos.y, spr.width, spr.height)

method update*(spr: RSprite, step: float) {.base.} =
  ## The base update implementation. It doesn't do anything.
  discard

method collideSprite*(a, b: RSprite) {.base.} =
  ## The base collide with sprite implementation. It doesn't do anything.
  discard

proc force*(spr: RSprite, force: Vec2[float]) =
  ## Add ``force`` to the sprite's acceleration.
  spr.acc += force

proc newRSprite*(width, height: float): RSprite =
  ## Create a new sprite of the specified size.
  result = RSprite(
    width: width, height: height
  )

proc `$`*(spr: RSprite): string =
  result =
    "Sprite " & $spr.width & "×" & $spr.height &
    " pos: " & $spr.pos & ", vel: " & $spr.vel & ", acc: " & $spr.acc

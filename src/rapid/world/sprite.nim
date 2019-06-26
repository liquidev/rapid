#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

import glm

import ../gfx

type
  RSpriteImpl* = tuple
    draw: proc (ctx: RGfxContext, spr: var RSprite, step: float) {.nimcall.}
    update: proc (spr: var RSprite, step: float) {.nimcall.}
  RSprite* = ref object of RootObj
    width*, height*: float
    pos*, vel*, acc*: Vec2[float]
    friction*: float

method draw*(spr: var RSprite, ctx: RGfxContext, step: float) {.base.} =
  ## The base draw implementation. It just draws a rectangle at the sprite's \
  ## position, with the sprite's dimensions.
  ctx.rect(spr.pos.x, spr.pos.y, spr.width, spr.height)

method update*(spr: var RSprite, step: float) {.base.} =
  ## The base update implementation. It doesn't do anything.
  discard

proc force*(spr: RSprite, force: Vec2[float]) =
  spr.acc += force

proc newRSprite*(width, height: float): RSprite =
  result = RSprite(
    width: width, height: height
  )

proc `$`*(spr: RSprite): string =
  result =
    "Sprite " & $spr.width & "×" & $spr.height &
    " pos: " & $spr.pos & ", vel: " & $spr.vel & ", acc: " & $spr.acc

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import sprite
import ../gfx/draw

type
  RWorld* = ref object of RootObj
    sprites*: seq[RSprite]

proc drawSprites*(wld: RWorld, ctx: var RGfxContext, step: float) =
  ## Draws all of the world's sprites.
  for spr in mitems(wld.sprites):
    spr.draw(ctx, step)

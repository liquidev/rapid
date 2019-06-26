#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

import tables

import sprite
import ../gfx

type
  RWorld* = ref object of RootObj
    sprites*: seq[RSprite]
    namedSprites: OrderedTableRef[string, RSprite]

proc init*(wld: RWorld) =
  wld.namedSprites = newOrderedTable[string, RSprite]()

iterator items*(wld: RWorld): RSprite =
  for spr in wld.sprites:
    yield spr

iterator pairs*(wld: RWorld): (string, RSprite) =
  for name, spr in wld.namedSprites:
    yield (name, spr)

proc drawSprites*(wld: RWorld, ctx: RGfxContext, step: float) =
  ## Draws all of the world's sprites.
  for spr in mitems(wld.sprites):
    spr.draw(ctx, step)

proc add*(wld: RWorld, sprite: RSprite) =
  wld.sprites.add(sprite)

proc add*(wld: RWorld, name: string, sprite: RSprite) =
  wld.add(sprite)
  wld.namedSprites.add(name, sprite)

proc `[]`*(wld: RWorld, name: string): RSprite =
  result = wld.namedSprites[name]

proc del*(wld: RWorld, index: int): RSprite {.discardable.} =
  result = wld.sprites[index]
  wld.sprites.del(index)

proc del*(wld: RWorld, spr: RSprite) =
  for i, sp in wld.sprites:
    if sp == spr:
      wld.del(i)

proc del*(wld: RWorld, name: string): RSprite {.discardable.} =
  let spr = wld[name]
  wld.del(spr)

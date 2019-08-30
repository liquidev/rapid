#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Base world implementation. Inherit your own worlds from this.

import tables

import sprite
import ../gfx

type
  RWorld* = ref object of RootObj
    sprites*: seq[RSprite]
    namedSprites: OrderedTableRef[string, RSprite]

proc init*(wld: RWorld) =
  ## Initialize a world.
  wld.namedSprites = newOrderedTable[string, RSprite]()

iterator items*(wld: RWorld): RSprite =
  ## Loop over the sprites in the world.
  for spr in wld.sprites:
    yield spr

iterator pairs*(wld: RWorld): (string, RSprite) =
  ## Loop over all named sprites in the world. This does not include regular
  ## sprites!
  for name, spr in wld.namedSprites:
    yield (name, spr)

proc drawSprites*(wld: RWorld, ctx: RGfxContext, step: float) =
  ## Draws all of the world's sprites.
  for spr in mitems(wld.sprites):
    spr.draw(ctx, step)

proc add*(wld: RWorld, sprite: RSprite) =
  ## Add a sprite to the world.
  wld.sprites.add(sprite)

proc add*(wld: RWorld, name: string, sprite: RSprite) =
  ## Add a named sprite to the world.
  wld.add(sprite)
  wld.namedSprites.add(name, sprite)

proc `[]`*(wld: RWorld, name: string): RSprite =
  ## Retrieve a named sprite from the world.
  result = wld.namedSprites[name]

proc del*(wld: RWorld, index: int): RSprite {.discardable.} =
  ## Delete a sprite from the world, at the specified index.
  result = wld.sprites[index]
  wld.sprites.del(index)

proc del*(wld: RWorld, spr: RSprite) =
  ## Delete a sprite by reference.
  for i, sp in wld.sprites:
    if sp == spr:
      wld.del(i)

proc del*(wld: RWorld, name: string): RSprite {.discardable.} =
  ## Delete a named sprite from the world.
  let spr = wld[name]
  wld.del(spr)

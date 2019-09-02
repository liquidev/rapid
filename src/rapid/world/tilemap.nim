#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

import aabb
import sprite
import worldbase
import ../gfx

export worldbase

type
  RTileImpl*[T] = tuple
    initImpl: proc (): T
    isSolidImpl: proc (tile: T): bool
    hitboxImpl: proc (x, y: float, tile: T): RAABounds {.closure.}
  RTmWorld*[T] = ref object of RWorld
    width*, height*: Natural

    tileWidth*, tileHeight*: float
    tile: RTileImpl[T]
    tiles: seq[seq[T]]
    oobTile: T

    wrapX*, wrapY*: bool

    drawImpl*: proc (ctx: RGfxContext, wld: RTmWorld[T], step: float)
    onModify*: proc (x, y: int, previousTile, currentTile: T)

proc isInbounds*(wld: RTmWorld, x, y: int): bool =
  ## Returns ``true`` if the specified coordinates are inside of the world's
  ## boundaries.
  result =
    (wld.wrapX or x >= 0 and x < wld.width) and
    (wld.wrapY or y >= 0 and y < wld.height)

proc `oobTile=`*[T](wld: var RTmWorld[T], tile: T) =
  ## Set an out of bounds tile. This tile is used as a placeholder for
  ## collision detection out of bounds.
  wld.oobTile = tile

proc implTile*[T](wld: RTmWorld[T],
                  initImpl: proc (): T,
                  isSolidImpl: proc (t: T): bool,
                  hitboxImpl: proc (x, y: float, t: T): RAABounds) =
  ## Set implementation for all tile-related procedures. This must be called
  ## with non-nil values for the world to properly function.
  wld.tile = (
    initImpl: initImpl,
    isSolidImpl: isSolidImpl,
    hitboxImpl: hitboxImpl
  ).RTileImpl[:T]

proc getX(wld: RTmWorld, x: int): int =
  result =
    if wld.wrapX: floorMod(x.float, wld.width.float).int
    else: x

proc getY(wld: RTmWorld, y: int): int =
  result =
    if wld.wrapY: floorMod(y.float, wld.height.float).int
    else: y

proc `[]`*[T](wld: RTmWorld[T], x, y: int): T =
  ## Returns a tile at the specified coordinates. If the coordinates are out \
  ## of bounds, returns the previously set OOB tile.
  result =
    if wld.isInbounds(x, y):
      wld.tiles[wld.getY(y)][wld.getX(x)]
    else:
      wld.oobTile

proc `[]=`*[T](wld: RTmWorld[T], x, y: int, tile: T) =
  ## Sets a tile. If the coordinates are out of bounds, doesn't set anything.
  if wld.isInbounds(x, y):
    let oldTile = wld[x, y]
    wld.tiles[wld.getY(y)][wld.getX(x)] = tile
    if not wld.onModify.isNil: wld.onModify(x, y, oldTile, tile)

proc isSolid*(wld: RTmWorld, x, y: int): bool =
  ## Returns whether a tile at the specified coordinates is a solid tile, using
  ## the specified ``isSolid`` implementation.
  result = wld.tile.isSolidImpl(wld[x, y])

proc init*[T](wld: RTmWorld[T]) =
  ## Initialize a world. This *must* be called before doing anything with the
  ## world.
  assert (not wld.tile.initImpl.isNil),
    "Cannot initialize a world with unimplemented tile procs"
  wld.tiles = @[]
  for y in 0..<wld.height:
    var row: seq[T] = @[]
    for x in 0..<wld.width:
      let tile = wld.tile.initImpl()
      row.add(tile)
    wld.tiles.add(row)

iterator tiles*[T](wld: RTmWorld[T]): tuple[x, y: int, tile: T] =
  ## Loops through all inbounds world tiles.
  for y in 0..<wld.height:
    for x in 0..<wld.width:
      yield (x, y, wld[x, y])

iterator area*[T](wld: RTmWorld[T],
                  x, y, w, h: int): tuple[x, y: int, tile: T] =
  ## Loops through an area of world tiles.
  ## Note that the coordinates *can* be out of bounds, in that case the same
  ## rules apply as when using the ``[]`` operator.
  for y in y..<y + h:
    for x in x..<x + w:
      yield (x, y, wld[x, y])

iterator areab*[T](wld: RTmWorld[T],
                   top, left, bottom, right: int): tuple[x, y: int, tile: T] =
  ## Similar to ``area``, but accepts top/left/bottom/right as the parameters,
  ## and the looped ranges are inclusive instead of exclusive.
  for y in top..bottom:
    for x in left..right:
      yield (x, y, wld[x, y])

proc clear*[T](wld: RTmWorld[T]) =
  ## Clears the world.
  for x, y, t in tiles(wld):
    t = wld.tile.initImpl()

proc tilePos*(wld: RTmWorld, x, y: float): tuple[x, y: int] =
  ## Converts world coordinates into world tile coordinates.
  result = (int(x / wld.tileWidth.float), int(y / wld.tileHeight.float))

proc wldPos*(wld: RTmWorld, x, y: int): tuple[x, y: float] =
  ## Converts tile coordinates into world coordinates.
  result = (x.float * wld.tileWidth.float, y.float * wld.tileHeight.float)

proc draw*[T](wld: RTmWorld[T], ctx: RGfxContext, step: float) =
  ## Draws the world onto the specified Gfx context.
  ## Drawing is largely dependent on the game you're creating, so it doesn't
  ## have a default implementation. ``drawImpl=`` must be used to set an
  ## implementation for how to draw the world.
  wld.drawImpl(ctx, wld, step)

proc tileAlignedHitbox(wld: RTmWorld,
                       hb: RAABounds): tuple[top, left, bottom, right: int] =
  result = (
    int(hb.top / wld.tileHeight.float),
    int(hb.left / wld.tileWidth.float),
    int(hb.bottom / wld.tileHeight.float),
    int(hb.right / wld.tileWidth.float)
  )

proc collectGarbage(wld: RTmWorld) =
  var idx = 0
  while idx < wld.sprites.len:
    if wld.sprites[idx].delete:
      wld.del(idx)
    else:
      inc(idx)

proc update*[T](wld: RTmWorld[T], step: float) =
  ## Updates the world, simulating physics on its sprites.
  assert wld.tile.isSolidImpl != nil, "Cannot update an uninitialized world"
  wld.collectGarbage()
  var sprites = wld.sprites
  for spr in sprites:
    spr.update(step)
    spr.vel += spr.acc
    spr.acc *= 0

    var p = spr.pos.xy

    p.x += spr.vel.x * step
    if wld.wrapX: p.x = floorMod(p.x, wld.width.float * wld.tileWidth)

    var
      s = newRAABB(p.x, p.y, spr.width, spr.height)
      st = wld.tileAlignedHitbox(s)

    for x, y, t in areab(wld, st.top, st.left, st.bottom, st.right): # X
      if wld.isSolid(x, y):
        let t = wld.tile.hitboxImpl(x.float, y.float, t)
        if spr.vel.x > 0.001 and not wld.isSolid(x - 1, y):
          let w = newRAABB(t.left, t.top + 1,
                           spr.vel.x * 1.5, t.height - 2)
          if s.intersects(w):
            spr.vel.x *= -spr.friction
            p.x = t.left - s.width
        if spr.vel.x < -0.001 and not wld.isSolid(x + 1, y):
          let w = newRAABB(t.right - (spr.vel.x * -1.5), t.top + 1,
                           spr.vel.x * -1.5, t.height - 2)
          if s.intersects(w):
            spr.vel.x *= -spr.friction
            p.x = t.right

    p.y += spr.vel.y * step
    if wld.wrapY: p.y = floorMod(p.y, wld.height.float * wld.tileWidth)

    s = newRAABB(p.x, p.y, spr.width, spr.height)
    st = wld.tileAlignedHitbox(s)

    for x, y, t in areab(wld, st.top, st.left, st.bottom, st.right): # Y
      if wld.isSolid(x, y):
        let t = wld.tile.hitboxImpl(x.float, y.float, t)
        if spr.vel.y > 0.001 and not wld.isSolid(x, y - 1):
          let w = newRAABB(t.left + 1, t.top,
                           t.width - 2, spr.vel.y * 1.5)
          if s.intersects(w):
            spr.vel.y *= -spr.friction
            p.y = t.top - s.height
        if spr.vel.y < -0.001 and not wld.isSolid(x, y + 1):
          let w = newRAABB(t.left + 1, t.bottom - (spr.vel.y * -1.5),
                           t.width - 2, spr.vel.y * -1.5)
          if s.intersects(w):
            spr.vel.y *= -spr.friction
            p.y = t.bottom

    spr.pos = p

    # TODO: Very inefficient, use a quad tree or grid for this
    for b in sprites:
      if b != spr:
        let
          ah = newRAABB(spr.pos.x, spr.pos.y, spr.width, spr.height)
          bh = newRAABB(b.pos.x, b.pos.y, b.width, b.height)
        if ah.intersects(bh):
          spr.collideSprite(b)

proc newRTmWorld*[T](width, height,
                     tileWidth, tileHeight: Natural): RTmWorld[T] =
  ## Creates a new, empty world.
  result = RTmWorld[T](
    width: width, height: height,
    tileWidth: tileWidth.float, tileHeight: tileHeight.float
  )
  result.RWorld.init()

proc load*[T; w, h: static[int]](wld: RTmWorld[T],
                                 map: array[h, array[w, T]]) =
  ## Loads tiles to a world, from a 2D array of tiles.
  ## This should be used only for testing purposes, as embedding the whole map
  ## in source code isn't really viable for full-blown games.
  wld.width = w
  wld.height = h
  for x, y, t in tiles(wld):
    wld[x, y] = map[y][x]

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import math

import aabb
import sprite
import worldbase
import ../gfx/surface

export worldbase

type
  RTileImpl*[T] = object
    initImpl: proc (): T
    isSolidImpl: proc (tile: T): bool
  RTmWorld*[T] = ref object of RWorld
    width*, height*: Natural

    tileWidth*, tileHeight*: float
    tile: RTileImpl[T]
    tiles: seq[seq[T]]
    oobTile: T

    wrapX*, wrapY*: bool

    drawImpl*: proc (ctx: var RGfxContext, wld: RTmWorld[T], step: float)
    onModify*: proc (x, y: int, previousTile, currentTile: T)

proc isInbounds*(wld: RTmWorld, x, y: int): bool =
  ## Returns ``true`` if the specified coordinates are inside of the world's
  ## boundaries.
  result =
    (wld.wrapX or x >= 0 and x < wld.width) and
    (wld.wrapY or y >= 0 and y < wld.height)

proc `oobTile=`*[T](wld: var RTmWorld[T], tile: T) =
  wld.oobTile = tile

proc implTile*[T](wld: var RTmWorld[T],
                  initImpl: proc (): T,
                  isSolidImpl: proc (t: T): bool) =
  wld.tile = RTileImpl[T](
    initImpl: initImpl,
    isSolidImpl: isSolidImpl
  )

proc getX(wld: RTmWorld, x: int): int =
  result =
    if wld.wrapX: x mod wld.width
    else: x

proc getY(wld: RTmWorld, y: int): int =
  result =
    if wld.wrapY: y mod wld.height
    else: y

proc `[]`*[T](wld: RTmWorld[T], x, y: int): T =
  ## Returns a tile at the specified coordinates. If the coordinates are out \
  ## of bounds, returns the previously set OOB tile.
  result =
    if wld.isInbounds(x, y):
      wld.tiles[wld.getY(y)][wld.getX(x)]
    else:
      wld.oobTile

proc `[]=`*[T](wld: var RTmWorld[T], x, y: int, tile: T) =
  ## Sets a tile. If the coordinates are out of bounds, doesn't set anything.
  if wld.isInbounds(x, y):
    let oldTile = wld[x, y]
    wld.tiles[wld.getY(y)][wld.getX(x)] = tile
    if not wld.onModify.isNil: wld.onModify(x, y, oldTile, tile)

proc isSolid*(wld: RTmWorld, x, y: int): bool =
  result = wld.tile.isSolidImpl(wld[x, y])

proc init*[T](wld: var RTmWorld[T]) =
  assert (not wld.tile.initImpl.isNil),
    "Attempt to initialize unimplemented world"
  wld.tiles = @[]
  for y in 0..<wld.height:
    var row: seq[T] = @[]
    for x in 0..<wld.width:
      var tile = wld.tile.initImpl()
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
  ## Note that the coordinates *can* be out of bounds, in that case the
  ## ``oobTile`` is yielded (because the ``[]`` operator is used).
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

proc clear*[T](wld: var RTmWorld[T]) =
  ## Clears the world.
  for x, y, t in tiles(wld):
    t = wld.tile.initImpl()

proc tilePos*(wld: RTmWorld, x, y: float): tuple[x, y: int] =
  ## Converts world coordinates into world tile coordinates.
  result = (int(x / wld.tileWidth.float), int(y / wld.tileHeight.float))

proc wldPos*(wld: RTmWorld, x, y: int): tuple[x, y: float] =
  ## Converts tile coordinates into world coordinates.
  result = (x.float * wld.tileWidth.float, y.float * wld.tileHeight.float)

proc draw*[T](wld: RTmWorld[T], ctx: var RGfxContext, step: float) =
  ## Draws the world onto the specified Gfx context.
  ## Drawing is implementation dependent, and largely specific to the world's
  ## tile type. That's why it doesn't have a default implementation.
  wld.drawImpl(ctx, wld, step)

proc tileAlignedHitbox(wld: RTmWorld,
                       hb: RAABounds): tuple[top, left, bottom, right: int] =
  result = (
    int(hb.top / wld.tileHeight.float),
    int(hb.left / wld.tileWidth.float),
    int(hb.bottom / wld.tileHeight.float),
    int(hb.right / wld.tileWidth.float)
  )

proc update*[T](wld: var RTmWorld[T], step: float) =
  ## Updates the world, simulating physics on its sprites.
  assert (not wld.tile.isSolidImpl.isNil),
    "Cannot update an uninitialized world"
  for spr in mitems(wld.sprites):
    spr.update(step)
    spr.vel += spr.acc
    spr.acc *= 0

    var p = spr.pos.xy
    p.x += spr.vel.x * step

    var
      s = newRAABB(p.x, p.y, spr.width, spr.height)
      st = wld.tileAlignedHitbox(s)

    for x, y, t in areab(wld, st.top, st.left, st.bottom, st.right): # X
      if wld.isSolid(x, y):
        let t = newRAABB(x.float * wld.tileWidth, y.float * wld.tileWidth,
                         wld.tileWidth, wld.tileHeight)
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
    s = newRAABB(p.x, p.y, spr.width, spr.height)
    st = wld.tileAlignedHitbox(s)

    for x, y, t in areab(wld, st.top, st.left, st.bottom, st.right): # Y
      if wld.isSolid(x, y):
        let t = newRAABB(x.float * wld.tileWidth, y.float * wld.tileWidth,
                         wld.tileWidth, wld.tileHeight)
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

proc newRTmWorld*[T](width, height,
                     tileWidth, tileHeight: Natural): RTmWorld[T] =
  ## Creates a new, empty world.
  result = RTmWorld[T](
    width: width, height: height,
    tileWidth: tileWidth.float, tileHeight: tileHeight.float
  )

proc load*[T; w, h: static[int]](wld: var RTmWorld[T],
                                 map: array[h, array[w, T]]) =
  ## Loads tiles to a world, from a 2D array of tiles.
  wld.width = w
  wld.height = h
  for x, y, t in tiles(wld):
    wld[x, y] = map[y][x]

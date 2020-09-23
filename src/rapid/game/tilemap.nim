## Tilemap with collision detection.

import std/tables

import glm/vec

import ../physics/aabb

type
  TilemapTile* {.explain.} = concept tile
    tile.isSolid is bool

  RootTilemap* = ref object of RootObj
    fSize: Vec2i
    fTileSize: Vec2f


# property getters

{.push inline.}

proc size*(tilemap: RootTilemap): Vec2i =
  ## Returns the size of the tilemap, as a vector.
  tilemap.fSize

proc `size=`*(tilemap: RootTilemap, newSize: Vec2i) =
  ## Returns the size of the tilemap, as a vector.
  tilemap.fSize = newSize

proc width*(tilemap: RootTilemap): int32 =
  ## Returns the width of the tilemap.
  tilemap.fSize.x

proc height*(tilemap: RootTilemap): int32 =
  ## Returns the height of the tilemap.
  tilemap.fSize.y

proc tileSize*(tilemap: RootTilemap): Vec2f =
  ## Returns the size of the tilemap's grid, as a vector.
  tilemap.fTileSize

proc `tileSize=`*(tilemap: RootTilemap): Vec2f =
  ## Returns the size of the tilemap's grid, as a vector.
  tilemap.fTileSize

proc tileWidth*(tilemap: RootTilemap): float32 =
  ## Returns the width of tiles on the tilemap.
  tilemap.fTileSize.x

proc tileHeight*(tilemap: RootTilemap): float32 =
  ## Returns the height of tiles the tilemap.
  tilemap.fTileSize.y

proc isInbounds*(tilemap: RootTilemap, position: Vec2i): bool =
  ## Returns whether the given coordinates lie inside of the tilemap's bounds.
  position.x >= 0 and position.x < tilemap.width and
  position.y >= 0 and position.y < tilemap.height

{.pop.}


# flat tilemap (fixed size)

type
  FlatTilemap*[T: TilemapTile] {.final.} = ref object of RootTilemap
    tiles: seq[T]
    fOutOfBounds: T


proc newFlatTilemap*[T](size: Vec2i,
                        outOfBounds: T = default(T)): FlatTilemap[T] =
  ## Creates a new flat tilemap.

  new(result)
  result.size = size
  result.outOfBounds = outOfBounds

{.push inline.}

proc outOfBounds*[T](tilemap: FlatTilemap[T]): lent T =
  ## Returns the out of bounds tile for this tilemap.
  ## By default, this is ``default(T)``.
  tilemap.fOutOfBounds

proc `outOfBounds=`*[T](tilemap: FlatTilemap[T], newOutOfBoundsTile: sink T) =
  ## Sets the out of bounds tile for this tilemap.
  tilemap.fOutOfBounds = newOutOfBoundsTile

proc `[]`*[T](tilemap: FlatTilemap[T], position: Vec2i): var T =
  ## Returns the tile at the given position, or ``tilemap.outOfBounds`` if the
  ## position lies out of bounds.

  if tilemap.isInbounds(position):
    tilemap.tiles[position.x + position.y * tilemap.width]
  else:
    tilemap.fOutOfBounds

proc `[]=`*[T](tilemap: FlatTilemap[T], position: Vec2i, tile: sink T) =
  ## Sets the tile at the given position, or does nothing if the position is out
  ## of bounds.

  if tilemap.isInbounds(position):
    tilemap.tiles[position.x + position.y * tilemap.width] = tile

{.pop.}

iterator tiles*[T](tilemap: FlatTilemap[T]): (Vec2i, var T) =
  ## Yields all of the tilemap's tiles, in top-to-bottom, left-to-right order.
  ## This can be used for serialization.

  for y in 0..<tilemap.height:
    for x in 0..<tilemap.width:
      let position = vec2i(x, y)
      yield (position, tilemap[position])

proc `size=`*(tilemap: FlatTilemap, _: Vec2i)
  {.error: "the size of a FlatTilemap is managed by its implementation".} =
  ## The size of the tilemap is managed by the implementation.
  ## Attempting to set it is an error.


# chunk tilemap (infinite size)

type
  Chunk*[T: TilemapTile, W, H: static int] = object
    tiles: array[W * H, T]

  ChunkTilemap*[T: TilemapTile,
                CW, CH: static int] {.final.} = ref object of RootTilemap
    chunks: Table[Vec2i, Chunk]


# abstract

type
  AnyTilemap*[T] = concept m
    m[Vec2i] is var T
    m[Vec2i] = T
    for position, tile in tiles(m):
      position is Vec2i
      tile is var T

iterator area*[T](tilemap: AnyTilemap, area: Recti): (Vec2i, var T) =
  ## Yields all tiles that lie in the given area. Iteration order is
  ## top-to-bottom, left-to-right.
  ## Out of bounds behavior is container-specific.

  for y in area.top..area.bottom:
    for x in area.left..area.right:
      let position = vec2i(x, y)
      yield (position, tilemap.container[position])


# physics

proc alignToGrid*(tilemap: RootTilemap, rect: Rectf): Recti =
  ## Returns grid coordinates of the given rectangle.

  let
    left = floor(rect.left / tilemap.tileWidth).int32
    top = floor(rect.top / tilemap.tileHeight).int32
    right = floor(rect.right / tilemap.tileWidth).int32
    bottom = floor(rect.bottom / tilemap.tileHeight).int32
  result = recti(left, top, right - left, bottom - top)

proc resolveCollisionX*[C](subject: var Rectf, tilemap: AnyTilemap,
                           direction: XCheckDirection): bool =
  ## Resolves collisions between the subject and the tilemap on the X axis.
  ## ``direction`` signifies the movement direction of the subject.
  ## ``outOfBounds`` is the tile used when the subject is out of bounds.

  let tiles = tilemap.alignToGrid(subject)
  for position, tile in area(tilemap, tiles):
    if tile.isSolid:
      let hitbox = rectf(position.vec2f * tilemap.tileSize, tilemap.tileSize)
      result = subject.resolveCollisionX(hitbox, direction) or result

proc resolveCollisionY*[C](subject: var Rectf, tilemap: AnyTilemap,
                           direction: YCheckDirection): bool =
  ## Resolves collisions between the subject and the tilemap on the Y axis.
  ## ``direction`` signifies the movement direction of the subject.
  ## ``outOfBounds`` is the tile used when the subject is out of bounds.

  let tiles = tilemap.alignToGrid(subject)
  for position, tile in area(tilemap, tiles):
    if tile.isSolid:
      let hitbox = rectf(position.vec2f * tilemap.tileSize, tilemap.tileSize)
      result = subject.resolveCollisionY(hitbox, direction) or result


# testing

when isMainModule:
  type
    Tile = distinct int

  proc isSolid(tile: Tile): bool = int(tile) != 0

  proc mustImplementAnyTilemap(T: type) =
    proc aux(m: AnyTilemap) = discard
    var x: T
    aux(x) {.explain.}

  FlatTilemap[Tile].mustImplementAnyTilemap

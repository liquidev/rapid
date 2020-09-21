## Tilemap with collision detection.

import std/options
import std/tables

import glm/vec

import ../physics/aabb

type
  TilemapTile* = concept tile {.explain.}
    tile.isSolid is bool

  TileContainer* = concept c, var mc, type T {.explain.}
    T is TilemapTile

    mc.init(Vec2i)

    c.size is Vec2i

    mc[Vec2i] is var T
    mc[Vec2i] = T

    for position, tile in tiles(mc):
      position is Vec2i
      tile is T

  Tilemap*[T: TilemapTile, C: TileContainer] = ref object
    container*: C
    fGridSize: Vec2f


# property getters

{.push inline.}

proc size*(tilemap: Tilemap): Vec2i =
  ## Returns the size of the tilemap, as a vector.
  tilemap.container.size

proc width*(tilemap: Tilemap): int32 =
  ## Returns the width of the tilemap.
  tilemap.container.size.x

proc height*(tilemap: Tilemap): int32 =
  ## Returns the height of the tilemap.
  tilemap.container.size.y

proc gridSize*(tilemap: Tilemap): Vec2f =
  ## Returns the size of the tilemap's grid, as a vector.
  tilemap.fGridSize

proc gridWidth*(tilemap: Tilemap): float32 =
  ## Returns the width of the tilemap.
  tilemap.fGridSize.x

proc gridHeight*(tilemap: Tilemap): float32 =
  ## Returns the height of the tilemap.
  tilemap.fGridSize.y


# tile getters/setters

proc `[]`*[T, C](tilemap: Tilemap[T, C], position: Vec2i): T =
  ## Retrieves a tile at the given position.
  ## Out of bounds behavior is container-specific.
  tilemap.container[position]

proc `[]=`*[T, C](tilemap: Tilemap[T, C], position: Vec2i, tile: T) =
  ## Sets a tile at the given position.
  ## Out of bounds behavior is container-specific.
  tilemap.container[position] = tile

{.pop.}


# iterators

iterator tiles*[T, C](tilemap: Tilemap[T, C]): (Vec2i, var T) =
  ## Yields all the tiles on the map.
  ## Depending on the tile container, this can be more efficient than
  ## iterating over the whole area of the map (eg. `ChunkTileContainer` will not
  ## iterate over non-existent chunks).

  for position, tile in tiles(tilemap.container):
    yield (position, tile)

iterator area*[T, C](tilemap: Tilemap[T, C], area: Recti): (Vec2i, var T) =
  ## Yields all tiles that lie in the given area. Iteration order is
  ## top-to-bottom, left-to-right.
  ## Out of bounds behavior is container-specific.

  for y in area.top..area.bottom:
    for x in area.left..area.right:
      let position = vec2i(x, y)
      yield (position, tilemap.container[position])


# initializers

proc newTilemap*[T, C](container: C, gridSize: Vec2f): Tilemap[T, C] =
  ## Creates a tilemap from an existing container.

  result = Tilemap[T, C](container: container, fGridSize: gridSize)

proc newTilemap*[T, C](size: Vec2i, gridSize: Vec2f): Tilemap[T, C] =
  ## Creates a tilemap from an empty container with the given size.

  result = Tilemap[T, C](fGridSize: gridSize)
  result.container.init(size)


# physics

proc alignToGrid*(tilemap: Tilemap, rect: Rectf): Recti =
  ## Returns grid coordinates of the given rectangle.

  let
    left = floor(rect.left / tilemap.gridWidth).int32
    top = floor(rect.top / tilemap.gridHeight).int32
    right = floor(rect.right / tilemap.gridWidth).int32
    bottom = floor(rect.bottom / tilemap.gridHeight).int32
  result = recti(left, top, right - left, bottom - top)

proc resolveCollisionX*[T, C](subject: var Rectf, tilemap: Tilemap[T, C],
                              direction: XCheckDirection,
                              outOfBounds: T = default(T)): bool =
  ## Resolves collisions between the subject and the tilemap on the X axis.
  ## ``direction`` signifies the movement direction of the subject.
  ## ``outOfBounds`` is the tile used when the subject is out of bounds.

  let tiles = tilemap.alignToGrid(subject)
  for position, tile in area(tilemap, tiles):
    if tile.isSolid:
      let hitbox = rectf(position.vec2f * tilemap.gridSize, tilemap.gridSize)
      result = subject.resolveCollisionX(hitbox, direction) or result

proc resolveCollisionY*[T, C](subject: var Rectf, tilemap: Tilemap[T, C],
                              direction: YCheckDirection,
                              outOfBounds: T = default(T)): bool =
  ## Resolves collisions between the subject and the tilemap on the Y axis.
  ## ``direction`` signifies the movement direction of the subject.
  ## ``outOfBounds`` is the tile used when the subject is out of bounds.

  let tiles = tilemap.alignToGrid(subject)
  for position, tile in area(tilemap, tiles):
    if tile.isSolid:
      let hitbox = rectf(position.vec2f * tilemap.gridSize, tilemap.gridSize)
      result = subject.resolveCollisionY(hitbox, direction) or result


# tile container: flat (finite size)

type
  FlatTileContainer*[T: TilemapTile] = object
    tiles*: seq[T]
    size: Vec2i
    outOfBounds: T

{.push inline.}

proc size*[T](c: FlatTileContainer[T]): Vec2i =
  ## Returns the size of the container.
  c.size

proc outOfBounds*[T](c: FlatTileContainer[T]): T =
  ## Returns the out of bounds tile for the container.
  c.outOfBounds

proc `outOfBounds=`*[T](c: var FlatTileContainer[T], tile: T) =
  ## Sets the out of bounds tile for the container.
  c.outOfBounds = tile

proc isInbounds*(c: FlatTileContainer, position: Vec2i): bool =
  ## Returns whether the given position lies inside the container's bounds.

  position.x >= 0 and position.x < c.size.x and
  position.y >= 0 and position.y < c.size.y

proc `[]`*[T](c: var FlatTileContainer[T], position: Vec2i): var T =
  ## Returns the tile at the given position, or ``c.outOfBounds`` if the
  ## position lies out of bounds.

  if c.isInbounds(position):
    c.tiles[position.x + position.y * c.size.x]
  else:
    c.outOfBounds

proc `[]=`*[T](c: var FlatTileContainer[T], position: Vec2i, tile: sink T) =
  ## Sets the tile at the given position, if the position lies inbounds.

  if c.isInbounds(position):
    c.tiles[position.x + position.y * c.size.x] = tile

iterator tiles*[T](c: var FlatTileContainer[T]): (Vec2i, var T) =
  ## Iterates over all tiles in the container.
  ## This iterator doesn't have any special optimizations, as there is no way in
  ## which you can iterate over a fixed-size tilemap in a more efficient manner.

  for y in 0..<c.size.y:
    for x in 0..<c.size.x:
      yield (vec2i(x, y), c.tiles[x + y * c.size.x])

type
  FlatTilemap*[T: TilemapTile] {.explain.} = Tilemap[T, FlatTileContainer[T]]

{.pop.}


# tile container: chunk-based (infinite size)

type
  Chunk*[T: TilemapTile, W, H: static int] = object
    tiles*: array[W * H, T]

  ChunkTileContainer*[T: TilemapTile, CW, CH: static int] = object
    chunks*: Table[Vec2i, Chunk[T, CW, CH]]
    size: Vec2i
    outOfBounds: T

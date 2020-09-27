## Tilemap with collision detection.

import std/options
import std/tables

import glm/vec

import ../math/vector
import ../physics/aabb

type
  TilemapTile* {.explain.} = concept a
    a == a is bool
    a.isSolid is bool

  RootTilemap*[T: TilemapTile] = ref object of RootObj
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

proc `tileSize=`*(tilemap: RootTilemap, newTileSize: Vec2f) =
  ## Returns the size of the tilemap's grid, as a vector.
  tilemap.fTileSize = newTileSize

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
  FlatTilemap*[T: TilemapTile] {.final.} = ref object of RootTilemap[T]
    tiles: seq[T]
    outOfBounds: T
    mutableOutOfBounds: T  # safety first! don't modify the main outOfBounds
                           # when returning a var reference to a tile


proc newFlatTilemap*[T](size: Vec2i, tileSize: Vec2f,
                        outOfBounds: T = default(T)): FlatTilemap[T] =
  ## Creates a new flat tilemap.

  new(result)
  result.fSize = size
  result.tileSize = tileSize
  result.outOfBounds = outOfBounds
  result.mutableOutOfBounds = outOfBounds

{.push inline.}

proc outOfBounds*[T](tilemap: FlatTilemap[T]): lent T =
  ## Returns the out of bounds tile for this tilemap.
  ## By default, this is ``default(T)``.
  tilemap.outOfBounds

proc `outOfBounds=`*[T](tilemap: FlatTilemap[T], newOutOfBoundsTile: sink T) =
  ## Sets the out of bounds tile for this tilemap.
  tilemap.outOfBounds = newOutOfBoundsTile
  tilemap.mutableOutOfBounds = newOutOfBoundsTile

proc `[]`*[T](tilemap: FlatTilemap[T], position: Vec2i): var T =
  ## Returns the tile at the given position, or ``tilemap.outOfBounds`` if the
  ## position lies out of bounds.

  if tilemap.isInbounds(position):
    result = tilemap.tiles[position.x + position.y * tilemap.width]
  else:
    result = tilemap.mutableOutOfBounds
    tilemap.mutableOutOfBounds = tilemap.outOfBounds

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
  ## The size of a fixed tilemap is managed by the implementation.
  ## Attempting to set it is an error.


# chunk tilemap (infinite size)

type
  Chunk*[T: TilemapTile, W, H: static int] {.byref.} = object
    tiles: array[W * H, T]
    filledTiles: uint32

  ChunkTilemap*[T: TilemapTile,
                CW, CH: static int] {.final.} = ref object of RootTilemap[T]
    chunks: Table[Vec2i, Chunk[T, CW, CH]]
    outOfBounds: T
    mutableOutOfBounds: T  # again, safety first!

proc newChunkTilemap*[T; CW, CH: static int](
  tileSize: Vec2f, outOfBounds: T = default(T)): ChunkTilemap[T, CW, CH] =
  ## Creates a new chunk tilemap.

  new(result)
  result.tileSize = tileSize
  result.outOfBounds = outOfBounds
  result.mutableOutOfBounds = outOfBounds

{.push inline.}

proc chunkPosition*[T; CW, CH: static int](tilemap: ChunkTilemap[T, CW, CH],
                                           position: Vec2i): Vec2i =
  ## Returns the coordinates of the chunk which contains the given
  ## global position.
  position div vec2i(CW.int32, CH.int32)

proc positionInChunk*[T; CW, CH: static int](tilemap: ChunkTilemap[T, CW, CH],
                                             position: Vec2i): Vec2i =
  ## Wraps the given global position to chunk coordinates.
  position mod vec2i(CW.int32, CH.int32)

proc hasChunk*[T; CW, CH: static int](tilemap: ChunkTilemap[T, CW, CH],
                                      position: Vec2i): bool =
  ## Returns whether the tilemap contains the given chunk.
  position in tilemap.chunks

proc chunk*[T; CW, CH: static int](
  tilemap: ChunkTilemap[T, CW, CH],
  position: Vec2i): Option[lent Chunk[T, CW, CH]] =
  ## Returns an immutable reference to a chunk at the given position.

  if tilemap.hasChunk(position):
    result = some tilemap.chunks[position]

proc `[]`*[T; CW, CH: static int](chunk: Chunk, position: Vec2i): lent T =
  ## Returns an immutable reference to the given tile in the given chunk.
  ##
  ## **Warning:** The position is not out of bounds-checked for performance
  ## reasons. The global coordinate [] should be preferred over this anyways.

  chunk.tiles[position.x + position.y * CW]

proc `[]`*[T; CW, CH: static int](chunk: var Chunk[T, CW, CH],
                                  position: Vec2i): var T =
  ## Returns a mutable reference to the given tile in the given chunk.
  ##
  ## **Warning:** The position is not out of bounds-checked for performance
  ## reasons. The global coordinate [] should be preferred over this anyways.

  chunk.tiles[position.x + position.y * CW]

proc `[]=`*[T; CW, CH: static int](chunk: var Chunk[T, CW, CH], position: Vec2i,
                                   tile: sink T)=
  ## Sets the tile at the given position in the given chunk.
  ##
  ## **Warning:** The position is not out of bounds-checked for performance
  ## reasons. The global coordinate [] should be preferred over this anyways.

  chunk.tiles[position.x + position.y * CW] = tile

proc `[]`*[T; CW, CH: static int](tilemap: ChunkTilemap[T, CW, CH],
                                  position: Vec2i): var T =
  ## Returns a mutable reference to the tile at the given position.

  let chunkPosition = tilemap.chunkPosition(position)
  if tilemap.hasChunk(chunkPosition):
    result = tilemap.chunks[chunkPosition][tilemap.positionInChunk(position)]
  else:
    result = tilemap.mutableOutOfBounds
    tilemap.mutableOutOfBounds = tilemap.outOfBounds

{.pop.}

proc `[]=`*[T; CW, CH: static int](tilemap: ChunkTilemap[T, CW, CH],
                                   position: Vec2i, tile: sink T) =
  ## Sets the tile at the given position.

  # this is quite big so let's not inline it

  let chunkPosition = tilemap.chunkPosition(position)

  var chunk: ptr Chunk[T, CW, CH]
  if not tilemap.hasChunk(chunkPosition):
    var c = Chunk[T, CW, CH]()
    for tile in mitems(c.tiles):
      tile = tilemap.outOfBounds
  else:
    chunk = addr tilemap.chunks[chunkPosition]

  let
    positionInChunk = tilemap.positionInChunk(position)
    diff =  # branchless programming™
      # only diff if the tile changed
      int(chunk[][positionInChunk] != tile) *
      # diff -1 if the tile was OOB or 1 if it was IB
      (2 * int(tile != tilemap.outOfBounds) - 1)
  chunk.filledTiles.inc diff
  if chunk.filledTiles == 0:
    # delete empty chunks
    tilemap.chunks.del(chunkPosition)
  chunk[][positionInChunk] = tile

iterator tiles*[T, CW, CH](chunk: Chunk[T, CW, CH]): (Vec2i, lent T) =
  ## Iterates through the chunk's tiles and yields immutable references to them.
  ## Iteration order is top-to-bottom, left-to-right.

  for y in 0..<CH:
    for x in 0..<CW:
      yield (vec2i(x.int32, y.int32), chunk.tiles[x + y * CW])

iterator tiles*[T, CW, CH](chunk: var Chunk[T, CW, CH]): (Vec2i, var T) =
  ## Iterates through the chunk's tiles and yields mutable references to them.
  ## Iteration order is top-to-bottom, left-to-right.

  for y in 0..<CH:
    for x in 0..<CW:
      yield (vec2i(x.int32, y.int32), chunk.tiles[x + y * CW])

iterator tiles*[T, CW, CH](tilemap: ChunkTilemap[T, CW, CH]): (Vec2i, var T) =
  ## Iterates through all of the tilemap's chunks and yields their positions and
  ## mutable tile references.
  ## Chunk iteration order is undefined. Tile iteration order is top-to-bottom,
  ## left-to-right per chunk.

  for chunkPosition, chunk in tilemap.chunks:
    let chunkOrigin = chunkPosition * vec2i(CW, CH)
    for offset, tile in tiles(chunk):
      let position = chunkOrigin + offset
      yield (position, tile)

proc `size=`*(tilemap: ChunkTilemap, _: Vec2i)
  {.error: "the size of a ChunkTilemap is managed by its implementation".} =
  ## The size of a chunk tilemap is managed by its implementation.
  ## Attempting to set it is an error.


# abstract

type
  AnyTilemap*[T] {.explain.} = concept m
    # m[Vec2i] is var T
    # m[Vec2i] = T
    # for position, tile in tiles(m):
    #   position is Vec2i
    #   tile is var T

iterator area*[T](tilemap: AnyTilemap[T], area: Recti): (Vec2i, var T) =
  ## Yields all tiles that lie in the given area. Iteration order is
  ## top-to-bottom, left-to-right.
  ## Out of bounds behavior is container-specific.

  for y in area.top..area.bottom:
    for x in area.left..area.right:
      let position = vec2i(x, y)
      yield (position, tilemap[position])


# physics

proc alignToGrid*(tilemap: RootTilemap, rect: Rectf): Recti =
  ## Returns grid coordinates of the given rectangle.

  let
    left = floor(rect.left / tilemap.tileWidth).int32
    top = floor(rect.top / tilemap.tileHeight).int32
    right = floor(rect.right / tilemap.tileWidth).int32
    bottom = floor(rect.bottom / tilemap.tileHeight).int32
  result = recti(left, top, right - left, bottom - top)

proc resolveCollisionX*[T](subject: var Rectf, tilemap: AnyTilemap[T],
                           direction: XCheckDirection): bool =
  ## Resolves collisions between the subject and the tilemap on the X axis.
  ## ``direction`` signifies the movement direction of the subject.
  ## ``outOfBounds`` is the tile used when the subject is out of bounds.

  let tiles = tilemap.alignToGrid(subject)
  for position, tile in area(tilemap, tiles):
    if tile.isSolid:
      let hitbox = rectf(position.vec2f * tilemap.tileSize, tilemap.tileSize)
      result = subject.resolveCollisionX(hitbox, direction) or result

proc resolveCollisionY*[T](subject: var Rectf, tilemap: AnyTilemap[T],
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

  proc `==`(a, b: Tile): bool {.borrow.}
  proc isSolid(tile: Tile): bool = int(tile) != 0

  proc mustImplementAnyTilemap(T: type) =
    proc aux(m: AnyTilemap) = discard
    var x: T
    aux(x) {.explain.}

  FlatTilemap[Tile].mustImplementAnyTilemap {.explain.}
  ChunkTilemap[Tile, 4, 4].mustImplementAnyTilemap {.explain.}

  type
    MyTilemap = ChunkTilemap[Tile, 16, 16]
  MyTilemap.mustImplementAnyTilemap

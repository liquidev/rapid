## Tilemap with collision detection.

import std/tables

import aglet/rect
import glm/vec

import ../math/vector

type
  TilemapTile* {.explain.} = concept a
    a == a is bool

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

  result.tiles.setLen(size.x * size.y)
  for tile in mitems(result.tiles):
    tile = outOfBounds

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
  UserChunk*[T: TilemapTile, W, H: static int, U] {.byref.} = object
    tiles: array[W * H, T]
    outOfBounds: T
    filledTiles: uint32
    user*: U

  Chunk*[T: TilemapTile, W, H: static int] = UserChunk[T, W, H, void]
    ## Chunk with void user type, for situtions when you don't need to store any
    ## extra data alongside chunks.

  UserChunkTilemap*[T: TilemapTile,
                    CW, CH: static int,
                    U] {.final.} = ref object of RootTilemap[T]
    chunks: Table[Vec2i, UserChunk[T, CW, CH, U]]
    outOfBounds: T
    mutableOutOfBounds: T  # again, safety first!

  ChunkTilemap*[T: TilemapTile, CW, CH: static int] =
    UserChunkTilemap[T, CW, CH, void]
    ## Chunk tilemap with void user type, for situations when you don't need to
    ## store any extra data alongside chunks.

proc newUserChunkTilemap*[T; CW, CH: static int, U](
  tileSize: Vec2f,
  outOfBounds: T = default(T)
): UserChunkTilemap[T, CW, CH, U] =
  ## Creates a new chunk tilemap.

  new(result)
  result.tileSize = tileSize
  result.outOfBounds = outOfBounds
  result.mutableOutOfBounds = outOfBounds

{.push inline.}

proc newChunkTilemap*[T; CW, CH: static int](
  tileSize: Vec2f,
  outOfBounds: T = default(T)
): ChunkTilemap[T, CW, CH] =
  ## Creates a new chunk tilemap without user data.
  newUserChunkTilemap[T, CW, CH, void](tileSize, outOfBounds)

proc outOfBounds*[T; CW, CH: static int, U](
  tilemap: UserChunkTilemap[T, CW, CH, U]
): lent T =
  ## Returns the out of bounds tile for this tilemap. This tile cannot be
  ## changed for safety and efficiency reasons.
  tilemap.outOfBounds

proc chunkPosition*[T; CW, CH: static int, U](
  tilemap: UserChunkTilemap[T, CW, CH, U],
  position: Vec2i
): Vec2i =
  ## Returns the coordinates of the chunk which contains the given
  ## global position.
  floor(position.vec2f / vec2f(CW, CH)).vec2i

proc positionInChunk*[T; CW, CH: static int, U](
  tilemap: UserChunkTilemap[T, CW, CH, U],
  position: Vec2i
): Vec2i =
  ## Wraps the given global position to chunk coordinates.
  position.vec2f.floorMod(vec2f(CW, CH)).vec2i

proc hasChunk*[T; CW, CH: static int, U](
  tilemap: UserChunkTilemap[T, CW, CH, U],
  position: Vec2i
): bool =
  ## Returns whether the tilemap contains the given chunk.
  position in tilemap.chunks

proc isInbounds*(tilemap: UserChunkTilemap, position: Vec2i): bool =
  ## Returns whether the given position lies inside of one of the tilemap's
  ## existing chunks.
  tilemap.hasChunk(tilemap.chunkPosition(position))

proc chunk*[T; CW, CH: static int, U](
  tilemap: UserChunkTilemap[T, CW, CH, U],
  position: Vec2i,
  outChunk: var UserChunk[T, CW, CH, U]
): bool =
  ## Returns the chunk at the given position.

  if tilemap.hasChunk(position):
    outChunk = tilemap.chunks[position]
    result = true

proc chunk*[T; CW, CH: static int, U](
  tilemap: UserChunkTilemap[T, CW, CH, U],
  position: Vec2i
): var UserChunk[T, CW, CH, U] =
  ## Returns a mutable reference to the chunk at the given position.
  ## Raises an exception if the chunk doesn't exist.

  if tilemap.hasChunk(position):
    result = tilemap.chunks[position]
  else:
    raise newException(IndexDefect, "chunk " & $position & " doesn't exist")

proc `[]`*[T; CW, CH: static int, U](chunk: UserChunk[T, CW, CH, U],
                                     position: Vec2i): lent T =
  ## Returns an immutable reference to the given tile in the given chunk.
  ##
  ## **Warning:** The position is not out of bounds-checked for performance
  ## reasons. The global coordinate [] should be preferred over this anyways.

  chunk.tiles[position.x + position.y * CW]

proc `[]`*[T; CW, CH: static int, U](chunk: var UserChunk[T, CW, CH, U],
                                     position: Vec2i): var T =
  ## Returns a mutable reference to the given tile in the given chunk.
  ##
  ## **Warning:** The position is not out of bounds-checked for performance
  ## reasons. The global coordinate [] should be preferred over this anyways.

  chunk.tiles[position.x + position.y * CW]

proc `[]=`*[T; CW, CH: static int, U](chunk: var UserChunk[T, CW, CH, U],
                                      position: Vec2i, tile: sink T)=
  ## Sets the tile at the given position in the given chunk.
  ##
  ## **Warning:** The position is not out of bounds-checked for performance
  ## reasons. The global coordinate [] should be preferred over this anyways.

  let oldTile = chunk[position]

  # branchless programming™
  inc chunk.filledTiles,
    int(oldTile == chunk.outOfBounds and tile != chunk.outOfBounds) * 1 -
    int(tile == chunk.outOfBounds and oldTile != chunk.outOfBounds) * 1

  chunk.tiles[position.x + position.y * CW] = tile

proc `[]`*[T; CW, CH: static int, U](tilemap: UserChunkTilemap[T, CW, CH, U],
                                     position: Vec2i): var T =
  ## Returns a mutable reference to the tile at the given position.

  let chunkPosition = tilemap.chunkPosition(position)
  if tilemap.hasChunk(chunkPosition):
    result = tilemap.chunks[chunkPosition][tilemap.positionInChunk(position)]
  else:
    tilemap.mutableOutOfBounds = tilemap.outOfBounds
    result = tilemap.mutableOutOfBounds

{.pop.}

proc `[]=`*[T; CW, CH: static int, U](tilemap: UserChunkTilemap[T, CW, CH, U],
                                      position: Vec2i, tile: sink T) =
  ## Sets the tile at the given position.

  # this is quite big so let's not inline it

  let chunkPosition = tilemap.chunkPosition(position)

  var chunk: ptr UserChunk[T, CW, CH, U]
  if not tilemap.hasChunk(chunkPosition):
    var c = UserChunk[T, CW, CH, U](outOfBounds: tilemap.outOfBounds)
    for tile in mitems(c.tiles):
      tile = tilemap.outOfBounds
    tilemap.chunks[chunkPosition] = c
  chunk = addr tilemap.chunks[chunkPosition]

  let positionInChunk = tilemap.positionInChunk(position)
  chunk[][positionInChunk] = tile
  if chunk.filledTiles == 0:
    # delete empty chunks
    tilemap.chunks.del(chunkPosition)

iterator tiles*[T, CW, CH, U](chunk: UserChunk[T, CW, CH, U]): (Vec2i, lent T) =
  ## Iterates through the chunk's tiles and yields immutable references to them.
  ## Iteration order is top-to-bottom, left-to-right.

  for y in 0..<CH:
    for x in 0..<CW:
      yield (vec2i(x.int32, y.int32), chunk.tiles[x + y * CW])

iterator tiles*[T, CW, CH, U](chunk: var UserChunk[T, CW, CH, U]):
                             (Vec2i, var T) =
  ## Iterates through the chunk's tiles and yields mutable references to them.
  ## Iteration order is top-to-bottom, left-to-right.

  for y in 0..<CH:
    for x in 0..<CW:
      yield (vec2i(x.int32, y.int32), chunk.tiles[x + y * CW])

iterator chunks*[T, CW, CH, U](tilemap: UserChunkTilemap[T, CW, CH, U]):
                              (Vec2i, var UserChunk[T, CW, CH, U]) =
  ## Iterates through all of the tilemap's chunks and returns their positions
  ## and mutable references. Iteration order is undefined.

  bind mpairs

  for chunkPosition, chunk in mpairs(tilemap.chunks):
    yield (chunkPosition, chunk)

iterator tiles*[T, CW, CH, U](tilemap: UserChunkTilemap[T, CW, CH, U]):
                             (Vec2i, var T) =
  ## Iterates through all of the tilemap's chunks' tiles and yields their
  ## positions and mutable references.
  ## Chunk iteration order is undefined. Tile iteration order is top-to-bottom,
  ## left-to-right per chunk.

  for chunkPosition, chunk in chunks(tilemap):
    let chunkOrigin = chunkPosition * vec2i(CW, CH)
    for offset, tile in tiles(chunk):
      let position = chunkOrigin + offset
      yield (position, tile)

proc size*(tilemap: UserChunkTilemap): Vec2i
  {.error: "the size of a UserChunkTilemap is infinite".}

proc `size=`*(tilemap: UserChunkTilemap, _: Vec2i)
  {.error: "the size of a UserChunkTilemap is infinite".} =
  ## The size of a chunk tilemap is undefined at any given moment.
  ## Attempting to access it is an error.


# abstract

type
  AnyTilemap*[T] = concept m
    m[Vec2i] is var T
    m[Vec2i] = T
    for position, tile in tiles(m):
      position is Vec2i
      tile is var T

iterator area*(tilemap: AnyTilemap, area: Recti): (Vec2i, var auto) =
  ## Yields all tiles that lie in the given area. Iteration order is
  ## top-to-bottom, left-to-right.
  ## Out of bounds behavior is container-specific.

  for y in area.top..area.bottom:
    for x in area.left..area.right:
      let position = vec2i(x, y)
      yield (position, tilemap[position])


# testing

when isMainModule:
  type
    Tile = distinct int

  proc `==`(a, b: Tile): bool {.borrow.}

  proc mustImplementAnyTilemap(T: type) =
    proc aux(m: AnyTilemap) = discard
    var x: T
    aux(x) {.explain.}

  FlatTilemap[Tile].mustImplementAnyTilemap {.explain.}
  ChunkTilemap[Tile, 4, 4].mustImplementAnyTilemap {.explain.}

  type
    MyTilemap = ChunkTilemap[Tile, 16, 16]
  MyTilemap.mustImplementAnyTilemap

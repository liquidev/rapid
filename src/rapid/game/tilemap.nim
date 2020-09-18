## Tilemap with collision detection.

import std/options

import glm/vec

import ../physics/aabb

type
  TilemapTile* = concept tile
    tile.isSolid is bool
  Tilemap*[T: TilemapTile] = object
    fSize: Vec2i
    tiles: seq[T]
    fGridSize: Vec2f


# property getters

{.push inline.}

proc size*(tilemap: Tilemap): Vec2i =
  ## Returns the size of the tilemap, as a vector.
  tilemap.fSize

proc width*(tilemap: Tilemap): int32 =
  ## Returns the width of the tilemap.
  tilemap.size.x

proc height*(tilemap: Tilemap): int32 =
  ## Returns the height of the tilemap.
  tilemap.size.y

proc gridSize*(tilemap: Tilemap): Vec2f =
  ## Returns the size of the tilemap's grid, as a vector.
  tilemap.fGridSize

proc gridWidth*(tilemap: Tilemap): float32 =
  ## Returns the width of the tilemap.
  tilemap.gridSize.x

proc gridHeight*(tilemap: Tilemap): float32 =
  ## Returns the height of the tilemap.
  tilemap.gridSize.y

proc isInbounds*(tilemap: Tilemap, position: Vec2i): bool =
  ## Returns whether the given position lies inside of the tilemap's boundaries.
  position.x >= 0 and position.x < tilemap.width and
  position.y >= 0 and position.y < tilemap.height

proc isOutOfBounds*(tilemap: Tilemap, position: Vec2i): bool =
  ## Returns whether the given position lies out of the tilemap's boundaries.
  not tilemap.isInbounds(position)


# tile getters

proc unsafeGet*[T](tilemap: var Tilemap[T],
                   position: Vec2i): var T =
  ## Returns a mutable view into the tile at the given position.
  ##
  ## **Warning:** This does not perform bounds checking. Prefer `[]` instead.

  tilemap.tiles[position.x + position.y * tilemap.width]

proc unsafeGet*[T](tilemap: Tilemap[T], position: Vec2i): lent T =
  ## Returns an immutable view into the tile at the given position.
  ##
  ## **Warning:** This does not perform bounds checking. Prefer `[]` instead.

  tilemap.tiles[position.x + position.y * tilemap.width]

proc unsafeSet*[T](tilemap: var Tilemap[T], position: Vec2i, tile: sink T) =
  ## Sets the tile at the given position.
  ##
  ## **Warning:** This does not perform bounds checking. Prefer `[]` instead.

  tilemap.tiles[position.x + position.y * tilemap.width] = tile

proc `[]`*[T](tilemap: var Tilemap[T], position: Vec2i): var T =
  ## Returns a mutable view into the tile at the given position.
  ## Raises an error if the position lies out of bounds.

  assert tilemap.isInbounds(position), "position must lie inbounds"
  tilemap.unsafeGet(position)

proc `[]`*[T](tilemap: Tilemap[T], position: Vec2i): lent T =
  ## Returns an immutable view into the tile at the given position.
  ## Raises an error if the position lies out of bounds.

  assert tilemap.isInbounds(position), "position must lie inbounds"
  tilemap.unsafeGet(position)

proc `[]=`*[T](tilemap: var Tilemap[T], position: Vec2i, tile: sink T) =
  ## Returns an immutable view into the tile at the given position.
  ## Raises an error if the position lies out of bounds.

  assert tilemap.isInbounds(position), "position must lie inbounds"
  tilemap.unsafeSet(position, tile)

proc `[]`*[T](tilemap: Tilemap[T], position: Vec2i, outOfBounds: T): T =
  ## Returns the tile at the given position, or ``outOfBounds`` if the position
  ## is out of bounds.

  if tilemap.isInbounds(position):
    tilemap.unsafeGet(position)
  else:
    outOfBounds

proc `{}`*[T](tilemap: var Tilemap[T], position: Vec2i): var T =
  ## Returns a _safe_ mutable view into a tile at the given position,
  ## wrapping the position around if it lies out of bounds.

  # this is a little slow since it uses ``mod``,
  # a fast if-based version would be nice

  let wrapped = position mod tilemap.size
  tilemap.unsafeGet(wrapped)

proc `{}=`*[T](tilemap: var Tilemap[T], position: Vec2i, tile: sink T) =
  ## Returns a _safe_ mutable view into a tile at the given position,
  ## wrapping the position around if it lies out of bounds.

  # this is a little slow since it uses ``mod``,
  # a fast if-based version would be nice

  let wrapped = position mod tilemap.size
  tilemap.unsafeSet(wrapped, tile)

proc `{}`*[T](tilemap: Tilemap[T], position: Vec2i): lent T =
  ## Returns a _safe_ mutable view into a tile at the given position,
  ## wrapping the position around if it lies out of bounds.

  let wrapped = position mod tilemap.size
  tilemap.unsafeGet(wrapped)

{.pop.}


# iterators

iterator tiles*[T](tilemap: var Tilemap[T]): (Vec2i, var T) =
  ## Iterates through all tiles in the given tilemap, and returns a mutable
  ## reference to each one along with its position on the map.

  for y in 0..<tilemap.height:
    for x in 0..<tilemap.width:
      let position = vec2i(x, y)
      yield (position, tilemap.unsafeGet(position))

iterator tiles*[T](tilemap: Tilemap[T]): (Vec2i, lent T) =
  ## Iterates through all tiles in the given tilemap, and returns a mutable
  ## reference to each one along with its position on the map.

  for y in 0..<tilemap.height:
    for x in 0..<tilemap.width:
      let position = vec2i(x, y)
      yield (position, tilemap.unsafeGet(position))

iterator area*[T](tilemap: Tilemap[T], rect: Recti,
                  outOfBounds: T = T.default): (Vec2i, lent T) =
  ## Iterates through all tiles lying in the given rectangle, and returns a
  ## reference to each one along with its position on the map.
  ## Returns ``default`` if a tile lies out of bounds.

  for y in rect.top..rect.bottom:
    for x in rect.left..rect.right:
      let position = vec2i(x, y)
      yield (position, tilemap[position, outOfBounds])

iterator areaWrap*[T](tilemap: var Tilemap[T],
                      rect: Recti): (Vec2i, var T) =
  ## Iterates through all tiles lying in the given rectangle, and returns a
  ## mutable reference to each one along with its position on the map.
  ## If the position is out of bounds, it is wrapped around to the other side.
  ## The yielded position is _not_ wrapped around to make rendering easy.
  ## Looking up tiles with this position will work correctly, as long as the
  ## ``{}`` operator is used.

  for y in rect.top..rect.bottom:
    for x in rect.left..rect.right:
      let position = vec2i(x, y)
      yield (position, tilemap{position})

iterator areaWrap*[T](tilemap: Tilemap[T],
                      rect: Recti): (Vec2i, lent T) =
  ## Iterates through all tiles lying in the given rectangle, and returns an
  ## immutable reference to each one along with its position on the map.
  ## The yielded position follows the same rules as in the ``var`` version of
  ## this iterator.

  for y in rect.top..rect.bottom:
    for x in rect.left..rect.right:
      let position = vec2i(x, y)
      yield (position, tilemap{position})


# init

proc init*[T](tilemap: var Tilemap[T], size: Vec2i, gridSize: Vec2f,
              defaultTile = default(T)) =
  ## Initializes a new tilemap with the given size and default tile.
  tilemap.fSize = size
  tilemap.fGridSize = gridSize
  tilemap.tiles.setLen(size.x * size.y)
  for position, tile in tiles(tilemap):
    tile = defaultTile


# physics

proc alignToGrid*(tilemap: Tilemap, rect: Rectf): Recti =
  ## Returns grid coordinates of the given rectangle.

  let
    left = floor(rect.left / tilemap.gridWidth).int32
    top = floor(rect.top / tilemap.gridHeight).int32
    right = floor(rect.right / tilemap.gridWidth).int32
    bottom = floor(rect.bottom / tilemap.gridHeight).int32
  result = recti(left, top, right - left, bottom - top)

# god damnit this doesn't work and i have to do this with procs
# template resolveCollisionXIt*[T](subject: var Rectf, tilemap: Tilemap[T],
#                                  direction: XCheckDirection,
#                                  isSolidExpr: untyped,
#                                  outOfBounds: T = default(T)): untyped =
#   ## Resolves collisions between the subject and the tilemap on the X axis.
#   ## ``direction`` signifies the movement direction of the subject.
#   ## ``isSolidExpr`` is a bool expression which should return whether a tile
#   ## (``it``) is solid or not. ``defaultTile`` is the tile used when the subject
#   ## is out of bounds.
#
#   var result = false
#   let tiles = tilemap.alignToGrid(subject)
#   for x in area(tilemap, tiles, outOfBounds):
#     echo x
#     if isSolidExpr:
#       let hitbox = rectf(position.vec2f * tilemap.gridSize, tilemap.gridSize)
#       result = subject.resolveCollisionX(hitbox, direction) or result
#   result
#
# template resolveCollisionYIt*[T](subject: var Rectf, tilemap: Tilemap[T],
#                                  direction: YCheckDirection,
#                                  isSolidExpr: untyped,
#                                  defaultTile = default(T)): bool =
#   ## Resolves collisions between the subject and the tilemap on the Y axis.
#   ## ``direction`` signifies the movement direction of the subject.
#   ## ``isSolidExpr`` is a bool expression which should return whether a tile
#   ## (``it``) is solid or not. ``defaultTile`` is the tile used when the subject
#   ## is out of bounds.
#
#   var result = false
#   let area = tilemap.alignToGrid(subject)
#   for position, tile in tilemap.area(area, defaultTile):
#     if (let it {.inject.} = tile; isSolidExpr):
#       let hitbox = rectf(position.vec2f * tilemap.gridSize, tilemap.gridSize)
#       result = subject.resolveCollisionY(hitbox, direction) or result
#   result

proc resolveCollisionX*[T](subject: var Rectf, tilemap: Tilemap[T],
                           direction: XCheckDirection,
                           outOfBounds: T = default(T)): bool =
  ## Resolves collisions between the subject and the tilemap on the X axis.
  ## ``direction`` signifies the movement direction of the subject.
  ## ``outOfBounds`` is the tile used when the subject is out of bounds.

  let tiles = tilemap.alignToGrid(subject)
  for position, tile in area(tilemap, tiles, outOfBounds):
    if tile.isSolid:
      let hitbox = rectf(position.vec2f * tilemap.gridSize, tilemap.gridSize)
      result = subject.resolveCollisionX(hitbox, direction) or result

proc resolveCollisionY*[T](subject: var Rectf, tilemap: Tilemap[T],
                           direction: YCheckDirection,
                           outOfBounds: T = default(T)): bool =
  ## Resolves collisions between the subject and the tilemap on the Y axis.
  ## ``direction`` signifies the movement direction of the subject.
  ## ``outOfBounds`` is the tile used when the subject is out of bounds.

  let tiles = tilemap.alignToGrid(subject)
  for position, tile in area(tilemap, tiles, outOfBounds):
    if tile.isSolid:
      let hitbox = rectf(position.vec2f * tilemap.gridSize, tilemap.gridSize)
      result = subject.resolveCollisionY(hitbox, direction) or result

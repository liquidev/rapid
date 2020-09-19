## Tilemap AABB collider implementation.

import ../ec/physics_aabb
import ../physics/aabb
import tilemap

type
  TilemapAabbCollider*[T] = ref object of AabbCollider
    tilemap: Tilemap[T]
    outOfBounds: T

proc collider*[T](tilemap: Tilemap[T],
                  outOfBounds = default(T)): TilemapAabbCollider[T] =
  ## Creates a collider for the given tilemap, with the given out of bounds
  ## tile.

  new(result)

  result.tilemap = tilemap
  result.outOfBounds = outOfBounds

  result.resolveCollisionXImpl = proc (collider: AabbCollider,
                                       subject: var Rectf,
                                       direction: XCheckDirection): bool
                                      {.nimcall.} =
    let collider = collider.TilemapAabbCollider[:T]
    result = subject.resolveCollisionX(collider.tilemap, direction,
                                       collider.outOfBounds)

  result.resolveCollisionYImpl = proc (collider: AabbCollider,
                                       subject: var Rectf,
                                       direction: YCheckDirection): bool
                                      {.nimcall.} =
    let collider = collider.TilemapAabbCollider[:T]
    result = subject.resolveCollisionY(collider.tilemap, direction,
                                       collider.outOfBounds)

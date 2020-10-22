## Tilemap-Chipmunk physics binding.
## This module is responsible for creating physics bodies out of tilemaps.

import std/options

import glm/vec

import ../math/rectangle
import ../physics/chipmunk
import tilemap

type
  TileCollisionProvider*[T: TilemapTile] = proc (tile: T): bool
    ## Callback that feeds the body shape generator with tile collision data,
    ## namely, whether the given tile is solid or not.

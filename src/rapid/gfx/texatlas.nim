#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module provides texture atlas utilities.

import tables

import ../res/textures

type
  RAtlas* = object
    tileWidth, tileHeight, spacingX, spacingY: float
    tilesX, tilesY: int
  RTileRect* = tuple[x, y, w, h: float]

proc rect*(atlas: RAtlas, x, y: int): RTileRect =
  ## Calculates texture coordinates for the tile (x, y).
  let
    left = x.float * (atlas.tileWidth + atlas.spacingX * 2) + atlas.spacingX
    top = y.float * (atlas.tileHeight + atlas.spacingY * 2) + atlas.spacingY
  result = (left, top, atlas.tileWidth, atlas.tileHeight)

proc newRAtlas*(texture: RTexture,
                tileWidth, tileHeight: Natural, spacing = 0.Natural): RAtlas =
  ## Creates a new tile atlas for an image.
  let
    fullTileWidth = (tileWidth + spacing * 2)
    fullTileHeight = (tileHeight + spacing * 2)
  result = RAtlas(
    tileWidth: tileWidth / texture.width,
    tileHeight: tileHeight / texture.height,
    spacingX: spacing / texture.width,
    spacingY: spacing / texture.height,
    tilesX: int(texture.width / fullTileWidth),
    tilesY: int(texture.height / fullTileHeight)
  )

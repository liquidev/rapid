#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module provides texture atlas utilities.
## It is not exported by ``gfx``, since not all games/applications use tile \
## atlases.

import tables

import ../data/storage

type
  RAtlas* = object
    tileWidth, tileHeight, spacingX, spacingY: float
    tilesX, tilesY: int
  RTileRect* = tuple[x, y, w, h: float]

proc rect*(atlas: RAtlas, x, y: int): RTileRect =
  ## Calculates texture coordinates for the tile (x, y).
  let
    left = float(x) * (atlas.tileWidth + atlas.spacingX * 2) + atlas.spacingX
    top = float(y) * (atlas.tileHeight + atlas.spacingY * 2) + atlas.spacingY
  result = (left, top, atlas.tileWidth, atlas.tileHeight)

proc newRAtlas*(img: RImage,
                tileWidth, tileHeight: Natural, spacing = 0.Natural): RAtlas =
  ## Creates a new tile atlas for an image.
  let
    fullTileWidth = (tileWidth + spacing * 2)
    fullTileHeight = (tileHeight + spacing * 2)
  result = RAtlas(
    tileWidth: tileWidth / img.width,
    tileHeight: tileHeight / img.height,
    spacingX: spacing / img.width,
    spacingY: spacing / img.height,
    tilesX: int(img.width / fullTileWidth),
    tilesY: int(img.height / fullTileHeight)
  )

proc newRAtlas*(data: RData, img: string,
                tileWidth, tileHeight: Natural, spacing = 0.Natural): RAtlas =
  result = newRAtlas(data.images[img], tileWidth, tileHeight, spacing)

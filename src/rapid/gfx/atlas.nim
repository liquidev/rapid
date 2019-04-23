#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module provides texture atlas utilities.
## It is not exported by ``gfx``, since not all games/applications use atlases.

import tables

import ../data/storage

type
  RAtlas* = object
    tileWidth, tileHeight, spacingX, spacingY: float
    tilesX, tilesY: int
  RTileQuad* = array[4, tuple[u, v: float]]

proc uv*(atlas: RAtlas, x, y: int): RTileQuad =
  let
    left = float(x) * (atlas.tileWidth + atlas.spacingX * 2)
    top = float(y) * (atlas.tileHeight + atlas.spacingY * 2)
  result = [
    (left, top),
    (left + atlas.tileWidth, top),
    (left + atlas.tileWidth, top + atlas.tileHeight),
    (left, top + atlas.tileHeight)
  ]

proc uv*(atlas: RAtlas, index: int): RTileQuad =
  result = atlas.uv(index mod atlas.tilesX, index div atlas.tilesY)

proc newRAtlas*(img: RImage,
                tileWidth, tileHeight: Natural, spacing = 0.Natural): RAtlas =
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

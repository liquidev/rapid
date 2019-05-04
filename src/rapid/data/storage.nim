#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## Game resource loading and management, packed into a convenient structure \
## supported by most resource-using objects.

import os
import tables

import nimPNG

include dsl
include fonts
include textures

type
  DataSpec = object
    images: Table[string, string]
    textures: Table[string, RTextureConfig]
    fonts: Table[string, FontConfig]
  RData* = ref object
    # Loading
    dir*: string
    spec: DataSpec
    # Storage
    images*: TableRef[string, RImage]
    textures*: TableRef[string, RTexture]
    fonts*: TableRef[string, RFont]
  RResKind* = enum
    resImage
    resFont

#--
# Data
#--

proc newRData*(): RData =
  ## Creates a new ``RData`` object, for automated game resource loading and \
  ## management.
  new(result)
  result.dir = "data"
  result.spec = DataSpec(
    images: initTable[string, string](),
    textures: initTable[string, RTextureConfig]()
  )
  result.images = newTable[string, RImage]()
  result.textures = newTable[string, RTexture]()

proc image*(data: var RData, name, filename: string, texConf: RTextureConfig) =
  ## Defines an image to be loaded with the ``load`` iterator.
  data.spec.images[name] = filename
  data.spec.textures[name] = texConf

proc font*(data: var RData, name, filename: string,
           height: int, width = 0, renderMode = frSmooth) =
  ## Defines a font to be loaded with the ``load`` iterator.
  data.spec.fonts[name] = FontConfig(
    path: filename,
    height: height, width: width,
    mode: renderMode
  )

iterator load*(data: var RData): tuple[kind: RResKind, id: string,
                                       progress: float] =
  ## An iterator for loading resources one by one.
  let
    progressPerImage = (1 / 2) / float(data.spec.images.len)
    progressPerFont = (1 / 2) / float(data.spec.fonts.len)
  var progress = 0.0
  for id, filename in data.spec.images:
    let png = loadPNG32(data.dir / filename)
    data.images[id] = RImage(
      width: png.width, height: png.height,
      data: png.data,
      textureConf: data.spec.textures[id]
    )
    progress += progressPerImage
    yield (resImage, id, progress)
  for id, conf in data.spec.fonts:
    let fnt = newRFont(conf.path, conf.height, conf.width, conf.mode)
    data.fonts[id] = fnt
    progress += progressPerFont
    yield (resFont, id, progress)


proc loadAll*(data: var RData) =
  ## Loads all resources in one go.
  for r in data.load(): discard

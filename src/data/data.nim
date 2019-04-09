#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import os
import tables

import nimPNG

import dsl
import ../lib/glad/gl
export dsl

type
  RImage* = ref object
    width*, height*: int
    data*: string
    textureConf*: RTextureConfig

  RTexture* = object
    id*: GLuint
  RTextureConfig* = tuple
    minFilter, magFilter: RTextureFilter
    wrap: RTextureWrap
  RTextureFilter* = enum
    fltNearest
    fltLinear
  RTextureWrap* = enum
    wrapRepeat
    wrapMirroredRepeat
    wrapClampToEdge
    wrapClampToBorder

  DataSpec = object
    images: Table[string, string]
    textures: Table[string, RTextureConfig]
  RData* = ref object
    # Loading
    dir*: string
    spec: DataSpec
    # Storage
    images*: TableRef[string, RImage]
    textures*: TableRef[string, RTexture]
  RResKind* = enum
    resImage

proc newRData*(): RData =
  new(result)
  result.dir = "data"
  result.spec = DataSpec(
    images: initTable[string, string](),
    textures: initTable[string, RTextureConfig]()
  )
  result.images = newTable[string, RImage]()
  result.textures = newTable[string, RTexture]()

proc image*(data: var RData, name, filename: string, texConf: RTextureConfig) =
  data.spec.images[name] = filename
  data.spec.textures[name] = texConf

iterator load*(data: var RData): tuple[kind: RResKind, id: string,
                                       progress: float] =
  let
    progressPerImage = (1 / 1) / float(data.spec.images.len)
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

proc loadAll*(data: var RData) =
  for r in data.load(): discard

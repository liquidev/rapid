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
    resSound

#--
# Textures
#--

proc GLenum*(flt: RTextureFilter): GLenum =
  case flt
  of fltNearest: GL_NEAREST
  of fltLinear:  GL_LINEAR

proc GLenum*(wrap: RTextureWrap): GLenum =
  case wrap
  of wrapRepeat:         GL_REPEAT
  of wrapMirroredRepeat: GL_MIRRORED_REPEAT
  of wrapClampToEdge:    GL_CLAMP_TO_EDGE
  of wrapClampToBorder:  GL_CLAMP_TO_BORDER

proc newRTexture*(width, height: int, data: pointer,
                  conf: RTextureConfig): RTexture =
  ## Creates a new, blank texture.
  result = RTexture()
  glGenTextures(1, addr result.id)
  glBindTexture(GL_TEXTURE_2D, result.id)
  glTexImage2D(GL_TEXTURE_2D,
    0,
    GLint GL_RGBA8, GLsizei width, GLsizei height,
    0,
    GL_RGBA, GL_UNSIGNED_BYTE,
    data)
  glTexParameteri(GL_TEXTURE_2D,
    GL_TEXTURE_MIN_FILTER, GLint GLenum(conf.minFilter))
  glTexParameteri(GL_TEXTURE_2D,
    GL_TEXTURE_MAG_FILTER, GLint GLenum(conf.magFilter))
  glTexParameteri(GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_S, GLint GLenum(conf.wrap))
  glTexParameteri(GL_TEXTURE_2D,
    GL_TEXTURE_WRAP_T, GLint GLenum(conf.wrap))

proc newRTexture*(img: RImage): RTexture =
  ## Creates a new texture from an image.
  result = newRTexture(
    img.width, img.height, img.data[0].unsafeAddr, img.textureConf)

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

iterator load*(data: var RData): tuple[kind: RResKind, id: string,
                                       progress: float] =
  ## An iterator for loading resources one by one.
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
  ## Loads all resources in one go.
  for r in data.load(): discard

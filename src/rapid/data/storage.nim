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

import ../lib/glad/gl
import ../lib/freetype

include dsl

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
  RPixelFormat* = enum
    pfRgb8
    pfRed8

  RFont* = ref object
    handle*: FT_Face
  RFontRenderMode* = enum
    frPixel
    frSmooth
    frLCD
    frLCDV
  FontConfig = object
    path: string
    height, width: int
    mode: RFontRenderMode

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
  glCreateTextures(GL_TEXTURE_2D, 1, addr result.id)
  glTextureStorage2D(result.id, 1, GL_RGBA8, width.GLsizei, height.GLsizei)
  glTextureSubImage2D(result.id, 0, 0, 0, width.GLsizei, height.GLsizei,
                      GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, data)
  glTextureParameteri(result.id,
    GL_TEXTURE_MIN_FILTER, GLint GLenum(conf.minFilter))
  glTextureParameteri(result.id,
    GL_TEXTURE_MAG_FILTER, GLint GLenum(conf.magFilter))
  glTextureParameteri(result.id,
    GL_TEXTURE_WRAP_S, GLint GLenum(conf.wrap))
  glTextureParameteri(result.id,
    GL_TEXTURE_WRAP_T, GLint GLenum(conf.wrap))

proc newRTexture*(img: RImage): RTexture =
  ## Creates a new texture from an image.
  result = newRTexture(
    img.width, img.height, img.data[0].unsafeAddr, img.textureConf)

#~~
# Fonts
#~~

type
  FreetypeError* = object of Exception

var freetypeLib*: FT_Library

proc newRFont*(file: string,
               height: int, width = 0, renderMode = frSmooth): RFont =
  once:
    let err = FT_Init_Freetype(addr freetypeLib).bool
    if err:
      raise newException(FreetypeError, "Could not initialize FreeType")
  let err = FT_New_Face(freetypeLib, file, 0, addr result.handle)
  if err == FT_Err_Unknown_File_Format:
    raise newException(FreetypeError, "Unknown font format (" & file & ")")
  elif err.bool:
    raise newException(FreetypeError, "Could not load font " & file & "")

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

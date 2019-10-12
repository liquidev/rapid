#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

import images
import ../gfx/opengl
import ../lib/glad/gl

type
  RTexture* = ref object
    id*: GLuint
    width*, height*: int
  RTextureConfig* = tuple
    minFilter, magFilter: RTextureFilter
    wrapH, wrapV: RTextureWrap
  RTextureFilter* = enum
    fltNearest
    fltLinear
  RTextureWrap* = enum
    wrapRepeat
    wrapMirroredRepeat
    wrapClampToEdge
    wrapClampToBorder
  RTexturePixelFormat* = enum
    fmtRGBA8
    fmtRed8

proc `$`*(tex: RTexture): string =
  result = "RTexture " & $tex.id & " " & $tex.width & "×" & $tex.height

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

proc internal*(fmt: RTexturePixelFormat): GLenum =
  case fmt
  of fmtRGBA8: GL_RGBA8
  of fmtRed8: GL_R8

proc color*(fmt: RTexturePixelFormat): GLenum =
  case fmt
  of fmtRGBA8: GL_RGBA
  of fmtRed8: GL_RED

proc pixelSize*(fmt: RTexturePixelFormat): int =
  case fmt
  of fmtRGBA8: 4
  of fmtRed8: 1

const
  DefaultTextureConfig* = (
    minFilter: fltLinear, magFilter: fltLinear,
    wrapH: wrapRepeat, wrapV: wrapRepeat
  ).RTextureConfig # for type safety

proc unload(tex: RTexture) =
  ## Unloads a texture. The texture cannot be used afterwards.
  glDeleteTextures(1, addr tex.id)

proc newRTexture*(width, height: int, data: pointer,
                  conf = DefaultTextureConfig, format = fmtRGBA8): RTexture =
  ## Creates a new texture from the specified data.
  new(result, unload)
  result.width = width
  result.height = height
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
  glGenTextures(1, addr result.id)
  currentGlc.withTex2D(result.id):
    glTexImage2D(GL_TEXTURE_2D, 0, format.internal.GLint,
                 width.GLsizei, height.GLsizei, 0,
                 format.color, GL_UNSIGNED_BYTE, data)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                    conf.minFilter.GLenum.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                    conf.magFilter.GLenum.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
                    conf.wrapH.GLenum.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
                    conf.wrapV.GLenum.GLint)

proc newRTexture*(width, height: int, conf = DefaultTextureConfig,
                  format = fmtRGBA8): RTexture =
  ## Creates a new texture. Unlike calling ``newRTexture`` with nil as the
  ## data pointer, this zeroes the texture out, making it perfect for use with
  ## any additional processing like texture packing.
  let zeroData = alloc0(width * height * format.pixelSize)
  result = newRTexture(width, height, zeroData, conf, format)
  dealloc(zeroData)

proc newRTexture*(image: RImage, conf = DefaultTextureConfig): RTexture =
  ## Creates a texture from an RImage.
  result = newRTexture(image.width, image.height, image.caddr, conf)

proc loadRTexture*(filename: string, conf = DefaultTextureConfig): RTexture =
  ## Loads an RGBA image from a PNG file and creates a texture from it.
  let img = loadRImage(filename)
  result = newRTexture(img, conf)

proc `minFilter=`*(tex: RTexture, flt: RTextureFilter) =
  ## Sets the minification filter of the texture.
  currentGlc.withTex2D(tex.id):
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, flt.GLenum.GLint)

proc `magFilter=`*(tex: RTexture, flt: RTextureFilter) =
  ## Sets the magnification filter of the texture.
  currentGlc.withTex2D(tex.id):
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, flt.GLenum.GLint)

proc `wrapH=`*(tex: RTexture, wrap: RTextureWrap) =
  ## Sets the horizontal wrapping of the texture.
  currentGlc.withTex2D(tex.id):
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap.GLenum.GLint)

proc `wrapV=`*(tex: RTexture, wrap: RTextureWrap) =
  ## Sets the vertical wrapping of the texture.
  currentGlc.withTex2D(tex.id):
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap.GLenum.GLint)

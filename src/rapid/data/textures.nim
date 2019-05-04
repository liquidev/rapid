#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import nimPNG

import ../gfx/opengl
import ../lib/glad/gl

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
  currentGlc.withTex2D(result.id):
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8.GLint,
                 width.GLsizei, height.GLsizei, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, data)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
                    conf.minFilter.GLenum.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,
                    conf.magFilter.GLenum.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,
                    conf.wrap.GLenum.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,
                    conf.wrap.GLenum.GLint)

proc newRTexture*(img: RImage): RTexture =
  ## Creates a new texture from an image.
  result = newRTexture(
    img.width, img.height, img.data[0].unsafeAddr, img.textureConf)

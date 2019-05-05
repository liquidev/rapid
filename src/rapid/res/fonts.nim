#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import tables
import unicode

import ../lib/freetype

import textures
import ../gfx/texpack

type
  RGlyph* = ref object
    rect*: RTextureRect
    width*, height*, bitmapLeft*, bitmapTop*, advanceX*: int
  RFont* = ref object
    handle*: FT_Face
    # TODO: optimize text rendering to use a single packed texture for all
    #       characters
    glyphs*: TableRef[Rune, RGlyph]
    texConf*: RTextureConfig
    packer*: RTexturePacker
  FreetypeError* = object of Exception

var freetypeLib*: FT_Library

proc newRFont*(file: string, textureConfig: RTextureConfig,
               height: Natural, width = 0.Natural,
               texWidth = 512.Natural, texHeight = texWidth): RFont =
  once:
    let err = FT_Init_Freetype(addr freetypeLib).bool
    doAssert not err, "Could not initialize FreeType"

  new(result)
  result.texConf = textureConfig
  result.glyphs = newTable[Rune, RGlyph]()
  result.packer = newRTexturePacker(texWidth, texHeight, textureConfig, fmtRed8)
  var err = FT_New_Face(freetypeLib, file, 0, addr result.handle)
  if err == FT_Err_Unknown_File_Format:
    raise newException(FreetypeError, "Unknown font format (" & file & ")")
  elif err.bool:
    raise newException(FreetypeError, "Could not load font " & file & "")
  err = FT_Set_Pixel_Sizes(result.handle, width.FT_uint, height.FT_uint)
  doAssert not err.bool, "Could not set font size"

proc renderGlyph(font: RFont, rune: Rune): RGlyph =
  var err = FT_Load_Char(font.handle, rune.FT_ulong, 0b100)
  doAssert not err.bool, "Could not render glyph '" & $rune & "'"

  let
    glyph = font.handle.glyph
    bitmap = glyph.bitmap
    rect = font.packer.place(bitmap.width.int, bitmap.rows.int, bitmap.buffer)
  result = RGlyph(
    rect: rect,
    width: bitmap.width.int, height: bitmap.rows.int,
    bitmapLeft: glyph.bitmapLeft, bitmapTop: glyph.bitmapTop,
    advanceX: glyph.advance.x
  )

proc render*(font: RFont, rune: Rune) =
  font.glyphs[rune] = font.renderGlyph(rune)

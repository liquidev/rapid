#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module implements font resource loading and rendering using the
## FreeType library.
## TTF and OTF formats are supported.

import tables
import unicode

import ../lib/freetype

import images
import textures
import ../gfx/texpack

type
  RGlyph* = ref object
    rect*: RTextureRect
    width*, height*, bitmapLeft*, bitmapTop*, advanceX*: int
  RTextHAlign* = enum
    taLeft
    taCenter
    taRight
  RTextVAlign* = enum
    taTop
    taBottom
    taMiddle
  RFont* = ref object
    handle*: FT_Face
    glyphs*: TableRef[Rune, RGlyph]
    texConf*: RTextureConfig
    packer*: RTexturePacker
    width*, height*: int
    lineSpacing, tabWidth: float
    halign: RTextHAlign
    valign: RTextVAlign
  FreetypeError* = object of Exception

var freetypeLib*: FT_Library

proc newRFont*(file: string, height: Natural, width = 0.Natural,
               textureConfig = DefaultTextureConfig,
               texWidth = 512.Natural, texHeight = 512.Natural): RFont =
  once:
    let err = FT_Init_Freetype(addr freetypeLib).bool
    doAssert not err, "Could not initialize FreeType"

  result = RFont(
    texConf: textureConfig,
    glyphs: newTable[Rune, RGlyph](),
    packer: newRTexturePacker(texWidth, texHeight, textureConfig, fmtRed8),
    width: if width == 0: height else: width,
    height: height,
    lineSpacing: 1.3,
    tabWidth: 96
  )
  var err = FT_New_Face(freetypeLib, file, 0, addr result.handle)
  if err == FT_Err_Unknown_File_Format:
    raise newException(FreetypeError, "Unknown font format (" & file & ")")
  elif err.bool:
    raise newException(FreetypeError, "Could not load font " & file & "")
  err = FT_Set_Pixel_Sizes(result.handle, width.FT_uint, height.FT_uint)
  doAssert not err.bool, "Could not set font size"

proc renderGlyph(font: RFont, rune: Rune): RGlyph =
  var err = FT_Load_Char(font.handle, rune.FT_ulong, 0b100 #[ FT_LOAD_RENDER ]#)
  doAssert not err.bool, "Could not render glyph '" & $rune & "'"

  let
    glyph = font.handle.glyph
    bitmap = glyph.bitmap
    image = newRImage(bitmap.width.int, bitmap.rows.int, bitmap.buffer, 1)
    rect = font.packer.place(image)

  result = RGlyph(
    rect: rect,
    width: bitmap.width.int, height: bitmap.rows.int,
    bitmapLeft: glyph.bitmapLeft, bitmapTop: glyph.bitmapTop,
    advanceX: glyph.advance.x
  )

proc render*(font: RFont, rune: Rune) =
  font.glyphs[rune] = font.renderGlyph(rune)

proc widthOf*(font: RFont, rune: Rune): float =
  if not font.glyphs.hasKey(rune):
    font.render(rune)
  let glyph = font.glyphs[rune]
  result = glyph.advanceX / 64

proc widthOf*(font: RFont, text: string): float =
  for r in runes(text):
    result += font.widthOf(r)

proc widthOf*(font: RFont, ch: char): float =
  result = font.widthOf(ch.Rune)

proc `lineSpacing=`*(font: RFont, spacing: float) =
  font.lineSpacing = spacing

proc lineSpacing*(font: RFont): float =
  result = font.lineSpacing

proc `tabWidth=`*(font: RFont, width: float) =
  font.tabWidth = width

proc tabWidth*(font: RFont): float =
  result = font.tabWidth

proc `horzAlign=`*(font: RFont, align: RTextHAlign) =
  font.halign = align

proc horzAlign*(font: RFont): RTextHAlign =
  result = font.halign

proc `vertAlign=`*(font: RFont, align: RTextVAlign) =
  font.valign = align

proc vertAlign*(font: RFont): RTextVAlign =
  result = font.valign

proc unload*(font: var RFont) =
  ## Unloads a font. The font cannot be used afterwards.
  let err = FT_Done_Face(font.handle)
  doAssert not err.bool, "Could not unload font face"
  font.packer.texture.unload()

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
  RGlyphId* = tuple
    rune: Rune
    width, height: int
  RFont* = ref object
    fHandle: FT_Face
    fGlyphs: TableRef[RGlyphId, RGlyph]
    fTexConf: RTextureConfig
    fPacker: RTexturePacker
    fWidth, fHeight: int
    fLineSpacing, fTabWidth: float
    fHAlign: RTextHAlign
    fVAlign: RTextVAlign
  FreetypeError* = object of Exception

var freetypeLib*: FT_Library

proc handle*(font: RFont): FT_Face = font.fHandle
proc packer*(font: RFont): RTexturePacker = font.fPacker

proc newRFont*(file: string, height: Natural, width = 0.Natural,
               textureConfig = DefaultTextureConfig,
               texWidth = 512.Natural, texHeight = 512.Natural): RFont =
  once:
    let err = FT_Init_Freetype(addr freetypeLib).bool
    doAssert not err, "Could not initialize FreeType"

  result = RFont(
    fTexConf: textureConfig,
    fGlyphs: newTable[RGlyphId, RGlyph](),
    fPacker: newRTexturePacker(texWidth, texHeight, textureConfig, fmtRed8),
    fWidth: width,
    fHeight: height,
    fLineSpacing: 1.3,
    fTabWidth: 96
  )
  var err = FT_New_Face(freetypeLib, file, 0, addr result.fHandle)
  if err == FT_Err_Unknown_File_Format:
    raise newException(FreetypeError, "Unknown font format (" & file & ")")
  elif err.bool:
    raise newException(FreetypeError, "Could not load font " & file & "")
  err = FT_Set_Pixel_Sizes(result.handle, width.FT_uint, height.FT_uint)
  doAssert not err.bool, "Could not set font size"

proc width*(font: RFont): int =
  if font.fWidth == 0: font.fHeight
  else: font.fWidth
proc `width=`*(font: RFont, width: int) =
  font.fWidth = width
  let err = FT_Set_Pixel_Sizes(font.handle,
                               font.fWidth.FT_uint, font.fHeight.FT_uint)
  doAssert not err.bool, "Could not set font size"

proc height*(font: RFont): int = font.fHeight
proc `height=`*(font: RFont, height: int) =
  font.fHeight = height
  let err = FT_Set_Pixel_Sizes(font.handle,
                               font.fWidth.FT_uint, font.fHeight.FT_uint)
  doAssert not err.bool, "Could not set font size"

proc renderGlyph(font: RFont, rune: Rune): RGlyph =
  var err = FT_Load_Char(font.handle, rune.FT_ulong, 0b100 #[ FT_LOAD_RENDER ]#)
  doAssert not err.bool, "Could not load or render glyph '" & $rune & "'"

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
  font.fGlyphs[(rune, font.width, font.height)] = font.renderGlyph(rune)

proc glyph*(font: RFont, rune: Rune): RGlyph =
  if not font.fGlyphs.hasKey((rune, font.width, font.height)):
    font.render(rune)
  result = font.fGlyphs[(rune, font.width, font.height)]

proc widthOf*(font: RFont, rune: Rune): float =
  let glyph = font.glyph(rune)
  result = glyph.advanceX / 64

proc widthOf*(font: RFont, text: string): float =
  for r in runes(text):
    result += font.widthOf(r)

proc widthOf*(font: RFont, ch: char): float =
  result = font.widthOf(ch.Rune)

proc lineSpacing*(font: RFont): float = font.fLineSpacing
proc `lineSpacing=`*(font: RFont, spacing: float) =
  font.fLineSpacing = spacing

proc tabWidth*(font: RFont): float = font.fTabWidth
proc `tabWidth=`*(font: RFont, width: float) =
  font.fTabWidth = width

proc horzAlign*(font: RFont): RTextHAlign = font.fHAlign
proc `horzAlign=`*(font: RFont, align: RTextHAlign) =
  font.fHAlign = align

proc vertAlign*(font: RFont): RTextVAlign = font.fVAlign
proc `vertAlign=`*(font: RFont, align: RTextVAlign) =
  font.fVAlign = align

proc unload*(font: var RFont) =
  ## Unloads a font. The font cannot be used afterwards.
  let err = FT_Done_Face(font.handle)
  doAssert not err.bool, "Could not unload font face"
  font.packer.texture.unload()

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module handles rendering of text through the FreeType library.
## See ``res/fonts`` for font loading and properties.

import math
import tables
import unicode

import ../gfx
import ../lib/freetype

import ../res/images
import ../res/textures
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
    taMiddle
    taBottom
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
  FreetypeError* = object of CatchableError

var freetypeLib*: FT_Library

proc handle*(font: RFont): FT_Face = font.fHandle
proc packer*(font: RFont): RTexturePacker = font.fPacker

proc loadRFont*(file: string, height: Natural, width = 0.Natural,
                textureConfig = DefaultTextureConfig,
                texWidth = 512.Natural, texHeight = 512.Natural): RFont =
  ## Create a new font loaded from the specified file, with the specified
  ## dimensions, texture configuration, and atlas size.
  ## The atlas size should be tweaked when lots of Unicode characters are used,
  ## but 512×512 is usually enough for most use cases.
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
  ## Get the width of the font.
  if font.fWidth == 0: font.fHeight
  else: font.fWidth
proc `width=`*(font: RFont, width: int) =
  ## Set the width of the font.
  font.fWidth = width
  let err = FT_Set_Pixel_Sizes(font.handle,
                               font.fWidth.FT_uint, font.fHeight.FT_uint)
  doAssert not err.bool, "Could not set font size"

proc height*(font: RFont): int =
  ## Get the height of the font.
  font.fHeight
proc `height=`*(font: RFont, height: int) =
  ## Set the height of the font.
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
  ## Render a single glyph and store it in an internal glyph table.
  font.fGlyphs[(rune, font.width, font.height)] = font.renderGlyph(rune)

proc glyph*(font: RFont, rune: Rune): RGlyph =
  ## Retrieve a glyph from the font. If the glyph hasn't already been rendered,
  ## this will render it for you.
  if not font.fGlyphs.hasKey((rune, font.width, font.height)):
    font.render(rune)
  result = font.fGlyphs[(rune, font.width, font.height)]

proc widthOf*(font: RFont, rune: Rune): float =
  ## Get the width of a Unicode character.
  let glyph = font.glyph(rune)
  result = glyph.advanceX / 64

proc widthOf*(font: RFont, text: string): float =
  ## Calculate the width of a string of text.
  for r in runes(text):
    result += font.widthOf(r)

proc widthOf*(font: RFont, text: seq[Rune]): float =
  ## Calculate the width of a Unicode string.
  for r in text:
    result += font.widthOf(r)

proc widthOf*(font: RFont, ch: char): float =
  ## Get the width of an ASCII character.
  result = font.widthOf(ch.Rune)

proc lineSpacing*(font: RFont): float =
  ## Get the line spacing.
  ## The line spacing of a font is used whenever ``'\n'`` is occured when
  ## rendering text. It's used for calculating how many pixels to descend when
  ## a line feed is found. The exact amount of pixels is calculated using this
  ## formula: ``font.height * font.lineSpacing``.
  font.fLineSpacing
proc `lineSpacing=`*(font: RFont, spacing: float) =
  ## Set the line spacing.
  font.fLineSpacing = spacing

proc tabWidth*(font: RFont): float =
  ## Get the tab width.
  ## Unlike usual text renderers, this is specified in pixels and not in the
  ## amount of space characters.
  font.fTabWidth
proc `tabWidth=`*(font: RFont, width: float) =
  ## Set the tab width.
  font.fTabWidth = width

proc unload*(font: var RFont) =
  ## Unloads a font. The font cannot be used afterwards.
  let err = FT_Done_Face(font.handle)
  doAssert not err.bool, "Could not unload font face"
  font.packer.unload()

proc drawChar(ctx: RGfxContext, font: RFont,
              x, y: float, penX, penY: var float, r: Rune) =
  case r
  of 0x09.Rune:
    var col = (penX / 64 - x) / font.tabWidth
    if col mod 1 <= 0.0001: col += 1
    penX = x * 64 + ceil(col) * font.tabWidth * 64
  of 0x0a.Rune:
    penX = x * 64
    penY += (font.height.float * font.lineSpacing) * 64
  of 0x0d.Rune:
    penX = x * 64
  else:
    let glyph = font.glyph(r)
    ctx.rect(round(penX / 64 + glyph.bitmapLeft.float),
             round(penY / 64 - glyph.bitmapTop.float),
             glyph.width.float, glyph.height.float, glyph.rect)
    penX += glyph.advanceX.float

proc penX[T](font: RFont, text: T, x, w: float, hAlign: RTextHAlign): float =
  result = floor(
    case hAlign
    of taLeft: x
    of taCenter: w / 2 + x - font.widthOf(text) / 2
    of taRight: w + x - font.widthOf(text)
  ) * 64

proc penY(font: RFont, y, h: float, vAlign: RTextVAlign): float =
  result = floor(
    case vAlign
    of taTop: y + font.height.float
    of taMiddle: h / 2 + y + font.height / 2
    of taBottom: h + y
  ) * 64

proc text*(ctx: RGfxContext, font: RFont, x, y: float, text: string,
           w, h = 0.0, hAlign = taLeft, vAlign = taTop) =
  ## Renders a string of text using the specified font, at the specified
  ## position. The text must be UTF-8 encoded.
  let previousTex = ctx.texture
  var
    penX = font.penX(text, x, w, hAlign)
    penY = font.penY(y, h, vAlign)
  ctx.uniform("rapid_renderText", 1)
  ctx.texture = font.packer.texture
  ctx.begin()
  for r in text.runes:
    ctx.drawChar(font, x, y, penX, penY, r)
  ctx.draw()
  ctx.uniform("rapid_renderText", 0)
  ctx.texture = previousTex

proc text*(ctx: RGfxContext, font: RFont, x, y: float, text: seq[Rune],
           w, h = 0.0, hAlign = taLeft, vAlign = taTop) =
  ## Renders a string of text using the specified font, at the specified
  ## position.
  let previousTex = ctx.texture
  var
    penX = font.penX(text, x, w, hAlign)
    penY = font.penY(y, h, vAlign)
  ctx.uniform("rapid_renderText", 1)
  ctx.texture = font.packer.texture
  ctx.begin()
  for r in text:
    ctx.drawChar(font, x, y, penX, penY, r)
  ctx.draw()
  ctx.uniform("rapid_renderText", 0)
  ctx.texture = previousTex

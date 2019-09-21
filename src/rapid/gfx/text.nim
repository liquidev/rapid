#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module handles font loading and rendering of text through the typography
## library. Keep in mind that this does not adhere to all rules imposed by the
## library's author, so slight rendering bugs may be present.

import math
import os
import tables
import unicode

import typography as tg
import vmath as v

import ../res/images
import ../res/textures
import ../gfx/texpack
import ../gfx
import ../mathutils

export HAlignMode, VAlignMode

type
  GlyphID = tuple
    utf8: string
    size, subpixel: float
  RGlyph = object
    tg: Glyph
    rect: RTextureRect
    offset: v.Vec2
    width, height: float
  Typeset = ref object
    glyphs: seq[GlyphPosition]
    width: float
  RFont* = ref object
    tg: Font
    packer: RTexturePacker
    glyphs: Table[GlyphID, RGlyph]
    typesetsR: Table[seq[Rune], Typeset]
    typesetsS: Table[string, Typeset]
    fTabWidth: float

proc name*(font: RFont): string = font.tg.name
proc height*(font: RFont): float = font.tg.sizePt
proc lineHeight*(font: RFont): float = font.tg.lineHeight
proc tabWidth*(font: RFont): float = font.fTabWidth
proc `height=`*(font: RFont, height: float) =
  font.tg.sizePt = height
proc `lineHeight=`*(font: RFont, height: float) =
  font.tg.lineHeight = height
proc `tabWidth=`*(font: RFont, tabWidth: float) =
  font.fTabWidth = tabWidth

proc loadRFont*(filename: string, size: float,
                textureConfig = DefaultTextureConfig,
                texWidth, texHeight = 2048): RFont =
  result = RFont()
  case filename.splitFile.ext
  of ".svg": result.tg = readFontSvg(filename)
  of ".ttf": result.tg = readFontTtf(filename)
  of ".otf": result.tg = readFontOtf(filename)
  result.height = size
  result.packer = newRTexturePacker(texWidth, texHeight,
                                    textureConfig, fmtRGBA8)
  result.tabWidth = 192

proc typeset(font: RFont, text: seq[Rune] | string,
             x, y, w, h: float,
             hAlign: HAlignMode, vAlign: VAlignMode): Typeset =
  when text is seq[Rune]:
    if text in font.typesetsR:
      return font.typesetsR[text]
  else:
    if text in font.typesetsS:
      return font.typesetsS[text]
  let glyphs = font.tg.typeset(text, v.vec2(x, y), v.vec2(w, h),
                               hAlign, vAlign, tabWidth = font.tabWidth)
  result = Typeset(glyphs: glyphs,
                   width: glyphs.textBounds.x)
  when text is seq[Rune]:
    font.typesetsR.add(text, result)
  else:
    font.typesetsS.add(text, result)

proc widthOf*(font: RFont, rune: Rune): float =
  result = font.tg.glyphs[$rune].advance

proc widthOf*(font: RFont, ch: char): float =
  result = font.widthOf(ch.Rune)

proc widthOf*(font: RFont, text: seq[Rune] | string): float =
  result = font.typeset(text, 0, 0, 0, 0, Left, Top).width

proc text*(ctx: RGfxContext, font: RFont, x, y: float, text: seq[Rune] | string,
           w, h = 0.0, hAlign = Left, vAlign = Top) =
  let
    ts = font.typeset(text, x, y, w, h, hAlign, vAlign)
    oldTex = ctx.texture
  ctx.begin()
  ctx.texture = font.packer.texture
  for pos in ts.glyphs:
    if pos.character in font.tg.glyphs:
      let shift = snap(pos.subpixelShift, 0.5, mode = smFloor)
      if (pos.character, font.height, shift) notin font.glyphs:
        echo (character: pos.character, height: font.height, shift: shift)
        var glyph = RGlyph()
        glyph.tg = font.tg.glyphs[pos.character]
        let
          img = font.tg.getGlyphImage(glyph.tg, glyph.offset,
                                      subpixelShift = shift)
          rimg = newRImage(img.width, img.height, img.data[0].unsafeAddr)
        glyph.width = rimg.width.float
        glyph.height = rimg.height.float
        glyph.rect = font.packer.place(rimg)
        font.glyphs.add((pos.character, font.height, shift), glyph)
      let glyph = font.glyphs[(pos.character, font.height, shift)]
      ctx.rect(pos.rect.x + glyph.offset.x, pos.rect.y + glyph.offset.y,
               glyph.width, glyph.height, glyph.rect)
  ctx.draw()
  ctx.texture = oldTex

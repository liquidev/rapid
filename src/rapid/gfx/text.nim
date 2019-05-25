#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import math
import tables
import unicode

import surface
import ../res/fonts

## This module handles rendering of text through the FreeType library.

proc text*(ctx: var RGfxContext, font: RFont, x, y: float, text: string) =
  ## Renders a string of text using the specified font, at the specified \
  ## position. The expected text must be UTF-8-encoded.
  let
    runes = text.toRunes()
    previousTex = ctx.texture
  var
    penX = floor(
      case font.horzAlign
      of taLeft: x
      of taCenter: x - font.widthOf(text) / 2
      of taRight: x - font.widthOf(text)
    ) * 64
    penY = floor(
      case font.vertAlign
      of taTop: y + font.height.float
      of taMiddle: y + font.height / 2
      of taBottom: y
    ) * 64
  ctx.uniform("rapid_renderText", 1)
  ctx.texture = font.packer.texture
  ctx.begin()
  for r in runes:
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
      if not font.glyphs.hasKey(r):
        font.render(r)
      let glyph = font.glyphs[r]
      ctx.rect(penX / 64 + glyph.bitmapLeft.float, penY / 64 - glyph.bitmapTop.float,
              glyph.width.float, glyph.height.float,
              glyph.rect)
      penX += glyph.advanceX.float
  ctx.draw()
  ctx.uniform("rapid_renderText", 0)
  ctx.texture = previousTex

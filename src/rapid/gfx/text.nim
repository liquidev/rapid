#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

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
    penX = x
    penY = y
  ctx.uniform("rapid_renderText", 1)
  ctx.texture = font.packer.texture
  ctx.begin()
  for r in runes:
    if not font.glyphs.hasKey(r):
      font.render(r)
    let glyph = font.glyphs[r]
    ctx.rect(penX + glyph.bitmapLeft.float, penY - glyph.bitmapTop.float,
             glyph.width.float, glyph.height.float,
             glyph.rect)
    penX += float(glyph.advanceX shr 6)
  ctx.draw()
  ctx.uniform("rapid_renderText", 0)
  ctx.texture = previousTex

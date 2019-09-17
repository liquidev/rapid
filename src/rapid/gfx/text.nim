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
import ../res/fonts

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

proc penX[T](font: RFont, x: float, text: T): float =
  result = floor(
    case font.horzAlign
    of taLeft: x
    of taCenter: x - font.widthOf(text) / 2
    of taRight: x - font.widthOf(text)
  ) * 64

proc penY(font: RFont, y: float): float =
  result = floor(
    case font.vertAlign
    of taTop: y + font.height.float
    of taMiddle: y + font.height / 2
    of taBottom: y
  ) * 64

proc text*(ctx: RGfxContext, font: RFont, x, y: float, text: string) =
  ## Renders a string of text using the specified font, at the specified
  ## position. The text must be UTF-8-encoded.
  let previousTex = ctx.texture
  var
    penX = font.penX(x, text)
    penY = font.penY(y)
  ctx.uniform("rapid_renderText", 1)
  ctx.texture = font.packer.texture
  ctx.begin()
  for r in text.runes:
    ctx.drawChar(font, x, y, penX, penY, r)
  ctx.draw()
  ctx.uniform("rapid_renderText", 0)
  ctx.texture = previousTex

proc text*(ctx: RGfxContext, font: RFont, x, y: float, text: seq[Rune]) =
  ## Renders a string of text using the specified font, at the specified
  ## position. The text must be UTF-8-encoded.
  let previousTex = ctx.texture
  var
    penX = font.penX(x, text)
    penY = font.penY(y)
  ctx.uniform("rapid_renderText", 1)
  ctx.texture = font.packer.texture
  ctx.begin()
  for r in text:
    ctx.drawChar(font, x, y, penX, penY, r)
  ctx.draw()
  ctx.uniform("rapid_renderText", 0)
  ctx.texture = previousTex

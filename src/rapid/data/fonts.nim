#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import tables
import unicode

import ../lib/freetype

import textures

type
  Glyph = ref object
    texture: RTexture
    bitmapLeft, bitmapTop, advanceX, advanceY: int
  RFont* = ref object
    handle*: FT_Face
    # TODO: optimize text rendering to use a single packed texture for all
    #       characters
    glyphs*: TableRef[Rune, Glyph]
    conf*: FontConfig
  FontConfig* = object
    texConf: RTextureConfig
  FreetypeError* = object of Exception

var freetypeLib*: FT_Library

proc newRFont*(file: string,
               height: Natural, width = 0.Natural,
               textureConfig: RTextureConfig): RFont =
  once:
    let err = FT_Init_Freetype(addr freetypeLib).bool
    doAssert not err, "Could not load FreeType"

  new(result)
  result.conf = FontConfig(
    texConf: textureConfig
  )
  var err = FT_New_Face(freetypeLib, file, 0, addr result.handle)
  if err == FT_Err_Unknown_File_Format:
    raise newException(FreetypeError, "Unknown font format (" & file & ")")
  elif err.bool:
    raise newException(FreetypeError, "Could not load font " & file & "")
  err = FT_Set_Pixel_Sizes(result.handle, width.FT_uint, height.FT_uint)
  doAssert not err.bool, "Could not set font size"

proc render(font: RFont, rune: Rune): Glyph =
  let glyphIdx = FT_Get_Char_Index(font.handle, rune.FT_ulong)
  var err = FT_Load_Char(font.handle, glyphIdx, FT_LOAD_DEFAULT)
  doAssert not err.bool, "Could not load glyph '" & $rune & "'"

  err = FT_Render_Glyph(font.handle.glyph, FT_RENDER_MODE_NORMAL)
  doAssert not err.bool, "Failed to render glyph '" & $rune & "'"

  let
    glyph = font.handle.glyph
    bitmap = glyph.bitmap
    buffer = cast[UncheckedArray[uint8]](bitmap.buffer)
  var glImg: seq[uint8]
  # TODO: waste of memory, replace this with a shader-based way of rendering
  for y in 0..<bitmap.rows:
    for x in 0..<bitmap.width:
      glImg.add([
        255'u8, 255, 255,
        buffer[x + y * bitmap.width]])
  let tex = newRTexture(bitmap.width.int, bitmap.rows.int,
                        glImg[0].unsafeAddr, font.conf.texConf)
  result = Glyph(
    texture: tex,
    bitmapLeft: glyph.bitmapLeft, bitmapTop: glyph.bitmapTop,
    advanceX: glyph.advance.x, advanceY: glyph.advance.y
  )

proc render*(font: RFont, glyph: string) =
  let rune = glyph.runeAt(0)
  font.glyphs[rune] = font.render(rune)

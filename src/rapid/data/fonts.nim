#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import ../lib/freetype

import textures

type
  RFont* = ref object
    handle*: FT_Face
  RFontRenderMode* = enum
    frPixel
    frSmooth
    frLCD
    frLCDV
  FontConfig* = object
    path: string
    height, width: int
    mode: RFontRenderMode
  FreetypeError* = object of Exception

var freetypeLib*: FT_Library

proc newRFont*(file: string,
                height: int, width = 0, renderMode = frSmooth): RFont =
  once:
    let err = FT_Init_Freetype(addr freetypeLib).bool
    if err:
      raise newException(FreetypeError, "Could not initialize FreeType")
  let err = FT_New_Face(freetypeLib, file, 0, addr result.handle)
  if err == FT_Err_Unknown_File_Format:
    raise newException(FreetypeError, "Unknown font format (" & file & ")")
  elif err.bool:
    raise newException(FreetypeError, "Could not load font " & file & "")

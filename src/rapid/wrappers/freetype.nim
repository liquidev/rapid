## Minimal, lightweight freetype wrapper.

import std/macros
import std/os

const
  Here = currentSourcePath.splitPath().head
  # using concatenation because of windows®®®®®®®® crosscompilation
  Freetype = Here & "/extern/freetype"
  Include = Freetype & "/include"
  Src = Freetype & "/src"
{.passC: "-I" & Include.}
{.passC: "-DFT2_BUILD_LIBRARY".}

macro genCompiles: untyped =
  const
    CompileList = [
      "autofit/autofit.c",
      "base/ftsystem.c",
      "base/ftinit.c",
      "base/ftdebug.c",
      "base/ftbase.c",
      "base/ftbbox.c",
      "base/ftglyph.c",
      "base/ftbdf.c",
      "base/ftbitmap.c",
      "bdf/bdf.c",
      "cff/cff.c",
      "pshinter/pshinter.c",
      "psnames/psnames.c",
      "sfnt/sfnt.c",
      "smooth/smooth.c",
      "truetype/truetype.c",
    ]
  var pragmas = newNimNode(nnkPragma)
  for file in CompileList:
    pragmas.add(newColonExpr(ident"compile", newLit(Src & "/" & file)))
  result = newStmtList(pragmas)
genCompiles

type
  FtPos* = clong
  FtFixed* = clong
  Ft26dot6* = clong
  FtVector* = object
    x*, y*: FtPos
  FtMatrix* = object
    xx*, xy*, yx*, yy*: FtFixed
  FtBbox* = object
    xMin*, yMin*, xMax*, yMax*: FtPos
  FtBitmap* = object
    rows*, width*: cuint
    pitch*: cint
    buffer*: ptr UncheckedArray[uint8]
    num_grays*: cushort
    pixel_mode*, palette_mode*: cuchar
    palette*: pointer
  FtBitmapSize* = object
    height*, width*: cshort
    size*, x_ppem*, y_ppem*: FtPos
  FtGenericFinalizer = proc (obj: pointer) {.cdecl.}
  FtGeneric* = object
    data*: pointer
    generic_finalizer*: FtGenericFinalizer

  FtLibrary* = pointer

  FtSizeMetrics* = object
    x_ppem*, y_ppem*: cushort
    x_scale*, y_scale*: FtFixed
    ascender*, descender*, height*, max_advance*: FtPos
  FtSize* = ptr object
    face*: FtFace
    generic*: FtGeneric
    metrics*: FtSizeMetrics
    internal*: pointer
  FtFace* = ptr object
    num_faces*, face_index*: clong
    face_flags*, style_flags*: clong
    num_glyphs*: clong
    family_name*, style_name*: cstring
    num_fixed_sizes*: cint
    available_sizes*: ptr FtBitmapSize
    num_charmaps: cint
    charmaps: pointer
    generic*: FtGeneric
    bbox*: FtBbox
    units_per_EM*: cushort
    ascender*, descender*, height*: cshort
    max_advance_width*, max_advance_height*: cshort
    underline_position*, underline_thickness*: cshort
    glyph*: FtGlyphSlot
    size*: FtSize
    # truncated; doesn't matter because we always deal with pointers to this

  FtGlyphMetrics* = object
    width*, height*: FtPos
    horiBearingX*, horiBearingY*, horiAdvance*: FtPos
    vertBearingX*, vertBearingY*, vertAdvance*: FtPos
  FtGlyphFormat* = distinct cuint
  FtGlyphSlot* = ptr object
    library*: FtLibrary
    face*: FtFace
    next*: FtGlyphSlot
    glyph_index*: cuint
    generic*: FtGeneric
    metrics*: FtGlyphMetrics
    linearHoriAdvance*, linearVertAdvance*: FtFixed
    advance*: FtVector
    format*: FtGlyphFormat
    bitmap*: FtBitmap
    bitmap_left*: cint
    bitmap_top*: cint
    # truncated; doesn't matter because we always deal with pointers to this

  FtError* {.size: 4.} = enum
    # this contains fteOk only mostly because error messages are retrieved via
    # FT_Error_String
    fteOk = 0x00

const
  ftFaceFlagScalable* = (1 shl 0)
  ftFaceFlagFixedSizes* = (1 shl 1)
  ftFaceFlagFixedWidth* = (1 shl 2)
  ftFaceFlagHorizontal* = (1 shl 4)
  ftFaceFlagVertical* = (1 shl 5)
  ftFaceFlagKerning* = (1 shl 6)
  ftLoadDefault* = 0x0
  ftLoadNoHinting* = (1 shl 1)
  ftLoadRender* = (1 shl 2)

{.push cdecl.}

proc initFreetype*(alibrary: var FtLibrary): FtError {.importc: "FT_Init_FreeType".}
proc destroy*(library: FtLibrary): FtError {.importc: "FT_Done_FreeType".}

proc newMemoryFace*(library: FtLibrary, file_base: pointer, file_size: clong, face_index: clong, aface: var FtFace): FtError {.importc: "FT_New_Memory_Face".}
proc destroy*(face: FtFace): FtError {.importc: "FT_Done_Face".}
proc setCharSize*(face: FtFace, char_width, char_height: Ft26dot6, horz_resolution, vert_resolution: cuint): FtError {.importc: "FT_Set_Char_Size".}
proc loadChar*(face: FtFace, char_code: culong, load_flags: int32): FtError {.importc: "FT_Load_Char".}
proc setTransform*(face: FtFace, matrix: ptr FtMatrix, delta: ptr FtVector) {.importc: "FT_Set_Transform".}
proc getKerning*(face: FtFace, left_glyph, right_glyph, kern_mode: cuint, akerning: var FtVector): FtError {.importc: "FT_Get_Kerning".}
proc getCharIndex*(face: FtFace, charcode: culong): cuint {.importc: "FT_Get_Char_Index".}

proc errorString(error: FtError): cstring {.importc: "FT_Error_String".}
proc `$`*(error: FtError): string = $error.errorString

{.pop.}

## Minimal, lightweight freetype wrapper.

import std/macros
import std/os

const
  Here = currentSourcePath.splitPath().head
  Freetype = Here/"extern"/"freetype"
  Include = Freetype/"include"
  Src = Freetype/"src"
{.passC: "-I" & Include.}
{.passC: "-DFT2_BUILD_LIBRARY".}

macro genCompiles: untyped =
  const
    CompileList = [
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
      "sfnt/sfnt.c",
      "truetype/truetype.c",
      "smooth/smooth.c",
      "autofit/autofit.c",
      "pshinter/pshinter.c",
      "psnames/psnames.c",
    ]
  var pragmas = newNimNode(nnkPragma)
  for file in CompileList:
    pragmas.add(newColonExpr(ident"compile", newLit(Src/file)))
  result = newStmtList(pragmas)
genCompiles

type
  FtError* = distinct cint
  FtPos* = clong
  FtFixed* = clong
  Ft26dot6* = clong
  FtVector* = object
    x, y: FtPos
  FtMatrix* = object
    xx, xy, yx, yy: FtFixed
  FtBitmap* = object
    rows, width: cuint
    pitch: cint
    buffer: ptr UncheckedArray[uint8]
    num_grays: cushort
    pixel_mode, palette_mode: cuchar
    palette: pointer
  FtBitmapSize* = object
    height, width: cshort
    size, x_ppem, y_ppem: FtPos
  FtGenericFinalizer = proc (obj: pointer) {.cdecl.}
  FtGeneric* = object
    data: pointer
    generic_finalizer: FtGenericFinalizer

  FtLibrary* = pointer
  FtFace* = ptr object
    num_faces, face_index: clong
    face_flags, style_flags: clong
    num_glyphs: clong
    family_name, style_name: cstring
    num_fixed_sizes: cint
    available_sizes: ptr FtBitmapSize
    # truncated; doesn't matter because we always deal with pointers to this

  FtGlyphMetrics* = object
    width, height: FtPos
    horiBearingX, horiBearingY, horiAdvance: FtPos
    vertBearingX, vertBearingY, vertAdvance: FtPos
  FtGlyphFormat* = distinct cuint
  FtGlyphSlot* = ptr object
    library: FtLibrary
    face: FtFace
    next: FtGlyphSlot
    glyph_index: cuint
    generic: FtGeneric
    metrics: FtGlyphMetrics
    linearHoriAdvance, linearVertAdvance: FtFixed
    advance: FtVector
    format: FtGlyphFormat
    bitmap: FtBitmap
    bitmap_left: cint
    bitmap_top: cint
    # truncated; doesn't matter because we always deal with pointers to this

const
  fteOk* = FtError(0x00)
  fteCannotOpenResource* = FtError(0x01)
  fteUnknownFileFormat* = FtError(0x02)
  fteInvalidFileFormat* = FtError(0x03)
  fteInvalidVersion* = FtError(0x04)
  fteLowerModuleVersion* = FtError(0x05)
  fteInvalidArgument* = FtError(0x06)
  fteUnimplementedFeature* = FtError(0x07)
  fteInvalidTable* = FtError(0x08)
  fteInvalidOffset* = FtError(0x09)
  fteArrayTooLarge* = FtError(0x0A)
  fteMissingModule* = FtError(0x0B)
  fteMissingProperty* = FtError(0x0C)
  fteInvalidGlyphIndex* = FtError(0x10)
  fteInvalidCharacterCode* = FtError(0x11)
  fteInvalidGlyphFormat* = FtError(0x12)
  fteCannotRenderGlyph* = FtError(0x13)
  fteInvalidOutline* = FtError(0x14)
  fteInvalidComposite* = FtError(0x15)
  fteTooManyHints* = FtError(0x16)
  fteInvalidPixelSize* = FtError(0x17)
  fteInvalidHandle* = FtError(0x20)
  fteInvalidLibraryHandle* = FtError(0x21)
  fteInvalidDriverHandle* = FtError(0x22)
  fteInvalidFaceHandle* = FtError(0x23)
  fteInvalidSizeHandle* = FtError(0x24)
  fteInvalidSlotHandle* = FtError(0x25)
  fteInvalidCharMapHandle* = FtError(0x26)
  fteInvalidCacheHandle* = FtError(0x27)
  fteInvalidStreamHandle* = FtError(0x28)
  fteTooManyDrivers* = FtError(0x30)
  fteTooManyExtensions* = FtError(0x31)
  fteOutOfMemory* = FtError(0x40)
  fteUnlistedObject* = FtError(0x41)
  fteCannotOpenStream* = FtError(0x51)
  fteInvalidStreamSeek* = FtError(0x52)
  fteInvalidStreamSkip* = FtError(0x53)
  fteInvalidStreamRead* = FtError(0x54)
  fteInvalidStreamOperation* = FtError(0x55)
  fteInvalidFrameOperation* = FtError(0x56)
  fteNestedFrameAccess* = FtError(0x57)
  fteInvalidFrameRead* = FtError(0x58)
  fteRasterUninitialized* = FtError(0x60)
  fteRasterCorrupted* = FtError(0x61)
  fteRasterOverflow* = FtError(0x62)
  fteRasterNegativeHeight* = FtError(0x63)
  fteTooManyCaches* = FtError(0x70)
  fteInvalidOpcode* = FtError(0x80)
  fteTooFewArguments* = FtError(0x81)
  fteStackOverflow* = FtError(0x82)
  fteCodeOverflow* = FtError(0x83)
  fteBadArgument* = FtError(0x84)
  fteDivideByZero* = FtError(0x85)
  fteInvalidReference* = FtError(0x86)
  fteDebugOpCode* = FtError(0x87)
  fteENDFInExecStream* = FtError(0x88)
  fteNestedDEFS* = FtError(0x89)
  fteInvalidCodeRange* = FtError(0x8A)
  fteExecutionTooLong* = FtError(0x8B)
  fteTooManyFunctionDefs* = FtError(0x8C)
  fteTooManyInstructionDefs* = FtError(0x8D)
  fteTableMissing* = FtError(0x8E)
  fteHorizHeaderMissing* = FtError(0x8F)
  fteLocationsMissing* = FtError(0x90)
  fteNameTableMissing* = FtError(0x91)
  fteCMapTableMissing* = FtError(0x92)
  fteHmtxTableMissing* = FtError(0x93)
  ftePostTableMissing* = FtError(0x94)
  fteInvalidHorizMetrics* = FtError(0x95)
  fteInvalidCharMapFormat* = FtError(0x96)
  fteInvalidPPem* = FtError(0x97)
  fteInvalidVertMetrics* = FtError(0x98)
  fteCouldNotFindContext* = FtError(0x99)
  fteInvalidPostTableFormat* = FtError(0x9A)
  fteInvalidPostTable* = FtError(0x9B)
  fteDEFInGlyfBytecode* = FtError(0x9C)
  fteMissingBitmap* = FtError(0x9D)
  fteSyntaxError* = FtError(0xA0)
  fteStackUnderflow* = FtError(0xA1)
  fteIgnore* = FtError(0xA2)
  fteNoUnicodeGlyphName* = FtError(0xA3)
  fteGlyphTooBig* = FtError(0xA4)
  fteMissingStartfontField* = FtError(0xB0)
  fteMissingFontField* = FtError(0xB1)
  fteMissingSizeField* = FtError(0xB2)
  fteMissingFontboundingboxField* = FtError(0xB3)
  fteMissingCharsField* = FtError(0xB4)
  fteMissingStartcharField* = FtError(0xB5)
  fteMissingEncodingField* = FtError(0xB6)
  fteMissingBbxField* = FtError(0xB7)
  fteBbxTooBig* = FtError(0xB8)
  fteCorruptedFontHeader* = FtError(0xB9)
  fteCorruptedFontGlyphs* = FtError(0xBA)

{.push cdecl.}

proc initFreetype*(alibrary: var FtLibrary): FtError {.importc: "FT_Init_FreeType".}
proc destroy*(library: FtLibrary): FtError {.importc: "FT_Done_FreeType".}

proc newMemoryFace*(library: FtLibrary, file_base: ptr byte, file_size: clong, face_index: clong, aface: var FtFace): FtError {.importc: "FT_New_Memory_Face".}
proc destroy*(face: FtFace): FtError {.importc: "FT_Done_Face".}
proc setCharSize*(face: FtFace, char_width, char_height: Ft26dot6, horz_resolution, vert_resolution: cuint): FtError {.importc: "FT_Set_Char_Size".}
proc loadChar*(face: FtFace, char_code: culong, load_flags: int32): FtError {.importc: "FT_Load_Char".}
proc setTransform*(face: FtFace, matrix: ptr FtMatrix, delta: ptr FtVector) {.importc: "FT_Set_Transform".}
proc getKerning*(face: FtFace, left_glyph, right_glyph, kern_mode: cuint, akerning: var FtVector): FtError {.importc: "FT_Get_Kerning".}

proc errorString(error: FtError): cstring {.importc: "FT_Error_String".}
proc `$`*(error: FtError): string = $error.errorString

{.pop.}

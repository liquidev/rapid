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
  FtSize* = object
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
    fteOk = 0x00
    fteCannotOpenResource = 0x01
    fteUnknownFileFormat = 0x02
    fteInvalidFileFormat = 0x03
    fteInvalidVersion = 0x04
    fteLowerModuleVersion = 0x05
    fteInvalidArgument = 0x06
    fteUnimplementedFeature = 0x07
    fteInvalidTable = 0x08
    fteInvalidOffset = 0x09
    fteArrayTooLarge = 0x0A
    fteMissingModule = 0x0B
    fteMissingProperty = 0x0C
    fteInvalidGlyphIndex = 0x10
    fteInvalidCharacterCode = 0x11
    fteInvalidGlyphFormat = 0x12
    fteCannotRenderGlyph = 0x13
    fteInvalidOutline = 0x14
    fteInvalidComposite = 0x15
    fteTooManyHints = 0x16
    fteInvalidPixelSize = 0x17
    fteInvalidHandle = 0x20
    fteInvalidLibraryHandle = 0x21
    fteInvalidDriverHandle = 0x22
    fteInvalidFaceHandle = 0x23
    fteInvalidSizeHandle = 0x24
    fteInvalidSlotHandle = 0x25
    fteInvalidCharMapHandle = 0x26
    fteInvalidCacheHandle = 0x27
    fteInvalidStreamHandle = 0x28
    fteTooManyDrivers = 0x30
    fteTooManyExtensions = 0x31
    fteOutOfMemory = 0x40
    fteUnlistedObject = 0x41
    fteCannotOpenStream = 0x51
    fteInvalidStreamSeek = 0x52
    fteInvalidStreamSkip = 0x53
    fteInvalidStreamRead = 0x54
    fteInvalidStreamOperation = 0x55
    fteInvalidFrameOperation = 0x56
    fteNestedFrameAccess = 0x57
    fteInvalidFrameRead = 0x58
    fteRasterUninitialized = 0x60
    fteRasterCorrupted = 0x61
    fteRasterOverflow = 0x62
    fteRasterNegativeHeight = 0x63
    fteTooManyCaches = 0x70
    fteInvalidOpcode = 0x80
    fteTooFewArguments = 0x81
    fteStackOverflow = 0x82
    fteCodeOverflow = 0x83
    fteBadArgument = 0x84
    fteDivideByZero = 0x85
    fteInvalidReference = 0x86
    fteDebugOpCode = 0x87
    fteENDFInExecStream = 0x88
    fteNestedDEFS = 0x89
    fteInvalidCodeRange = 0x8A
    fteExecutionTooLong = 0x8B
    fteTooManyFunctionDefs = 0x8C
    fteTooManyInstructionDefs = 0x8D
    fteTableMissing = 0x8E
    fteHorizHeaderMissing = 0x8F
    fteLocationsMissing = 0x90
    fteNameTableMissing = 0x91
    fteCMapTableMissing = 0x92
    fteHmtxTableMissing = 0x93
    ftePostTableMissing = 0x94
    fteInvalidHorizMetrics = 0x95
    fteInvalidCharMapFormat = 0x96
    fteInvalidPPem = 0x97
    fteInvalidVertMetrics = 0x98
    fteCouldNotFindContext = 0x99
    fteInvalidPostTableFormat = 0x9A
    fteInvalidPostTable = 0x9B
    fteDEFInGlyfBytecode = 0x9C
    fteMissingBitmap = 0x9D
    fteSyntaxError = 0xA0
    fteStackUnderflow = 0xA1
    fteIgnore = 0xA2
    fteNoUnicodeGlyphName = 0xA3
    fteGlyphTooBig = 0xA4
    fteMissingStartfontField = 0xB0
    fteMissingFontField = 0xB1
    fteMissingSizeField = 0xB2
    fteMissingFontboundingboxField = 0xB3
    fteMissingCharsField = 0xB4
    fteMissingStartcharField = 0xB5
    fteMissingEncodingField = 0xB6
    fteMissingBbxField = 0xB7
    fteBbxTooBig = 0xB8
    fteCorruptedFontHeader = 0xB9
    fteCorruptedFontGlyphs = 0xBA

const
  ftFaceFlagScalable* = (1 shl 0)
  ftFaceFlagFixedSizes* = (1 shl 1)
  ftFaceFlagFixedWidth* = (1 shl 2)
  ftFaceFlagSfnt* = (1 shl 3)
  ftFaceFlagHorizontal* = (1 shl 4)
  ftFaceFlagVertical* = (1 shl 5)
  ftFaceFlagKerning* = (1 shl 6)
  ftFaceFlagFastGlyphs* = (1 shl 7)
  ftFaceFlagMultipleMasters* = (1 shl 8)
  ftFaceFlagGlyphNames* = (1 shl 9)
  ftFaceFlagExternalStream* = (1 shl 10)
  ftFaceFlagHinter* = (1 shl 11)
  ftFaceFlagCidKeyed* = (1 shl 12)
  ftFaceFlagTricky* = (1 shl 13)
  ftFaceFlagColor* = (1 shl 14)
  ftFaceFlagVariation* = (1 shl 15)

{.push cdecl.}

proc initFreetype*(alibrary: var FtLibrary): FtError {.importc: "FT_Init_FreeType".}
proc destroy*(library: FtLibrary): FtError {.importc: "FT_Done_FreeType".}

proc newMemoryFace*(library: FtLibrary, file_base: pointer, file_size: clong, face_index: clong, aface: var FtFace): FtError {.importc: "FT_New_Memory_Face".}
proc destroy*(face: FtFace): FtError {.importc: "FT_Done_Face".}
proc setCharSize*(face: FtFace, char_width, char_height: Ft26dot6, horz_resolution, vert_resolution: cuint): FtError {.importc: "FT_Set_Char_Size".}
proc loadChar*(face: FtFace, char_code: culong, load_flags: int32): FtError {.importc: "FT_Load_Char".}
proc setTransform*(face: FtFace, matrix: ptr FtMatrix, delta: ptr FtVector) {.importc: "FT_Set_Transform".}
proc getKerning*(face: FtFace, left_glyph, right_glyph, kern_mode: cuint, akerning: var FtVector): FtError {.importc: "FT_Get_Kerning".}

proc errorString(error: FtError): cstring {.importc: "FT_Error_String".}
proc `$`*(error: FtError): string = $error.errorString

{.pop.}

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This is a wrapper for the FreeType library.

import os

import nimterop/[cimport, git]

const
  BaseDir = currentSourcePath().splitPath().head/"freetype_src"
  Incl = BaseDir/"include"
  Src = BaseDir/"src"

  FreetypeModules = """
FT_USE_MODULE( FT_Driver_ClassRec, tt_driver_class )
FT_USE_MODULE( FT_Driver_ClassRec, cff_driver_class )
FT_USE_MODULE( FT_Module_Class, psnames_module_class )
FT_USE_MODULE( FT_Module_Class, pshinter_module_class )
FT_USE_MODULE( FT_Renderer_Class, ft_raster1_renderer_class )
FT_USE_MODULE( FT_Module_Class, sfnt_module_class )
FT_USE_MODULE( FT_Renderer_Class, ft_smooth_renderer_class )
FT_USE_MODULE( FT_Renderer_Class, ft_smooth_lcd_renderer_class )
FT_USE_MODULE( FT_Renderer_Class, ft_smooth_lcdv_renderer_class )
"""

static:
  gitPull("https://git.savannah.nongnu.org/git/freetype/freetype2.git", BaseDir,
          "src/*\ninclude/*\n", "VER-2-10-0")
  gitReset(BaseDir)
  writeFile(Incl/"freetype/config/ftmodule.h", FreetypeModules)

type
  FT_RasterRec* = object
  FT_LibraryRec* = object
  FT_ModuleRec* = object
  FT_DriverRec* = object
  FT_RendererRec* = object
  FT_Face_InternalRec* = object
  FT_Size_InternalRec* = object
  FT_SubGlyphRec* = object
  FT_Slot_InternalRec* = object

  FT_GlyphFormat* = enum
    xero
  FT_Encoding* = enum
    xero2

cPlugin:
  import strutils

  proc onSymbol(sym: var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.strip(chars = {'_'})

cIncludeDir(Incl)

cDefine("FT2_BUILD_LIBRARY")

cImport("freetype_import.h", recurse = true)

cCompile(Src/"base/ftsystem.c")
cCompile(Src/"base/ftinit.c")
cCompile(Src/"base/ftdebug.c")
cCompile(Src/"base/ftbase.c")
cCompile(Src/"base/ftbitmap.c")
when defined(macosx):
  cCompile(Src/"base/ftmac.c")

cCompile(Src/"gzip/ftgzip.c")
cCompile(Src/"sfnt/sfnt.c")
cCompile(Src/"pshinter/pshinter.c")
cCompile(Src/"psnames/psnames.c")
cCompile(Src/"cff/cff.c")
cCompile(Src/"truetype/truetype.c")

cCompile(Src/"raster/raster.c")
cCompile(Src/"smooth/smooth.c")

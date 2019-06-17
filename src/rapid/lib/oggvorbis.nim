#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## libvorbis wrapper using nimterop.

import os

import nimterop/[git, cimport]

const
  ThisDir = currentSourcePath().splitPath().head
  OggDir = ThisDir/"ogg_src"
  OggSrc = OggDir/"src"
  OggIncl = OggDir/"include"
  VorbisDir = ThisDir/"vorbis_src"
  VorbisLib = VorbisDir/"lib"
  VorbisIncl = VorbisDir/"include"

static:
  gitPull("https://github.com/xiph/ogg", OggDir, "src/*\ninclude/*\n")
  gitPull("https://github.com/xiph/vorbis", VorbisDir, "lib/*\ninclude/*\n")
  writeFile(OggIncl/"ogg/config_types.h", """
    #ifndef __CONFIG_TYPES_H__
    #define __CONFIG_TYPES_H__

    #include <stdint.h>

    typedef int16_t ogg_int16_t;
    typedef uint16_t ogg_uint16_t;
    typedef int32_t ogg_int32_t;
    typedef uint32_t ogg_uint32_t;
    typedef int64_t ogg_int64_t;
    typedef uint64_t ogg_uint64_t;

    #endif
  """)

cIncludeDir(OggIncl)
cIncludeDir(VorbisIncl)

cOverride:
  type
    ogg_int64* = int64
    ogg_int64_t* = int64

cImport(OggIncl/"ogg/ogg.h")
cImport(VorbisIncl/"vorbis/codec.h")
cImport(VorbisIncl/"vorbis/vorbisfile.h")
cImport(VorbisIncl/"vorbis/vorbisenc.h")

cCompile(OggSrc/"bitwise.c")
cCompile(OggSrc/"framing.c")
cCompile(VorbisLib/"mdct.c")
cCompile(VorbisLib/"smallft.c")
cCompile(VorbisLib/"block.c")
cCompile(VorbisLib/"envelope.c")
cCompile(VorbisLib/"window.c")
cCompile(VorbisLib/"lsp.c")
cCompile(VorbisLib/"lpc.c")
cCompile(VorbisLib/"analysis.c")
cCompile(VorbisLib/"synthesis.c")
cCompile(VorbisLib/"psy.c")
cCompile(VorbisLib/"info.c")
cCompile(VorbisLib/"floor1.c")
cCompile(VorbisLib/"floor0.c")
cCompile(VorbisLib/"res0.c")
cCompile(VorbisLib/"mapping0.c")
cCompile(VorbisLib/"registry.c")
cCompile(VorbisLib/"codebook.c")
cCompile(VorbisLib/"sharedbook.c")
cCompile(VorbisLib/"lookup.c")
cCompile(VorbisLib/"bitrate.c")

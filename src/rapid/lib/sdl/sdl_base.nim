#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Base SDL2 wrapper using nimterop.
## This builds SDL and wraps SDL_stdinc.h which is used by all SDL headers.

import os

import nimterop/build
import nimterop/cimport
import nimterop/types

export splitPath, cImport

const
  Base = getProjectCacheDir("rapid_sdl2")

when defined(windows) or defined(RStaticSDL2):
  const HeaderPath = "include/SDL.h"
  setDefines(@[
    "SDLDL", "SDLSetVer=2.0.10", "SDLStatic"
  ])
else:
  const HeaderPath = "SDL2/SDL.h"
  setDefines(@[
    "SDLStd"
  ])

getHeader(HeaderPath,
          giturl = "https://github.com/SDL-mirror/SDL",
          dlurl = "http://libsdl.org/release/SDL2-$1.zip",
          outdir = Base,
          altNames = "SDL2")

cPlugin:
  import strutils

  const NoPrefixStripping = [
    "SDL_bool", "SDL_floor", "SDL_Quit"
  ]

  proc onSymbol*(sym: var Symbol) {.exportc, dynlib.} =
    sym.name = sym.name.replace("__", "_").strip(chars = {'_'})
    if sym.name notin NoPrefixStripping:
      sym.name.removePrefix("SDL_")
    if sym.name.startsWith("GL") and sym.kind == nskType:
      sym.name[0..1] = "gl"
    if sym.name.endsWith("Event") or sym.name.endsWith("Update"):
      sym.name.insert("X", 0)
    if sym.kind == nskProc and
       not (sym.name.startsWith("GL_") or sym.name.startsWith("SDL_")):
      sym.name[0] = sym.name[0].toLowerAscii

template sdlImport*(header: string) =
  const IncludePath = SDLPath.splitPath().head
  when defined(windows) or defined(RStaticSDL2):
    cImport(IncludePath/header, recurse = false)
  else:
    cImport(IncludePath/header, recurse = false, dynlib = "SDLLPath")

sdlImport("SDL_stdinc.h")

type
  SDLError* = object of CatchableError

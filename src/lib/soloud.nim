# Soloud wrapper
# from https://github.com/nimterop/nimterop/blob/master/tests/tsoloud.nim

import os, nimterop/[cimport, git, paths]

const
  baseDir = nimteropBuildDir()/"soloud"
  incl = baseDir/"include"
  src = baseDir/"src"

static:
  gitPull("https://github.com/jarikomppa/soloud", baseDir, "include/*\nsrc/*\n")
  cDisableCaching()

cIncludeDir(incl)

when defined(osx):
  cDefine("WITH_COREAUDIO")
  {.passL: "-framework CoreAudio -framework AudioToolbox".}
  cCompile(src/"backend/coreaudio/*.cpp")
elif defined(Linux):
  {.passL: "-lpthread".}
  cDefine("WITH_OSS")
  cCompile(src/"backend/oss/*.cpp")
elif defined(Windows):
  {.passC: "-msse".}
  {.passL: "-lwinmm".}
  cDefine("WITH_WINMM")
  cCompile(src/"backend/winmm/*.cpp")
else:
  static: doAssert false

cCompile(src/"c_api/soloud_c.cpp")
cCompile(src/"core/*.cpp")
cCompile(src/"audiosource", "cpp")
cCompile(src/"audiosource", "c")
cCompile(src/"filter/*.cpp")

cImport(incl/"soloud_c.h")

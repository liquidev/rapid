#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This is a miniaudio wrapper using nimterop.

import os
import strutils

import nimterop/[git, cimport]

const
  ThisDir = currentSourcePath().splitPath().head
  BaseDir = ThisDir/"soundio_src"
  Src = BaseDir/"src"
  Incl = BaseDir/"soundio"

static:
  gitPull("https://github.com/andrewrk/libsoundio", BaseDir,
          "src/*\nsoundio/*\n", checkout = "2.0.0")

cIncludeDir(BaseDir)
cIncludeDir(Incl)

# check availability of audio backends
when defined(windows):
  # only WASAPI is supported on Windows
  const
    WASAPIAvailable = true
    CoreAudioAvailable = false
    JACKAvailable = false
    PulseAudioAvailable = false
    ALSAAvailable = false
elif defined(macosx):
  # only CoreAudio is supported on OS X
  const
    WASAPIAvailable = false
    CoreAudioAvailable = true
    JACKAvailable = false
    PulseAudioAvailable = false
    ALSAAvailable = false
else:
  # determine which development headers are available
  const
    WASAPIAvailable = false
    CoreAudioAvailable = false
  # check for pkg-config, some installs may not have it
  when gorgeEx("pkg-config --version").exitCode != 0:
    {.error: "pkg-config is required to build rapid/lib/soundio".}
  else:
    const
      JACKAvailable =
        not defined(RNoJACK) and gorgeEx("pkg-config jack").exitCode == 0
      PulseAudioAvailable =
        not defined(RNoPulse) and gorgeEx("pkg-config libpulse").exitCode == 0
      ALSAAvailable =
        not defined(RNoALSA) and gorgeEx("pkg-config alsa").exitCode == 0
    static:
      echo "--- rapid/audio - linux config ---"
      echo "jack: ", JACKAvailable
      echo "pulse: ", PulseAudioAvailable
      echo "alsa: ", ALSAAvailable

# pass linker args
when defined(windows):
  {.passL: "-lole32".}
elif defined(macosx):
  # XXX: link CoreAudio, probably using '-framework CoreAudio'
  # I don't have a way of testing this, contributions welcome
  discard
else:
  when not ALSAAvailable:
    {.warning:
      "ALSA development headers not found. " &
      "This audio backend will be disabled".}
  when not PulseAudioAvailable:
    {.warning:
      "PulseAudio development headers not found. " &
      "This audio backend will be disabled".}
  when not JACKAvailable:
    {.warning:
      "JACK development headers not found. " &
      "This audio backend will be disabled".}
  {.passL: "-lpthread " &
    (if ALSAAvailable: "-lasound " else: "") &
    (if PulseAudioAvailable: "-lpulse " else: "") &
    (if JACKAvailable: "-ljack" else: "").}

static:
  var backends = ""
  when WASAPIAvailable: backends.add("#define SOUNDIO_HAVE_WASAPI\n")
  when CoreAudioAvailable: backends.add("#define SOUNDIO_HAVE_COREAUDIO\n")
  when JACKAvailable: backends.add("#define SOUNDIO_HAVE_JACK\n")
  when PulseAudioAvailable: backends.add("#define SOUNDIO_HAVE_PULSEAUDIO\n")
  when ALSAAvailable: backends.add("#define SOUNDIO_HAVE_ALSA\n")
  let configH = """
    /*
    * Copyright (c) 2015 Andrew Kelley
    *
    * This file is part of libsoundio, which is MIT licensed.
    * See http://opensource.org/licenses/MIT
    */

    #ifndef SOUNDIO_CONFIG_H
    #define SOUNDIO_CONFIG_H

    #define SOUNDIO_VERSION_MAJOR @LIBSOUNDIO_VERSION_MAJOR@
    #define SOUNDIO_VERSION_MINOR @LIBSOUNDIO_VERSION_MINOR@
    #define SOUNDIO_VERSION_PATCH @LIBSOUNDIO_VERSION_PATCH@
    #define SOUNDIO_VERSION_STRING "@LIBSOUNDIO_VERSION@"

    $backends

    #endif
  """
    # quite janky, but works
    # TODO: retrieve version from CMakeLists.txt?
    .replace("@LIBSOUNDIO_VERSION_MAJOR@", "2")
    .replace("@LIBSOUNDIO_VERSION_MINOR@", "0")
    .replace("@LIBSOUNDIO_VERSION_PATCH@", "0")
    .replace("@LIBSOUNDIO_VERSION@", "2.0.0")
    .replace("$backends", backends)
  writeFile(Src/"config.h", configH)
  when defined(RCompileDebug):
    echo configH

cOverride:
  type
    SoundioBool = bool

cPlugin:
  proc onSymbol(sym: var Symbol) {.exportc, dynlib.} =
    if sym.name == "_Bool": sym.name = "SoundioBool"

cImport(Incl/"soundio.h")

cDefine("SOUNDIO_STATIC_LIBRARY")

cCompile(Src/"soundio.c")
cCompile(Src/"util.c")
cCompile(Src/"os.c")
cCompile(Src/"dummy.c")
cCompile(Src/"channel_layout.c")
cCompile(Src/"ring_buffer.c")

when WASAPIAvailable: cCompile(Src/"wasapi.c")
when CoreAudioAvailable: cCompile(Src/"coreaudio.c")
when JACKAvailable: cCompile(Src/"jack.c")
when PulseAudioAvailable: cCompile(Src/"pulseaudio.c")
when ALSAAvailable: cCompile(Src/"alsa.c")

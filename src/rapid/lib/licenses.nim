#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This file contains licenses of all libraries used within rapid.
## You should include those licenses somewhere in your game. This module
## has them conveniently, statically pre-loaded.

const
  LicenseFreeType* = slurp("LICENSE_FreeType_FTL.txt")
  LicenseGLFW* = slurp("LICENSE_GLFW.md")
  LicenseSoundIo* = slurp("LICENSE_libsoundio")
  LicenseVorbis* = slurp("LICENSE_libvorbis")

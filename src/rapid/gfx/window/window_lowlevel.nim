#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Low-level window utilities.

import ../../lib/sdl/[sdl_error, sdl_video]

proc primaryDisplay*(): DisplayMode =
  doAssert getNumVideoDisplays() > 0, "No displays available"
  doAssert getDesktopDisplayMode(0, addr result) == 0, $getError()

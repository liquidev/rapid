#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## SDL_video.h wrapper.

import sdl_base
import sdl_rect

static:
  cSkipSymbol(@["getWindowSurface", "setWindowIcon"])

sdlImport("SDL_video.h")

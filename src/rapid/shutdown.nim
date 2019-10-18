#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## rapid shutdown handlers. This is just a wrapper to addQuitProc, to not
## fill it up in case many rapid modules are used.

var shutdownHandlers: seq[proc ()]

proc onShutdown*(callback: proc ()) =
  shutdownHandlers.add(callback)

addQuitProc do:
  for p in shutdownHandlers:
    p()

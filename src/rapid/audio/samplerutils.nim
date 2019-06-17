#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Utilities for creating samplers.

proc fill*[T](s: var seq[T], amt: int, val: T) =
  for n in 0..<amt:
    s.add(val)

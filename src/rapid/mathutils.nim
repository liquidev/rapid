#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Various math utilities.

import math

type
  SnapMode* = enum
    smFloor
    smRound
    smCeil

proc snap*[T: SomeFloat](x, snap: T, mode = smRound): T =
  ## Snaps ``x`` to a grid of size ``snap``.
  let inv = 1 / snap
  result =
    case mode
    of smFloor: floor(x * inv) / inv
    of smRound: round(x * inv) / inv
    of smCeil: ceil(x * inv) / inv

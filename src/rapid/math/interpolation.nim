#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

import math

type
  InterpFunc* = proc (t: float): float

func step*(step: float): InterpFunc =
  result = func (t: float): float =
    if t < step: 0.0
    else: 1.0

func linear*(t: float): float =
  if t < 0: 0.0
  elif t > 1: 1.0
  else: t

func hermite*(t: float): float =
  if t < 0: 0.0
  elif t > 1: 1.0
  else: t * t * (3 - 2 * t)

func interp*(a, b, t: float, fn: InterpFunc): float =
  let c = fn(t)
  c * b + (1 - c) * a

func interp*(vals: openarray[float], t: float, fn: InterpFunc): float =
  let
    t = clamp(t, 0, vals.len.float - 1)
    i0 = max(0, floor(t).int)
    i1 = min(vals.len - 1, ceil(t).int)
  interp(vals[i0], vals[i1], t mod 1, fn)

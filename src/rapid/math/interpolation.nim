#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module implements interpolation math, including step, linear, and cubic
## Hermite spline curves.

import math

type
  InterpFunc* = proc (t: float): float

func step*(step: float): InterpFunc =
  ## Creates a step function.
  result = func (t: float): float =
    if t < step: 0.0
    else: 1.0

func linear*(t: float): float =
  ## Linear interpolation, with clamping from 0.0 to 1.0.
  if t < 0: 0.0
  elif t > 1: 1.0
  else: t

func hermite*(t: float): float =
  ## Cubic Hermite spline, with clamping from 0.0 to 1.0.
  if t < 0: 0.0
  elif t > 1: 1.0
  else: t * t * (3 - 2 * t)

func interp*(a, b, t: float, fn: InterpFunc): float =
  ## Interpolate between the two values using the given interpolation function.
  let c = fn(t)
  c * b + (1 - c) * a

func interp*(vals: openarray[float], t: float, fn: InterpFunc): float =
  ## Interpolate between an array of values using the given interpolation
  ## function.
  let
    t = clamp(t, 0, vals.len.float - 1)
    i0 = max(0, floor(t).int)
    i1 = min(vals.len - 1, ceil(t).int)
  interp(vals[i0], vals[i1], t mod 1, fn)

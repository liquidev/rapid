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
  InterpFunc*[T] = proc (t: T): T

func step*[T](step: T): InterpFunc[T] =
  ## Creates a step function.
  result = func (t: T): T =
    if t < step: 0.0.T
    else: 1.0.T

func linear*[T](t: T): T =
  ## Linear interpolation, with clamping from 0.0 to 1.0.
  if t < 0.T: 0.0.T
  elif t > 1.T: 1.0.T
  else: t

func hermite*[T](t: T): T =
  ## Cubic Hermite spline, with clamping from 0.0 to 1.0.
  if t < 0.T: 0.0.T
  elif t > 1.T: 1.0.T
  else: t * t * (3.T - 2.T * t)

func interp*[T](a, b, t: T, fn: InterpFunc[T] = linear): T {.inline.} =
  ## Interpolate between the two values using the given interpolation function.
  let c = fn(t)
  c * b + (1.T - c) * a

func interp*(vals: openarray[float], t: float,
             fn: InterpFunc): float {.inline.} =
  ## Interpolate between an array of values using the given interpolation
  ## function.
  let
    t = clamp(t, 0, vals.len.float - 1)
    i0 = max(0, floor(t).int)
    i1 = min(vals.len - 1, ceil(t).int)
  interp(vals[i0], vals[i1], t mod 1, fn)

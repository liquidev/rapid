#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module implements interpolation math, including step, linear, and cubic
## Hermite spline curves.

import math


# basics

func lerp*[T](a, b: T, t: SomeFloat): T {.inline.} =
  ## Fast linear interpolation. This is faster than ``interp``.
  t * b + (1 - t) * a


# interpolators

type
  Interpolated*[T] = object
    prev, curr: T

{.push inline.}

converter interpolated*[T](value: T): Interpolated[T] =
  ## Converter from values to ``Interpolated[T]``.
  Interpolated[T](prev: value, curr: value)

converter value*[T](interp: Interpolated[T]): T =
  ## Converter from ``Interpolated[T]`` to values.
  interp.curr

converter mvalue*[T](interp: var Interpolated[T]): var T =
  ## "Dereference" operator for ``Interpolated[T]``
  interp.curr

func lerp*[T](interp: Interpolated[T], t: SomeFloat): T =
  ## Linearly interpolates between the previous and current value of the
  ## ``Interpolated[T]``.
  result = lerp(interp.prev, interp.curr, t)

proc tick*[T](interp: var Interpolated[T]) =
  ## Updates the given ``Interpolated[T]``'s previous value with the current
  ## value. This is usually called in ``update``.
  interp.prev = interp.curr

proc tickInterpolated*[T: tuple | object](rec: var T) =
  ## Ticks all ``Interpolated[T]`` in the given object.

  for value in fields(rec):
    when value is Interpolated:
      value.tick()

proc `<-`*[T](interp: var Interpolated[T], value: T) =
  ## Shortcut operator for assigning to ``mvalue(interp)``.
  interp.curr = value

proc `<-+`*[T](interp: var Interpolated[T], x: T) =
  ## Shortcut for ``mvalue(interp) += x``.
  interp.curr += x

proc `<--`*[T](interp: var Interpolated[T], x: T) =
  ## Shortcut for ``mvalue(interp) -= x``.
  interp.curr -= x

proc `<-*`*[T](interp: var Interpolated[T], x: T) =
  ## Shortcut for ``mvalue(interp) *= x``.
  interp.curr *= x

proc `<-/`*[T](interp: var Interpolated[T], x: T) =
  ## Shortcut for ``mvalue(interp) /= x``.
  interp.curr /= x

{.pop.}

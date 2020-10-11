##  Copyright (c) 2013 Scott Lembcke and Howling Moon Software
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in
##  all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##  SOFTWARE.
##

import std/math

import types

## / @defgroup cpVect cpVect
## / Chipmunk's 2D vector type along with a handy 2D vector math lib.
## / @{
## / Constant for the zero vector.

var cpvzero*: cpVect = cpVect(x: 0.0, y: 0.0)

## / Convenience constructor for cpVect structs.

proc cpv*(x: cpFloat; y: cpFloat): cpVect {.inline.} =
  var v: cpVect = cpVect(x: x, y: y)
  return v

## / Check if two vectors are equal. (Be careful when comparing floating point numbers!)

proc cpveql*(v1: cpVect; v2: cpVect): bool {.inline.} =
  return v1.x == v2.x and v1.y == v2.y

## / Add two vectors

proc cpvadd*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x + v2.x, v1.y + v2.y)

## / Subtract two vectors.

proc cpvsub*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x - v2.x, v1.y - v2.y)

## / Negate a vector.

proc cpvneg*(v: cpVect): cpVect {.inline.} =
  return cpv(-v.x, -v.y)

## / Scalar multiplication.

proc cpvmult*(v: cpVect; s: cpFloat): cpVect {.inline.} =
  return cpv(v.x * s, v.y * s)

## / Vector dot product.

proc cpvdot*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return v1.x * v2.x + v1.y * v2.y

## / 2D vector cross product analog.
## / The cross product of 2D vectors results in a 3D vector with only a z component.
## / This function returns the magnitude of the z value.

proc cpvcross*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return v1.x * v2.y - v1.y * v2.x

## / Returns a perpendicular vector. (90 degree rotation)

proc cpvperp*(v: cpVect): cpVect {.inline.} =
  return cpv(-v.y, v.x)

## / Returns a perpendicular vector. (-90 degree rotation)

proc cpvrperp*(v: cpVect): cpVect {.inline.} =
  return cpv(v.y, -v.x)

## / Returns the vector projection of v1 onto v2.

proc cpvproject*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpvmult(v2, cpvdot(v1, v2) / cpvdot(v2, v2))

## / Returns the unit length vector for the given angle (in radians).

proc cpvforangle*(a: cpFloat): cpVect {.inline.} =
  return cpv(cos(a), sin(a))

## / Returns the angular direction v is pointing in (in radians).

proc cpvtoangle*(v: cpVect): cpFloat {.inline.} =
  return arctan2(v.y, v.x)

## / Uses complex number multiplication to rotate v1 by v2. Scaling will occur if v1 is not a unit vector.

proc cpvrotate*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x * v2.x - v1.y * v2.y, v1.x * v2.y + v1.y * v2.x)

## / Inverse of cpvrotate().

proc cpvunrotate*(v1: cpVect; v2: cpVect): cpVect {.inline.} =
  return cpv(v1.x * v2.x + v1.y * v2.y, v1.y * v2.x - v1.x * v2.y)

## / Returns the squared length of v. Faster than cpvlength() when you only need to compare lengths.

proc cpvlengthsq*(v: cpVect): cpFloat {.inline.} =
  return cpvdot(v, v)

## / Returns the length of v.

proc cpvlength*(v: cpVect): cpFloat {.inline.} =
  return sqrt(cpvdot(v, v))

## / Linearly interpolate between v1 and v2.

proc cpvlerp*(v1: cpVect; v2: cpVect; t: cpFloat): cpVect {.inline.} =
  return cpvadd(cpvmult(v1, 1.0 - t), cpvmult(v2, t))

## / Returns a normalized copy of v.

proc cpvnormalize*(v: cpVect): cpVect {.inline.} =
  ##  Neat trick I saw somewhere to avoid div/0.
  return cpvmult(v, 1.0 / (cpvlength(v) + 0.000001))

## / Spherical linearly interpolate between v1 and v2.

proc cpvslerp*(v1: cpVect; v2: cpVect; t: cpFloat): cpVect {.inline.} =
  var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2))
  var omega: cpFloat = arccos(cpfclamp(dot, -1.0, 1.0))
  if omega < 0.001:
    ##  If the angle between two vectors is very small, lerp instead to avoid precision issues.
    return cpvlerp(v1, v2, t)
  else:
    var denom: cpFloat = 1.0 / sin(omega)
    return cpvadd(cpvmult(v1, sin((1.0 - t) * omega) * denom),
                 cpvmult(v2, sin(t * omega) * denom))

## / Spherical linearly interpolate between v1 towards v2 by no more than angle a radians

proc cpvslerpconst*(v1: cpVect; v2: cpVect; a: cpFloat): cpVect {.inline.} =
  var dot: cpFloat = cpvdot(cpvnormalize(v1), cpvnormalize(v2))
  var omega: cpFloat = arccos(cpfclamp(dot, -1.0, 1.0))
  return cpvslerp(v1, v2, cpfmin(a, omega) / omega)

## / Clamp v to length len.

proc cpvclamp*(v: cpVect; len: cpFloat): cpVect {.inline.} =
  return if (cpvdot(v, v) > len * len): cpvmult(cpvnormalize(v), len) else: v

## / Linearly interpolate between v1 towards v2 by distance d.

proc cpvlerpconst*(v1: cpVect; v2: cpVect; d: cpFloat): cpVect {.inline.} =
  return cpvadd(v1, cpvclamp(cpvsub(v2, v1), d))

## / Returns the distance between v1 and v2.

proc cpvdist*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return cpvlength(cpvsub(v1, v2))

## / Returns the squared distance between v1 and v2. Faster than cpvdist() when you only need to compare distances.

proc cpvdistsq*(v1: cpVect; v2: cpVect): cpFloat {.inline.} =
  return cpvlengthsq(cpvsub(v1, v2))

## / Returns true if the distance between v1 and v2 is less than dist.

proc cpvnear*(v1: cpVect; v2: cpVect; dist: cpFloat): bool {.inline.} =
  return cpvdistsq(v1, v2) < dist * dist

## / @}
## / @defgroup cpMat2x2 cpMat2x2
## / 2x2 matrix type used for tensors and such.
## / @{
##  NUKE

proc cpMat2x2New*(a: cpFloat; b: cpFloat; c: cpFloat; d: cpFloat): cpMat2x2 {.inline.} =
  var m: cpMat2x2 = cpMat2x2(a: a, b: b, c: c, d: d)
  return m

proc cpMat2x2Transform*(m: cpMat2x2; v: cpVect): cpVect {.inline.} =
  return cpv(v.x * m.a + v.y * m.b, v.x * m.c + v.y * m.d)

## /@}

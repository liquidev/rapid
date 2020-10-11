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

when defined(nimHasUsed):
  {.used.}

when sizeof(pointer) == 8:
  type
    uintptr_t* = culong
else:
  type
    uintptr_t* = cuint

const
  CP_USE_DOUBLES* = defined(rapidChipmunkUseFloat64)
## / @defgroup basicTypes Basic Types
## / Most of these types can be configured at compile time.
## / @{

when CP_USE_DOUBLES:
  ## / Chipmunk's floating point type.
  ## / Can be reconfigured at compile time.
  type
    cpFloat* = cdouble
else:
  type
    cpFloat* = cfloat

## / Return the max of two cpFloats.

proc cpfmax*(a: cpFloat; b: cpFloat): cpFloat {.inline.} =
  return if (a > b): a else: b

## / Return the min of two cpFloats.

proc cpfmin*(a: cpFloat; b: cpFloat): cpFloat {.inline.} =
  return if (a < b): a else: b

## / Return the absolute value of a cpFloat.

proc cpfabs*(f: cpFloat): cpFloat {.inline.} =
  return if (f < 0): -f else: f

## / Clamp @c f to be between @c min and @c max.

proc cpfclamp*(f: cpFloat; min: cpFloat; max: cpFloat): cpFloat {.inline.} =
  return cpfmin(cpfmax(f, min), max)

## / Clamp @c f to be between 0 and 1.

proc cpfclamp01*(f: cpFloat): cpFloat {.inline.} =
  return cpfmax(0.0, cpfmin(f, 1.0))

## / Linearly interpolate (or extrapolate) between @c f1 and @c f2 by @c t percent.

proc cpflerp*(f1: cpFloat; f2: cpFloat; t: cpFloat): cpFloat {.inline.} =
  return f1 * (1.0 - t) + f2 * t

## / Linearly interpolate from @c f1 to @c f2 by no more than @c d.

proc cpflerpconst*(f1: cpFloat; f2: cpFloat; d: cpFloat): cpFloat {.inline.} =
  return f1 + cpfclamp(f2 - f1, -d, d)

## / Hash value type.

type
  cpHashValue* = uintptr_t
## / Type used internally to cache colliding object info for cpCollideShapes().
## / Should be at least 32 bits.

type
  cpCollisionID* = uint32

##  Oh C, how we love to define our own boolean types to get compiler compatibility
## / Chipmunk's boolean type.

type
  cpBool* = cuchar
## / Type used for user data pointers.
type
  cpDataPointer* = pointer
## / Type used for cpSpace.collision_type.
type
  cpCollisionType* = uint16
## / Type used for cpShape.group.
type
  cpGroup* = uintptr_t
## / Type used for cpShapeFilter category and mask.
type
  cpBitmask* = uint64
## / Type used for various timestamps in Chipmunk.
type
  cpTimestamp* = cuint

{.pragma: cpstruct, importc, header: "<chipmunk/chipmunk.h>".}

## / Chipmunk's 2D vector type.
## / @addtogroup cpVect
type
  cpVect* {.cpstruct.} = object
    x*: cpFloat
    y*: cpFloat

## / Column major affine transform.
type
  cpTransform* {.cpstruct.} = object
    a*: cpFloat
    b*: cpFloat
    c*: cpFloat
    d*: cpFloat
    tx*: cpFloat
    ty*: cpFloat

##  NUKE

type
  cpMat2x2* {.cpstruct.} = object
    a*: cpFloat                ##  Row major [[a, b][c d]]
    b*: cpFloat
    c*: cpFloat
    d*: cpFloat

{.pragma: cpistruct, importc, incompleteStruct, header: "<chipmunk/chipmunk.h>".}

type
  cpShape* {.cpistruct.} = object
  cpCircleShape* {.cpistruct.} = object
  cpSegmentShape* {.cpistruct.} = object
  cpPolyShape* {.cpistruct.} = object
  cpArbiter* {.cpistruct.} = object
  cpSpace* {.cpistruct.} = object
  cpBody* {.cpistruct.} = object
  cpConstraint* {.cpistruct.} = object
  cpPinJoint* {.cpistruct.} = object
  cpSlideJoint* {.cpistruct.} = object
  cpPivotJoint* {.cpistruct.} = object
  cpGrooveJoint* {.cpistruct.} = object
  cpDampedSpring* {.cpistruct.} = object
  cpDampedRotarySpring* {.cpistruct.} = object
  cpRotaryLimitJoint* {.cpistruct.} = object
  cpRatchetJoint* {.cpistruct.} = object
  cpGearJoint* {.cpistruct.} = object
  cpSimpleMotorJoint* {.cpistruct.} = object

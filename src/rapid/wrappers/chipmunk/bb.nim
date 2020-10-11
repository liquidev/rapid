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
import vect

## / @defgroup cpBBB cpBB
## / Chipmunk's axis-aligned 2D bounding box type along with a few handy routines.
## / @{
## / Chipmunk's axis-aligned 2D bounding box type. (left, bottom, right, top)

type
  cpBB* {.bycopy.} = object
    l*: cpFloat
    b*: cpFloat
    r*: cpFloat
    t*: cpFloat


## / Convenience constructor for cpBB structs.

proc cpBBNew*(l: cpFloat; b: cpFloat; r: cpFloat; t: cpFloat): cpBB {.inline.} =
  var bb: cpBB = cpBB(l: l, b: b, r: r, t: t)
  return bb

## / Constructs a cpBB centered on a point with the given extents (half sizes).

proc cpBBNewForExtents*(c: cpVect; hw: cpFloat; hh: cpFloat): cpBB {.inline.} =
  return cpBBNew(c.x - hw, c.y - hh, c.x + hw, c.y + hh)

## / Constructs a cpBB for a circle with the given position and radius.

proc cpBBNewForCircle*(p: cpVect; r: cpFloat): cpBB {.inline.} =
  return cpBBNewForExtents(p, r, r)

## / Returns true if @c a and @c b intersect.

proc cpBBIntersects*(a: cpBB; b: cpBB): bool {.inline.} =
  return a.l <= b.r and b.l <= a.r and a.b <= b.t and b.b <= a.t

## / Returns true if @c other lies completely within @c bb.

proc cpBBContainsBB*(bb: cpBB; other: cpBB): bool {.inline.} =
  return bb.l <= other.l and bb.r >= other.r and bb.b <= other.b and bb.t >= other.t

## / Returns true if @c bb contains @c v.

proc cpBBContainsVect*(bb: cpBB; v: cpVect): bool {.inline.} =
  return bb.l <= v.x and bb.r >= v.x and bb.b <= v.y and bb.t >= v.y

## / Returns a bounding box that holds both bounding boxes.

proc cpBBMerge*(a: cpBB; b: cpBB): cpBB {.inline.} =
  return cpBBNew(cpfmin(a.l, b.l), cpfmin(a.b, b.b), cpfmax(a.r, b.r), cpfmax(a.t, b.t))

## / Returns a bounding box that holds both @c bb and @c v.

proc cpBBExpand*(bb: cpBB; v: cpVect): cpBB {.inline.} =
  return cpBBNew(cpfmin(bb.l, v.x), cpfmin(bb.b, v.y), cpfmax(bb.r, v.x),
                cpfmax(bb.t, v.y))

## / Returns the center of a bounding box.

proc cpBBCenter*(bb: cpBB): cpVect {.inline.} =
  return cpvlerp(cpv(bb.l, bb.b), cpv(bb.r, bb.t), 0.5)

## / Returns the area of the bounding box.

proc cpBBArea*(bb: cpBB): cpFloat {.inline.} =
  return (bb.r - bb.l) * (bb.t - bb.b)

## / Merges @c a and @c b and returns the area of the merged bounding box.

proc cpBBMergedArea*(a: cpBB; b: cpBB): cpFloat {.inline.} =
  return (cpfmax(a.r, b.r) - cpfmin(a.l, b.l)) *
      (cpfmax(a.t, b.t) - cpfmin(a.b, b.b))

## / Returns the fraction along the segment query the cpBB is hit. Returns INFINITY if it doesn't hit.

proc cpBBSegmentQuery*(bb: cpBB; a: cpVect; b: cpVect): cpFloat {.inline.} =
  var delta: cpVect = cpvsub(b, a)
  var
    tmin: cpFloat = -Inf
    tmax: cpFloat = Inf
  if delta.x == 0.0:
    if a.x < bb.l or bb.r < a.x:
      return Inf
  else:
    var t1: cpFloat = (bb.l - a.x) / delta.x
    var t2: cpFloat = (bb.r - a.x) / delta.x
    tmin = cpfmax(tmin, cpfmin(t1, t2))
    tmax = cpfmin(tmax, cpfmax(t1, t2))
  if delta.y == 0.0:
    if a.y < bb.b or bb.t < a.y:
      return Inf
  else:
    var t1: cpFloat = (bb.b - a.y) / delta.y
    var t2: cpFloat = (bb.t - a.y) / delta.y
    tmin = cpfmax(tmin, cpfmin(t1, t2))
    tmax = cpfmin(tmax, cpfmax(t1, t2))
  if tmin <= tmax and 0.0 <= tmax and tmin <= 1.0:
    return cpfmax(tmin, 0.0)
  else:
    return Inf

## / Return true if the bounding box intersects the line segment with ends @c a and @c b.

proc cpBBIntersectsSegment*(bb: cpBB; a: cpVect; b: cpVect): bool {.inline.} =
  return cpBBSegmentQuery(bb, a, b) != Inf

## / Clamp a vector to a bounding box.

proc cpBBClampVect*(bb: cpBB; v: cpVect): cpVect {.inline.} =
  return cpv(cpfclamp(v.x, bb.l, bb.r), cpfclamp(v.y, bb.b, bb.t))

## / Wrap a vector to a bounding box.

proc cpBBWrapVect*(bb: cpBB; v: cpVect): cpVect {.inline.} =
  var dx: cpFloat = cpfabs(bb.r - bb.l)
  var modx: cpFloat = floorMod(v.x - bb.l, dx)
  var x: cpFloat = if (modx > 0.0): modx else: modx + dx
  var dy: cpFloat = cpfabs(bb.t - bb.b)
  var mody: cpFloat = floorMod(v.y - bb.b, dy)
  var y: cpFloat = if (mody > 0.0): mody else: mody + dy
  return cpv(x + bb.l, y + bb.b)

## / Returns a bounding box offseted by @c v.

proc cpBBOffset*(bb: cpBB; v: cpVect): cpBB {.inline.} =
  return cpBBNew(bb.l + v.x, bb.b + v.y, bb.r + v.x, bb.t + v.y)

## /@}

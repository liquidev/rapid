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

include compile_chipmunk

proc cpMessage*(condition: cstring; file: cstring; line: cint; isError: cint;
               isHardError: cint; message: cstring) {.varargs, importc: "cpMessage",
    header: "<chipmunk/chipmunk.h>".}

import types, vect, bb
export types, vect, bb

include transform
include spatial_index
include arbiter
include body
include shape
include poly_shape
include constraint
include space

##  Chipmunk 7.0.3

const
  CP_VERSION_MAJOR* = 7
  CP_VERSION_MINOR* = 0
  CP_VERSION_RELEASE* = 3

## / Version string.

var cpVersionString* {.importc: "cpVersionString", header: "<chipmunk/chipmunk.h>".}: cstring

## / Calculate the moment of inertia for a circle.
## / @c r1 and @c r2 are the inner and outer diameters. A solid circle has an inner diameter of 0.

proc cpMomentForCircle*(m: cpFloat; r1: cpFloat; r2: cpFloat; offset: cpVect): cpFloat {.
    importc: "cpMomentForCircle", header: "<chipmunk/chipmunk.h>".}
## / Calculate area of a hollow circle.
## / @c r1 and @c r2 are the inner and outer diameters. A solid circle has an inner diameter of 0.

proc cpAreaForCircle*(r1: cpFloat; r2: cpFloat): cpFloat {.importc: "cpAreaForCircle",
    header: "<chipmunk/chipmunk.h>".}
## / Calculate the moment of inertia for a line segment.
## / Beveling radius is not supported.

proc cpMomentForSegment*(m: cpFloat; a: cpVect; b: cpVect; radius: cpFloat): cpFloat {.
    importc: "cpMomentForSegment", header: "<chipmunk/chipmunk.h>".}
## / Calculate the area of a fattened (capsule shaped) line segment.

proc cpAreaForSegment*(a: cpVect; b: cpVect; radius: cpFloat): cpFloat {.
    importc: "cpAreaForSegment", header: "<chipmunk/chipmunk.h>".}
## / Calculate the moment of inertia for a solid polygon shape assuming it's center of gravity is at it's centroid. The offset is added to each vertex.

proc cpMomentForPoly*(m: cpFloat; count: cint; verts: ptr cpVect; offset: cpVect;
                     radius: cpFloat): cpFloat {.importc: "cpMomentForPoly",
    header: "<chipmunk/chipmunk.h>".}
## / Calculate the signed area of a polygon. A Clockwise winding gives positive area.
## / This is probably backwards from what you expect, but matches Chipmunk's the winding for poly shapes.

proc cpAreaForPoly*(count: cint; verts: ptr cpVect; radius: cpFloat): cpFloat {.
    importc: "cpAreaForPoly", header: "<chipmunk/chipmunk.h>".}
## / Calculate the natural centroid of a polygon.

proc cpCentroidForPoly*(count: cint; verts: ptr cpVect): cpVect {.
    importc: "cpCentroidForPoly", header: "<chipmunk/chipmunk.h>".}
## / Calculate the moment of inertia for a solid box.

proc cpMomentForBox*(m: cpFloat; width: cpFloat; height: cpFloat): cpFloat {.
    importc: "cpMomentForBox", header: "<chipmunk/chipmunk.h>".}
## / Calculate the moment of inertia for a solid box.

proc cpMomentForBox2*(m: cpFloat; box: cpBB): cpFloat {.importc: "cpMomentForBox2",
    header: "<chipmunk/chipmunk.h>".}

proc cpConvexHull*(count: cint; verts: ptr cpVect; result: ptr cpVect; first: ptr cint;
                  tol: cpFloat): cint {.importc: "cpConvexHull", header: "<chipmunk/chipmunk.h>".}

proc cpClosetPointOnSegment*(p: cpVect; a: cpVect; b: cpVect): cpVect {.inline.} =
  var delta: cpVect
  var t: cpFloat
  return cpvadd(b, cpvmult(delta, t))

## @}

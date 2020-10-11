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
## / @defgroup cpPolyShape cpPolyShape
## / @{
## / Allocate a polygon shape.

import bb, types

proc cpPolyShapeAlloc*(): ptr cpPolyShape {.importc: "cpPolyShapeAlloc",
                                        header: "<chipmunk/chipmunk.h>".}
## / Initialize a polygon shape with rounded corners.
## / A convex hull will be created from the vertexes.

proc cpPolyShapeInit*(poly: ptr cpPolyShape; body: ptr cpBody; count: cint;
                     verts: ptr cpVect; transform: cpTransform; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpPolyShapeInit", header: "<chipmunk/chipmunk.h>".}
## / Initialize a polygon shape with rounded corners.
## / The vertexes must be convex with a counter-clockwise winding.

proc cpPolyShapeInitRaw*(poly: ptr cpPolyShape; body: ptr cpBody; count: cint;
                        verts: ptr cpVect; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpPolyShapeInitRaw", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a polygon shape with rounded corners.
## / A convex hull will be created from the vertexes.

proc cpPolyShapeNew*(body: ptr cpBody; count: cint; verts: ptr cpVect;
                    transform: cpTransform; radius: cpFloat): ptr cpShape {.
    importc: "cpPolyShapeNew", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a polygon shape with rounded corners.
## / The vertexes must be convex with a counter-clockwise winding.

proc cpPolyShapeNewRaw*(body: ptr cpBody; count: cint; verts: ptr cpVect; radius: cpFloat): ptr cpShape {.
    importc: "cpPolyShapeNewRaw", header: "<chipmunk/chipmunk.h>".}
## / Initialize a box shaped polygon shape with rounded corners.

proc cpBoxShapeInit*(poly: ptr cpPolyShape; body: ptr cpBody; width: cpFloat;
                    height: cpFloat; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpBoxShapeInit", header: "<chipmunk/chipmunk.h>".}
## / Initialize an offset box shaped polygon shape with rounded corners.

proc cpBoxShapeInit2*(poly: ptr cpPolyShape; body: ptr cpBody; box: cpBB; radius: cpFloat): ptr cpPolyShape {.
    importc: "cpBoxShapeInit2", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a box shaped polygon shape.

proc cpBoxShapeNew*(body: ptr cpBody; width: cpFloat; height: cpFloat; radius: cpFloat): ptr cpShape {.
    importc: "cpBoxShapeNew", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize an offset box shaped polygon shape.

proc cpBoxShapeNew2*(body: ptr cpBody; box: cpBB; radius: cpFloat): ptr cpShape {.
    importc: "cpBoxShapeNew2", header: "<chipmunk/chipmunk.h>".}
## / Get the number of verts in a polygon shape.

proc cpPolyShapeGetCount*(shape: ptr cpShape): cint {.importc: "cpPolyShapeGetCount",
    header: "<chipmunk/chipmunk.h>".}
## / Get the @c ith vertex of a polygon shape.

proc cpPolyShapeGetVert*(shape: ptr cpShape; index: cint): cpVect {.
    importc: "cpPolyShapeGetVert", header: "<chipmunk/chipmunk.h>".}
## / Get the radius of a polygon shape.

proc cpPolyShapeGetRadius*(shape: ptr cpShape): cpFloat {.
    importc: "cpPolyShapeGetRadius", header: "<chipmunk/chipmunk.h>".}
## / @}

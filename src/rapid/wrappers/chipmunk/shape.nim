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
## / @defgroup cpShape cpShape
## / The cpShape struct defines the shape of a rigid body.
## / @{
## / Point query info struct.

import bb, types

type
  cpPointQueryInfo* {.importc: "cpPointQueryInfo", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    shape* {.importc: "shape".}: ptr cpShape ## / The nearest shape, NULL if no shape was within range.
    ## / The closest point on the shape's surface. (in world space coordinates)
    point* {.importc: "point".}: cpVect ## / The distance to the point. The distance is negative if the point is inside the shape.
    distance* {.importc: "distance".}: cpFloat ## / The gradient of the signed distance function.
                                           ## / The value should be similar to info.p/info.d, but accurate even for very small values of info.d.
    gradient* {.importc: "gradient".}: cpVect


## / Segment query info struct.

type
  cpSegmentQueryInfo* {.importc: "cpSegmentQueryInfo", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    shape* {.importc: "shape".}: ptr cpShape ## / The shape that was hit, or NULL if no collision occured.
    ## / The point of impact.
    point* {.importc: "point".}: cpVect ## / The normal of the surface hit.
    normal* {.importc: "normal".}: cpVect ## / The normalized distance along the query segment in the range [0, 1].
    alpha* {.importc: "alpha".}: cpFloat


## / Fast collision filtering type that is used to determine if two objects collide before calling collision or query callbacks.

type
  cpShapeFilter* {.importc: "cpShapeFilter", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    group* {.importc: "group".}: cpGroup ## / Two objects with the same non-zero group value do not collide.
                                     ## / This is generally used to group objects in a composite object together to disable self collisions.
    ## / A bitmask of user definable categories that this object belongs to.
    ## / The category/mask combinations of both objects in a collision must agree for a collision to occur.
    categories* {.importc: "categories".}: cpBitmask ## / A bitmask of user definable category types that this object object collides with.
                                                 ## / The category/mask combinations of both objects in a collision must agree for a collision to occur.
    mask* {.importc: "mask".}: cpBitmask


## / Collision filter value for a shape that will collide with anything except CP_SHAPE_FILTER_NONE.

var CP_SHAPE_FILTER_ALL* {.importc: "CP_SHAPE_FILTER_ALL", header: "<chipmunk/chipmunk.h>".}: cpShapeFilter

## / Collision filter value for a shape that does not collide with anything.

var CP_SHAPE_FILTER_NONE* {.importc: "CP_SHAPE_FILTER_NONE", header: "<chipmunk/chipmunk.h>".}: cpShapeFilter

## / Create a new collision filter.

proc cpShapeFilterNew*(group: cpGroup; categories: cpBitmask; mask: cpBitmask): cpShapeFilter {.
    inline.} =
  var filter: cpShapeFilter
  return filter

## / Destroy a shape.

proc cpShapeDestroy*(shape: ptr cpShape) {.importc: "cpShapeDestroy",
                                       header: "<chipmunk/chipmunk.h>".}
## / Destroy and Free a shape.

proc cpShapeFree*(shape: ptr cpShape) {.importc: "cpShapeFree", header: "<chipmunk/chipmunk.h>".}
## / Update, cache and return the bounding box of a shape based on the body it's attached to.

proc cpShapeCacheBB*(shape: ptr cpShape): cpBB {.importc: "cpShapeCacheBB",
    header: "<chipmunk/chipmunk.h>".}
## / Update, cache and return the bounding box of a shape with an explicit transformation.

proc cpShapeUpdate*(shape: ptr cpShape; transform: cpTransform): cpBB {.
    importc: "cpShapeUpdate", header: "<chipmunk/chipmunk.h>".}
## / Perform a nearest point query. It finds the closest point on the surface of shape to a specific point.
## / The value returned is the distance between the points. A negative distance means the point is inside the shape.

proc cpShapePointQuery*(shape: ptr cpShape; p: cpVect; `out`: ptr cpPointQueryInfo): cpFloat {.
    importc: "cpShapePointQuery", header: "<chipmunk/chipmunk.h>".}
## / Perform a segment query against a shape. @c info must be a pointer to a valid cpSegmentQueryInfo structure.

proc cpShapeSegmentQuery*(shape: ptr cpShape; a: cpVect; b: cpVect; radius: cpFloat;
                         info: ptr cpSegmentQueryInfo): cpBool {.
    importc: "cpShapeSegmentQuery", header: "<chipmunk/chipmunk.h>".}
## / Return contact information about two shapes.

proc cpShapesCollide*(a: ptr cpShape; b: ptr cpShape): cpContactPointSet {.
    importc: "cpShapesCollide", header: "<chipmunk/chipmunk.h>".}
## / The cpSpace this body is added to.

proc cpShapeGetSpace*(shape: ptr cpShape): ptr cpSpace {.importc: "cpShapeGetSpace",
    header: "<chipmunk/chipmunk.h>".}
## / The cpBody this shape is connected to.

proc cpShapeGetBody*(shape: ptr cpShape): ptr cpBody {.importc: "cpShapeGetBody",
    header: "<chipmunk/chipmunk.h>".}
## / Set the cpBody this shape is connected to.
## / Can only be used if the shape is not currently added to a space.

proc cpShapeSetBody*(shape: ptr cpShape; body: ptr cpBody) {.importc: "cpShapeSetBody",
    header: "<chipmunk/chipmunk.h>".}
## / Get the mass of the shape if you are having Chipmunk calculate mass properties for you.

proc cpShapeGetMass*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetMass",
    header: "<chipmunk/chipmunk.h>".}
## / Set the mass of this shape to have Chipmunk calculate mass properties for you.

proc cpShapeSetMass*(shape: ptr cpShape; mass: cpFloat) {.importc: "cpShapeSetMass",
    header: "<chipmunk/chipmunk.h>".}
## / Get the density of the shape if you are having Chipmunk calculate mass properties for you.

proc cpShapeGetDensity*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetDensity",
    header: "<chipmunk/chipmunk.h>".}
## / Set the density  of this shape to have Chipmunk calculate mass properties for you.

proc cpShapeSetDensity*(shape: ptr cpShape; density: cpFloat) {.
    importc: "cpShapeSetDensity", header: "<chipmunk/chipmunk.h>".}
## / Get the calculated moment of inertia for this shape.

proc cpShapeGetMoment*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetMoment",
    header: "<chipmunk/chipmunk.h>".}
## / Get the calculated area of this shape.

proc cpShapeGetArea*(shape: ptr cpShape): cpFloat {.importc: "cpShapeGetArea",
    header: "<chipmunk/chipmunk.h>".}
## / Get the centroid of this shape.

proc cpShapeGetCenterOfGravity*(shape: ptr cpShape): cpVect {.
    importc: "cpShapeGetCenterOfGravity", header: "<chipmunk/chipmunk.h>".}
## / Get the bounding box that contains the shape given it's current position and angle.

proc cpShapeGetBB*(shape: ptr cpShape): cpBB {.importc: "cpShapeGetBB",
    header: "<chipmunk/chipmunk.h>".}
## / Get if the shape is set to be a sensor or not.

proc cpShapeGetSensor*(shape: ptr cpShape): cpBool {.importc: "cpShapeGetSensor",
    header: "<chipmunk/chipmunk.h>".}
## / Set if the shape is a sensor or not.

proc cpShapeSetSensor*(shape: ptr cpShape; sensor: cpBool) {.
    importc: "cpShapeSetSensor", header: "<chipmunk/chipmunk.h>".}
## / Get the elasticity of this shape.

proc cpShapeGetElasticity*(shape: ptr cpShape): cpFloat {.
    importc: "cpShapeGetElasticity", header: "<chipmunk/chipmunk.h>".}
## / Set the elasticity of this shape.

proc cpShapeSetElasticity*(shape: ptr cpShape; elasticity: cpFloat) {.
    importc: "cpShapeSetElasticity", header: "<chipmunk/chipmunk.h>".}
## / Get the friction of this shape.

proc cpShapeGetFriction*(shape: ptr cpShape): cpFloat {.
    importc: "cpShapeGetFriction", header: "<chipmunk/chipmunk.h>".}
## / Set the friction of this shape.

proc cpShapeSetFriction*(shape: ptr cpShape; friction: cpFloat) {.
    importc: "cpShapeSetFriction", header: "<chipmunk/chipmunk.h>".}
## / Get the surface velocity of this shape.

proc cpShapeGetSurfaceVelocity*(shape: ptr cpShape): cpVect {.
    importc: "cpShapeGetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
## / Set the surface velocity of this shape.

proc cpShapeSetSurfaceVelocity*(shape: ptr cpShape; surfaceVelocity: cpVect) {.
    importc: "cpShapeSetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
## / Get the user definable data pointer of this shape.

proc cpShapeGetUserData*(shape: ptr cpShape): cpDataPointer {.
    importc: "cpShapeGetUserData", header: "<chipmunk/chipmunk.h>".}
## / Set the user definable data pointer of this shape.

proc cpShapeSetUserData*(shape: ptr cpShape; userData: cpDataPointer) {.
    importc: "cpShapeSetUserData", header: "<chipmunk/chipmunk.h>".}
## / Set the collision type of this shape.

proc cpShapeGetCollisionType*(shape: ptr cpShape): cpCollisionType {.
    importc: "cpShapeGetCollisionType", header: "<chipmunk/chipmunk.h>".}
## / Get the collision type of this shape.

proc cpShapeSetCollisionType*(shape: ptr cpShape; collisionType: cpCollisionType) {.
    importc: "cpShapeSetCollisionType", header: "<chipmunk/chipmunk.h>".}
## / Get the collision filtering parameters of this shape.

proc cpShapeGetFilter*(shape: ptr cpShape): cpShapeFilter {.
    importc: "cpShapeGetFilter", header: "<chipmunk/chipmunk.h>".}
## / Set the collision filtering parameters of this shape.

proc cpShapeSetFilter*(shape: ptr cpShape; filter: cpShapeFilter) {.
    importc: "cpShapeSetFilter", header: "<chipmunk/chipmunk.h>".}
## / @}
## / @defgroup cpCircleShape cpCircleShape
## / Allocate a circle shape.

proc cpCircleShapeAlloc*(): ptr cpCircleShape {.importc: "cpCircleShapeAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / Initialize a circle shape.

proc cpCircleShapeInit*(circle: ptr cpCircleShape; body: ptr cpBody; radius: cpFloat;
                       offset: cpVect): ptr cpCircleShape {.
    importc: "cpCircleShapeInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a circle shape.

proc cpCircleShapeNew*(body: ptr cpBody; radius: cpFloat; offset: cpVect): ptr cpShape {.
    importc: "cpCircleShapeNew", header: "<chipmunk/chipmunk.h>".}
## / Get the offset of a circle shape.

proc cpCircleShapeGetOffset*(shape: ptr cpShape): cpVect {.
    importc: "cpCircleShapeGetOffset", header: "<chipmunk/chipmunk.h>".}
## / Get the radius of a circle shape.

proc cpCircleShapeGetRadius*(shape: ptr cpShape): cpFloat {.
    importc: "cpCircleShapeGetRadius", header: "<chipmunk/chipmunk.h>".}
## / @}
## / @defgroup cpSegmentShape cpSegmentShape
## / Allocate a segment shape.

proc cpSegmentShapeAlloc*(): ptr cpSegmentShape {.importc: "cpSegmentShapeAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / Initialize a segment shape.

proc cpSegmentShapeInit*(seg: ptr cpSegmentShape; body: ptr cpBody; a: cpVect; b: cpVect;
                        radius: cpFloat): ptr cpSegmentShape {.
    importc: "cpSegmentShapeInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a segment shape.

proc cpSegmentShapeNew*(body: ptr cpBody; a: cpVect; b: cpVect; radius: cpFloat): ptr cpShape {.
    importc: "cpSegmentShapeNew", header: "<chipmunk/chipmunk.h>".}
## / Let Chipmunk know about the geometry of adjacent segments to avoid colliding with endcaps.

proc cpSegmentShapeSetNeighbors*(shape: ptr cpShape; prev: cpVect; next: cpVect) {.
    importc: "cpSegmentShapeSetNeighbors", header: "<chipmunk/chipmunk.h>".}
## / Get the first endpoint of a segment shape.

proc cpSegmentShapeGetA*(shape: ptr cpShape): cpVect {.importc: "cpSegmentShapeGetA",
    header: "<chipmunk/chipmunk.h>".}
## / Get the second endpoint of a segment shape.

proc cpSegmentShapeGetB*(shape: ptr cpShape): cpVect {.importc: "cpSegmentShapeGetB",
    header: "<chipmunk/chipmunk.h>".}
## / Get the normal of a segment shape.

proc cpSegmentShapeGetNormal*(shape: ptr cpShape): cpVect {.
    importc: "cpSegmentShapeGetNormal", header: "<chipmunk/chipmunk.h>".}
## / Get the first endpoint of a segment shape.

proc cpSegmentShapeGetRadius*(shape: ptr cpShape): cpFloat {.
    importc: "cpSegmentShapeGetRadius", header: "<chipmunk/chipmunk.h>".}
## / @}

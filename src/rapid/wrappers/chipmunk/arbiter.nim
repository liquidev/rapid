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
## / @defgroup cpArbiter cpArbiter
## / The cpArbiter struct tracks pairs of colliding shapes.
## / They are also used in conjuction with collision handler callbacks
## / allowing you to retrieve information on the collision or change it.
## / A unique arbiter value is used for each pair of colliding objects. It persists until the shapes separate.
## / @{

const
  CP_MAX_CONTACTS_PER_ARBITER* = 2

## / Get the restitution (elasticity) that will be applied to the pair of colliding objects.

proc cpArbiterGetRestitution*(arb: ptr cpArbiter): cpFloat {.
    importc: "cpArbiterGetRestitution", header: "<chipmunk/chipmunk.h>".}
## / Override the restitution (elasticity) that will be applied to the pair of colliding objects.

proc cpArbiterSetRestitution*(arb: ptr cpArbiter; restitution: cpFloat) {.
    importc: "cpArbiterSetRestitution", header: "<chipmunk/chipmunk.h>".}
## / Get the friction coefficient that will be applied to the pair of colliding objects.

proc cpArbiterGetFriction*(arb: ptr cpArbiter): cpFloat {.
    importc: "cpArbiterGetFriction", header: "<chipmunk/chipmunk.h>".}
## / Override the friction coefficient that will be applied to the pair of colliding objects.

proc cpArbiterSetFriction*(arb: ptr cpArbiter; friction: cpFloat) {.
    importc: "cpArbiterSetFriction", header: "<chipmunk/chipmunk.h>".}
##  Get the relative surface velocity of the two shapes in contact.

proc cpArbiterGetSurfaceVelocity*(arb: ptr cpArbiter): cpVect {.
    importc: "cpArbiterGetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
##  Override the relative surface velocity of the two shapes in contact.
##  By default this is calculated to be the difference of the two surface velocities clamped to the tangent plane.

proc cpArbiterSetSurfaceVelocity*(arb: ptr cpArbiter; vr: cpVect) {.
    importc: "cpArbiterSetSurfaceVelocity", header: "<chipmunk/chipmunk.h>".}
## / Get the user data pointer associated with this pair of colliding objects.

proc cpArbiterGetUserData*(arb: ptr cpArbiter): cpDataPointer {.
    importc: "cpArbiterGetUserData", header: "<chipmunk/chipmunk.h>".}
## / Set a user data point associated with this pair of colliding objects.
## / If you need to perform any cleanup for this pointer, you must do it yourself, in the separate callback for instance.

proc cpArbiterSetUserData*(arb: ptr cpArbiter; userData: cpDataPointer) {.
    importc: "cpArbiterSetUserData", header: "<chipmunk/chipmunk.h>".}
## / Calculate the total impulse including the friction that was applied by this arbiter.
## / This function should only be called from a post-solve, post-step or cpBodyEachArbiter callback.

proc cpArbiterTotalImpulse*(arb: ptr cpArbiter): cpVect {.
    importc: "cpArbiterTotalImpulse", header: "<chipmunk/chipmunk.h>".}
## / Calculate the amount of energy lost in a collision including static, but not dynamic friction.
## / This function should only be called from a post-solve, post-step or cpBodyEachArbiter callback.

proc cpArbiterTotalKE*(arb: ptr cpArbiter): cpFloat {.importc: "cpArbiterTotalKE",
    header: "<chipmunk/chipmunk.h>".}
## / Mark a collision pair to be ignored until the two objects separate.
## / Pre-solve and post-solve callbacks will not be called, but the separate callback will be called.

proc cpArbiterIgnore*(arb: ptr cpArbiter): cpBool {.importc: "cpArbiterIgnore",
    header: "<chipmunk/chipmunk.h>".}
## / Return the colliding shapes involved for this arbiter.
## / The order of their cpSpace.collision_type values will match
## / the order set when the collision handler was registered.

proc cpArbiterGetShapes*(arb: ptr cpArbiter; a: ptr ptr cpShape; b: ptr ptr cpShape) {.
    importc: "cpArbiterGetShapes", header: "<chipmunk/chipmunk.h>".}
## / A macro shortcut for defining and retrieving the shapes from an arbiter.
##  #define CP_ARBITER_GET_SHAPES(__arb__, __a__, __b__) cpShape *__a__, *__b__; cpArbiterGetShapes(__arb__, &__a__, &__b__);

proc cpArbiterGetBodies*(arb: ptr cpArbiter; a: ptr ptr cpBody; b: ptr ptr cpBody) {.
    importc: "cpArbiterGetBodies", header: "<chipmunk/chipmunk.h>".}
## / A macro shortcut for defining and retrieving the bodies from an arbiter.
##  #define CP_ARBITER_GET_BODIES(__arb__, __a__, __b__) cpBody *__a__, *__b__; cpArbiterGetBodies(__arb__, &__a__, &__b__);
## / A struct that wraps up the important collision data for an arbiter.

type
  INNER_C_STRUCT_cpArbiter_88* {.importc: "no_name", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    pointA* {.importc: "pointA".}: cpVect ## / The position of the contact on the surface of each shape.
    pointB* {.importc: "pointB".}: cpVect ## / Penetration distance of the two shapes. Overlapping means it will be negative.
                                      ## / This value is calculated as cpvdot(cpvsub(point2, point1), normal) and is ignored by cpArbiterSetContactPointSet().
    distance* {.importc: "distance".}: cpFloat

  cpContactPointSet* {.importc: "cpContactPointSet", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    count* {.importc: "count".}: cint ## / The number of contact points in the set.
    ## / The normal of the collision.
    normal* {.importc: "normal".}: cpVect ## / The array of contact points.
    points* {.importc: "points".}: array[CP_MAX_CONTACTS_PER_ARBITER,
                                      INNER_C_STRUCT_cpArbiter_88]


## / Return a contact set from an arbiter.

proc cpArbiterGetContactPointSet*(arb: ptr cpArbiter): cpContactPointSet {.
    importc: "cpArbiterGetContactPointSet", header: "<chipmunk/chipmunk.h>".}
## / Replace the contact point set for an arbiter.
## / This can be a very powerful feature, but use it with caution!

proc cpArbiterSetContactPointSet*(arb: ptr cpArbiter; set: ptr cpContactPointSet) {.
    importc: "cpArbiterSetContactPointSet", header: "<chipmunk/chipmunk.h>".}
## / Returns true if this is the first step a pair of objects started colliding.

proc cpArbiterIsFirstContact*(arb: ptr cpArbiter): cpBool {.
    importc: "cpArbiterIsFirstContact", header: "<chipmunk/chipmunk.h>".}
## / Returns true if the separate callback is due to a shape being removed from the space.

proc cpArbiterIsRemoval*(arb: ptr cpArbiter): cpBool {.importc: "cpArbiterIsRemoval",
    header: "<chipmunk/chipmunk.h>".}
## / Get the number of contact points for this arbiter.

proc cpArbiterGetCount*(arb: ptr cpArbiter): cint {.importc: "cpArbiterGetCount",
    header: "<chipmunk/chipmunk.h>".}
## / Get the normal of the collision.

proc cpArbiterGetNormal*(arb: ptr cpArbiter): cpVect {.importc: "cpArbiterGetNormal",
    header: "<chipmunk/chipmunk.h>".}
## / Get the position of the @c ith contact point on the surface of the first shape.

proc cpArbiterGetPointA*(arb: ptr cpArbiter; i: cint): cpVect {.
    importc: "cpArbiterGetPointA", header: "<chipmunk/chipmunk.h>".}
## / Get the position of the @c ith contact point on the surface of the second shape.

proc cpArbiterGetPointB*(arb: ptr cpArbiter; i: cint): cpVect {.
    importc: "cpArbiterGetPointB", header: "<chipmunk/chipmunk.h>".}
## / Get the depth of the @c ith contact point.

proc cpArbiterGetDepth*(arb: ptr cpArbiter; i: cint): cpFloat {.
    importc: "cpArbiterGetDepth", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
## / You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardBeginA*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardBeginA", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
## / You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardBeginB*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardBeginB", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.
## / You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardPreSolveA*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardPreSolveA", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.
## / You must decide how to handle the wildcard's return value since it may disagree with the other wildcard handler's return value or your own.

proc cpArbiterCallWildcardPreSolveB*(arb: ptr cpArbiter; space: ptr cpSpace): cpBool {.
    importc: "cpArbiterCallWildcardPreSolveB", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.

proc cpArbiterCallWildcardPostSolveA*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardPostSolveA", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.

proc cpArbiterCallWildcardPostSolveB*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardPostSolveB", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the first collision type, you must call this function explicitly.

proc cpArbiterCallWildcardSeparateA*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardSeparateA", header: "<chipmunk/chipmunk.h>".}
## / If you want a custom callback to invoke the wildcard callback for the second collision type, you must call this function explicitly.

proc cpArbiterCallWildcardSeparateB*(arb: ptr cpArbiter; space: ptr cpSpace) {.
    importc: "cpArbiterCallWildcardSeparateB", header: "<chipmunk/chipmunk.h>".}
## / @}

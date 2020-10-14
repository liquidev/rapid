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
## / @defgroup cpBody cpBody
## / Chipmunk's rigid body type. Rigid bodies hold the physical properties of an object like
## / it's mass, and position and velocity of it's center of gravity. They don't have an shape on their own.
## / They are given a shape by creating collision shapes (cpShape) that point to the body.
## / @{

import types

type ## / A dynamic body is one that is affected by gravity, forces, and collisions.
    ## / This is the default body type.
  cpBodyType* {.size: sizeof(cint).} = enum
    CP_BODY_TYPE_DYNAMIC, ## / A kinematic body is an infinite mass, user controlled body that is not affected by gravity, forces or collisions.
                         ## / Instead the body only moves based on it's velocity.
                         ## / Dynamic bodies collide normally with kinematic bodies, though the kinematic body will be unaffected.
                         ## / Collisions between two kinematic bodies, or a kinematic body and a static body produce collision callbacks, but no collision response.
    CP_BODY_TYPE_KINEMATIC, ## / A static body is a body that never (or rarely) moves. If you move a static body, you must call one of the cpSpaceReindex*() functions.
                           ## / Chipmunk uses this information to optimize the collision detection.
                           ## / Static bodies do not produce collision callbacks when colliding with other static bodies.
    CP_BODY_TYPE_STATIC


## / Rigid body velocity update function type.

type
  cpBodyVelocityFunc* = proc (body: ptr cpBody; gravity: cpVect; damping: cpFloat;
                           dt: cpFloat) {.cdecl.}

## / Rigid body position update function type.

type
  cpBodyPositionFunc* = proc (body: ptr cpBody; dt: cpFloat) {.cdecl.}

## / Allocate a cpBody.

proc cpBodyAlloc*(): ptr cpBody {.importc: "cpBodyAlloc", header: "<chipmunk/chipmunk.h>".}
## / Initialize a cpBody.

proc cpBodyInit*(body: ptr cpBody; mass: cpFloat; moment: cpFloat): ptr cpBody {.
    importc: "cpBodyInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a cpBody.

proc cpBodyNew*(mass: cpFloat; moment: cpFloat): ptr cpBody {.importc: "cpBodyNew",
    header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a cpBody, and set it as a kinematic body.

proc cpBodyNewKinematic*(): ptr cpBody {.importc: "cpBodyNewKinematic",
                                     header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a cpBody, and set it as a static body.

proc cpBodyNewStatic*(): ptr cpBody {.importc: "cpBodyNewStatic", header: "<chipmunk/chipmunk.h>".}
## / Destroy a cpBody.

proc cpBodyDestroy*(body: ptr cpBody) {.importc: "cpBodyDestroy", header: "<chipmunk/chipmunk.h>".}
## / Destroy and free a cpBody.

proc cpBodyFree*(body: ptr cpBody) {.importc: "cpBodyFree", header: "<chipmunk/chipmunk.h>".}
##  Defined in cpSpace.c
## / Wake up a sleeping or idle body.

proc cpBodyActivate*(body: ptr cpBody) {.importc: "cpBodyActivate", header: "<chipmunk/chipmunk.h>".}
## / Wake up any sleeping or idle bodies touching a static body.

proc cpBodyActivateStatic*(body: ptr cpBody; filter: ptr cpShape) {.
    importc: "cpBodyActivateStatic", header: "<chipmunk/chipmunk.h>".}
## / Force a body to fall asleep immediately.

proc cpBodySleep*(body: ptr cpBody) {.importc: "cpBodySleep", header: "<chipmunk/chipmunk.h>".}
## / Force a body to fall asleep immediately along with other bodies in a group.

proc cpBodySleepWithGroup*(body: ptr cpBody; group: ptr cpBody) {.
    importc: "cpBodySleepWithGroup", header: "<chipmunk/chipmunk.h>".}
## / Returns true if the body is sleeping.

proc cpBodyIsSleeping*(body: ptr cpBody): cpBool {.importc: "cpBodyIsSleeping",
    header: "<chipmunk/chipmunk.h>".}
## / Get the type of the body.

proc cpBodyGetType*(body: ptr cpBody): cpBodyType {.importc: "cpBodyGetType",
    header: "<chipmunk/chipmunk.h>".}
## / Set the type of the body.

proc cpBodySetType*(body: ptr cpBody; `type`: cpBodyType) {.importc: "cpBodySetType",
    header: "<chipmunk/chipmunk.h>".}
## / Get the space this body is added to.

proc cpBodyGetSpace*(body: ptr cpBody): ptr cpSpace {.importc: "cpBodyGetSpace",
    header: "<chipmunk/chipmunk.h>".}
## / Get the mass of the body.

proc cpBodyGetMass*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetMass",
    header: "<chipmunk/chipmunk.h>".}
## / Set the mass of the body.

proc cpBodySetMass*(body: ptr cpBody; m: cpFloat) {.importc: "cpBodySetMass",
    header: "<chipmunk/chipmunk.h>".}
## / Get the moment of inertia of the body.

proc cpBodyGetMoment*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetMoment",
    header: "<chipmunk/chipmunk.h>".}
## / Set the moment of inertia of the body.

proc cpBodySetMoment*(body: ptr cpBody; i: cpFloat) {.importc: "cpBodySetMoment",
    header: "<chipmunk/chipmunk.h>".}
## / Set the position of a body.

proc cpBodyGetPosition*(body: ptr cpBody): cpVect {.importc: "cpBodyGetPosition",
    header: "<chipmunk/chipmunk.h>".}
## / Set the position of the body.

proc cpBodySetPosition*(body: ptr cpBody; pos: cpVect) {.importc: "cpBodySetPosition",
    header: "<chipmunk/chipmunk.h>".}
## / Get the offset of the center of gravity in body local coordinates.

proc cpBodyGetCenterOfGravity*(body: ptr cpBody): cpVect {.
    importc: "cpBodyGetCenterOfGravity", header: "<chipmunk/chipmunk.h>".}
## / Set the offset of the center of gravity in body local coordinates.

proc cpBodySetCenterOfGravity*(body: ptr cpBody; cog: cpVect) {.
    importc: "cpBodySetCenterOfGravity", header: "<chipmunk/chipmunk.h>".}
## / Get the velocity of the body.

proc cpBodyGetVelocity*(body: ptr cpBody): cpVect {.importc: "cpBodyGetVelocity",
    header: "<chipmunk/chipmunk.h>".}
## / Set the velocity of the body.

proc cpBodySetVelocity*(body: ptr cpBody; velocity: cpVect) {.
    importc: "cpBodySetVelocity", header: "<chipmunk/chipmunk.h>".}
## / Get the force applied to the body for the next time step.

proc cpBodyGetForce*(body: ptr cpBody): cpVect {.importc: "cpBodyGetForce",
    header: "<chipmunk/chipmunk.h>".}
## / Set the force applied to the body for the next time step.

proc cpBodySetForce*(body: ptr cpBody; force: cpVect) {.importc: "cpBodySetForce",
    header: "<chipmunk/chipmunk.h>".}
## / Get the angle of the body.

proc cpBodyGetAngle*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetAngle",
    header: "<chipmunk/chipmunk.h>".}
## / Set the angle of a body.

proc cpBodySetAngle*(body: ptr cpBody; a: cpFloat) {.importc: "cpBodySetAngle",
    header: "<chipmunk/chipmunk.h>".}
## / Get the angular velocity of the body.

proc cpBodyGetAngularVelocity*(body: ptr cpBody): cpFloat {.
    importc: "cpBodyGetAngularVelocity", header: "<chipmunk/chipmunk.h>".}
## / Set the angular velocity of the body.

proc cpBodySetAngularVelocity*(body: ptr cpBody; angularVelocity: cpFloat) {.
    importc: "cpBodySetAngularVelocity", header: "<chipmunk/chipmunk.h>".}
## / Get the torque applied to the body for the next time step.

proc cpBodyGetTorque*(body: ptr cpBody): cpFloat {.importc: "cpBodyGetTorque",
    header: "<chipmunk/chipmunk.h>".}
## / Set the torque applied to the body for the next time step.

proc cpBodySetTorque*(body: ptr cpBody; torque: cpFloat) {.importc: "cpBodySetTorque",
    header: "<chipmunk/chipmunk.h>".}
## / Get the rotation vector of the body. (The x basis vector of it's transform.)

proc cpBodyGetRotation*(body: ptr cpBody): cpVect {.importc: "cpBodyGetRotation",
    header: "<chipmunk/chipmunk.h>".}
## / Get the user data pointer assigned to the body.

proc cpBodyGetUserData*(body: ptr cpBody): cpDataPointer {.
    importc: "cpBodyGetUserData", header: "<chipmunk/chipmunk.h>".}
## / Set the user data pointer assigned to the body.

proc cpBodySetUserData*(body: ptr cpBody; userData: cpDataPointer) {.
    importc: "cpBodySetUserData", header: "<chipmunk/chipmunk.h>".}
## / Set the callback used to update a body's velocity.

proc cpBodySetVelocityUpdateFunc*(body: ptr cpBody; velocityFunc: cpBodyVelocityFunc) {.
    importc: "cpBodySetVelocityUpdateFunc", header: "<chipmunk/chipmunk.h>".}
## / Set the callback used to update a body's position.
## / NOTE: It's not generally recommended to override this unless you call the default position update function.

proc cpBodySetPositionUpdateFunc*(body: ptr cpBody; positionFunc: cpBodyPositionFunc) {.
    importc: "cpBodySetPositionUpdateFunc", header: "<chipmunk/chipmunk.h>".}
## / Default velocity integration function..

proc cpBodyUpdateVelocity*(body: ptr cpBody; gravity: cpVect; damping: cpFloat;
                          dt: cpFloat) {.importc: "cpBodyUpdateVelocity",
                                       header: "<chipmunk/chipmunk.h>".}
## / Default position integration function.

proc cpBodyUpdatePosition*(body: ptr cpBody; dt: cpFloat) {.
    importc: "cpBodyUpdatePosition", header: "<chipmunk/chipmunk.h>".}
## / Convert body relative/local coordinates to absolute/world coordinates.

proc cpBodyLocalToWorld*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyLocalToWorld", header: "<chipmunk/chipmunk.h>".}
## / Convert body absolute/world coordinates to  relative/local coordinates.

proc cpBodyWorldToLocal*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyWorldToLocal", header: "<chipmunk/chipmunk.h>".}
## / Apply a force to a body. Both the force and point are expressed in world coordinates.

proc cpBodyApplyForceAtWorldPoint*(body: ptr cpBody; force: cpVect; point: cpVect) {.
    importc: "cpBodyApplyForceAtWorldPoint", header: "<chipmunk/chipmunk.h>".}
## / Apply a force to a body. Both the force and point are expressed in body local coordinates.

proc cpBodyApplyForceAtLocalPoint*(body: ptr cpBody; force: cpVect; point: cpVect) {.
    importc: "cpBodyApplyForceAtLocalPoint", header: "<chipmunk/chipmunk.h>".}
## / Apply an impulse to a body. Both the impulse and point are expressed in world coordinates.

proc cpBodyApplyImpulseAtWorldPoint*(body: ptr cpBody; impulse: cpVect; point: cpVect) {.
    importc: "cpBodyApplyImpulseAtWorldPoint", header: "<chipmunk/chipmunk.h>".}
## / Apply an impulse to a body. Both the impulse and point are expressed in body local coordinates.

proc cpBodyApplyImpulseAtLocalPoint*(body: ptr cpBody; impulse: cpVect; point: cpVect) {.
    importc: "cpBodyApplyImpulseAtLocalPoint", header: "<chipmunk/chipmunk.h>".}
## / Get the velocity on a body (in world units) at a point on the body in world coordinates.

proc cpBodyGetVelocityAtWorldPoint*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyGetVelocityAtWorldPoint", header: "<chipmunk/chipmunk.h>".}
## / Get the velocity on a body (in world units) at a point on the body in local coordinates.

proc cpBodyGetVelocityAtLocalPoint*(body: ptr cpBody; point: cpVect): cpVect {.
    importc: "cpBodyGetVelocityAtLocalPoint", header: "<chipmunk/chipmunk.h>".}
## / Get the amount of kinetic energy contained by the body.

proc cpBodyKineticEnergy*(body: ptr cpBody): cpFloat {.
    importc: "cpBodyKineticEnergy", header: "<chipmunk/chipmunk.h>".}
## / Body/shape iterator callback function type.

type
  cpBodyShapeIteratorFunc* = proc (body: ptr cpBody; shape: ptr cpShape; data: pointer) {.cdecl.}

## / Call @c func once for each shape attached to @c body and added to the space.

proc cpBodyEachShape*(body: ptr cpBody; `func`: cpBodyShapeIteratorFunc; data: pointer) {.
    importc: "cpBodyEachShape", header: "<chipmunk/chipmunk.h>".}
## / Body/constraint iterator callback function type.

type
  cpBodyConstraintIteratorFunc* = proc (body: ptr cpBody;
                                     constraint: ptr cpConstraint; data: pointer) {.cdecl.}

## / Call @c func once for each constraint attached to @c body and added to the space.

proc cpBodyEachConstraint*(body: ptr cpBody; `func`: cpBodyConstraintIteratorFunc;
                          data: pointer) {.importc: "cpBodyEachConstraint",
    header: "<chipmunk/chipmunk.h>".}
## / Body/arbiter iterator callback function type.

type
  cpBodyArbiterIteratorFunc* = proc (body: ptr cpBody; arbiter: ptr cpArbiter;
                                  data: pointer) {.cdecl.}

## / Call @c func once for each arbiter that is currently active on the body.

proc cpBodyEachArbiter*(body: ptr cpBody; `func`: cpBodyArbiterIteratorFunc;
                       data: pointer) {.importc: "cpBodyEachArbiter",
                                      header: "<chipmunk/chipmunk.h>".}
## /@}

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
## / @defgroup cpConstraint cpConstraint
## / @{
## / Callback function type that gets called before solving a joint.

import types

type
  cpConstraintPreSolveFunc* = proc (constraint: ptr cpConstraint; space: ptr cpSpace)

## / Callback function type that gets called after solving a joint.

type
  cpConstraintPostSolveFunc* = proc (constraint: ptr cpConstraint; space: ptr cpSpace)

## / Destroy a constraint.

proc cpConstraintDestroy*(constraint: ptr cpConstraint) {.
    importc: "cpConstraintDestroy", header: "<chipmunk/chipmunk.h>".}
## / Destroy and free a constraint.

proc cpConstraintFree*(constraint: ptr cpConstraint) {.importc: "cpConstraintFree",
    header: "<chipmunk/chipmunk.h>".}
## / Get the cpSpace this constraint is added to.

proc cpConstraintGetSpace*(constraint: ptr cpConstraint): ptr cpSpace {.
    importc: "cpConstraintGetSpace", header: "<chipmunk/chipmunk.h>".}
## / Get the first body the constraint is attached to.

proc cpConstraintGetBodyA*(constraint: ptr cpConstraint): ptr cpBody {.
    importc: "cpConstraintGetBodyA", header: "<chipmunk/chipmunk.h>".}
## / Get the second body the constraint is attached to.

proc cpConstraintGetBodyB*(constraint: ptr cpConstraint): ptr cpBody {.
    importc: "cpConstraintGetBodyB", header: "<chipmunk/chipmunk.h>".}
## / Get the maximum force that this constraint is allowed to use.

proc cpConstraintGetMaxForce*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetMaxForce", header: "<chipmunk/chipmunk.h>".}
## / Set the maximum force that this constraint is allowed to use. (defaults to INFINITY)

proc cpConstraintSetMaxForce*(constraint: ptr cpConstraint; maxForce: cpFloat) {.
    importc: "cpConstraintSetMaxForce", header: "<chipmunk/chipmunk.h>".}
## / Get rate at which joint error is corrected.

proc cpConstraintGetErrorBias*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetErrorBias", header: "<chipmunk/chipmunk.h>".}
## / Set rate at which joint error is corrected.
## / Defaults to pow(1.0 - 0.1, 60.0) meaning that it will
## / correct 10% of the error every 1/60th of a second.

proc cpConstraintSetErrorBias*(constraint: ptr cpConstraint; errorBias: cpFloat) {.
    importc: "cpConstraintSetErrorBias", header: "<chipmunk/chipmunk.h>".}
## / Get the maximum rate at which joint error is corrected.

proc cpConstraintGetMaxBias*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetMaxBias", header: "<chipmunk/chipmunk.h>".}
## / Set the maximum rate at which joint error is corrected. (defaults to INFINITY)

proc cpConstraintSetMaxBias*(constraint: ptr cpConstraint; maxBias: cpFloat) {.
    importc: "cpConstraintSetMaxBias", header: "<chipmunk/chipmunk.h>".}
## / Get if the two bodies connected by the constraint are allowed to collide or not.

proc cpConstraintGetCollideBodies*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintGetCollideBodies", header: "<chipmunk/chipmunk.h>".}
## / Set if the two bodies connected by the constraint are allowed to collide or not. (defaults to cpFalse)

proc cpConstraintSetCollideBodies*(constraint: ptr cpConstraint;
                                  collideBodies: cpBool) {.
    importc: "cpConstraintSetCollideBodies", header: "<chipmunk/chipmunk.h>".}
## / Get the pre-solve function that is called before the solver runs.

proc cpConstraintGetPreSolveFunc*(constraint: ptr cpConstraint): cpConstraintPreSolveFunc {.
    importc: "cpConstraintGetPreSolveFunc", header: "<chipmunk/chipmunk.h>".}
## / Set the pre-solve function that is called before the solver runs.

proc cpConstraintSetPreSolveFunc*(constraint: ptr cpConstraint;
                                 preSolveFunc: cpConstraintPreSolveFunc) {.
    importc: "cpConstraintSetPreSolveFunc", header: "<chipmunk/chipmunk.h>".}
## / Get the post-solve function that is called before the solver runs.

proc cpConstraintGetPostSolveFunc*(constraint: ptr cpConstraint): cpConstraintPostSolveFunc {.
    importc: "cpConstraintGetPostSolveFunc", header: "<chipmunk/chipmunk.h>".}
## / Set the post-solve function that is called before the solver runs.

proc cpConstraintSetPostSolveFunc*(constraint: ptr cpConstraint;
                                  postSolveFunc: cpConstraintPostSolveFunc) {.
    importc: "cpConstraintSetPostSolveFunc", header: "<chipmunk/chipmunk.h>".}
## / Get the user definable data pointer for this constraint

proc cpConstraintGetUserData*(constraint: ptr cpConstraint): cpDataPointer {.
    importc: "cpConstraintGetUserData", header: "<chipmunk/chipmunk.h>".}
## / Set the user definable data pointer for this constraint

proc cpConstraintSetUserData*(constraint: ptr cpConstraint; userData: cpDataPointer) {.
    importc: "cpConstraintSetUserData", header: "<chipmunk/chipmunk.h>".}
## / Get the last impulse applied by this constraint.

proc cpConstraintGetImpulse*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpConstraintGetImpulse", header: "<chipmunk/chipmunk.h>".}

include
  pin_joint, slide_joint, pivot_joint, groove_joint, damped_spring,
  damped_rotary_spring, rotary_limit_joint, ratchet_joint, gear_joint,
  simple_motor

## /@}

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
## / @defgroup cpDampedSpring cpDampedSpring
## / @{
## / Check if a constraint is a slide joint.

proc cpConstraintIsDampedSpring*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsDampedSpring", header: "<chipmunk/chipmunk.h>".}
## / Function type used for damped spring force callbacks.

type
  cpDampedSpringForceFunc* = proc (spring: ptr cpConstraint; dist: cpFloat): cpFloat

## / Allocate a damped spring.

proc cpDampedSpringAlloc*(): ptr cpDampedSpring {.importc: "cpDampedSpringAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / Initialize a damped spring.

proc cpDampedSpringInit*(joint: ptr cpDampedSpring; a: ptr cpBody; b: ptr cpBody;
                        anchorA: cpVect; anchorB: cpVect; restLength: cpFloat;
                        stiffness: cpFloat; damping: cpFloat): ptr cpDampedSpring {.
    importc: "cpDampedSpringInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a damped spring.

proc cpDampedSpringNew*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect;
                       restLength: cpFloat; stiffness: cpFloat; damping: cpFloat): ptr cpConstraint {.
    importc: "cpDampedSpringNew", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the first anchor relative to the first body.

proc cpDampedSpringGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpDampedSpringGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the first anchor relative to the first body.

proc cpDampedSpringSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpDampedSpringSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the second anchor relative to the second body.

proc cpDampedSpringGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpDampedSpringGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the second anchor relative to the second body.

proc cpDampedSpringSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpDampedSpringSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Get the rest length of the spring.

proc cpDampedSpringGetRestLength*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedSpringGetRestLength", header: "<chipmunk/chipmunk.h>".}
## / Set the rest length of the spring.

proc cpDampedSpringSetRestLength*(constraint: ptr cpConstraint; restLength: cpFloat) {.
    importc: "cpDampedSpringSetRestLength", header: "<chipmunk/chipmunk.h>".}
## / Get the stiffness of the spring in force/distance.

proc cpDampedSpringGetStiffness*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedSpringGetStiffness", header: "<chipmunk/chipmunk.h>".}
## / Set the stiffness of the spring in force/distance.

proc cpDampedSpringSetStiffness*(constraint: ptr cpConstraint; stiffness: cpFloat) {.
    importc: "cpDampedSpringSetStiffness", header: "<chipmunk/chipmunk.h>".}
## / Get the damping of the spring.

proc cpDampedSpringGetDamping*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedSpringGetDamping", header: "<chipmunk/chipmunk.h>".}
## / Set the damping of the spring.

proc cpDampedSpringSetDamping*(constraint: ptr cpConstraint; damping: cpFloat) {.
    importc: "cpDampedSpringSetDamping", header: "<chipmunk/chipmunk.h>".}
## / Get the damping of the spring.

proc cpDampedSpringGetSpringForceFunc*(constraint: ptr cpConstraint): cpDampedSpringForceFunc {.
    importc: "cpDampedSpringGetSpringForceFunc", header: "<chipmunk/chipmunk.h>".}
## / Set the damping of the spring.

proc cpDampedSpringSetSpringForceFunc*(constraint: ptr cpConstraint;
                                      springForceFunc: cpDampedSpringForceFunc) {.
    importc: "cpDampedSpringSetSpringForceFunc", header: "<chipmunk/chipmunk.h>".}
## / @}

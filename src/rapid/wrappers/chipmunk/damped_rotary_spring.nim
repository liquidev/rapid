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
## / @defgroup cpDampedRotarySpring cpDampedRotarySpring
## / @{
## / Check if a constraint is a damped rotary springs.

proc cpConstraintIsDampedRotarySpring*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsDampedRotarySpring", header: "<chipmunk/chipmunk.h>".}
## / Function type used for damped rotary spring force callbacks.

type
  cpDampedRotarySpringTorqueFunc* = proc (spring: ptr cpConstraint;
                                       relativeAngle: cpFloat): cpFloat

## / Allocate a damped rotary spring.

proc cpDampedRotarySpringAlloc*(): ptr cpDampedRotarySpring {.
    importc: "cpDampedRotarySpringAlloc", header: "<chipmunk/chipmunk.h>".}
## / Initialize a damped rotary spring.

proc cpDampedRotarySpringInit*(joint: ptr cpDampedRotarySpring; a: ptr cpBody;
                              b: ptr cpBody; restAngle: cpFloat; stiffness: cpFloat;
                              damping: cpFloat): ptr cpDampedRotarySpring {.
    importc: "cpDampedRotarySpringInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a damped rotary spring.

proc cpDampedRotarySpringNew*(a: ptr cpBody; b: ptr cpBody; restAngle: cpFloat;
                             stiffness: cpFloat; damping: cpFloat): ptr cpConstraint {.
    importc: "cpDampedRotarySpringNew", header: "<chipmunk/chipmunk.h>".}
## / Get the rest length of the spring.

proc cpDampedRotarySpringGetRestAngle*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedRotarySpringGetRestAngle", header: "<chipmunk/chipmunk.h>".}
## / Set the rest length of the spring.

proc cpDampedRotarySpringSetRestAngle*(constraint: ptr cpConstraint;
                                      restAngle: cpFloat) {.
    importc: "cpDampedRotarySpringSetRestAngle", header: "<chipmunk/chipmunk.h>".}
## / Get the stiffness of the spring in force/distance.

proc cpDampedRotarySpringGetStiffness*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedRotarySpringGetStiffness", header: "<chipmunk/chipmunk.h>".}
## / Set the stiffness of the spring in force/distance.

proc cpDampedRotarySpringSetStiffness*(constraint: ptr cpConstraint;
                                      stiffness: cpFloat) {.
    importc: "cpDampedRotarySpringSetStiffness", header: "<chipmunk/chipmunk.h>".}
## / Get the damping of the spring.

proc cpDampedRotarySpringGetDamping*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpDampedRotarySpringGetDamping", header: "<chipmunk/chipmunk.h>".}
## / Set the damping of the spring.

proc cpDampedRotarySpringSetDamping*(constraint: ptr cpConstraint; damping: cpFloat) {.
    importc: "cpDampedRotarySpringSetDamping", header: "<chipmunk/chipmunk.h>".}
## / Get the damping of the spring.

proc cpDampedRotarySpringGetSpringTorqueFunc*(constraint: ptr cpConstraint): cpDampedRotarySpringTorqueFunc {.
    importc: "cpDampedRotarySpringGetSpringTorqueFunc",
    header: "<chipmunk/chipmunk.h>".}
## / Set the damping of the spring.

proc cpDampedRotarySpringSetSpringTorqueFunc*(constraint: ptr cpConstraint;
    springTorqueFunc: cpDampedRotarySpringTorqueFunc) {.
    importc: "cpDampedRotarySpringSetSpringTorqueFunc",
    header: "<chipmunk/chipmunk.h>".}
## / @}

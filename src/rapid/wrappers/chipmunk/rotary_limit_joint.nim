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
## / @defgroup cpRotaryLimitJoint cpRotaryLimitJoint
## / @{
## / Check if a constraint is a damped rotary springs.

proc cpConstraintIsRotaryLimitJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsRotaryLimitJoint", header: "<chipmunk/chipmunk.h>".}
## / Allocate a damped rotary limit joint.

proc cpRotaryLimitJointAlloc*(): ptr cpRotaryLimitJoint {.
    importc: "cpRotaryLimitJointAlloc", header: "<chipmunk/chipmunk.h>".}
## / Initialize a damped rotary limit joint.

proc cpRotaryLimitJointInit*(joint: ptr cpRotaryLimitJoint; a: ptr cpBody;
                            b: ptr cpBody; min: cpFloat; max: cpFloat): ptr cpRotaryLimitJoint {.
    importc: "cpRotaryLimitJointInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a damped rotary limit joint.

proc cpRotaryLimitJointNew*(a: ptr cpBody; b: ptr cpBody; min: cpFloat; max: cpFloat): ptr cpConstraint {.
    importc: "cpRotaryLimitJointNew", header: "<chipmunk/chipmunk.h>".}
## / Get the minimum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointGetMin*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRotaryLimitJointGetMin", header: "<chipmunk/chipmunk.h>".}
## / Set the minimum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointSetMin*(constraint: ptr cpConstraint; min: cpFloat) {.
    importc: "cpRotaryLimitJointSetMin", header: "<chipmunk/chipmunk.h>".}
## / Get the maximum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointGetMax*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRotaryLimitJointGetMax", header: "<chipmunk/chipmunk.h>".}
## / Set the maximum distance the joint will maintain between the two anchors.

proc cpRotaryLimitJointSetMax*(constraint: ptr cpConstraint; max: cpFloat) {.
    importc: "cpRotaryLimitJointSetMax", header: "<chipmunk/chipmunk.h>".}
## / @}

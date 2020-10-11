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
## / @defgroup cpPinJoint cpPinJoint
## / @{
## / Check if a constraint is a pin joint.

proc cpConstraintIsPinJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsPinJoint", header: "<chipmunk/chipmunk.h>".}
## / Allocate a pin joint.

proc cpPinJointAlloc*(): ptr cpPinJoint {.importc: "cpPinJointAlloc",
                                      header: "<chipmunk/chipmunk.h>".}
## / Initialize a pin joint.

proc cpPinJointInit*(joint: ptr cpPinJoint; a: ptr cpBody; b: ptr cpBody; anchorA: cpVect;
                    anchorB: cpVect): ptr cpPinJoint {.importc: "cpPinJointInit",
    header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a pin joint.

proc cpPinJointNew*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect): ptr cpConstraint {.
    importc: "cpPinJointNew", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the first anchor relative to the first body.

proc cpPinJointGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPinJointGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the first anchor relative to the first body.

proc cpPinJointSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpPinJointSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the second anchor relative to the second body.

proc cpPinJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPinJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the second anchor relative to the second body.

proc cpPinJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpPinJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Get the distance the joint will maintain between the two anchors.

proc cpPinJointGetDist*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpPinJointGetDist", header: "<chipmunk/chipmunk.h>".}
## / Set the distance the joint will maintain between the two anchors.

proc cpPinJointSetDist*(constraint: ptr cpConstraint; dist: cpFloat) {.
    importc: "cpPinJointSetDist", header: "<chipmunk/chipmunk.h>".}
## /@}

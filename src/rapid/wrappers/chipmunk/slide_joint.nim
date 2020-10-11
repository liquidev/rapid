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
## / @defgroup cpSlideJoint cpSlideJoint
## / @{
## / Check if a constraint is a slide joint.

proc cpConstraintIsSlideJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsSlideJoint", header: "<chipmunk/chipmunk.h>".}
## / Allocate a slide joint.

proc cpSlideJointAlloc*(): ptr cpSlideJoint {.importc: "cpSlideJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / Initialize a slide joint.

proc cpSlideJointInit*(joint: ptr cpSlideJoint; a: ptr cpBody; b: ptr cpBody;
                      anchorA: cpVect; anchorB: cpVect; min: cpFloat; max: cpFloat): ptr cpSlideJoint {.
    importc: "cpSlideJointInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a slide joint.

proc cpSlideJointNew*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect;
                     min: cpFloat; max: cpFloat): ptr cpConstraint {.
    importc: "cpSlideJointNew", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the first anchor relative to the first body.

proc cpSlideJointGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpSlideJointGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the first anchor relative to the first body.

proc cpSlideJointSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpSlideJointSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the second anchor relative to the second body.

proc cpSlideJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpSlideJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the second anchor relative to the second body.

proc cpSlideJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpSlideJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Get the minimum distance the joint will maintain between the two anchors.

proc cpSlideJointGetMin*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpSlideJointGetMin", header: "<chipmunk/chipmunk.h>".}
## / Set the minimum distance the joint will maintain between the two anchors.

proc cpSlideJointSetMin*(constraint: ptr cpConstraint; min: cpFloat) {.
    importc: "cpSlideJointSetMin", header: "<chipmunk/chipmunk.h>".}
## / Get the maximum distance the joint will maintain between the two anchors.

proc cpSlideJointGetMax*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpSlideJointGetMax", header: "<chipmunk/chipmunk.h>".}
## / Set the maximum distance the joint will maintain between the two anchors.

proc cpSlideJointSetMax*(constraint: ptr cpConstraint; max: cpFloat) {.
    importc: "cpSlideJointSetMax", header: "<chipmunk/chipmunk.h>".}
## / @}

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
## / @defgroup cpPivotJoint cpPivotJoint
## / @{
## / Check if a constraint is a slide joint.

proc cpConstraintIsPivotJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsPivotJoint", header: "<chipmunk/chipmunk.h>".}
## / Allocate a pivot joint

proc cpPivotJointAlloc*(): ptr cpPivotJoint {.importc: "cpPivotJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / Initialize a pivot joint.

proc cpPivotJointInit*(joint: ptr cpPivotJoint; a: ptr cpBody; b: ptr cpBody;
                      anchorA: cpVect; anchorB: cpVect): ptr cpPivotJoint {.
    importc: "cpPivotJointInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a pivot joint.

proc cpPivotJointNew*(a: ptr cpBody; b: ptr cpBody; pivot: cpVect): ptr cpConstraint {.
    importc: "cpPivotJointNew", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a pivot joint with specific anchors.

proc cpPivotJointNew2*(a: ptr cpBody; b: ptr cpBody; anchorA: cpVect; anchorB: cpVect): ptr cpConstraint {.
    importc: "cpPivotJointNew2", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the first anchor relative to the first body.

proc cpPivotJointGetAnchorA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPivotJointGetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the first anchor relative to the first body.

proc cpPivotJointSetAnchorA*(constraint: ptr cpConstraint; anchorA: cpVect) {.
    importc: "cpPivotJointSetAnchorA", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the second anchor relative to the second body.

proc cpPivotJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpPivotJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the second anchor relative to the second body.

proc cpPivotJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpPivotJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / @}

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
## / @defgroup cpGrooveJoint cpGrooveJoint
## / @{
## / Check if a constraint is a slide joint.

proc cpConstraintIsGrooveJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsGrooveJoint", header: "<chipmunk/chipmunk.h>".}
## / Allocate a groove joint.

proc cpGrooveJointAlloc*(): ptr cpGrooveJoint {.importc: "cpGrooveJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / Initialize a groove joint.

proc cpGrooveJointInit*(joint: ptr cpGrooveJoint; a: ptr cpBody; b: ptr cpBody;
                       groove_a: cpVect; groove_b: cpVect; anchorB: cpVect): ptr cpGrooveJoint {.
    importc: "cpGrooveJointInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a groove joint.

proc cpGrooveJointNew*(a: ptr cpBody; b: ptr cpBody; groove_a: cpVect; groove_b: cpVect;
                      anchorB: cpVect): ptr cpConstraint {.
    importc: "cpGrooveJointNew", header: "<chipmunk/chipmunk.h>".}
## / Get the first endpoint of the groove relative to the first body.

proc cpGrooveJointGetGrooveA*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpGrooveJointGetGrooveA", header: "<chipmunk/chipmunk.h>".}
## / Set the first endpoint of the groove relative to the first body.

proc cpGrooveJointSetGrooveA*(constraint: ptr cpConstraint; grooveA: cpVect) {.
    importc: "cpGrooveJointSetGrooveA", header: "<chipmunk/chipmunk.h>".}
## / Get the first endpoint of the groove relative to the first body.

proc cpGrooveJointGetGrooveB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpGrooveJointGetGrooveB", header: "<chipmunk/chipmunk.h>".}
## / Set the first endpoint of the groove relative to the first body.

proc cpGrooveJointSetGrooveB*(constraint: ptr cpConstraint; grooveB: cpVect) {.
    importc: "cpGrooveJointSetGrooveB", header: "<chipmunk/chipmunk.h>".}
## / Get the location of the second anchor relative to the second body.

proc cpGrooveJointGetAnchorB*(constraint: ptr cpConstraint): cpVect {.
    importc: "cpGrooveJointGetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / Set the location of the second anchor relative to the second body.

proc cpGrooveJointSetAnchorB*(constraint: ptr cpConstraint; anchorB: cpVect) {.
    importc: "cpGrooveJointSetAnchorB", header: "<chipmunk/chipmunk.h>".}
## / @}

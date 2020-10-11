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
## / @defgroup cpGearJoint cpGearJoint
## / @{
## / Check if a constraint is a damped rotary springs.

proc cpConstraintIsGearJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsGearJoint", header: "<chipmunk/chipmunk.h>".}
## / Allocate a gear joint.

proc cpGearJointAlloc*(): ptr cpGearJoint {.importc: "cpGearJointAlloc",
                                        header: "<chipmunk/chipmunk.h>".}
## / Initialize a gear joint.

proc cpGearJointInit*(joint: ptr cpGearJoint; a: ptr cpBody; b: ptr cpBody;
                     phase: cpFloat; ratio: cpFloat): ptr cpGearJoint {.
    importc: "cpGearJointInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a gear joint.

proc cpGearJointNew*(a: ptr cpBody; b: ptr cpBody; phase: cpFloat; ratio: cpFloat): ptr cpConstraint {.
    importc: "cpGearJointNew", header: "<chipmunk/chipmunk.h>".}
## / Get the phase offset of the gears.

proc cpGearJointGetPhase*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpGearJointGetPhase", header: "<chipmunk/chipmunk.h>".}
## / Set the phase offset of the gears.

proc cpGearJointSetPhase*(constraint: ptr cpConstraint; phase: cpFloat) {.
    importc: "cpGearJointSetPhase", header: "<chipmunk/chipmunk.h>".}
## / Get the angular distance of each ratchet.

proc cpGearJointGetRatio*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpGearJointGetRatio", header: "<chipmunk/chipmunk.h>".}
## / Set the ratio of a gear joint.

proc cpGearJointSetRatio*(constraint: ptr cpConstraint; ratio: cpFloat) {.
    importc: "cpGearJointSetRatio", header: "<chipmunk/chipmunk.h>".}
## / @}

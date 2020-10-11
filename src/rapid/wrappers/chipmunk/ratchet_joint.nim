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
## / @defgroup cpRatchetJoint cpRatchetJoint
## / @{
## / Check if a constraint is a damped rotary springs.

proc cpConstraintIsRatchetJoint*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsRatchetJoint", header: "<chipmunk/chipmunk.h>".}
## / Allocate a ratchet joint.

proc cpRatchetJointAlloc*(): ptr cpRatchetJoint {.importc: "cpRatchetJointAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / Initialize a ratched joint.

proc cpRatchetJointInit*(joint: ptr cpRatchetJoint; a: ptr cpBody; b: ptr cpBody;
                        phase: cpFloat; ratchet: cpFloat): ptr cpRatchetJoint {.
    importc: "cpRatchetJointInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a ratchet joint.

proc cpRatchetJointNew*(a: ptr cpBody; b: ptr cpBody; phase: cpFloat; ratchet: cpFloat): ptr cpConstraint {.
    importc: "cpRatchetJointNew", header: "<chipmunk/chipmunk.h>".}
## / Get the angle of the current ratchet tooth.

proc cpRatchetJointGetAngle*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRatchetJointGetAngle", header: "<chipmunk/chipmunk.h>".}
## / Set the angle of the current ratchet tooth.

proc cpRatchetJointSetAngle*(constraint: ptr cpConstraint; angle: cpFloat) {.
    importc: "cpRatchetJointSetAngle", header: "<chipmunk/chipmunk.h>".}
## / Get the phase offset of the ratchet.

proc cpRatchetJointGetPhase*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRatchetJointGetPhase", header: "<chipmunk/chipmunk.h>".}
## / Get the phase offset of the ratchet.

proc cpRatchetJointSetPhase*(constraint: ptr cpConstraint; phase: cpFloat) {.
    importc: "cpRatchetJointSetPhase", header: "<chipmunk/chipmunk.h>".}
## / Get the angular distance of each ratchet.

proc cpRatchetJointGetRatchet*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpRatchetJointGetRatchet", header: "<chipmunk/chipmunk.h>".}
## / Set the angular distance of each ratchet.

proc cpRatchetJointSetRatchet*(constraint: ptr cpConstraint; ratchet: cpFloat) {.
    importc: "cpRatchetJointSetRatchet", header: "<chipmunk/chipmunk.h>".}
## / @}

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
## / @defgroup cpSimpleMotor cpSimpleMotor
## / @{
## / Opaque struct type for damped rotary springs.

type
  cpSimpleMotor* {.importc, incompleteStruct.} = object

## / Check if a constraint is a damped rotary springs.

proc cpConstraintIsSimpleMotor*(constraint: ptr cpConstraint): cpBool {.
    importc: "cpConstraintIsSimpleMotor", header: "<chipmunk/chipmunk.h>".}
## / Allocate a simple motor.

proc cpSimpleMotorAlloc*(): ptr cpSimpleMotor {.importc: "cpSimpleMotorAlloc",
    header: "<chipmunk/chipmunk.h>".}
## / initialize a simple motor.

proc cpSimpleMotorInit*(joint: ptr cpSimpleMotor; a: ptr cpBody; b: ptr cpBody;
                       rate: cpFloat): ptr cpSimpleMotor {.
    importc: "cpSimpleMotorInit", header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a simple motor.

proc cpSimpleMotorNew*(a: ptr cpBody; b: ptr cpBody; rate: cpFloat): ptr cpConstraint {.
    importc: "cpSimpleMotorNew", header: "<chipmunk/chipmunk.h>".}
## / Get the rate of the motor.

proc cpSimpleMotorGetRate*(constraint: ptr cpConstraint): cpFloat {.
    importc: "cpSimpleMotorGetRate", header: "<chipmunk/chipmunk.h>".}
## / Set the rate of the motor.

proc cpSimpleMotorSetRate*(constraint: ptr cpConstraint; rate: cpFloat) {.
    importc: "cpSimpleMotorSetRate", header: "<chipmunk/chipmunk.h>".}
## / @}

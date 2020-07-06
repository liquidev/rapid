## Mathematical units and type-safe function wrappers.

import std/macros
import std/math
import std/strutils

type
  Radians* = distinct float32
  Degrees* = distinct float32

func radians*(value: float32): Radians =
  ## Converts a float value to radians.
  value.Radians

func degrees*(value: float32): Degrees =
  ## Converts a float value to degrees.
  value.Degrees

converter toRadians*(degrees: Degrees): Radians =
  ## Converter from degrees to radians.
  radians(degrees.float32.degToRad)

converter toDegrees*(radians: Radians): Degrees =
  ## Converter from radians to degrees.
  degrees(radians.float32.radToDeg)

macro wrapTrig(): untyped =
  result = newStmtList()
  for baseName in ["sin", "cos", "tan", "cot", "sec", "csc"]:
    for deriv in ["$1", "$1h", "arc$1", "arc$1h"]:
      let name = ident(deriv % baseName)
      var doc = newNimNode(nnkCommentStmt)
      doc.strVal =
        "Type-safe wrapper for ``" & name.repr & "`` trigonometric function."
      result.add quote do:
        func `name`*(x: Radians): float32 =
          `doc`
          `name`(x.float32)
wrapTrig

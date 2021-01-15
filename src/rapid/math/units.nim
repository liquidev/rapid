## Mathematical units and type-safe function wrappers.

import std/macros
import std/math
import std/strutils

type
  Radians* = distinct float32
  Degrees* = distinct float32

proc `$`*(radians: Radians): string {.inline.} = $radians.float32 & " rad"
proc `$`*(degrees: Degrees): string {.inline.} = $degrees.float32 & "°"

proc `-`*(x: Degrees): Degrees {.borrow.}
proc `+`*(a, b: Degrees): Degrees {.borrow.}
proc `-`*(a, b: Degrees): Degrees {.borrow.}
proc `*`*(a, b: Degrees): Degrees {.borrow.}
proc `/`*(a, b: Degrees): Degrees {.borrow.}
proc `==`*(a, b: Degrees): bool {.borrow.}
proc `<`*(a, b: Degrees): bool {.borrow.}
proc `<=`*(a, b: Degrees): bool {.borrow.}

proc `-`*(x: Radians): Radians {.borrow.}
proc `+`*(a, b: Radians): Radians {.borrow.}
proc `-`*(a, b: Radians): Radians {.borrow.}
proc `*`*(a, b: Radians): Radians {.borrow.}
proc `/`*(a, b: Radians): Radians {.borrow.}
proc `==`*(a, b: Radians): bool {.borrow.}
proc `<`*(a, b: Radians): bool {.borrow.}
proc `<=`*(a, b: Radians): bool {.borrow.}

converter toRadians*(degrees: Degrees): Radians {.inline.} =
  ## Converter from degrees to radians.
  Radians(degrees.float32.degToRad)

converter toDegrees*(radians: Radians): Degrees {.inline.} =
  ## Converter from radians to degrees.
  Degrees(radians.float32.radToDeg)

macro wrapTrig(): untyped =
  result = newStmtList()
  for baseName in ["sin", "cos", "tan", "cot", "sec", "csc"]:
    for deriv in ["$1", "$1h", "arc$1", "arc$1h"]:
      let
        name = ident(deriv % baseName)
        x = ident"x"  # prevent x`gensym1283719203709821370973921 ugliness
      var doc = newNimNode(nnkCommentStmt)
      doc.strVal =
        "Type-safe wrapper for ``" & name.repr & "`` trigonometric function."
      result.add quote do:
        func `name`*(`x`: Radians): float32 {.inline.} =
          `doc`
          result = `name`(`x`.float32)
wrapTrig

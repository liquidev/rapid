## This module compiles Chipmunk2D without using CMake.
## Included by ``wrappers/chipmunk``, do not use directly.

import std/macros
import std/os

const
  Parent = currentSourcePath.splitPath().head & "/.."
  Freetype = Parent & "/extern/chipmunk"
  Include = Freetype & "/include"
  Src = Freetype & "/src"
{.passC: "-I" & Include.}

# TODO: remove this passC bloat mess when nim 1.4 is released

# set up types

when defined(rapidChipmunkUseFloat64):
  {.passC: "-DCP_USE_DOUBLES=1".}
else:
  {.passC: "-DCP_USE_DOUBLES=0".}

{.passC: "-DCP_COLLISION_TYPE_TYPE=uint16_t".}
{.passC: "-DCP_BITMASK_TYPE=uint64_t".}

# disable debug messages because they're annoying
# this also disables runtime assertions which is a bit trash but i don't want
# chipmunk spamming my console output
# DEAR LIBRARY DEVELOPERS: DON'T WRITE TO STDOUT IN YOUR LIBRARIES.
# SIGNED, LQDEV
# 11 OCTOBER 2020

{.passC: "-DNDEBUG".}

macro genCompiles: untyped =
  var
    compileList = @[
      "chipmunk.c",
      "cpArbiter.c",
      "cpArray.c",
      "cpBBTree.c",
      "cpBody.c",
      "cpCollision.c",
      "cpConstraint.c",
      "cpDampedRotarySpring.c",
      "cpDampedSpring.c",
      "cpGearJoint.c",
      "cpGrooveJoint.c",
      "cpHashSet.c",
      "cpMarch.c",
      "cpPinJoint.c",
      "cpPivotJoint.c",
      "cpPolyShape.c",
      "cpPolyline.c",
      "cpRatchetJoint.c",
      "cpRobust.c",
      "cpRotaryLimitJoint.c",
      "cpShape.c",
      "cpSimpleMotor.c",
      "cpSlideJoint.c",
      "cpSpace.c",
      "cpSpaceComponent.c",
      "cpSpaceDebug.c",
      "cpSpaceHash.c",
      "cpSpaceQuery.c",
      "cpSpaceStep.c",
      "cpSpatialIndex.c",
      "cpSweep1D.c",
    ]
  when compileOption("threads"):
    compileList.add "cpHastySpace.c"
  var pragmas = newNimNode(nnkPragma)
  for file in compileList:
    pragmas.add(newColonExpr(ident"compile", newLit(Src & "/" & file)))
  result = newStmtList(pragmas)
genCompiles

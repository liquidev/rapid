## ``ecs`` macro for creating ECS worlds.

import std/macros

import system_macro

macro ecs*(body: untyped{nkStmtList}) =
  ## Generates an ECS world.

  result = newStmtList()

when isMainModule:
  discard

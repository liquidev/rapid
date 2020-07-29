## Common symbols used both by system_macro and ecs_macro.

import std/macros
import std/tables

type
  SystemImpl* = object
    ## System endpoint implementation.
    abstract*: NimNode
      # abstract, untyped implementation
    concrete*: NimNode
      # typed implementation with all the requires in params

  SystemInfo* = object
    doc*: string
      # documentation string
    requires*: seq[NimNode]
      # list of nnkIdentDefs containing all the required components
    implements*: seq[SystemImpl]
      # list of nnkProcDef containing all the implemented sysinterface procs

  EntityBase* = uint32
    ## Type used for entity ID storage.

  AtEntity* = distinct EntityBase

proc extractVarType*(maybeVar: NimNode): NimNode =
  ## Extracts a type from a ``var`` expression.

  if maybeVar.kind == nnkVarTy: maybeVar[0]
  else: maybeVar

var ecsSystems* {.compileTime.}: Table[string, SystemInfo]
  ## Registry storing all the available ECS systems.

proc getConcrete*(impl: NimNode, sys: SystemInfo,
                  entityType, worldType: NimNode = nil): NimNode =
  ## Gets the concrete implementation of the ``sys``'s endpoint
  ## implementation ``impl``.

  result = copy(impl)
  if result[0].kind == nnkPostfix:
    hint("export marker is unnecessary", result[0][0])
    result[0] = result[0][1]
  result.addPragma(ident"used")
  result.addPragma(ident"nimcall")  # force it to be non-closure
  for req in sys.requires:
    let
      name = req[0]
      fullType = req[1].extractVarType()
      typeSym =
        if fullType.eqIdent("@entity"):
          if entityType != nil: entityType
          else: bindSym"AtEntity"
        elif fullType.eqIdent("@world"):
          if worldType != nil: worldType
          else: return nil
        else: fullType
      ty =
        if req[1].kind == nnkVarTy: newTree(nnkVarTy, typeSym)
        else: typeSym
    result.params.add(newIdentDefs(name, ty))

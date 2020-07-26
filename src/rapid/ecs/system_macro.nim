## ``system`` macro for defining ECS systems.

import std/macros
import std/strformat
import std/strutils
import std/tables

type
  EcsSystemInfo* = object
    doc*: string
      # documentation string
    requires*: seq[NimNode]
      # list of nnkIdentDefs containing all the required components
    implements*: seq[NimNode]
      # list of nnkProcDef containing all the implemented sysinterface procs

var ecsSystems* {.compileTime.}: Table[string, EcsSystemInfo]
  ## Registry storing all the available ECS systems.

macro addRequire(sysName: static string,
                 name: untyped{ident}, ty: typed{sym}) =
  ## Auxiliary macro used to resolve the type ``ty`` before adding a require to
  ## a system.

  if ty.symKind != nskType:
    error("type expected", ty)
  ecsSystems[sysName].requires.add(newIdentDefs(name, ty))

proc genDocComment(sys: EcsSystemInfo): NimNode =
  ## Generates a doc comment for a system.

  const
    RequiresHeader = "Requires:"
    ImplementsHeader = "Implements:"

  var doc = sys.doc.strip

  doc.add(&"\n\n**{RequiresHeader}** ")
  for i, req in sys.requires:
    let
      ty = req[1]
      owner = ty.owner
      name =
        if owner != nil and owner.symKind == nskModule:
          fmt"{owner.repr}.{ty.repr}"
        else:
          ty.repr
    doc.add(&"``{name}``")
    if i != sys.requires.len - 1:
      doc.add(", ")

  doc.add(&"\n\n**{ImplementsHeader}**\n\n")
  doc.add(".. code-block:: nim")
  for i, impl in sys.implements:
    var decl = copy(impl)
    decl[^1] = newEmptyNode()
    doc.add("\n " & decl.repr)

  result = newNimNode(nnkCommentStmt)
  result.strVal = doc

macro genSystemDoc(sysName: static string) =
  ## Generates a dummy const with a system's documentation.

  let sys = ecsSystems[sysName]
  result = newProc(name = postfix(ident("system:" & sysName), "*"))
  result.body.add(genDocComment(sys))
  result.addPragma(newColonExpr(ident"error",
                                newLit("systems cannot be called")))

macro system*(name: untyped{ident}, body: untyped{nkStmtList}) =
  ## Defines an ECS system. The body accepts:
  ##
  ## - doc comments describing the system's behavior
  ## - a list of name-component bindings for components required by the system
  ##   (type names are without the ``Comp`` prefix)
  ## - any number of implemented system interface procedures (endpoints).
  ##
  ## Implemented system interface procedures may use the special ``world`` and
  ## ``entity`` ``usings``. These ``usings`` are added implicitly by the ``ecs``
  ## macro.
  ##
  ## The macro will generate documentation about the system's requires and
  ## endpoints. Unfortunately, Nim does not allow for easily creating your own
  ## doc sections, so the documentation is put under the Procs section, and the
  ## procedure's name is prefixed with ``system:``. The resulting ``proc``
  ## cannot be called—attempting to do so will result in a compilation error.

  runnableExamples:
    import rapid/ecs/components/physics

    system exampleGravity:
      requires:
        physics: PhysicsBody
        gravity: Gravity

      proc update*(world; entity; step: float32) =
        physics.acceleration += gravity.gravity

  let sysName = name.strVal
  result = newStmtList()
  if sysName in ecsSystems:
    error("redefinition of system " & sysName, name)
  var sys = EcsSystemInfo()

  var requireList: NimNode

  for stmt in body:
    stmt.expectKind({nnkCall, nnkProcDef, nnkCommentStmt})
    case stmt.kind
    of nnkCall:
      stmt[0].expectIdent("requires")
      requireList = stmt[1]
    of nnkProcDef:
      sys.implements.add(stmt)
    of nnkCommentStmt:
      sys.doc.add(stmt.strVal & '\n')
    else: assert false, "unreachable"

  for req in requireList:
                                    # the following statemeot checks:
    req.expectKind(nnkCall)         # a: T
    req[0].expectKind(nnkIdent)     # a
    req[1].expectKind(nnkStmtList)  # : T
    req[1].expectLen(1)
    req[1][0].expectKind(nnkIdent)  # T

    let
      compName = req[0]
      ty = ident(req[1][0].strVal)

    result.add(newCall(bindSym"addRequire", newLit(sysName), compName, ty))

  ecsSystems[sysName] = sys
  result.add(newCall(bindSym"genSystemDoc", newLit(sysName)))

import components/physics

when isMainModule:
  import components/physics

  system applyGravity:
    ## Applies gravity to physics bodies.

    requires:
      physics: PhysicsBody
      gravity: Gravity

    proc update*(world; entity; step: float32) =
      physics.acceleration += gravity

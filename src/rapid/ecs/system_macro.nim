## ``system`` macro for defining ECS systems.

import std/macros
import std/strformat
import std/strutils
import std/tables

type
  EcsSystemInfo* = object
    doc: string
      # documentation string
    requires*: seq[NimNode]
      # list of nnkIdentDefs containing all the required components
    implements*: seq[NimNode]
      # list of nnkProcDef containing all the implemented sysinterface procs
    earlyTypecheck: bool
      # whether the system can be typechecked early

  EntityBase* = uint32
    ## Type used for entity ID storage.

  AtEntity = distinct EntityBase

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
    let ty = req[1]
    if ty.kind != nnkSym: continue
    let
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

macro semcheck(what: typed) =
  ## Doesn't do anything. Accepts a ``typed`` and discards it.
  ## Passing an untyped AST to a macro that accepts typed AST has an extra
  ## effect, though: it forces the AST to go through a semcheck. That's how the
  ## ``system`` macro manages to do typechecking on implemented system interface
  ## procedures.
  discard

macro checkSystem(sysName: static string) =
  ## Type checks a system's procedures.

  result = newStmtList()

  let sys = ecsSystems[sysName]
  if not sys.earlyTypecheck: return

  for impl in sys.implements:
    var theProc = copy(impl)
    if theProc[0].kind == nnkPostfix:
      theProc[0] = theProc[0][1]
    theProc.addPragma(ident"used")
    for req in sys.requires:
      let
        name = req[0]
        ty =
          if req[1].strVal == "@entity": bindSym"AtEntity"
          else: newTree(nnkVarTy, req[1])
      theProc.params.add(newIdentDefs(name, ty))
    result.add(newCall(bindSym"semcheck", newBlockStmt(theProc)))

macro system*(name: untyped{ident}, body: untyped{nkStmtList}) =
  ## Defines an ECS system. The body accepts:
  ##
  ## - doc comments describing the system's behavior
  ## - a list of name-component bindings for components required by the system.
  ##   two special bindings may be used: ``<name>: @world``, and
  ##   ``<name>: @entity``. these refer to the world and entity types generated
  ##   by the ECS macro.
  ## - any number of implemented system interface procedures (endpoints).
  ##
  ## The macro will generate documentation about the system's requires and
  ## endpoints. Unfortunately, Nim does not allow for easily creating your own
  ## doc sections, so the documentation is put under the Procs section, and the
  ## procedure's name is prefixed with ``system:``. The resulting ``proc``
  ## cannot be called—attempting to do so will result in a compilation error.
  ##
  ## **Remarks:**
  ##
  ## Requiring an ``@entity`` without a ``@world`` is pretty much useless,
  ## as all entity-related actions (such as getting components) also require
  ## the world the entity belongs to (as that's what stores all the
  ## actual data).
  ## Requiring a ``@world`` disables all declaration-time checks. Just like with
  ## generics, there's no way of knowing what the world type is—what components
  ## it has, what system interface procs it implements, etc.—so all early checks
  ## are delayed to the ``ecs`` macro.

  runnableExamples:
    import rapid/ecs/components/physics

    system exampleGravity:
      requires:
        physics: PhysicsBody
        gravity: Gravity

      proc update*(step: float32) =
        physics.acceleration += gravity.gravity

  let sysName = name.strVal
  result = newStmtList()
  if sysName in ecsSystems:
    error("redefinition of system " & sysName, name)
  var sys = EcsSystemInfo(earlyTypecheck: true)

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
    req.expectKind(nnkCall)                      # a: T
    req[0].expectKind({nnkIdent, nnkAccQuoted})  # a
    req[1].expectKind(nnkStmtList)               # : T
    req[1].expectLen(1)
    req[1][0].expectKind({nnkIdent, nnkPrefix})  # T
    if req[1][0].kind == nnkPrefix:
      req[1][0][0].expectIdent("@")
      req[1][0][1].expectKind(nnkIdent)

    let
      compName = req[0]
      ty = req[1][0]
    if ty.kind == nnkIdent:
      result.add(newCall(bindSym"addRequire", newLit(sysName), compName, ty))
    else:
      if ty[1].strVal == "world":
        sys.earlyTypecheck = false
      sys.requires.add(newIdentDefs(compName, ident(ty.repr)))

  ecsSystems[sysName] = sys
  result.add(newCall(bindSym"genSystemDoc", newLit(sysName)))
  result.add(newCall(bindSym"checkSystem", newLit(sysName)))

when isMainModule:
  import glm/vec

  import components/physics

  system applyGravity:
    ## Applies gravity to physics bodies.

    requires:
      physics: PhysicsBody
      gravity: Gravity

    proc update*(step: float32) =
      physics.acceleration += gravity.force

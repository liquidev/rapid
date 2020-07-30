## ``system`` macro for defining ECS systems.

import std/macros
import std/strformat
import std/strutils
import std/tables

import common

macro addRequire(sysName: static string,
                 name: untyped{ident}, fullType: typed) =
  ## Auxiliary macro used to resolve the type ``ty`` before adding a require to
  ## a system.

  let ty = fullType.extractVarType()
  if ty.symKind != nskType:
    error("type expected", ty)
  ecsSystems[sysName].requires.add(newIdentDefs(name, fullType))

proc genDocComment(sys: SystemInfo): NimNode =
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
    var decl = copy(impl.abstract)
    decl[^1] = newEmptyNode()
    doc.add("\n " & decl.repr)

  result = newNimNode(nnkCommentStmt)
  result.strVal = doc

macro genSystemDoc(sysName: static string) =
  ## Generates a dummy const with a system's documentation.

  let sys = ecsSystems[sysName]
  result = newProc(name = postfix(ident("system:" & sysName), "*"))
  result.body.add(genDocComment(sys))
  # ↓ unfortunately this is not possible, since it doesn't play well with
  # ecs_macro.useSym
  # result.addPragma(newColonExpr(ident"error",
  #                               newLit("systems cannot be called")))

macro semcheckEndpointImpl(sysName: static string, implIndex: static int,
                           blockWithProc: typed) =
  ## Semchecks an endpoint implementation and saves it in the ``concrete`` field
  ## of ``ecsSystem[sysName].implements[implIndex]``.

  blockWithProc.expectKind({nnkBlockStmt, nnkBlockExpr})
  # skip if the concrete implementation is nil (because @world was used)
  if blockWithProc.kind == nnkBlockExpr:
    return
  blockWithProc[1].expectKind(nnkProcDef)

  ecsSystems[sysName].implements[implIndex].concrete = blockWithProc[1]

macro checkSystem(sysName: static string) =
  ## Type checks a system's procedures.

  result = newStmtList()

  let sys = ecsSystems[sysName]
  for index, impl in sys.implements:
    if impl.abstract.params[0].kind != nnkEmpty:
      error("endpoint implementations must not return anything",
            impl.abstract.params[0])
    let concrete = getConcrete(impl.abstract, sys)
    result.add(newCall(bindSym"semcheckEndpointImpl",
                       newLit(sysName), newLit(index), newBlockStmt(concrete)))

macro system*(name: untyped{ident}, body: untyped{nkStmtList}) =
  ## Defines an ECS system. The body accepts:
  ##
  ## - doc comments describing the system's behavior
  ## - a list of name-component bindings for components required by the system.
  ##   these take the form of ``var`` or ``let`` variable declarations, eg.
  ##   ``let gravity: Gravity`` and ``var physics: PhysicsBody``. ``var``
  ##   signifies that the component will be mutated, and ``let`` signifies that
  ##   the component will only be read.
  ##   two special bindings may be used: ``<name>: @world``, and
  ##   ``<name>: @entity``. these refer to the world and entity types generated
  ##   by the ECS macro.
  ## - any number of implemented system interface procedures (endpoints).
  ##   these may use any requires declared in the ``requires`` section.
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
  ## are delayed to the ``ecs`` macro. This has the drawback of symbols not
  ## being bound early, so usage of any symbols from external modules will also
  ## require these modules to be imported in the module that declares the ECS
  ## world.

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
  var sys = SystemInfo()

  var requireList: NimNode

  for stmt in body:
    stmt.expectKind({nnkCall, nnkProcDef, nnkCommentStmt})
    case stmt.kind
    of nnkCall:
      stmt[0].expectIdent("requires")
      requireList = stmt[1]
    of nnkProcDef:
      sys.implements.add(SystemImpl(abstract: stmt))
    of nnkCommentStmt:
      sys.doc.add(stmt.strVal & '\n')
    else: assert false, "unreachable"

  if requireList == nil:
    error("missing require list", body)

  proc require(result: var NimNode, paramName, ty: NimNode, isVar: bool) =
    if ty.kind == nnkIdent:
      let varTy =
        if isVar: newTree(nnkVarTy, ty)
        else: ty
      result.add(newCall(bindSym"addRequire", newLit(sysName),
                         paramName, varTy))
    else:
      let varTy =
        if isVar: newTree(nnkVarTy, ident(ty.repr))
        else: ident(ty.repr)
      sys.requires.add(newIdentDefs(paramName, varTy))

  for req in requireList:
    req.expectKind({nnkVarSection, nnkLetSection})
    for defs in req:
      defs[0].expectKind({nnkIdent, nnkAccQuoted})
      defs[1].expectKind({nnkIdent, nnkPrefix})
      defs[2].expectKind(nnkEmpty)
      let
        paramName = defs[0]
        ty = defs[1]
      result.require(paramName, ty, isVar = req.kind == nnkVarSection)

  ecsSystems[sysName] = sys
  result.add(newCall(bindSym"genSystemDoc", newLit(sysName)))
  result.add(newCall(bindSym"checkSystem", newLit(sysName)))

when isMainModule:
  import glm/vec

  import components/physics

  system applyGravity:
    ## Applies gravity to physics bodies.

    requires:
      var physics: PhysicsBody
      let gravity: Gravity

    proc update() =
      physics.acceleration += gravity.force

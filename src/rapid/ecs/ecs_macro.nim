## ``ecs`` macro for creating ECS worlds.

import std/macros
import std/tables

import system_macro

type
  Endpoint = object
    impl: NimNode
    signature: NimNode

macro useSyms(sym: varargs[typed]) =
  ## Shuts the compiler up about unused symbols.
  ## ``discard`` can't be used for this as it raises an error.

proc useSystems(systemList: NimNode): NimNode =
  ## Generates a ``useSyms`` call to shut up the compiler about unused
  ## imports.

  result = newCall(bindSym"useSyms")
  for sysName in systemList:
    if sysName.strVal notin ecsSystems:
      error("undeclared system " & sysName.strVal, sysName)
    let procName = ident("system:" & sysName.strVal)
    procName.copyLineInfo(sysName)
    result.add(procName)

proc genHasEnum(typeName, componentList: NimNode): NimNode =
  ## Generates the EntityHas enum from a list of components.

  result = newTree(nnkEnumTy, newEmptyNode())

  for comp in componentList:
    result.add(comp)

proc genWorldObject(typeName, componentList, entityHas: NimNode): NimNode =
  ## Generates the @world object from a list of components.

  var fields = newNimNode(nnkRecList)

  let hasSet = newTree(nnkBracketExpr, ident"set", entityHas)
  fields.add(newIdentDefs(ident"entityComponents",
                          newTree(nnkBracketExpr, ident"seq", hasSet)))

  for comp in componentList:
    fields.add(newIdentDefs(ident("comp" & comp.repr),
                            newTree(nnkBracketExpr, bindSym"seq", comp)))

  result = newTree(nnkObjectTy, newEmptyNode(), newEmptyNode(), fields)

proc genTypeToHasEnumProc(entityHas, componentList: NimNode): NimNode =
  ## Generates a proc for converting ``type`` to ``EntityHas``.

  result = newProc(name = ident"toHasEnum",
                   params = [entityHas, newIdentDefs(ident"T", bindSym"type")])

  var whenStmt = newTree(nnkWhenStmt)
  for comp in componentList:
    let branch = newTree(nnkElifBranch, infix(ident"T", "is", comp),
                         newAssignment(ident"result",
                                       newDotExpr(entityHas, comp)))
    whenStmt.add(branch)
  whenStmt.add(newTree(nnkElse,
                       newTree(nnkPragma,
                               newColonExpr(ident"error",
                                            newLit("invalid component type")))))

  result.body.add(whenStmt)

proc genGetComponentProcs(worldType, entityType,
                          componentList: NimNode): NimNode =
  ## Generates the ``component`` and ``mcomponent`` procs for retrieving
  ## entities' components.

  result = newStmtList()

  proc make(name: string, returnTy: NimNode): NimNode =
    result = newProc(name = name.ident,
                     params = [returnTy,
                               newIdentDefs(ident"world", worldType),
                               newIdentDefs(ident"entity", entityType)])
    result[2] = newTree(nnkGenericParams,
                        newIdentDefs(ident"T", newEmptyNode()))

    result.body.add quote do:
      assert T.toHasEnum in world.entityComponents[entity.BaseEntity],
        "entity must have the given component"

    var whenStmt = newNimNode(nnkWhenStmt)
    for comp in componentList:
      var branch = newTree(nnkElifBranch, infix(ident"T", "is", comp))
      let
        components = newDotExpr(ident"world", ident("comp" & comp.repr))
        index = newDotExpr(ident"entity", bindSym"EntityBase")
        component = newTree(nnkBracketExpr, components, index)
        assignment = newAssignment(ident"result", component)
      branch.add(assignment)
      whenStmt.add(branch)
    result.body.add(whenStmt)

  result.add(make("component", ident"T"),
             make("mcomponent", newTree(nnkVarTy, ident"T")))

proc genBaseSysInterface(sysInterface, worldType: NimNode): seq[Endpoint] =
  ## Reads the system interface list and assembles base AST for endpoints.

  for signature in sysInterface:
    signature.expectKind(nnkProcDef)
    if signature.params[0].kind != nnkEmpty:
      error("endpoints must not return anything", signature.params[0])

    var impl = copy(signature)
    impl.params.insert(1, newIdentDefs(ident"world", worldType))
    impl.body =
      if impl.body.kind == nnkEmpty: newStmtList()
      else: newStmtList(impl.body)

    result.add(Endpoint(impl: impl, signature: signature))

proc stripExportMarker(name: NimNode): NimNode =
  ## Strips the * export marker off a node.
  if name.kind == nnkPostfix: name[1]
  else: name

macro ecs*(body: untyped{nkStmtList}) =
  ## Generates an ECS world.

  result = newStmtList()

  var
    worldTypeName, entityTypeName: NimNode
    componentList, systemList, systemInterfaceList: NimNode

  for stmt in body:
    stmt.expectKind({nnkTypeSection, nnkCall})
    case stmt.kind
    of nnkTypeSection:
      for typedef in stmt:
        typedef[1].expectKind(nnkEmpty)
        typedef[2].expectKind(nnkPrefix)
        typedef[2][0].expectIdent("@")
        typedef[2][1].expectKind(nnkIdent)
        let what = typedef[2][1]
        if what.eqIdent("world"):
          worldTypeName = typedef[0]
        elif what.eqIdent("entity"):
          entityTypeName = typedef[0]
    of nnkCall:
      stmt[0].expectKind(nnkIdent)
      stmt[1].expectKind(nnkStmtList)
      if stmt[0].eqIdent("components"):
        componentList = stmt[1]
      elif stmt[0].eqIdent("systems"):
        systemList = stmt[1]
      elif stmt[0].eqIdent("systemInterface"):
        systemInterfaceList = stmt[1]
    else: assert false, "unreachable"

  if worldTypeName == nil: error("missing @world type", body)
  if entityTypeName == nil: error("missing @entity type", body)
  if componentList == nil: error("missing components list", body)
  if systemList == nil: error("missing systems list", body)
  if systemInterfaceList == nil: error("missing systemInterface list", body)

  let
    worldType = stripExportMarker(worldTypeName)
    entityType = stripExportMarker(entityTypeName)

  result.add(useSystems(systemList))

  let
    entityHasName = ident(entityType.strVal & "Has")
    entityHasEnum = genHasEnum(entityType, componentList)
    worldObject = genWorldObject(worldType, componentList, entityHasName)
    typeToHasEnumProc = genTypeToHasEnumProc(entityHasName, componentList)
    getComponentProcs = genGetComponentProcs(worldType, entityType,
                                             componentList)

  result.add quote do:
    type
      `entityTypeName` = distinct EntityBase
      `entityHasName` {.pure.} = `entityHasEnum`
      `worldTypeName` = `worldObject`

    `typeToHasEnumProc`
    `getComponentProcs`

  let endpoints = genBaseSysInterface(systemInterfaceList, worldType)
  # do stuff

  for endpoint in endpoints:
    result.add(endpoint.impl)

  echo result.repr

when isMainModule:
  import components/basic
  import physics

  ecs:
    type
      World* = @world
      Entity* = @entity

    components:
      Position
      Size
      PhysicsBody
      Gravity

    systemInterface:
      proc update*() =
        ## Runs a single tick of updates.

    systems:
      tickPhysics
      applyGravity

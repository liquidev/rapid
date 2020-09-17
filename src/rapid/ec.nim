## Entity-component framework. Object oriented alternative to rapid/ecs for the
## time being, as rapid/ecs is not really usable at this point in time,
## and I don't have the knowledge nor time needed to continue its development.
##
## This framework assumes you're using the rapid/game module.

import std/macros

import aglet
import graphics/context

type
  RootComponent* {.byref.} = object of RootObj
    ## Empty component, base for inheriting from.
    ## Every component **must** implement an ``impl`` proc which fills out the
    ## ``impl`` field. This proc is later called by ``registerComponent``.

    impl*: ComponentImpl  ## interface implementation

  ComponentUpdate*[C: RootComponent] =
    proc (comp: var C) {.nimcall.}

  ComponentDraw*[C: RootComponent] =
    proc (comp: var C, target: Target, step: float32) {.nimcall.}

  ComponentRender*[C: RootComponent] =
    proc (comp: var C, target: Target, graphics: Graphics,
          step: float32) {.nimcall.}

  ComponentShape*[C: RootComponent] =
    proc (comp: var C, graphics: Graphics, step: float32) {.nimcall.}

  RC = RootComponent
  ComponentImpl* = object
    ## An object holding all the callbacks a component can implement.

    update*: ComponentUpdate[RC]
      ## Ticks the component once. This runs a fixed amount of times per second
      ## (60 by default, but this can change depending on the game).

    draw*: ComponentDraw[RC]
    render*: ComponentRender[RC]
    shape*: ComponentShape[RC]
      ## Components can implement either draw, render or shape,
      ## depending on the need. These endpoints are triggered by the respective
      ## Entity procs, and have the following semantics:
      ##
      ## - draw should be used when drawing raw aglet objects, eg. Meshes.
      ##   This is later called "aglet-drawing"
      ## - render should be used when you need a Graphics context but also need
      ##   to invoke a draw call. This is later called "rapid-rendering"
      ## - shape should be used when rendering using a Graphics context only.
      ##   This is later called "shape-rendering"

  RootEntity* = ref object of RootObj
    ## Empty entity, base for inheriting from.

    components: seq[ptr RootComponent]
      # ↑ a bit non-idiomatic, but should suffice until lent in object fields is
      # implemented. you don't use this directly anyways.


# component essentials

iterator components*(entity: RootEntity): var RootComponent =
  ## Iterates through the entity's registered components.

  for comp in entity.components:
    yield comp[]

proc registerComponent*[T: RootComponent](entity: RootEntity, comp: ptr T) =
  ## Registers an entity's component. You usually don't need to use this,
  ## as this is handled by registerComponents.

  entity.components.add(comp)

proc registerComponents*[T: RootEntity](entity: T) =
  ## Initializes an entity by registering all of its components.

  for name, value in fieldPairs(entity[]):
    when value is RootComponent:
      entity.registerComponent(addr value)


# callbacks

proc onUpdate*[T: RootComponent](comp: var T, impl: ComponentUpdate[T]) =
  comp.impl.update = cast[ComponentUpdate[RC]](impl)

proc onDraw*[T: RootComponent](comp: var T, impl: ComponentDraw[T]) =
  comp.impl.draw = cast[ComponentDraw[RC]](impl)

proc onRender*[T: RootComponent](comp: var T, impl: ComponentRender[T]) =
  comp.impl.render = cast[ComponentRender[RC]](impl)

proc onShape*[T: RootComponent](comp: var T, impl: ComponentShape[T]) =
  ## Shortcuts for setting ``comp.impl`` fields manually, for use with either
  ## the ``do`` notation or overload resolution.
  comp.impl.shape = cast[ComponentShape[RC]](impl)

proc autoImplement*[T: RootComponent](comp: var T) =
  ## Automagically implement any callbacks, depending on what procs have been
  ## declared at callsite, eg. if ``proc update(comp: var T)`` is declared, it
  ## will automatically be implemented for the given component instance.

  template attempt(stmt) =
    when compiles(stmt):
      stmt

  attempt:
    mixin update
    comp.onUpdate update
  attempt:
    mixin draw
    comp.onDraw draw
  attempt:
    mixin render
    comp.onRender render
  attempt:
    mixin shape
    comp.onShape shape

proc update*(entity: RootEntity) =
  ## Tick all of the entity's components update routines once.

  for comp in components(entity):
    if comp.impl.update != nil:
      comp.impl.update(comp)

proc draw*(entity: RootEntity, target: Target, step: float32) =
  ## aglet-draw all of the entity's components.
  ##
  ## Explanations of what the difference between draw/render/shape is can be
  ## found above.

  for comp in components(entity):
    if comp.impl.draw != nil:
      comp.impl.draw(comp, target, step)

proc render*(entity: RootEntity, target: Target, graphics: Graphics,
             step: float32) =
  ## rapid-render all of the entity's components.

  for comp in components(entity):
    if comp.impl.render != nil:
      comp.impl.render(comp, target, graphics, step)

proc shape*(entity: RootEntity, graphics: Graphics, step: float32) =
  ## Shape-render all of the entity's components.

  for comp in components(entity):
    if comp.impl.shape != nil:
      comp.impl.shape(comp, graphics, step)

proc update*(entities: seq[RootEntity]) =
  ## Ticks all the entities in the sequence.

  for entity in entities:
    entity.update()

proc draw*(entities: seq[RootEntity], target: Target, step: float32) =
  ## aglet-draws all the entities in the sequence.

  for entity in entities:
    entity.draw(target, step)

proc render*(entities: seq[RootEntity], target: Target, graphics: Graphics,
             step: float32) =
  ## rapid-renders all the entities in the sequence.

  for entity in entities:
    entity.render(target, graphics, step)

proc shape*(entities: seq[RootEntity], graphics: Graphics, step: float32) =
  ## Shape-renders all the entities in the sequence.

  for entity in entities:
    entity.shape(graphics, step)


# tests

when isMainModule:

  type
    CompPhysics = object of RootComponent
      position, velocity, acceleration: Vec2f

    Player = ref object of RootEntity
      physics: CompPhysics

  proc update(physics: var CompPhysics) =
    physics.velocity += physics.acceleration
    physics.acceleration *= 0
    physics.position += physics.velocity

  proc physics*(position: Vec2f,
                velocity, acceleration = vec2f(0)): CompPhysics =
    result = CompPhysics(position: position, velocity: velocity,
                         acceleration: acceleration)
    result.autoImplement()

  var player = Player(physics: physics(position = vec2f(32, 32)))
  player.registerComponents()

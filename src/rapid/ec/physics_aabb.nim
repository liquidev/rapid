## AABB physics component.

import glm/vec

import ../ec
import ../math/util
import ../physics/aabb

{.experimental: "implicitDeref".}

type
  RootAabbCollider* = ref object of RootObj
    ## General interface for colliders.

    resolveCollisionXImpl*: proc (collider: RootAabbCollider,
                                  subject: var Rectf,
                                  direction: XCheckDirection,
                                  speed: float32): bool
                                 {.nimcall.}
    resolveCollisionYImpl*: proc (collider: RootAabbCollider,
                                  subject: var Rectf,
                                  direction: YCheckDirection,
                                  speed: float32): bool
                                 {.nimcall.}
      ## Implementations for collision detection on the X/Y axes.

  AabbCollider*[T] = ref object of RootAabbCollider
    ## Generic implementation for all collidable objects.
    ## You should prefer this over implementing ``RootAabbCollider`` directly.

    obj: T

  AabbWall* = enum
    wallLeft
    wallRight
    wallTop
    wallBottom

  AabbPhysics* = object of RootComponent
    position*, velocity*, acceleration*: Vec2f
    size*: Vec2f
    elasticity*: float32                       ## how much velocity is
                                               ## lost or gained on collision
                                               ## with walls
    collidesWith: seq[RootAabbCollider]
    collidingWithWalls: array[AabbWall, bool]

  AabbCollidable* = concept o
    ## Concept for matching objects that can be stored in an AabbCollider.
    resolveCollisionX(var Rectf, o, XCheckDirection, float32) is bool
    resolveCollisionY(var Rectf, o, YCheckDirection, float32) is bool

proc hitbox*(physics: AabbPhysics): Rectf =
  ## Returns the physics body's hitbox.
  rectf(physics.position, physics.size)

proc collidingWithWall*(physics: AabbPhysics, wall: AabbWall): bool =
  ## Returns whether the physics body collides with the given wall.
  physics.collidingWithWalls[wall]

proc force*(physics: var AabbPhysics, force: Vec2f) =
  ## Applies a force to the physics body.
  physics.acceleration += force

proc update(p: var AabbPhysics) =
  ## Ticks physics: updates position/velocity/acceleration, and resolves
  ## collisions with all colliders.

  # the easy part

  p.velocity += p.acceleration
  p.acceleration *= 0

  # collision resolution

  # just some variables for optimization
  let
    movingX = not p.velocity.x.closeTo(0.001)
    movingY = not p.velocity.y.closeTo(0.001)
  var hitbox: Rectf

  # of course we're not colliding with anything by default
  reset(p.collidingWithWalls)

  # X axis phase
  # to this day i'm not entirely sure why this axis separation is needed but eh
  # it works, so don't touch it.
  p.position.x += p.velocity.x
  hitbox = p.hitbox

  if movingX:
    let directionX = cdLeft.succ(ord(p.velocity.x > 0))
    for i, collider in p.collidesWith:
      let
        collides =
          collider.resolveCollisionXImpl(collider, hitbox, directionX,
                                         p.velocity.x)
        wall = wallLeft.succ(ord(directionX))
      p.position.x = hitbox.x
      if collides:
        p.velocity.x *= -p.elasticity
      p.collidingWithWalls[wall] = true

  # Y axis phase
  p.position.y += p.velocity.y
  hitbox = p.hitbox  # needs to be updated because the position was updated

  if movingY:
    let directionY = cdUp.succ(ord(p.velocity.y > 0))
    for i, collider in p.collidesWith:
      let
        collides =
          collider.resolveCollisionYImpl(collider, hitbox, directionY,
                                         p.velocity.y)
        wall = wallTop.succ(ord(directionY))
      p.position.y = hitbox.y
      if collides:
        p.velocity.y *= -p.elasticity
      p.collidingWithWalls[wall] = true

proc aabbPhysics*(position, size: Vec2f, colliders: varargs[RootAabbCollider],
                  velocity, acceleration = vec2f(0),
                  elasticity: float32 = 0): AabbPhysics =
  ## Constructs a new AabbPhysics component.

  result = AabbPhysics(position: position, velocity: velocity,
                       acceleration: acceleration,
                       elasticity: elasticity,
                       size: size,
                       collidesWith: @colliders)
  result.autoImplement()

proc collider*[T: AabbCollidable](obj: T): AabbCollider[T] =
  ## Creates a collider for the given AABB-collidable physics object.

  new(result)

  result.obj = obj

  result.resolveCollisionXImpl = proc (collider: RootAabbCollider,
                                       subject: var Rectf,
                                       direction: XCheckDirection,
                                       speed: float32): bool =
    mixin resolveCollisionX
    result = resolveCollisionX(subject, AabbCollider[T](collider).obj,
                               direction, speed)

  result.resolveCollisionYImpl = proc (collider: RootAabbCollider,
                                       subject: var Rectf,
                                       direction: YCheckDirection,
                                       speed: float32): bool =
    mixin resolveCollisionY
    result = resolveCollisionY(subject, AabbCollider[T](collider).obj,
                               direction, speed)

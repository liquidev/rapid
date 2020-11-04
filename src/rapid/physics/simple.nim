## A simple physics engine for use with tilemaps.
##
## This engine can (on a limited level) interoperate with Chipmunk, if you
## create kinematic bodies that represent simple Bodies. Keep in mind that
## kinematic bodies are controlled fully by physics/simple, so Chipmunk has no
## influence over them.

import glm/vec

import ../game/tilemap
import ../math/rectangle

export RectangleSide

type
  CollidableTile* {.explain.} = concept t
    ## A tile that can be collided with.
    t.isSolid is bool

  CollisionState* = enum
    csJustStartedColliding
    csIsColliding
    csJustSeparated

  Body* = ref object of RootObj
    ## A physics body.

    # physics data
    position, velocity, force: Vec2f
    size: Vec2f
    elasticity: float32

    # internal data
    indexInSpace: int
    collisionStates: array[RectangleSide, set[CollisionState]]

  UserBody*[U] = ref object of Body
    ## A physics body with user data.
    user*: U

  UpdateBodyPositionCallback* = proc (body: Body)

  Space*[M] = ref object
    ## A space. This is what simulates physics on all bodies.
    tilemap: M
    bodies: seq[Body]
    gravity: Vec2f
    updateBodyX, updateBodyY: UpdateBodyPositionCallback


# body

proc init*(body: var Body, size: Vec2f) =
  ## Initializes a body. ``body`` must not be nil.
  body.size = size

proc newBody*(size: Vec2f): Body =
  ## Creates and initializes a new body with the given size.

  new result
  result.init(size)

proc newBody*[U](size: Vec2f, user: U): UserBody[U] =
  ## Creates and initializes a new body with the given size and user data.

  new result
  result.init(size)
  result.user = user

proc position*(body: Body): var Vec2f =
  ## Returns the position of the body.
  body.position

proc `position=`*(body: Body, newPosition: Vec2f) =
  ## Sets the position of the body.
  body.position = newPosition

proc velocity*(body: Body): var Vec2f =
  ## Returns the velocity of the body.
  body.velocity

proc `velocity=`*(body: Body, newVelocity: Vec2f) =
  ## Sets the velocity of the body.
  body.velocity = newVelocity

proc force*(body: Body): var Vec2f =
  ## Returns the force of the body.
  body.force

proc `force=`*(body: Body, newForce: Vec2f) =
  ## Sets the force of the body.
  body.force = newForce

proc elasticity*(body: Body): var float32 =
  ## Returns the elasticity of the body.
  body.elasticity

proc `elasticity=`*(body: Body, newElasticity: float32) =
  ## Sets the elasticity of the body.
  ## This controls how bouncy the body is. Note that an elasticity of 1 will not
  ## make the body bounce back to its original height due to precision losses.
  body.elasticity = newElasticity

proc hitbox*(body: Body): Rectf =
  ## Returns the hitbox of the body.
  rectf(body.position, body.size)

proc applyForce*(body: Body, force: Vec2f) =
  ## Applies a force to the given body.
  body.force += force

proc collisionState*(body: Body, wall: RectangleSide): set[CollisionState] =
  ## Returns the set of collision states for the given wall.
  body.collisionStates[wall]

proc collidingWith*(body: Body, wall: RectangleSide): bool =
  ## Returns whether the body is colliding with the given wall.
  csIsColliding in body.collisionState(wall)

proc justStartedCollidingWith*(body: Body, wall: RectangleSide): bool =
  ## Returns whether the body just started touching the given wall.
  csJustStartedColliding in body.collisionState(wall)

proc justSeparatedWith*(body: Body, wall: RectangleSide): bool =
  ## Returns whether the body just finished colliding with the given wall.
  csJustSeparated in body.collisionState(wall)


# space

proc addBody*(space: Space, body: Body) =
  ## Adds the given body to the space.

  body.indexInSpace = space.bodies.len
  space.bodies.add(body)

proc delBody*(space: Space, body: Body) =
  ## Deletes the given body from the space.

  space.bodies[body.indexInSpace] = space.bodies[^1]
  space.bodies[body.indexInSpace].indexInSpace = body.indexInSpace
  body.indexInSpace = 0
  space.bodies.setLen(space.bodies.len - 1)

proc addTo*(body: Body, space: Space): Body =
  ## Adds a body to the given space and returns the body.

  space.addBody(body)
  body

iterator bodies*(space: Space): Body =
  ## Yields all bodies in the given space.

  for body in space.bodies:
    yield body

proc onUpdateBodyX*(space: Space, callback: UpdateBodyPositionCallback) =
  ## Sets the callback to be called when the X position of the body should
  ## update. This callback is triggered *before* processing collisions on the
  ## X axis.
  space.updateBodyX = callback

proc onUpdateBodyY*(space: Space, callback: UpdateBodyPositionCallback) =
  ## Sets the callback to be called when the Y position of the body should
  ## update. This callback is triggered *before* processing collisions on the
  ## Y axis.
  space.updateBodyY = callback

proc newSpace*[M](tilemap: M, gravity: Vec2f): Space[M] =
  ## Creates and initializes a new space with the given tilemap and gravity.

  new result
  result.tilemap = tilemap
  result.gravity = gravity

  result.onUpdateBodyX proc (body: Body) =
    body.position.x += body.velocity.x

  result.onUpdateBodyY proc (body: Body) =
    body.position.y += body.velocity.y


# collision resolution

{.push inline.}

proc snapToTiles[M](tilemap: M, rect: Rectf): Recti =
  ## Snaps a hitbox to tiles.
  mixin tileSize
  rectSides(
    floor(rect.left / tilemap.tileSize.x).int32,
    floor(rect.top / tilemap.tileSize.y).int32,
    ceil(rect.right / tilemap.tileSize.x).int32,
    ceil(rect.bottom / tilemap.tileSize.y).int32,
  )

proc tileHitbox[M](tilemap: M, position: Vec2i): Rectf =
  ## Returns the hitbox of a tile at the given position.
  mixin tileSize
  rectf(position.vec2f * tilemap.tileSize, tilemap.tileSize)

# i really do not like how repetitive this code is.
# i couldn't however find an appropriate solution for checking both axes in a
# cleaner way. templates failed me, i ain't gonna touch macros unless absolutely
# necessary, and luckily two copies of almost the same code are not really that
# big of a deal. it'd be much worse if it were five, ten, maybe even twenty
# copies, but two is *relatively* maintainable. i can't wait until this spirals
# out of control into a complete mess.

template isCollidingWith(body: Body, side: RectangleSide) =
  body.collisionStates[side].excl(csJustStartedColliding)
  if csIsColliding notin body.collisionStates[side]:
    body.collisionStates[side].incl(csJustStartedColliding)
  body.collisionStates[side].incl(csIsColliding)

template isNotCollidingWith(body: Body, side: RectangleSide) =
  body.collisionStates[side].excl(csJustSeparated)
  if csIsColliding in body.collisionStates[side]:
    body.collisionStates[side].incl(csJustSeparated)
  body.collisionStates[side].excl(csIsColliding)

proc collideWithTilemapX[M](body: Body, tilemap: M) =
  ## Processes collisions with the tilemap on the X axis.

  mixin tileSize

  let
    hitbox = body.hitbox
    tileAlignedHitbox = tilemap.snapToTiles(hitbox)
    velocity = clamp(body.velocity.x, -tilemap.tileSize.x, tilemap.tileSize.x)
  var collWithLeft, collWithRight = false

  for position, tile in tilemap.area(tileAlignedHitbox):
    if not tile.isSolid: continue

    let tileHitbox = tilemap.tileHitbox(position)

    template isNotSolid(dx, dy: int): bool =
      not tilemap[position + vec2i(dx, dy)].isSolid

    if velocity > 0.001 and isNotSolid(-1, 0):
      let wall = rectSides(
        tileHitbox.left, tileHitbox.top + 1,
        tileHitbox.left + velocity, tileHitbox.bottom - 1,
      )
      if hitbox.intersects(wall):
        body.position.x = tileHitbox.left - hitbox.width
        body.velocity.x = -body.velocity.x * body.elasticity
        collWithLeft = true
    elif velocity < 0.001 and isNotSolid(1, 0):
      let wall = rectSides(
        tileHitbox.right + velocity, tileHitbox.top + 1,
        tileHitbox.right, tileHitbox.bottom - 1,
      )
      if hitbox.intersects(wall):
        body.position.x = tileHitbox.right
        body.velocity.x = -body.velocity.x * body.elasticity
        collWithRight = true

  if collWithLeft:
    body.isCollidingWith(rsLeft)
  else:
    body.isNotCollidingWith(rsLeft)

  if collWithRight:
    body.isCollidingWith(rsRight)
  else:
    body.isNotCollidingWith(rsRight)

proc collideWithTilemapY[M](body: Body, tilemap: M) =
  ## Processes collisions with the tilemap on the Y axis.

  mixin tileSize

  let
    hitbox = body.hitbox
    tileAlignedHitbox = tilemap.snapToTiles(hitbox)
    velocity = clamp(body.velocity.y, -tilemap.tileSize.y, tilemap.tileSize.y)
  var collWithTop, collWithBottom = false

  for position, tile in tilemap.area(tileAlignedHitbox):
    if not tile.isSolid: continue

    let tileHitbox = tilemap.tileHitbox(position)

    template isNotSolid(dx, dy: int): bool =
      not tilemap[position + vec2i(dx, dy)].isSolid

    if velocity > 0.001 and isNotSolid(0, -1):
      let wall = rectSides(
        tileHitbox.left + 1, tileHitbox.top,
        tileHitbox.right - 1, tileHitbox.top + velocity,
      )
      if hitbox.intersects(wall):
        body.position.y = tileHitbox.top - hitbox.height
        body.velocity.y = -body.velocity.y * body.elasticity
        collWithTop = true
    elif velocity < 0.001 and isNotSolid(0, 1):
      let wall = rectSides(
        tileHitbox.left + 1, tileHitbox.bottom + velocity,
        tileHitbox.right - 1, tileHitbox.bottom,
      )
      if hitbox.intersects(wall):
        body.position.y = tileHitbox.bottom
        body.velocity.y = -body.velocity.y * body.elasticity
        collWithBottom = true

  if collWithTop:
    body.isCollidingWith(rsTop)
  else:
    body.isNotCollidingWith(rsTop)

  if collWithBottom:
    body.isCollidingWith(rsBottom)
  else:
    body.isNotCollidingWith(rsBottom)

{.pop.}

proc update*[T: CollidableTile; M: AnyTilemap[T]](space: Space[M]) =
  ## Simulates the space for one tick. Keep in mind that the simple space only
  ## supports *fixed timestep.*

  for body in space.bodies:
    body.applyForce(space.gravity)

    body.velocity += body.force
    body.force *= 0

    space.updateBodyX(body)
#     body.position.x += body.velocity.x * timestep
    body.collideWithTilemapX(space.tilemap)

    space.updateBodyY(body)
#     body.position.y += body.velocity.y * timestep
    body.collideWithTilemapY(space.tilemap)

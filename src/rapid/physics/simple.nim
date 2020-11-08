## A simple physics engine for use with tilemaps.
##
## This engine can (on a limited level) interoperate with Chipmunk, if you
## create kinematic bodies that represent simple Bodies. Keep in mind that
## kinematic bodies are controlled fully by physics/simple, so Chipmunk has no
## influence over them.

import std/hashes
import std/options
import std/sets
import std/tables

import glm/vec

import ../game/tilemap
import ../math/interpolation
import ../math/rectangle

export RectangleSide
export
  interpolation.interpolated,
  interpolation.value,
  interpolation.mvalue

type
  CollidableTile* {.explain.} = concept t
    ## A tile that can be collided with.
    t.isSolid is bool

  CollisionState* = enum
    csJustStartedColliding
    csIsColliding
    csJustSeparated

  GoThroughSeamCallback* = proc (body: Body)
    ## Callback for when a body passes a wrapping seam.

  CollideWithBodyCallback* = proc (body, other: Body)
    ## Callback for when a body collides with another body.

  Body* = ref object of RootObj
    ## A physics body.

    # physics data
    position: Interpolated[Vec2f]
    velocity, force: Vec2f
    size: Vec2f
    elasticity: float32
    mass: float32

    # internal data: state
    delete: bool
    goThroughSeamCallback: GoThroughSeamCallback
    collideWithBodyCallback: CollideWithBodyCallback
    collisionStates: array[RectangleSide, set[CollisionState]]

    # internal data: redundancy
    indexInSpace: int
    checkedForCollisions: HashSet[Body]

  UserBody*[U] = ref object of Body
    ## A physics body with user data.
    user*: U

  Space*[M] = ref object
    ## A space. This is what simulates physics on all bodies.

    tilemap: M
    bodies: seq[Body]

    gravity: Vec2f
    boundsX, boundsY: Option[Slice[float32]]

    spatialHash: Table[Vec2i, seq[Body]]
    spatialHashCellSize: float32


# body

proc hash*(body: Body): Hash =
  result = hash(cast[pointer](body))

proc init*(body: Body, size: Vec2f, mass: float32) =
  ## Initializes a body. ``body`` must not be nil.

  body.size = size
  body.mass = mass

proc init*(body: Body, size: Vec2f, density: float32) =
  ## Initializes a body. ``body`` must not be nil. The mass of the body is
  ## calculated as the quotient of its volume ``size.x * size.y`` with the
  ## given density.
  body.init(size, mass = size.x * size.y * density)

proc newBody*(size: Vec2f, mass: float32): Body =
  ## Creates and initializes a new body with the given size and mass.

  new result
  result.init(size, mass = mass)

proc newBody*(size: Vec2f, density: float32): Body =
  ## Creates and initializes a new body with the given size and density.

  new result
  result.init(size, density = density)

proc newBody*[U](size: Vec2f, mass: float32, user: U): UserBody[U] =
  ## Creates and initializes a new body with the given size, mass,
  ## and user data.

  new result
  result.init(size, mass = mass)
  result.user = user

proc newBody*[U](size: Vec2f, density: float32, user: U): UserBody[U] =
  ## Creates and initializes a new body with the given size, density,
  ## and user data.

  new result
  result.init(size, density = density)
  result.user = user

{.push inline.}

proc position*(body: Body): var Interpolated[Vec2f] =
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

proc size*(body: Body): Vec2f =
  ## Returns the size of the body.
  body.size

proc elasticity*(body: Body): var float32 =
  ## Returns the elasticity of the body.
  body.elasticity

proc `elasticity=`*(body: Body, newElasticity: float32) =
  ## Sets the elasticity of the body.
  ## This controls how bouncy the body is. Note that an elasticity of 1 will not
  ## make the body bounce back to its original height due to precision losses.
  body.elasticity = newElasticity

proc mass*(body: Body): var float32 =
  ## Returns the mass of the body.
  body.mass

proc `mass=`*(body: Body, newMass: float32) =
  ## Sets the mass of the body.
  ## The mass controls how fast the body is pulled towards the ground.
  body.mass = newMass

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

proc onGoThroughSeam*(body: Body, callback: GoThroughSeamCallback) =
  ## Sets the callback to be called when the body goes through an X or Y
  ## wrapping seam. This is usually used to tick interpolation to avoid
  ## janky-looking animations.
  body.goThroughSeamCallback = callback

proc onCollideWithBody*(body: Body, callback: CollideWithBodyCallback) =
  ## Sets the callback to be called when the body collides with another body.
  body.collideWithBodyCallback = callback

proc delete*(body: Body) =
  ## Marks the body for deletion.
  body.delete = true

{.pop.}


# space

proc boundsX*(space: Space): var Option[Slice[float32]] =
  ## Returns the X wrapping boundaries.
  ## The space is capable of wrapping bodies around some set boundaries.
  ## Setting this to ``Some(bounds)`` will enable wrapping, setting this to
  ## ``None`` will disable wrapping.
  ##
  ## Wrapping is disabled by default.
  space.boundsX

proc boundsY*(space: Space): var Option[Slice[float32]] =
  ## Returns the Y wrapping boundaries.
  space.boundsY

proc `boundsX=`*(space: Space, bounds: Option[Slice[float32]]) =
  ## Sets X wrapping boundaries.
  space.boundsX = bounds

proc `boundsY=`*(space: Space, bounds: Option[Slice[float32]]) =
  ## Sets Y wrapping boundaries.
  space.boundsY = bounds

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

proc newSpace*[M](tilemap: M, gravity: Vec2f,
                  spatialHashCellSize: float32 = 12): Space[M] =
  ## Creates and initializes a new space with the given tilemap and gravity.

  new result
  result.tilemap = tilemap
  result.gravity = gravity
  result.spatialHashCellSize = spatialHashCellSize


# collision resolution

{.push inline.}

proc alignToGrid(rect: Rectf, gridSize: Vec2f): Recti =
  ## Snaps a hitbox to tiles.
  rectSides(
    floor(rect.left / gridSize.x).int32,
    floor(rect.top / gridSize.y).int32,
    ceil(rect.right / gridSize.x).int32 - 1,
    ceil(rect.bottom / gridSize.y).int32 - 1,
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
    tileAlignedHitbox = hitbox.alignToGrid(tilemap.tileSize)
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
        mvalue(body.position).x = tileHitbox.left - hitbox.width
        body.velocity.x = -body.velocity.x * body.elasticity
        collWithLeft = true
    elif velocity < 0.001 and isNotSolid(1, 0):
      let wall = rectSides(
        tileHitbox.right + velocity, tileHitbox.top + 1,
        tileHitbox.right, tileHitbox.bottom - 1,
      )
      if hitbox.intersects(wall):
        mvalue(body.position).x = tileHitbox.right
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
    tileAlignedHitbox = hitbox.alignToGrid(tilemap.tileSize)
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
        mvalue(body.position).y = tileHitbox.top - hitbox.height
        body.velocity.y = -body.velocity.y * body.elasticity
        collWithTop = true
    elif velocity < 0.001 and isNotSolid(0, 1):
      let wall = rectSides(
        tileHitbox.left + 1, tileHitbox.bottom + velocity,
        tileHitbox.right - 1, tileHitbox.bottom,
      )
      if hitbox.intersects(wall):
        mvalue(body.position).y = tileHitbox.bottom
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

proc updateSpatialHash(space: Space) =
  ## Updates the spatial hash cells for all bodies.

  for _, cell in mpairs(space.spatialHash):
    cell.setLen(0)  # we don't want to dealloc the cells completely

  for body in space.bodies:
    let cells = body.hitbox.alignToGrid(vec2f(space.spatialHashCellSize))
    for y in cells.top..cells.bottom:
      for x in cells.left..cells.right:
        let cell = vec2i(x, y)
        if cell notin space.spatialHash:
          space.spatialHash[cell] = @[]
        space.spatialHash[cell].add(body)

proc collideBodies(a, b: Body) =

  let
    hitboxA = a.hitbox
    hitboxB = b.hitbox

  if hitboxA.intersects(hitboxB):
    # TODO: proper collision resolution
    if a.collideWithBodyCallback != nil:
      a.collideWithBodyCallback(a, b)
    if b.collideWithBodyCallback != nil:
      b.collideWithBodyCallback(b, a)

proc wrapAround[T](a: var T, range: Slice[T]): bool {.inline.} =

  result = true
  if a < range.a:
    a = range.b
  elif a > range.b:
    a = range.a
  else:
    result = false

{.pop.}

proc cleanup(space: Space) =
  ## Cleans up any bodies marked for deletion.

  var
    len = space.bodies.len
    i = 0
  while i < len:
    let body = space.bodies[i]
    if body.delete:
      space.bodies.del(i)
      dec len
      continue
    inc i

proc update*[T: CollidableTile; M: AnyTilemap[T]](space: Space[M]) =
  ## Simulates the space for one tick. Keep in mind that the simple space only
  ## supports *fixed timestep* and does not do any time scaling.

  for body in space.bodies:
    body.position.tick()

    body.applyForce(space.gravity * body.mass)

    body.velocity += body.force
    body.force *= 0

    mvalue(body.position).x += body.velocity.x
    if space.boundsX.isSome and
       wrapAround(mvalue(body.position).x, space.boundsX.get):
      # this is done to prevent weird interpolation when a body passes through
      # the seam
      body.position.tick()
      if not body.goThroughSeamCallback.isNil:
        body.goThroughSeamCallback(body)
    body.collideWithTilemapX(space.tilemap)

    mvalue(body.position).y += body.velocity.y
    if space.boundsY.isSome and
       wrapAround(mvalue(body.position).y, space.boundsY.get):
      body.position.tick()
      if not body.goThroughSeamCallback.isNil:
        body.goThroughSeamCallback(body)
    body.collideWithTilemapY(space.tilemap)

  space.updateSpatialHash()
  for a in space.bodies:
    let cells = a.hitbox.alignToGrid(vec2f(space.spatialHashCellSize))
    for y in cells.top..cells.bottom:
      for x in cells.left..cells.right:
        let cell = vec2i(x, y)
        for b in space.spatialHash[cell]:
          if a == b: continue
          collideBodies(a, b)
          a.checkedForCollisions.incl(b)
          b.checkedForCollisions.incl(a)
    a.checkedForCollisions.clear()

  space.cleanup()

## The `Chipmunk <https://github.com/slembcke/Chipmunk2D>` physics engine
## for rapid. This is a high-level wrapper around the engine's core features.
##
## This wrapper doesn't aim for 100% coverage of the physics engine, but
## features may be added as needed.

import aglet/rect
import glm/mat
import glm/vec

import ../math/units
import ../wrappers/chipmunk


# convenience converters

{.push inline.}

proc cpv(v: Vec2f): cpVect = cpv(v.x, v.y)
proc vec2f(v: cpVect): Vec2f = vec2f(v.x, v.y)
proc rectf(bb: cpBB): Rectf = rectf(bb.l, bb.t, bb.r - bb.l, bb.b - bb.t)

{.pop.}


# types

type

  # most of these types are just ``ref`` wrappers over chipmunk's
  # incomplete structs

  CollisionKind* = distinct uint16
    ## Collision kind. This is a per-shape field accessible from collision
    ## handler callbacks.
  CollisionCategory* = distinct range[0..63]
    ## Collision categories are used in shape filters.

  ShapeObj = object of RootObj
    raw: ptr cpShape

  CircleShapeObj {.final.} = object of ShapeObj
  SegmentShapeObj {.final.} = object of ShapeObj
  PolygonShapeObj {.final.} = object of ShapeObj

  Shape* = ref ShapeObj
    ## Parent object for collision shapes.
  CircleShape* = ref CircleShapeObj
    ## Circle, the fastest and simplest collision shape.
  SegmentShape* = ref SegmentShapeObj
    ## Beveled line segment collision shape.
  PolygonShape* = ref PolygonShapeObj
    ## Convex polygon collision shape. Slowest, but most flexible.

  ShapeFilter* = tuple
    ## A collision filter for shapes. This allows some collisions between shapes
    ## to be ignored.
    group: uint
    categories, mask: set[CollisionCategory]

  BodyKind* = enum
    ## The kind of a physics body. Body kinds are explained below in their
    ## respective Body constructors.
    bkDynamic
    bkKinematic
    bkStatic

  BodyObj = object
    raw: ptr cpBody
    shapes: seq[Shape]
  Body* = ref BodyObj
    ## A rigid body.

  SpaceObj = object
    raw: ptr cpSpace
  Space* = ref SpaceObj
    ## Space for simulating physics.


# body

{.push inline.}

proc kind*(body: Body): BodyKind =
  ## Returns the kind of this body.
  cpBodyGetType(body.raw).BodyKind

proc `kind=`*(body: Body, newKind: BodyKind) =
  ## Sets the kind of this body.
  ##
  ## If the new kind is ``bkDynamic``, the mass and moment of the body are
  ## recalculated from the shapes of the body.
  ## Custom masses and moments are not preserved when changing kinds.
  ##
  ## This procedure cannot be called directly in a collision callback.
  cpBodySetType(body.raw, newKind.cpBodyType)

proc space*(body: Body): Space =
  ## Returns the space the body is currently added to, or ``nil`` if the body is
  ## not currently added to a space.

  if (let s = cpBodyGetSpace(body.raw); s != nil):
    result = cast[Space](cpSpaceGetUserData(s))

proc mass*(body: Body): float32 =
  ## Returns the mass of the body.
  cpBodyGetMass(body.raw)

proc `mass=`*(body: Body, newMass: float32) =
  ## Sets the mass of the body.
  cpBodySetMass(body.raw, newMass)

proc moment*(body: Body): float32 =
  ## Returns the moment of inertia of the body.
  cpBodyGetMoment(body.raw)

proc `moment=`*(body: Body, newMoment: float32) =
  ## Sets the moment of inertia of the body. The moment is like a rotational
  ## mass of a body.
  cpBodySetMoment(body.raw, newMoment)

proc position*(body: Body): Vec2f =
  ## Returns the position of the body.
  cpBodyGetPosition(body.raw).vec2f

proc `position=`*(body: Body, newPosition: Vec2f) =
  ## Sets the position of the body.
  ##
  ## When updating the position, you may want to call ``reindexShapesForBody``
  ## to update the collision detection information for attached shapes if you're
  ## planning on making any queries against the space.
  cpBodySetPosition(body.raw, newPosition.cpv)

proc centerOfGravity*(body: Body): Vec2f =
  ## Returns the body's center of gravity.
  cpBodyGetCenterOfGravity(body.raw).vec2f

proc `centerOfGravity=`*(body: Body, newCog: Vec2f) =
  ## Sets the body's center of gravity.
  cpBodySetCenterOfGravity(body.raw, newCog.cpv)

proc velocity*(body: Body): Vec2f =
  ## Returns the linear velocity of the body's center of gravity.
  cpBodyGetVelocity(body.raw).vec2f

proc `velocity=`*(body: Body, newVelocity: Vec2f) =
  ## Sets the linear velocity of the body's center of gravity.
  cpBodySetVelocity(body.raw, newVelocity.cpv)

proc force*(body: Body): Vec2f =
  ## Returns the force applied to the body's center of gravity.
  cpBodyGetForce(body.raw).vec2f

proc `force=`*(body: Body, newForce: Vec2f): Vec2f =
  ## Sets the force applied to the body's center of gravity.
  ## This value is reset every time step.
  cpBodySetForce(body.raw, newForce.cpv)

proc angle*(body: Body): Radians =
  ## Returns the angle of the body.
  cpBodyGetAngle(body.raw).radians

proc `angle=`*(body: Body, newAngle: Radians) =
  ## Sets the angle of the body.
  ##
  ## When updating the angle, you may want to call ``reindexShapesForBody``
  ## to update the collision detection information for attached shapes if you're
  ## planning on making any queries against the space.
  cpBodySetAngle(body.raw, newAngle.float32)

proc angularVelocity*(body: Body): Radians =
  ## Returns the angular velocity of the body's, in radians per second.
  cpBodyGetAngularVelocity(body.raw).radians

proc `angularVelocity=`*(body: Body, newAngularVelocity: Radians) =
  ## Sets the angular velocity of the body in radians per second.
  cpBodySetAngularVelocity(body.raw, newAngularVelocity.float32)

proc torque*(body: Body): Radians =
  ## Returns the torque applied to the body.
  cpBodyGetTorque(body.raw).radians

proc `torque=`*(body: Body, newTorque: Radians) =
  ## Sets the torque applied to the body. This value is reset every time step.
  cpBodySetTorque(body.raw, newTorque.float32)

proc rotation*(body: Body): Vec2f =
  ## Returns the rotation vector of the body.
  cpBodyGetRotation(body.raw).vec2f

proc momentForCircle*(mass: float32, innerRadius, outerRadius: float32,
                      center: Vec2f): float32 =
  ## Calculates the moment of inertia for a hollow circle positioned at
  ## ``center`` relative to the body's center.
  ## A solid circle has an inner diameter of 0.
  cpMomentForCircle(mass, innerRadius * 2, outerRadius * 2, center.cpv)

proc momentForSegment*(mass: float32, a, b: Vec2f, radius: float32): float32 =
  ## Calculates the moment of inertia for a beveled line segment.
  ## The endpoints ``a`` and ``b`` are relative to the body.
  cpMomentForSegment(mass, a.cpv, b.cpv, radius)

proc momentForPolygon*(mass: float32, vertices: openArray[Vec2f],
                       offset: Vec2f, radius: float32): float32 =
  ## Calculates the moment of inertia for a solid polygon shape assuming its
  ## center of gravity is at its centroid. The offset is added to each vertex.
  cpMomentForPoly(mass, vertices.len.cint,
                  # vec2f and cpVect are binary compatible so this shouldn't
                  # be a problem
                  cast[ptr cpVect](vertices[0].unsafeAddr),
                  offset.cpv, radius)

proc momentForBox*(mass: float32, size: Vec2f): float32 =
  ## Calculates the moment of inertia for a solid box centered on the body.
  cpMomentForBox(mass, size.x, size.y)

proc areaForCircle*(innerRadius, outerRadius: float32): float32 =
  ## Calculates the area of a hollow circle.
  cpAreaForCircle(innerRadius, outerRadius)

proc areaForSegment*(a, b: Vec2f, radius: float32): float32 =
  ## Calculates the area of a beveled line segment.
  cpAreaForSegment(a.cpv, b.cpv, radius)

proc areaForPolygon*(vertices: openArray[Vec2f], radius: float32): float32 =
  ## Calculates the signed area of a polygon.
  cpAreaForPoly(vertices.len.cint, cast[ptr cpVect](vertices[0].unsafeAddr),
                radius)

proc localToWorld*(body: Body, point: Vec2f): Vec2f =
  ## Converts from body local coordinates to world space coordinates.
  cpBodyLocalToWorld(body.raw, point.cpv).vec2f

proc worldToLocal*(body: Body, point: Vec2f): Vec2f =
  ## Converts from world space coordinates to body local coordinates.
  cpBodyWorldToLocal(body.raw, point.cpv).vec2f

proc applyForce*(body: Body, force: Vec2f, localPoint = vec2f(0)) =
  ## Applies a force to the body at the given body local point.
  cpBodyApplyForceAtLocalPoint(body.raw, force.cpv, localPoint.cpv)

proc applyForce*(body: Body, force: Vec2f, worldPoint: Vec2f) =
  ## Applies a force to the body at the given world space point.
  cpBodyApplyForceAtWorldPoint(body.raw, force.cpv, worldPoint.cpv)

proc applyImpulse*(body: Body, impulse: Vec2f, localPoint = vec2f(0)) =
  ## Applies an impulse to the body at the given body local point.
  ## An impulse is a very strong force applied over a very short period of time;
  ## in case of Chipmunk, it is applied immediately after this procedure is
  ## called.
  cpBodyApplyImpulseAtLocalPoint(body.raw, impulse.cpv, localPoint.cpv)

proc applyImpulse*(body: Body, impulse: Vec2f, worldPoint = vec2f(0)) =
  ## Applies an impulse to the body at the given world space point.
  cpBodyApplyImpulseAtWorldPoint(body.raw, impulse.cpv, worldPoint.cpv)

proc isSleeping*(body: Body): bool =
  ## Returns whether the body is currently sleeping.
  cpBodyIsSleeping(body.raw).bool

proc activate*(body: Body) =
  ## Resets the idle timer of the body, then wakes up the body and any bodies
  ## touching it.
  cpBodyActivate(body.raw)

proc sleep*(body: Body) =
  ## Force the body into a sleeping state, even if it's in midair.
  ##
  ## This procedure cannot be called from a callback.
  cpBodySleep(body.raw)

{.pop.}

proc new(body: var Body, raw: ptr cpBody) =

  new(body) do (body: Body):
    cpBodyFree(body.raw)
    for shape in body.shapes:
      cpSpaceRemoveShape(body.space.raw, shape.raw)

  body.raw = raw
  cpBodySetUserData(body.raw, cast[ptr BodyObj](body))

proc newDynamicBody*(mass, moment = 0.0f): Body =
  ## Creates a new dynamic body with the given mass and moment of inertia.
  ##
  ## Dynamic bodies are simulated and controlled by the physics engine.
  ##
  ## You usually do not want to provide the moment of inertia yourself, so
  ## Chipmunk will calculate it automatically in the following cases:
  ##
  ## - If the mass and moment of inertia are set to 0, they will be calculated
  ##   automatically after adding shapes to the body; this should be preferred
  ##   in most cases.
  ## - If the mass is non-zero, and the mass of all shapes is 0, the moment of
  ##   inertia will be calculated automatically from the attached shapes.

  result.new(cpBodyNew(mass, moment))

proc newKinematicBody*(): Body =
  ## Creates a new kinematic body.
  ##
  ## Kinematic bodies are simulated by the game. They aren't affected by
  ## gravity, and have an infinite amount of mass, so they don't react to
  ## collisions or forces with other bodies.
  ##
  ## These bodies can be controlled by setting their velocity.
  ## Objects touching a kinematic body are never allowed to fall asleep.

  result.new(cpBodyNewKinematic())

proc newStaticBody*(): Body =
  ## Creates a new static body.
  ##
  ## Static bodies hardly ever move, aren't affected by gravity, and don't react
  ## to collisions. Using static bodies for things like level geometry has a big
  ## performance boost, as Chipmunk doesn't have to check collisions between
  ## static bodies nor does it have to update their collision information.
  ## There is, however, a performance penalty when a static object needs to
  ## be moved, as all the collision information has to be recalculated.

  result.new(cpBodyNewStatic())


# shape

{.push inline.}

proc body*(shape: Shape): Body =
  ## Returns the shape's body.
  cast[Body](cpBodyGetUserData(cpShapeGetBody(shape.raw)))

proc `body=`*(shape: Shape, newBody: Body) =
  ## Sets the rigit body the shape is attached to. Can only be set when the
  ## shape is not added to a space.
  cpShapeSetBody(shape.raw, newBody.raw)

proc boundingBox*(shape: Shape): Rectf =
  ## Returns the shape's bounding box.
  ## This is only guaranteed to be valid after calling ``cacheBoundingBox`` or
  ## stepping the space.
  cpShapeGetBB(shape.raw).rectf

proc cacheBoundingBox*(shape: Shape): Rectf =
  ## Synchronizes the shape's axis-aligned bounding box with the actual shape,
  ## and returns the bounding box.
  cpShapeCacheBB(shape.raw).rectf

proc isSensor*(shape: Shape): bool =
  ## Returns whether the shape is a sensor (doesn't interact with bodies).
  cpShapeGetSensor(shape.raw).bool

proc `isSensor=`*(shape: Shape, sensor: bool) =
  ## Sets whether the shape is a sensor. Sensor shapes do not interact with
  ## physics bodies, but still report collisions via callbacks.
  cpShapeSetSensor(shape.raw, sensor.cpBool)

proc elasticity*(shape: Shape): float32 =
  ## Returns the elasticity of the shape.
  cpShapeGetElasticity(shape.raw)

proc `elasticity=`*(shape: Shape, newElasticity: float32) =
  ## Sets the elasticity of the shape. This controls how bouncy the shape is;
  ## a value of 0 gives no bounce, a value of 1 gives a "perfect" bounce.
  ## Due to inaccuracies in the simulation, using values >=1 is not recommended.
  cpShapeSetElasticity(shape.raw, newElasticity)

proc friction*(shape: Shape): float32 =
  ## Returns the shape's friction coefficient.
  cpShapeGetFriction(shape.raw)

proc `friction=`*(shape: Shape, newFriction: float32) =
  ## Sets the shape's friction coefficient. Chipmunk uses the Coulomb friction
  ## model, a value of 0 is frictionless.
  cpShapeSetFriction(shape.raw, newFriction)

proc surfaceVelocity*(shape: Shape): Vec2f =
  ## Returns the surface velocity of the shape.
  cpShapeGetSurfaceVelocity(shape.raw).vec2f

proc `surfaceVelocity=`*(shape: Shape, newVelocity: Vec2f) =
  ## Sets the surface velocity of the shape.
  ## According to the Chipmunk documentation, this is "useful for creating
  ## conveyor belts or players that move around".
  cpShapeSetSurfaceVelocity(shape.raw, newVelocity.cpv)

proc collisionKind*(shape: Shape): CollisionKind =
  ## Returns the collision kind of the shape. This value is passed to collision
  ## callbacks.
  cpShapeGetCollisionType(shape.raw).CollisionKind

proc `collisionKind=`*(shape: Shape, newKind: CollisionKind) =
  ## Sets the collision kind of the shape. This is passed to collision
  ## callbacks.
  cpShapeSetCollisionType(shape.raw, newKind.cpCollisionType)

proc toRapid(f: cpShapeFilter): ShapeFilter =
  (group: f.group,
   categories: cast[set[CollisionCategory]](f.categories),
   mask: cast[set[CollisionCategory]](f.mask))
proc toChipmunk(f: ShapeFilter): cpShapeFilter =
  cpShapeFilter(group: f.group,
                categories: cast[cpBitmask](f.categories),
                mask: cast[cpBitmask](f.mask))

template makeCollisionCategory*(T: type[enum]): untyped =
  ## Helper for generating converters to and from CollisionCategory.
  ## The size of ``set[T]`` must not exceed ``8``, which means that
  ## ``high(T).ord - low(T).ord <= 64``. Thus, the enum can have 64 elements at
  ## most.

  when high(T).ord - low(T).ord > 64:
    {.error: $T & " must have 64 elements at most".}

  converter `to T`*(x: CollisionCategory) = cast[T](x)
  converter toCollisionCategory*(x: T) = cast[CollisionCategory](x)

proc filter*(shape: Shape): ShapeFilter =
  ## Returns the shape filter of the shape.
  cpShapeGetFilter(shape.raw).toRapid

proc `filter=`*(shape: Shape, newFilter: ShapeFilter) =
  ## Sets the shape filter of the shape.
  cpShapeSetFilter(shape.raw, newFilter.toChipmunk)

{.pop.}

proc new[T: Shape](shape: var T, body: Body, raw: ptr cpShape) =
  doAssert body.space != nil,
           "body must be added to a space before creating any shapes"

  new(shape) do (shape: T):
    cpShapeFree(shape.raw)

  shape.raw = raw
  discard cpSpaceAddShape(body.space.raw, raw)
  body.shapes.add(shape)
  cpShapeSetUserData(shape.raw, cast[ptr Shape](shape))

proc newCircleShape*(body: Body, radius: float32,
                     offset = vec2f(0)): CircleShape =
  ## Creates a new circle shape with the given radius and offset from the body's
  ## center, and attaches it to the body.
  ##
  ## **Note:** By the time this, or any of the other shape constructors
  ## is called, the body *must* have been added to a space. Otherwise an
  ## assertion is triggered.

  result.new(body, cpCircleShapeNew(body.raw, radius, offset.cpv))

proc offset*(shape: CircleShape): Vec2f =
  ## Returns the circle's offset from the body's center.
  cpCircleShapeGetOffset(shape.raw).vec2f

proc radius*(shape: CircleShape): float32 =
  ## Returns the circle's radius.
  cpCircleShapeGetRadius(shape.raw)

proc newSegmentShape*(body: Body, a, b: Vec2f, radius = 0.0f): SegmentShape =
  ## Creates a new beveled segment shape with the given start and end points and
  ## bevel radius, and attaches it to the body.

  result.new(body, cpSegmentShapeNew(body.raw, a.cpv, b.cpv, radius))

proc a*(shape: SegmentShape): Vec2f =
  ## Returns the first endpoint of the segment.
  cpSegmentShapeGetA(shape.raw).vec2f

proc b*(shape: SegmentShape): Vec2f =
  ## Returns the second endpoint of the segment.
  cpSegmentShapeGetB(shape.raw).vec2f

proc normal*(shape: SegmentShape): Vec2f =
  ## Returns the normal vector of the segment.
  cpSegmentShapeGetNormal(shape.raw).vec2f

proc radius*(shape: SegmentShape): float32 =
  ## Returns the bevel radius of the segment.
  cpSegmentShapeGetRadius(shape.raw)

proc `neighbors=`*(shape: SegmentShape,
                   neighbors: tuple[previous, next: Vec2f]) =
  ## Sets the shape's neighbors.
  ##
  ## This should be used when constructing polylines from segments. Without this
  ## set, things can still collide with the "cracks" between segments.
  ## By setting this, Chipmunk will avoid colliding with the inner parts of the
  ## crack.
  cpSegmentShapeSetNeighbors(shape.raw,
                             neighbors.previous.cpv,
                             neighbors.next.cpv)

proc transform(translation: Vec2f, mat: Mat2f): cpTransform =
  cpTransform(tx: translation.x, ty: translation.y,
              a: mat.arr[0][0], b: mat.arr[1][0],
              c: mat.arr[1][0], d: mat.arr[1][1])

proc newPolygonShape*(body: Body,
                      vertices: openArray[Vec2f],
                      offset = vec2f(0),
                      radius = 0.0f,
                      transform = mat2f()): PolygonShape =
  ## Creates a new polygon shape with the given vertices, offset, radius, and
  ## transform matrix. A convex hull is calculated automatically from the
  ## vertices. The polygon shape will be created with a "skin" around it with
  ## the size of ``radius``, increasing the size of the shape.

  result.new(body, cpPolyShapeNew(body.raw,
                                  vertices.len.cint,
                                  cast[ptr cpVect](vertices[0].unsafeAddr),
                                  transform(offset, transform),
                                  radius))

proc vertexCount*(shape: PolygonShape): int =
  ## Returns the amount of vertices the polygon has.
  cpPolyShapeGetCount(shape.raw).int

proc vertex*(shape: PolygonShape, n: int): Vec2f =
  ## Returns the ``n``-th vertex of the shape.
  cpPolyShapeGetVert(shape.raw, n.cint).vec2f

proc radius*(shape: PolygonShape): float32 =
  ## Returns the polygon shape's skin radius.
  cpPolyShapeGetRadius(shape.raw)

proc newBoxShape*(body: Body, size: Vec2f, radius = 0.0f): PolygonShape =
  ## Shortcut for creating a box polygon centered at the body, with the given
  ## size and skin radius.

  result.new(body, cpBoxShapeNew(body.raw, size.x, size.y, radius))


# space

{.push inline.}

proc gravity*(space: Space): Vec2f =
  ## Returns the space's gravity.
  cpSpaceGetGravity(space.raw).vec2f

proc `gravity=`*(space: Space, newGravity: Vec2f) =
  ## Sets the space's gravity. Defaults to ``vec2f(0, 0)``.
  cpSpaceSetGravity(space.raw, newGravity.cpv)

proc iterations*(space: Space): Natural =
  ## Returns the number of iterations for this space.
  cpSpaceGetIterations(space.raw).Natural

proc `iterations=`*(space: Space, newCount: Natural) =
  ## Sets the number of iterations for this space.
  ## This controls the accuracy of the simulation.
  ## Defaults to 10.
  cpSpaceSetIterations(space.raw, newCount.cint)

proc damping*(space: Space): float32 =
  ## Returns the amount of simple damping applied to the space.
  cpSpaceGetDamping(space.raw)

proc `damping=`*(space: Space, newDamping: float32) =
  ## Sets the amount of simple damping applied to the space.
  ## This value controls how much velocity is lost by each body per second:
  ## a value of 0.9 means that each body loses 10% of its velocity per second.
  ## Defaults to 1; can be overridden per body.
  cpSpaceSetDamping(space.raw, newDamping)

proc idleSpeedThreshold*(space: Space): float32 =
  ## Returns the idle speed threshold for this space.
  cpSpaceGetIdleSpeedThreshold(space.raw)

proc `idleSpeedThreshold=`*(space: Space, newThreshold: float32) =
  ## Sets the idle speed threshold for this space.
  ## This controls how little speed a body must have to be considered idle.
  ## Defaults to 0, which means that the space will estimate the value based on
  ## the gravity.
  cpSpaceSetIdleSpeedThreshold(space.raw, newThreshold)

proc sleepTimeThreshold*(space: Space): float32 =
  ## Returns the sleep time threshold for this space.
  cpSpaceGetSleepTimeThreshold(space.raw)

proc `sleepTimeThreshold=`*(space: Space, newThreshold: float32) =
  ## Sets the sleep time threshold for this space.
  ## This value controls how much time a group of bodies must be idle before it
  ## falls asleep (pauses simulating physics).
  ## Defaults to Inf, which disables the feature.
  cpSpaceSetSleepTimeThreshold(space.raw, newThreshold)

proc collisionSlop*(space: Space): float32 =
  ## Returns the collision slop for this space.
  cpSpaceGetCollisionSlop(space.raw)

proc `collisionSlop=`*(space: Space, newSlop: float32) =
  ## Sets the collision slop for this space.
  ## This controls how much overlap may occur between shapes, and should be set
  ## as high as possible without noticable overlapping.
  ## Defaults to 0.1.
  cpSpaceSetCollisionSlop(space.raw, newSlop)

proc collisionBias*(space: Space): float32 =
  ## Returns the collision bias for this space.
  cpSpaceGetCollisionBias(space.raw)

proc `collisionBias=`*(space: Space, newBias: float32) =
  ## Sets the collision bias for this space.
  ## Refer to the `Chipmunk documentation`__ for information on what this is;
  ## very, _very_ few games need to change this value.
  ## Defaults to 0.1.
  ##
  ## .. doc_: https://chipmunk-physics.net/release/ChipmunkLatest-Docs/#cpSpace-Properties
  ## __ doc_
  cpSpaceSetCollisionBias(space.raw, newBias)

proc collisionPersistence*(space: Space): Natural =
  ## Returns the collision persistence value for this space.
  cpSpaceGetCollisionPersistence(space.raw).Natural

proc `collisionPersistence=`*(space: Space, value: Natural) =
  ## Sets the collision persistence value for this space.
  ## This controls for how many frames collisions should be kept around for,
  ## which helps jittering contacts from getting worse. Very, _very_, _very_ few
  ## games need to change this value.
  ## Defaults to 3.
  cpSpaceSetCollisionPersistence(space.raw, value.cpTimestamp)

proc currentTimeStep*(space: Space): float32 =
  ## Returns the current or most recent timestep of the space.
  cpSpaceGetCurrentTimeStep(space.raw)

proc isLocked*(space: Space): bool =
  ## Returns whether the space is locked (new objects cannot be added to it).
  ## Spaces are locked within collision callbacks.
  cpSpaceIsLocked(space.raw).bool

proc reindexShapesForBody*(space: Space, body: Body) =
  ## Reindexes all shapes for the given body.
  ## This **must** be done for static bodies to let Chipmunk know it needs to
  ## have its collision detection data updated.
  cpSpaceReindexShapesForBody(space.raw, body.raw)

proc addBody*(space: Space, body: Body) =
  ## Adds the body to the space.

  GC_ref(body)
  discard cpSpaceAddBody(space.raw, body.raw)

proc delBody*(space: Space, body: Body) =
  ## Deletes the given body from the space.

  cpSpaceRemoveBody(space.raw, body.raw)
  GC_unref(body)

proc contains*(space: Space, body: Body): bool =
  ## Returns whether the given space has the given body.
  cpSpaceContainsBody(space.raw, body.raw).bool

proc update*(space: Space, deltaTime: float32) =
  ## Steps the space by ``deltaTime`` seconds. This should be called inside of
  ## your game's update loop; ``deltaTime`` is the time passed between the
  ## previous and current update.
  ## You usually need to pass ``secondsPerUpdate`` here.
  cpSpaceStep(space.raw, deltaTime)

{.pop.}

proc newSpace*(gravity: Vec2f, iterations = 10.Natural): Space =
  ## Creates a new space with the given gravity and iteration count.

  new(result) do (space: Space):
    cpSpaceFree(space.raw)

  result.raw = cpSpaceNew()
  result.gravity = gravity
  result.iterations = iterations

  cpSpaceSetUserData(result.raw, cast[ptr SpaceObj](result))


# debug draw

import aglet/pixeltypes

type
  SpaceDebugDrawFlag* = enum
    ## Defines what should be debug-drawn.
    ddShapes
    ddConstraints
    ddCollisionPoints

  SpaceDebugDrawOptions*[T] = tuple
    ## Options for debug drawing. This contains callback implementations and
    ## various other settings that can be tuned.

    user: T  ## user-defined value, passed to all of the callbacks

    drawCircle: proc (t: T, center: Vec2f, radius: float32,
                      lineColor, fillColor: Rgba32f) {.nimcall.}
    drawLine: proc (t: T, a, b: Vec2f, color: Rgba32f) {.nimcall.}
    drawFatLine: proc (t: T, a, b: Vec2f, radius: float32,
                       lineColor, fillColor: Rgba32f) {.nimcall.}
    drawPolygon: proc (t: T, vertices: openArray[Vec2f], radius: float32,
                       lineColor, fillColor: Rgba32f) {.nimcall.}
    drawPoint: proc (t: T, position: Vec2f, size: float32, color: Rgba32f)
                    {.nimcall.}
    getColorForShape: proc (t: T, shape: Shape): Rgba32f {.nimcall.}
    flags: set[SpaceDebugDrawFlag]
    shapeOutlineColor, constraintColor, collisionPointColor: Rgba32f

{.push inline.}

const
  ddAll* = {low(SpaceDebugDrawFlag)..high(SpaceDebugDrawFlag)}

proc rgba(color: cpSpaceDebugColor): Rgba32f =
  rgba(color.r, color.g, color.b, color.a)

proc debug(rgba: Rgba32f): cpSpaceDebugColor =
  cpSpaceDebugColor(r: rgba.r, g: rgba.g, b: rgba.b, a: rgba.a)

proc toChipmunk[T](opts: SpaceDebugDrawOptions[T]): cpSpaceDebugDrawOptions =
  cpSpaceDebugDrawOptions(

    data: opts.unsafeAddr,

    shapeOutlineColor: opts.shapeOutlineColor.debug,
    constraintColor: opts.constraintColor.debug,
    collisionPointColor: opts.collisionPointColor.debug,

    drawCircle: proc (pos: cpVect, angle, radius: cpFloat,
                      outline, fill: cpSpaceDebugColor, data: pointer) =
      var opts = cast[ptr SpaceDebugDrawOptions](data)
      opts.drawCircle(opts.user, pos.vec2f, radius,
                      outline.rgba, fill.rgba),

    drawSegment: proc (a, b: cpVect, color: cpSpaceDebugColor, data: pointer) =
      var opts = cast[ptr SpaceDebugDrawOptions](data)
      opts.drawLine(opts.user, a.vec2f, b.vec2f, color.rgba),

    drawFatSegment: proc (a, b: cpVect, radius: float32,
                          outline, fill: cpSpaceDebugColor, data: pointer) =
      var opts = cast[ptr SpaceDebugDrawOptions](data)
      opts.drawFatLine(opts.user, a.vec2f, b.vec2f, radius,
                       outline.rgba, fill.rgba),

    drawPolygon: proc (count: cint, firstVert: ptr cpVect, radius: float32,
                       outline, fill: cpSpaceDebugColor, data: pointer) =
      var opts = cast[ptr SpaceDebugDrawOptions](data)
      opts.drawPolygon(opts.user,
                       cast[ptr UncheckedArray[Vec2f]](firstVert)
                         .toOpenArray(0, count - 1),
                       radius, outline.rgba, fill.rgba),

    drawDot: proc (size: float32, pos: cpVect,
                   color: cpSpaceDebugColor, data: pointer) =
      var opts = cast[ptr SpaceDebugDrawOptions](data)
      opts.drawPoint(opts.data, pos.vec2f, size, color.rgba),

    colorForShape: proc (shape: ptr cpShape, data: pointer): cpSpaceDebugColor =
      var
        shape = cast[Shape](cpShapeGetUserData(shape))
        opts = cast[ptr SpaceDebugDrawOptions](data)
      result = opts.getColorForShape(opts.user, shape)

  )

{.pop.}

proc debugDraw*(space: Space, opts: SpaceDebugDrawOptions) =
  ## Draws debug information using the given options.

  var cpopts = opts.toChipmunk
  cpSpaceDebugDraw(space.raw, addr cpopts)

when defined(nimcheck) or defined(nimdoc):
  # deprecated shmeprecated. 1.4 de-deprecates this pragma anyways
  {.define: rapidChipmunkGraphicsDebugDraw.}

when defined(rapidChipmunkGraphicsDebugDraw):

  import ../graphics

  proc debugDrawOptions*(
    graphics: Graphics,
    flags = ddAll,
    shapeOutlineColor: Rgba32f = colBlack,
    constraintColor: Rgba32f = colBlue,
    collisionPointColor: Rgba32f = colRed,
  ): SpaceDebugDrawOptions[Graphics] =
    ## Implements debug drawing using rapid/graphics.
    ##
    ## This feature must be enabled using -d:rapidChipmunkGraphicsDebugDraw,
    ## or alternatively, using ``{.define: rapidChipmunkGraphicsDebugDraw.}``
    ## before importing this module.

    proc drawCircle(graphics: Graphics, center: Vec2f, radius: float32,
                    lineColor, fillColor: Rgba32f) {.nimcall.} =
      graphics.circle(center, radius, fillColor)
      graphics.lineCircle(center, radius, thickness = 1, lineColor)

    proc drawLine(graphics: Graphics, a, b: Vec2f, color: Rgba32f) {.nimcall.} =
      discard

    proc drawFatLine(graphics: Graphics, a, b: Vec2f, radius: float32,
                     lineColor, fillColor: Rgba32f) {.nimcall.} =
      discard

    proc drawPolygon(graphics: Graphics, vertices: openArray[Vec2f],
                     radius: float32, lineColor, fillColor: Rgba32f)
                    {.nimcall.} =
      discard

    proc drawPoint(graphics: Graphics, point: Vec2f, size: float32,
                   color: Rgba32f) {.nimcall.} =
      discard

    proc getColorForShape(_: Graphics, shape: Shape): Rgba32f {.nimcall.} =
      if shape of CircleShape:
        result = rgba(0, 1, 0, 0.3)
      elif shape of SegmentShape:
        result = rgba(1, 0, 0, 0.3)
      else:
        result = rgba(0, 0, 1, 0.3)

    result = (
      user: graphics,
      drawCircle: drawCircle,
      drawLine: drawLine,
      drawFatLine: drawFatLine,
      drawPolygon: drawPolygon,
      drawPoint: drawPoint,
      getColorForShape: getColorForShape,
      flags: flags,
      shapeOutlineColor: shapeOutlineColor,
      constraintColor: constraintColor,
      collisionPointColor: collisionPointColor,
    )

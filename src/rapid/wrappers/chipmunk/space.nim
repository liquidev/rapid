##  Copyright (c) 2013 Scott Lembcke and Howling Moon Software
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in
##  all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
##  SOFTWARE.
##
## / @defgroup cpSpace cpSpace
## / @{
## MARK: Definitions
## / Collision begin event function callback type.
## / Returning false from a begin callback causes the collision to be ignored until
## / the the separate callback is called when the objects stop colliding.

type
  cpCollisionBeginFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                             userData: cpDataPointer): cpBool {.cdecl.}

## / Collision pre-solve event function callback type.
## / Returning false from a pre-step callback causes the collision to be ignored until the next step.

type
  cpCollisionPreSolveFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                                userData: cpDataPointer): cpBool {.cdecl.}

## / Collision post-solve event function callback type.

type
  cpCollisionPostSolveFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                                 userData: cpDataPointer) {.cdecl.}

## / Collision separate event function callback type.

type
  cpCollisionSeparateFunc* = proc (arb: ptr cpArbiter; space: ptr cpSpace;
                                userData: cpDataPointer) {.cdecl.}

## / Struct that holds function callback pointers to configure custom collision handling.
## / Collision handlers have a pair of types; when a collision occurs between two shapes that have these types, the collision handler functions are triggered.

type
  cpCollisionHandler* {.importc: "cpCollisionHandler", header: "<chipmunk/chipmunk.h>", bycopy.} = object
    typeA* {.importc: "typeA".}: cpCollisionType ## / Collision type identifier of the first shape that this handler recognizes.
                                             ## / In the collision handler callback, the shape with this type will be the first argument. Read only.
    ## / Collision type identifier of the second shape that this handler recognizes.
    ## / In the collision handler callback, the shape with this type will be the second argument. Read only.
    typeB* {.importc: "typeB".}: cpCollisionType ## / This function is called when two shapes with types that match this collision handler begin colliding.
    beginFunc* {.importc: "beginFunc".}: cpCollisionBeginFunc ## / This function is called each step when two shapes with types that match this collision handler are colliding.
                                                          ## / It's called before the collision solver runs so that you can affect a collision's outcome.
    preSolveFunc* {.importc: "preSolveFunc".}: cpCollisionPreSolveFunc ## / This function is called each step when two shapes with types that match this collision handler are colliding.
                                                                   ## / It's called after the collision solver runs so that you can read back information about the collision to trigger events in your game.
    postSolveFunc* {.importc: "postSolveFunc".}: cpCollisionPostSolveFunc ## / This function is called when two shapes with types that match this collision handler stop colliding.
    separateFunc* {.importc: "separateFunc".}: cpCollisionSeparateFunc ## / This is a user definable context pointer that is passed to all of the collision handler functions.
    userData* {.importc: "userData".}: cpDataPointer


##  TODO: Make timestep a parameter?
## MARK: Memory and Initialization
## / Allocate a cpSpace.

proc cpSpaceAlloc*(): ptr cpSpace {.importc: "cpSpaceAlloc", header: "<chipmunk/chipmunk.h>".}
## / Initialize a cpSpace.

proc cpSpaceInit*(space: ptr cpSpace): ptr cpSpace {.importc: "cpSpaceInit",
    header: "<chipmunk/chipmunk.h>".}
## / Allocate and initialize a cpSpace.

proc cpSpaceNew*(): ptr cpSpace {.importc: "cpSpaceNew", header: "<chipmunk/chipmunk.h>".}
## / Destroy a cpSpace.

proc cpSpaceDestroy*(space: ptr cpSpace) {.importc: "cpSpaceDestroy",
                                       header: "<chipmunk/chipmunk.h>".}
## / Destroy and free a cpSpace.

proc cpSpaceFree*(space: ptr cpSpace) {.importc: "cpSpaceFree", header: "<chipmunk/chipmunk.h>".}
## MARK: Properties
## / Number of iterations to use in the impulse solver to solve contacts and other constraints.

proc cpSpaceGetIterations*(space: ptr cpSpace): cint {.
    importc: "cpSpaceGetIterations", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetIterations*(space: ptr cpSpace; iterations: cint) {.
    importc: "cpSpaceSetIterations", header: "<chipmunk/chipmunk.h>".}
## / Gravity to pass to rigid bodies when integrating velocity.

proc cpSpaceGetGravity*(space: ptr cpSpace): cpVect {.importc: "cpSpaceGetGravity",
    header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetGravity*(space: ptr cpSpace; gravity: cpVect) {.
    importc: "cpSpaceSetGravity", header: "<chipmunk/chipmunk.h>".}
## / Damping rate expressed as the fraction of velocity bodies retain each second.
## / A value of 0.9 would mean that each body's velocity will drop 10% per second.
## / The default value is 1.0, meaning no damping is applied.
## / @note This damping value is different than those of cpDampedSpring and cpDampedRotarySpring.

proc cpSpaceGetDamping*(space: ptr cpSpace): cpFloat {.importc: "cpSpaceGetDamping",
    header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetDamping*(space: ptr cpSpace; damping: cpFloat) {.
    importc: "cpSpaceSetDamping", header: "<chipmunk/chipmunk.h>".}
## / Speed threshold for a body to be considered idle.
## / The default value of 0 means to let the space guess a good threshold based on gravity.

proc cpSpaceGetIdleSpeedThreshold*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetIdleSpeedThreshold", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetIdleSpeedThreshold*(space: ptr cpSpace; idleSpeedThreshold: cpFloat) {.
    importc: "cpSpaceSetIdleSpeedThreshold", header: "<chipmunk/chipmunk.h>".}
## / Time a group of bodies must remain idle in order to fall asleep.
## / Enabling sleeping also implicitly enables the the contact graph.
## / The default value of INFINITY disables the sleeping algorithm.

proc cpSpaceGetSleepTimeThreshold*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetSleepTimeThreshold", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetSleepTimeThreshold*(space: ptr cpSpace; sleepTimeThreshold: cpFloat) {.
    importc: "cpSpaceSetSleepTimeThreshold", header: "<chipmunk/chipmunk.h>".}
## / Amount of encouraged penetration between colliding shapes.
## / Used to reduce oscillating contacts and keep the collision cache warm.
## / Defaults to 0.1. If you have poor simulation quality,
## / increase this number as much as possible without allowing visible amounts of overlap.

proc cpSpaceGetCollisionSlop*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetCollisionSlop", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetCollisionSlop*(space: ptr cpSpace; collisionSlop: cpFloat) {.
    importc: "cpSpaceSetCollisionSlop", header: "<chipmunk/chipmunk.h>".}
## / Determines how fast overlapping shapes are pushed apart.
## / Expressed as a fraction of the error remaining after each second.
## / Defaults to pow(1.0 - 0.1, 60.0) meaning that Chipmunk fixes 10% of overlap each frame at 60Hz.

proc cpSpaceGetCollisionBias*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetCollisionBias", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetCollisionBias*(space: ptr cpSpace; collisionBias: cpFloat) {.
    importc: "cpSpaceSetCollisionBias", header: "<chipmunk/chipmunk.h>".}
## / Number of frames that contact information should persist.
## / Defaults to 3. There is probably never a reason to change this value.

proc cpSpaceGetCollisionPersistence*(space: ptr cpSpace): cpTimestamp {.
    importc: "cpSpaceGetCollisionPersistence", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetCollisionPersistence*(space: ptr cpSpace;
                                    collisionPersistence: cpTimestamp) {.
    importc: "cpSpaceSetCollisionPersistence", header: "<chipmunk/chipmunk.h>".}
## / User definable data pointer.
## / Generally this points to your game's controller or game state
## / class so you can access it when given a cpSpace reference in a callback.

proc cpSpaceGetUserData*(space: ptr cpSpace): cpDataPointer {.
    importc: "cpSpaceGetUserData", header: "<chipmunk/chipmunk.h>".}
proc cpSpaceSetUserData*(space: ptr cpSpace; userData: cpDataPointer) {.
    importc: "cpSpaceSetUserData", header: "<chipmunk/chipmunk.h>".}
## / The Space provided static body for a given cpSpace.
## / This is merely provided for convenience and you are not required to use it.

proc cpSpaceGetStaticBody*(space: ptr cpSpace): ptr cpBody {.
    importc: "cpSpaceGetStaticBody", header: "<chipmunk/chipmunk.h>".}
## / Returns the current (or most recent) time step used with the given space.
## / Useful from callbacks if your time step is not a compile-time global.

proc cpSpaceGetCurrentTimeStep*(space: ptr cpSpace): cpFloat {.
    importc: "cpSpaceGetCurrentTimeStep", header: "<chipmunk/chipmunk.h>".}
## / returns true from inside a callback when objects cannot be added/removed.

proc cpSpaceIsLocked*(space: ptr cpSpace): cpBool {.importc: "cpSpaceIsLocked",
    header: "<chipmunk/chipmunk.h>".}
## MARK: Collision Handlers
## / Create or return the existing collision handler that is called for all collisions that are not handled by a more specific collision handler.

proc cpSpaceAddDefaultCollisionHandler*(space: ptr cpSpace): ptr cpCollisionHandler {.
    importc: "cpSpaceAddDefaultCollisionHandler", header: "<chipmunk/chipmunk.h>".}
## / Create or return the existing collision handler for the specified pair of collision types.
## / If wildcard handlers are used with either of the collision types, it's the responibility of the custom handler to invoke the wildcard handlers.

proc cpSpaceAddCollisionHandler*(space: ptr cpSpace; a: cpCollisionType;
                                b: cpCollisionType): ptr cpCollisionHandler {.
    importc: "cpSpaceAddCollisionHandler", header: "<chipmunk/chipmunk.h>".}
## / Create or return the existing wildcard collision handler for the specified type.

proc cpSpaceAddWildcardHandler*(space: ptr cpSpace; `type`: cpCollisionType): ptr cpCollisionHandler {.
    importc: "cpSpaceAddWildcardHandler", header: "<chipmunk/chipmunk.h>".}
## MARK: Add/Remove objects
## / Add a collision shape to the simulation.
## / If the shape is attached to a static body, it will be added as a static shape.

proc cpSpaceAddShape*(space: ptr cpSpace; shape: ptr cpShape): ptr cpShape {.
    importc: "cpSpaceAddShape", header: "<chipmunk/chipmunk.h>".}
## / Add a rigid body to the simulation.

proc cpSpaceAddBody*(space: ptr cpSpace; body: ptr cpBody): ptr cpBody {.
    importc: "cpSpaceAddBody", header: "<chipmunk/chipmunk.h>".}
## / Add a constraint to the simulation.

proc cpSpaceAddConstraint*(space: ptr cpSpace; constraint: ptr cpConstraint): ptr cpConstraint {.
    importc: "cpSpaceAddConstraint", header: "<chipmunk/chipmunk.h>".}
## / Remove a collision shape from the simulation.

proc cpSpaceRemoveShape*(space: ptr cpSpace; shape: ptr cpShape) {.
    importc: "cpSpaceRemoveShape", header: "<chipmunk/chipmunk.h>".}
## / Remove a rigid body from the simulation.

proc cpSpaceRemoveBody*(space: ptr cpSpace; body: ptr cpBody) {.
    importc: "cpSpaceRemoveBody", header: "<chipmunk/chipmunk.h>".}
## / Remove a constraint from the simulation.

proc cpSpaceRemoveConstraint*(space: ptr cpSpace; constraint: ptr cpConstraint) {.
    importc: "cpSpaceRemoveConstraint", header: "<chipmunk/chipmunk.h>".}
## / Test if a collision shape has been added to the space.

proc cpSpaceContainsShape*(space: ptr cpSpace; shape: ptr cpShape): cpBool {.
    importc: "cpSpaceContainsShape", header: "<chipmunk/chipmunk.h>".}
## / Test if a rigid body has been added to the space.

proc cpSpaceContainsBody*(space: ptr cpSpace; body: ptr cpBody): cpBool {.
    importc: "cpSpaceContainsBody", header: "<chipmunk/chipmunk.h>".}
## / Test if a constraint has been added to the space.

proc cpSpaceContainsConstraint*(space: ptr cpSpace; constraint: ptr cpConstraint): cpBool {.
    importc: "cpSpaceContainsConstraint", header: "<chipmunk/chipmunk.h>".}
## MARK: Post-Step Callbacks
## / Post Step callback function type.

type
  cpPostStepFunc* = proc (space: ptr cpSpace; key: pointer; data: pointer) {.cdecl.}

## / Schedule a post-step callback to be called when cpSpaceStep() finishes.
## / You can only register one callback per unique value for @c key.
## / Returns true only if @c key has never been scheduled before.
## / It's possible to pass @c NULL for @c func if you only want to mark @c key as being used.

proc cpSpaceAddPostStepCallback*(space: ptr cpSpace; `func`: cpPostStepFunc;
                                key: pointer; data: pointer): cpBool {.
    importc: "cpSpaceAddPostStepCallback", header: "<chipmunk/chipmunk.h>".}
## MARK: Queries
##  TODO: Queries and iterators should take a cpSpace parametery.
##  TODO: They should also be abortable.
## / Nearest point query callback function type.

type
  cpSpacePointQueryFunc* = proc (shape: ptr cpShape; point: cpVect; distance: cpFloat;
                              gradient: cpVect; data: pointer) {.cdecl.}

## / Query the space at a point and call @c func for each shape found.

proc cpSpacePointQuery*(space: ptr cpSpace; point: cpVect; maxDistance: cpFloat;
                       filter: cpShapeFilter; `func`: cpSpacePointQueryFunc;
                       data: pointer) {.importc: "cpSpacePointQuery",
                                      header: "<chipmunk/chipmunk.h>".}
## / Query the space at a point and return the nearest shape found. Returns NULL if no shapes were found.

proc cpSpacePointQueryNearest*(space: ptr cpSpace; point: cpVect;
                              maxDistance: cpFloat; filter: cpShapeFilter;
                              `out`: ptr cpPointQueryInfo): ptr cpShape {.
    importc: "cpSpacePointQueryNearest", header: "<chipmunk/chipmunk.h>".}
## / Segment query callback function type.

type
  cpSpaceSegmentQueryFunc* = proc (shape: ptr cpShape; point: cpVect; normal: cpVect;
                                alpha: cpFloat; data: pointer) {.cdecl.}

## / Perform a directed line segment query (like a raycast) against the space calling @c func for each shape intersected.

proc cpSpaceSegmentQuery*(space: ptr cpSpace; start: cpVect; `end`: cpVect;
                         radius: cpFloat; filter: cpShapeFilter;
                         `func`: cpSpaceSegmentQueryFunc; data: pointer) {.
    importc: "cpSpaceSegmentQuery", header: "<chipmunk/chipmunk.h>".}
## / Perform a directed line segment query (like a raycast) against the space and return the first shape hit. Returns NULL if no shapes were hit.

proc cpSpaceSegmentQueryFirst*(space: ptr cpSpace; start: cpVect; `end`: cpVect;
                              radius: cpFloat; filter: cpShapeFilter;
                              `out`: ptr cpSegmentQueryInfo): ptr cpShape {.
    importc: "cpSpaceSegmentQueryFirst", header: "<chipmunk/chipmunk.h>".}
## / Rectangle Query callback function type.

type
  cpSpaceBBQueryFunc* = proc (shape: ptr cpShape; data: pointer) {.cdecl.}

## / Perform a fast rectangle query on the space calling @c func for each shape found.
## / Only the shape's bounding boxes are checked for overlap, not their full shape.

proc cpSpaceBBQuery*(space: ptr cpSpace; bb: cpBB; filter: cpShapeFilter;
                    `func`: cpSpaceBBQueryFunc; data: pointer) {.
    importc: "cpSpaceBBQuery", header: "<chipmunk/chipmunk.h>".}
## / Shape query callback function type.

type
  cpSpaceShapeQueryFunc* = proc (shape: ptr cpShape; points: ptr cpContactPointSet;
                              data: pointer) {.cdecl.}

## / Query a space for any shapes overlapping the given shape and call @c func for each shape found.

proc cpSpaceShapeQuery*(space: ptr cpSpace; shape: ptr cpShape;
                       `func`: cpSpaceShapeQueryFunc; data: pointer): cpBool {.
    importc: "cpSpaceShapeQuery", header: "<chipmunk/chipmunk.h>".}
## MARK: Iteration
## / Space/body iterator callback function type.

type
  cpSpaceBodyIteratorFunc* = proc (body: ptr cpBody; data: pointer) {.cdecl.}

## / Call @c func for each body in the space.

proc cpSpaceEachBody*(space: ptr cpSpace; `func`: cpSpaceBodyIteratorFunc;
                     data: pointer) {.importc: "cpSpaceEachBody",
                                    header: "<chipmunk/chipmunk.h>".}
## / Space/body iterator callback function type.

type
  cpSpaceShapeIteratorFunc* = proc (shape: ptr cpShape; data: pointer) {.cdecl.}

## / Call @c func for each shape in the space.

proc cpSpaceEachShape*(space: ptr cpSpace; `func`: cpSpaceShapeIteratorFunc;
                      data: pointer) {.importc: "cpSpaceEachShape",
                                     header: "<chipmunk/chipmunk.h>".}
## / Space/constraint iterator callback function type.

type
  cpSpaceConstraintIteratorFunc* = proc (constraint: ptr cpConstraint; data: pointer) {.cdecl.}

## / Call @c func for each shape in the space.

proc cpSpaceEachConstraint*(space: ptr cpSpace;
                           `func`: cpSpaceConstraintIteratorFunc; data: pointer) {.
    importc: "cpSpaceEachConstraint", header: "<chipmunk/chipmunk.h>".}
## MARK: Indexing
## / Update the collision detection info for the static shapes in the space.

proc cpSpaceReindexStatic*(space: ptr cpSpace) {.importc: "cpSpaceReindexStatic",
    header: "<chipmunk/chipmunk.h>".}
## / Update the collision detection data for a specific shape in the space.

proc cpSpaceReindexShape*(space: ptr cpSpace; shape: ptr cpShape) {.
    importc: "cpSpaceReindexShape", header: "<chipmunk/chipmunk.h>".}
## / Update the collision detection data for all shapes attached to a body.

proc cpSpaceReindexShapesForBody*(space: ptr cpSpace; body: ptr cpBody) {.
    importc: "cpSpaceReindexShapesForBody", header: "<chipmunk/chipmunk.h>".}
## / Switch the space to use a spatial has as it's spatial index.

proc cpSpaceUseSpatialHash*(space: ptr cpSpace; dim: cpFloat; count: cint) {.
    importc: "cpSpaceUseSpatialHash", header: "<chipmunk/chipmunk.h>".}
## MARK: Time Stepping
## / Step the space forward in time by @c dt.

proc cpSpaceStep*(space: ptr cpSpace; dt: cpFloat) {.importc: "cpSpaceStep",
    header: "<chipmunk/chipmunk.h>".}
## MARK: Debug API

when not defined(CP_SPACE_DISABLE_DEBUG_API):
  ## / Color type to use with the space debug drawing API.
  type
    cpSpaceDebugColor* {.importc: "cpSpaceDebugColor", header: "<chipmunk/chipmunk.h>", bycopy.} = object
      r* {.importc: "r".}: cfloat
      g* {.importc: "g".}: cfloat
      b* {.importc: "b".}: cfloat
      a* {.importc: "a".}: cfloat

  ## / Callback type for a function that draws a filled, stroked circle.
  type
    cpSpaceDebugDrawCircleImpl* = proc (pos: cpVect; angle: cpFloat; radius: cpFloat;
                                     outlineColor: cpSpaceDebugColor;
                                     fillColor: cpSpaceDebugColor;
                                     data: cpDataPointer) {.cdecl.}
  ## / Callback type for a function that draws a line segment.
  type
    cpSpaceDebugDrawSegmentImpl* = proc (a: cpVect; b: cpVect;
                                      color: cpSpaceDebugColor;
                                      data: cpDataPointer) {.cdecl.}
  ## / Callback type for a function that draws a thick line segment.
  type
    cpSpaceDebugDrawFatSegmentImpl* = proc (a: cpVect; b: cpVect; radius: cpFloat;
        outlineColor: cpSpaceDebugColor; fillColor: cpSpaceDebugColor;
        data: cpDataPointer) {.cdecl.}
  ## / Callback type for a function that draws a convex polygon.
  type
    cpSpaceDebugDrawPolygonImpl* = proc (count: cint; verts: ptr cpVect;
                                      radius: cpFloat;
                                      outlineColor: cpSpaceDebugColor;
                                      fillColor: cpSpaceDebugColor;
                                      data: cpDataPointer) {.cdecl.}
  ## / Callback type for a function that draws a dot.
  type
    cpSpaceDebugDrawDotImpl* = proc (size: cpFloat; pos: cpVect;
                                  color: cpSpaceDebugColor; data: cpDataPointer) {.cdecl.}
  ## / Callback type for a function that returns a color for a given shape. This gives you an opportunity to color shapes based on how they are used in your engine.
  type
    cpSpaceDebugDrawColorForShapeImpl* = proc (shape: ptr cpShape; data: cpDataPointer): cpSpaceDebugColor {.cdecl.}
    cpSpaceDebugDrawFlags* {.size: sizeof(cint).} = enum
      CP_SPACE_DEBUG_DRAW_SHAPES = 1 shl 0,
      CP_SPACE_DEBUG_DRAW_CONSTRAINTS = 1 shl 1,
      CP_SPACE_DEBUG_DRAW_COLLISION_POINTS = 1 shl 2
  ## / Struct used with cpSpaceDebugDraw() containing drawing callbacks and other drawing settings.
  type
    cpSpaceDebugDrawOptions* {.importc: "cpSpaceDebugDrawOptions",
                              header: "<chipmunk/chipmunk.h>", bycopy.} = object
      drawCircle* {.importc: "drawCircle".}: cpSpaceDebugDrawCircleImpl ## / Function that will be invoked to draw circles.
      ## / Function that will be invoked to draw line segments.
      drawSegment* {.importc: "drawSegment".}: cpSpaceDebugDrawSegmentImpl ## / Function that will be invoked to draw thick line segments.
      drawFatSegment* {.importc: "drawFatSegment".}: cpSpaceDebugDrawFatSegmentImpl ##
                                                                                ## /
                                                                                ## Function
                                                                                ## that
                                                                                ## will
                                                                                ## be
                                                                                ## invoked
                                                                                ## to
                                                                                ## draw
                                                                                ## convex
                                                                                ## polygons.
      drawPolygon* {.importc: "drawPolygon".}: cpSpaceDebugDrawPolygonImpl ## / Function that will be invoked to draw dots.
      drawDot* {.importc: "drawDot".}: cpSpaceDebugDrawDotImpl ## / Flags that request which things to draw (collision shapes, constraints, contact points).
      flags* {.importc: "flags".}: cpSpaceDebugDrawFlags ## / Outline color passed to the drawing function.
      shapeOutlineColor* {.importc: "shapeOutlineColor".}: cpSpaceDebugColor ## /
                                                                         ## Function that decides what fill color to draw shapes using.
      colorForShape* {.importc: "colorForShape".}: cpSpaceDebugDrawColorForShapeImpl ##
                                                                                 ## /
                                                                                 ## Color
                                                                                 ## passed
                                                                                 ## to
                                                                                 ## drawing
                                                                                 ## functions
                                                                                 ## for
                                                                                 ## constraints.
      constraintColor* {.importc: "constraintColor".}: cpSpaceDebugColor ## / Color passed to drawing functions for collision points.
      collisionPointColor* {.importc: "collisionPointColor".}: cpSpaceDebugColor ## /
                                                                             ## User
                                                                             ## defined
                                                                             ## context
                                                                             ## pointer
                                                                             ## passed to all of the
                                                                             ## callback
                                                                             ## functions as the
                                                                             ## 'data'
                                                                             ## argument.
      data* {.importc: "data".}: cpDataPointer

  ## / Debug draw the current state of the space using the supplied drawing options.
  proc cpSpaceDebugDraw*(space: ptr cpSpace; options: ptr cpSpaceDebugDrawOptions) {.
      importc: "cpSpaceDebugDraw", header: "<chipmunk/chipmunk.h>".}
## / @}

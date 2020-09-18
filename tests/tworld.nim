import std/macros

import aglet
import aglet/window/glfw
import rapid/ec
import rapid/game
import rapid/game/tilemap
import rapid/graphics
import rapid/physics/aabb

{.experimental: "implicitDeref".}  # why is this still experimental?

type
  Tiles = ref Tilemap[Tile]

  Physics = object of RootComponent
    position, velocity, acceleration: Vec2f
    size: Vec2f
  Collision = object of RootComponent
    physics: ptr Physics
    tilemap: Tiles
  PlayerController = object of RootComponent
    window: Window  # for input
    speed: float32

  Player = ref object of RootEntity
    controller: PlayerController
    physics: Physics
    collision: Collision

  Tile = enum
    tileAir
    tileBlock

  World = object
    tilemap: Tiles
    entities: seq[RootEntity]

proc update(physics: var Physics) =
  physics.velocity += physics.acceleration
  physics.acceleration *= 0
  physics.position += physics.velocity

proc physics(position, size: Vec2f): Physics =
  result = Physics(position: position, size: size)
  result.autoImplement()

proc update(collision: var Collision) =
  var hitbox = rectf(collision.physics.position, collision.physics.size)

  let
    velocity = collision.physics.velocity
    movingX = not velocity.x.closeTo(0.001)
    movingY = not velocity.y.closeTo(0.001)
    # did somebody say: "branchless programming"?
    directionX = cdLeft.succ(ord(velocity.x > 0))
    directionY = cdUp.succ(ord(velocity.y > 0))

  # ha, let's just throw that out the window.
  if movingX:
    let collides = hitbox.resolveCollisionXIt(collision.tilemap[], directionX):
      it == tileBlock
  if movingY:
    discard

proc collision(physics: ptr Physics, tilemap: Tiles): Collision =
  result = Collision(physics: physics, tilemap: tilemap)
  result.autoImplement()

proc playerController(window: Window, speed: float32): PlayerController =
  result = PlayerController(window: window, speed: speed)
  result.autoImplement()

proc main() =

  var agl = initAglet()
  agl.initWindow()

  var
    window = agl.newWindowGlfw(vec2i(800, 600), "game", winHints())
    graphics = window.newGraphics()

  var
    world = World(tilemap: Tiles())
    player = Player()

  world.tilemap.init(window.size div vec2i(32),
                     vec2f(32, 32))

  player.controller = playerController(window, speed = 1.0)
  player.physics = physics(position = vec2f(32, 32), size = vec2f(32, 32))
  player.collision = collision(addr player.physics, world.tilemap)
  player.registerComponents()
  world.entities.add(player)

  runGameWhile not window.closeRequested:

    window.pollEvents do (event: InputEvent):
      discard

    update:
      discard

    draw step:
      discard

when isMainModule: main()

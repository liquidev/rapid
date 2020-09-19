import aglet
import aglet/window/glfw
import rapid/ec
import rapid/game
import rapid/game/tilemap
import rapid/graphics
import rapid/physics/aabb

{.experimental: "implicitDeref".}  # why is this still experimental?

type
  Tile = enum
    tileAir
    tileBlock

proc isSolid(tile: Tile): bool = tile != tileAir

type
  Tiles = ref Tilemap[Tile]

  Physics = object of RootComponent
    position, velocity, acceleration: Vec2f
    size: Vec2f
    tilemap: Tiles
  PlayerController = object of RootComponent
    window: Window  # for input
    physics: ptr Physics
    speed: float32
  PlayerGraphics = object of RootComponent
    physics: ptr Physics
    color: Rgba32f

  Player = ref object of RootEntity
    controller: PlayerController
    physics: Physics
    graphics: PlayerGraphics

  World = object
    tilemap: Tiles
    entities: seq[RootEntity]

proc update(physics: var Physics) =
  physics.velocity += physics.acceleration
  physics.acceleration *= 0

  let
    velocity = physics.velocity
    movingX = not velocity.x.closeTo(0.001)
    movingY = not velocity.y.closeTo(0.001)
    # did somebody say: "branchless programming"?
    directionX = cdLeft.succ(ord(velocity.x > 0))
    directionY = cdUp.succ(ord(velocity.y > 0))
  var
    hitbox: Rectf

  physics.position.x += physics.velocity.x
  hitbox = rectf(physics.position, physics.size)

  # ha, let's just throw that out the window.
  if movingX:
    let collides = hitbox.resolveCollisionX(physics.tilemap[], directionX)
    physics.position.x = hitbox.x
    physics.velocity.x *= float32(not collides)

  physics.position.y += physics.velocity.y
  hitbox = rectf(physics.position, physics.size)

  if movingY:
    let collides = hitbox.resolveCollisionY(physics.tilemap[], directionY)
    physics.position.y = hitbox.y
    physics.velocity.y *= float32(not collides)


proc physics(position, size: Vec2f, tilemap: Tiles): Physics =
  result = Physics(position: position, size: size, tilemap: tilemap)
  result.autoImplement()

proc update(controller: var PlayerController) =
  let
    window = controller.window
    physics = controller.physics
    speed = controller.speed

  if window.key(keyUp):
    physics.acceleration += vec2f(0, -speed)
  if window.key(keyDown):
    physics.acceleration += vec2f(0, speed)
  if window.key(keyLeft):
    physics.acceleration += vec2f(-speed, 0)
  if window.key(keyRight):
    physics.acceleration += vec2f(speed, 0)

  physics.velocity *= 0.8

proc playerController(window: Window, physics: ptr Physics,
                      speed: float32): PlayerController =
  result = PlayerController(window: window, physics: physics, speed: speed)
  result.autoImplement()

proc shape(pgfx: var PlayerGraphics, graphics: Graphics, step: float32) =
  let position = pgfx.physics.position + pgfx.physics.velocity * step
  graphics.rectangle(position, pgfx.physics.size, color = pgfx.color)

proc playerGraphics(physics: ptr Physics, color: Rgba32f): PlayerGraphics =
  result = PlayerGraphics(physics: physics, color: color)
  result.autoImplement()

proc draw(world: var World, target: Target, graphics: Graphics, step: float32) =
  graphics.resetShape()

  for position, tile in world.tilemap.tiles:
    if tile == tileAir: continue
    graphics.rectangle(position.vec2f * world.tilemap.gridSize,
                       world.tilemap.gridSize,
                       color = colGray)

  world.entities.shape(graphics, step)

  graphics.draw(target)

proc main() =

  var agl = initAglet()
  agl.initWindow()

  var
    window = agl.newWindowGlfw(vec2i(800, 600), "game",
                               winHints(resizable = false))
    graphics = window.newGraphics()

  var
    world = World(tilemap: Tiles())
    player = Player()

  world.tilemap.init(window.size div vec2i(32),
                     vec2f(32, 32))
  for x in 1..5:
    world.tilemap[][vec2i(x.int32, 3)] = tileBlock
  for y in 3..3+5:
    world.tilemap[][vec2i(5, y.int32)] = tileBlock

  player.physics = physics(position = vec2f(32, 32), size = vec2f(32, 32),
                           world.tilemap)
  player.controller = playerController(window, addr player.physics, speed = 1.0)
  player.graphics = playerGraphics(addr player.physics, colWhite)
  player.registerComponents()
  world.entities.add(player)

  runGameWhile not window.closeRequested:

    window.pollEvents do (event: InputEvent):
      discard

    update:
      world.entities.update()

    draw step:
      var frame = window.render()
      frame.clearColor(colBlack)

      world.draw(frame, graphics, step)

      frame.finish()

when isMainModule: main()

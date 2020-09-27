import aglet
import aglet/window/glfw
import rapid/ec
import rapid/ec/physics_aabb
import rapid/game
import rapid/game/tilemap
import rapid/graphics
import rapid/physics/aabb

{.experimental: "implicitDeref".}

type
  Tile = enum
    tileAir
    tileBlock

proc isSolid(tile: Tile): bool = tile != tileAir

type
  Tiles = FlatTilemap[Tile]

  PlayerController = object of RootComponent
    window: Window  # for input
    physics: ptr AabbPhysics
    speed: float32
  PlayerGraphics = object of RootComponent
    physics: ptr AabbPhysics
    color: Rgba32f

  Player = ref object of RootEntity
    controller: PlayerController
    physics: AabbPhysics
    graphics: PlayerGraphics

  World = object
    tilemap: Tiles
    entities: seq[RootEntity]

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

proc playerController(window: Window, physics: ptr AabbPhysics,
                      speed: float32): PlayerController =
  result = PlayerController(window: window, physics: physics, speed: speed)
  result.autoImplement()

proc shape(pgfx: var PlayerGraphics, graphics: Graphics, step: float32) =
  let position = pgfx.physics.position + pgfx.physics.velocity * step
  graphics.rectangle(position, pgfx.physics.size, color = pgfx.color)

proc playerGraphics(physics: ptr AabbPhysics, color: Rgba32f): PlayerGraphics =
  result = PlayerGraphics(physics: physics, color: color)
  result.autoImplement()

proc draw(world: var World, target: Target, graphics: Graphics, step: float32) =
  graphics.resetShape()

  for position, tile in world.tilemap.tiles:
    if tile == tileAir: continue
    graphics.rectangle(position.vec2f * world.tilemap.tileSize,
                       world.tilemap.tileSize,
                       color = colGray)

  world.entities.shape(graphics, step)

  graphics.draw(target)

proc main() =

  var agl = initAglet()
  agl.initWindow()

  var
    window = agl.newWindowGlfw(800, 600, "game",
                               winHints(resizable = false))
    graphics = window.newGraphics()

  var
    world = World(tilemap: Tiles())
    player = Player()

  world.tilemap = newFlatTilemap[Tile](window.size div vec2i(32), vec2f(32, 32))
  for x in 1..5:
    world.tilemap[vec2i(x.int32, 3)] = tileBlock
  for y in 3..3+5:
    world.tilemap[vec2i(5, y.int32)] = tileBlock

  player.physics = aabbPhysics(position = vec2f(32, 32), size = vec2f(32, 32),
                               world.tilemap.collider)
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

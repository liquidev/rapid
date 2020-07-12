import std/monotimes
import std/sugar
import std/times

import aglet
import aglet/window/glfw
import rapid/graphics
import glm/noise

var tileset: seq[Sprite]

proc loadTileset(graphics: Graphics) =
  const TilesetPng = slurp("sampleData/tileset.png")
  let image = readPngImage(TilesetPng)
  template tile(x, y: int32): Image = image[recti(x * 10 + 1, y * 10 + 1, 8, 8)]
  tileset.add graphics.addSprite(tile(0, 1))
  tileset.add graphics.addSprite(tile(1, 1))
  tileset.add graphics.addSprite(tile(2, 1))
  tileset.add graphics.addSprite(tile(0, 2))
  tileset.add graphics.addSprite(tile(1, 2))
  tileset.add graphics.addSprite(tile(2, 2))
  tileset.add graphics.addSprite(tile(3, 2))

proc shapes(graphics: Graphics, time: float32) =
  graphics.rectangle(32, 32, 32, 32)
  graphics.line(vec2f(128, 32), vec2f(128 + 64, 32 + 64),
                thickness = 10, cap = lcRound,
                colorA = colMagenta, colorB = colAqua)
  graphics.circle(48, 128, 32)
  graphics.arc(48, 160, 32, 0.degrees, 180.degrees)
  graphics.transform:
    graphics.translate(128, 128)
    graphics.scale(32)
    for y in 0..<4:
      for x in 0..<4:
        let
          position = vec2f(x.float32, y.float32)
          color = rgba(x / 3, y / 3, 1, 1)
        graphics.point(position, size = 4/32, color)
  graphics.transform:
    graphics.translate(64, 256)
    let
      angle = radians(time * (2 * Pi) * 0.10)
      points = [
        vec2f(0, -48),
        vec2f(0, 0),
        angle.toVector * 48
      ]
    graphics.polyline(points, thickness = 16.0, cap = lcRound, join = ljRound,
                      color = rgba(1, 1, 1, 1))
  graphics.transform:
    graphics.translate(128, 320)
    let points = collect(newSeq):
      for x in 0..<10:
        let y = perlin(vec2f(x.float32 / 4.2, time)) * 64
        vec2f(x.float32 * 16, y)
    graphics.polyline(points, thickness = 4.0)

proc tiles(graphics: Graphics) =
  graphics.transform:
    graphics.translate(256, 32)
    for index, sprite in tileset:
      let y = index.float32 * 32
      graphics.sprite(sprite, 0, y, scale = 4)

proc main() =

  var agl = initAglet()
  agl.initWindow()

  var
    win = agl.newWindowGlfw(800, 600, "rapid/gfx", winHints(msaaSamples = 8))
    graphics = win.newGraphics()

  graphics.defaultDrawParams = graphics.defaultDrawParams.derive:
    multisample on
  graphics.spriteMinFilter = fmNearest
  graphics.spriteMagFilter = fmNearest

  graphics.loadTileset()

  let startTime = getMonoTime()
  while not win.closeRequested:
    let time = int(inMilliseconds(getMonoTime() - startTime)) / 1000
    var frame = win.render()

    frame.clearColor(rgba(0.125, 0.125, 0.125, 1.0))

    graphics.resetShape()
    shapes(graphics, time)
    tiles(graphics)
    graphics.draw(frame, graphics.defaultProgram, aglet.uniforms({
      ..graphics.uniforms(frame),
    }))

    frame.finish()

    win.pollEvents do (event: InputEvent):
      discard

main()

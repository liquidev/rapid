import std/monotimes
import std/times

import aglet
import aglet/window/glfw
import rapid/graphics

proc shapes(target: Target, graphics: Graphics, time: float32) =
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
    graphics.polyline(points, thickness = 6.0, color = rgba(1, 1, 1, 0.5))

block:
  var agl = initAglet()
  agl.initWindow()

  var
    win = agl.newWindowGlfw(800, 600, "rapid/gfx", winHints(msaaSamples = 8))
    graphics = win.newGraphics()

  graphics.defaultDrawParams = graphics.defaultDrawParams.derive:
    multisample on

  let startTime = getMonoTime()
  while not win.closeRequested:
    let time = int(inMilliseconds(getMonoTime() - startTime)) / 1000
    var frame = win.render()

    frame.clearColor(rgba(0.125, 0.125, 0.125, 1.0))

    graphics.resetShape()
    shapes(frame, graphics, time)
    graphics.draw(frame)

    frame.finish()

    win.pollEvents do (event: InputEvent):
      discard

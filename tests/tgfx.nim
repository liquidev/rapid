import aglet
import aglet/window/glfw
import rapid/gfx

var agl = initAglet()
agl.initWindow()

var
  win = agl.newWindowGlfw(800, 600, "rapid/gfx", winHints(msaaSamples = 8))
  graphics = win.newGraphics()

graphics.defaultDrawParams = graphics.defaultDrawParams.derive:
  multisample on

while not win.closeRequested:
  var frame = win.render()

  frame.clearColor(rgba(0.125, 0.125, 0.125, 1.0))

  graphics.resetShape()
  graphics.rectangle(32, 32, 32, 32)
  graphics.line(vec2f(128, 32), vec2f(128 + 64, 32 + 64),
                thickness = 3, colorA = colMagenta, colorB = colAqua)
  graphics.circle(32 + 16, 128, 32)
  graphics.draw(frame)

  frame.finish()

  win.pollEvents do (event: InputEvent):
    discard

import aglet
import aglet/window/glfw
import rapid/gfx

var agl = initAglet()
agl.initWindow()

var
  win = agl.newWindowGlfw(800, 600, "rapid/gfx", winHints())
  vect = win.newVectorial()

while not win.closeRequested:
  var frame = win.render()

  frame.clearColor(rgba(0.125, 0.125, 0.125, 1.0))

  vect.resetShape()
  vect.rectangle(32, 32, 32, 32)
  vect.draw(frame)

  frame.finish()

  win.pollEvents do (event: InputEvent):
    discard

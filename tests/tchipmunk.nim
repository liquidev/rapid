# test for chipmunk physics wrapper

import aglet
import aglet/window/glfw
import rapid/game
import rapid/graphics
{.define: rapidChipmunkGraphicsDebugDraw.}
import rapid/physics/chipmunk

proc main() =

  var agl = initAglet()
  agl.initWindow()

  var
    window = agl.newWindowGlfw(400, 400, "tchipmunk",
                               winHints(resizable = false))
    graphics = window.newGraphics()
    space = newSpace(gravity = vec2f(0, 1))

  var
    floor = newStaticBody().addTo(space)

  runGameWhile not window.closeRequested:

    window.pollEvents do (event: InputEvent):
      discard

    update:
      space.debugDraw(graphics.debugDrawOptions())

    draw step:
      var frame = window.render()
      frame.clearColor(colWhite)
      frame.finish()

when isMainModule: main()

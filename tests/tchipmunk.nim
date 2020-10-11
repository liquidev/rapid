# test for chipmunk physics wrapper

import aglet
import aglet/window/glfw
import rapid/game
import rapid/graphics
{.define: rapidChipmunkGraphicsDebugDraw.}
import rapid/physics/chipmunk

proc spawnBox(space: Space, position: Vec2f) =

  var
    body = newDynamicBody().addTo(space)
    shape = body.newBoxShape(size = vec2f(32))
  body.position = position
  shape.density = 100
  shape.elasticity = 0.5
  shape.friction = 0.4

  space.reindexShapesForBody(body)

proc main() =

  var agl = initAglet()
  agl.initWindow()

  var
    window = agl.newWindowGlfw(400, 400, "tchipmunk",
                               winHints(resizable = false,
                                        msaaSamples = 8))
    graphics = window.newGraphics()
    space = newSpace(gravity = vec2f(0, 10))

  var
    floor = newStaticBody().addTo(space)
    floorSegment = floor.newSegmentShape(vec2f(100, 300), vec2f(300, 300))
  floorSegment.elasticity = 0.5
  floorSegment.friction = 0.4

  graphics.defaultDrawParams = graphics.defaultDrawParams.derive:
    multisample on

  runGameWhile not window.closeRequested:

    window.pollEvents do (event: InputEvent):
      case event.kind
      of iekMousePress:
        space.spawnBox(window.mouse)
      else: discard

    update:
      var oob: seq[Body]
      space.update(secondsPerUpdate * 10)
      space.eachBody do (body: Body):
        if body.position.y > 500:
          oob.add(body)
        echo (position: body.position)
      for body in oob:
        space.delBody(body)
      GC_fullCollect()

    draw step:
      var frame = window.render()
      frame.clearColor(colWhite)

      graphics.resetShape()
      space.debugDraw(graphics.debugDrawOptions())
      graphics.draw(frame)

      frame.finish()

when isMainModule: main()

# test for chipmunk physics wrapper

import aglet
import aglet/window/glfw
import rapid/game
import rapid/graphics
import rapid/graphics/postprocess
{.define: rapidChipmunkGraphicsDebugDraw.}
import rapid/physics/chipmunk

type
  FluidObj = object

const
  FluidTag = FluidObj()
  ParticleSize = 4

proc spawnBox(space: Space, position: Vec2f) =

  var
    body = newDynamicBody(FluidTag).addTo(space)
    shape = body.newCircleShape(radius = ParticleSize)
  body.position = position
  shape.density = 100
  shape.elasticity = 0.5
  # shape.friction = 0.4

  space.reindexShapesForBody(body)

proc main() =

  var agl = initAglet()
  agl.initWindow()

  var
    window = agl.newWindowGlfw(400, 400, "tchipmunk",
                               winHints(resizable = false,
                                        msaaSamples = 8))
    graphics = window.newGraphics()
    effectBuffer = window.newEffectBuffer(window.size)
    space = newSpace(gravity = vec2f(0, 60 * 8), iterations = 10)
    placing = false
    debugDraw = false

  var
    floor = newStaticBody().addTo(space)
    floorSegments = [
      (a: vec2f(68, 85), b: vec2f(200, 161)),
      (a: vec2f(149, 306), b: vec2f(330, 200)),
      (a: vec2f(34, 364), b: vec2f(234, 364)),
    ]
  for (a, b) in floorSegments:
    var segment = floor.newSegmentShape(a, b, radius = 2)
    segment.elasticity = 0.5
    # segment.friction = 0.4

  let
    blobSprite = block:
      const blobSize = 16
      var pixels: seq[Rgba8]
      for y in 0..<blobSize:
        for x in 0..<blobSize:
          let
            fx = (x / blobSize) * 2 - 1
            fy = (y / blobSize) * 2 - 1
            i = max(0.0, 1.0 - distance(vec2f(0), vec2f(fx, fy)))
            a = i.pow(2)
          pixels.add(rgba8(255, 255, 255, uint8 a * 255))
      graphics.addSprite(vec2i(blobSize), pixels)
    alphaThreshold = window.newPostProcess(glsl"""
      #version 330 core

      in vec2 bufferUv;
      in vec2 pixelPosition;

      uniform sampler2D buffer;
      uniform float threshold;
      uniform float smoothness;
      uniform vec4 color;

      out vec4 outColor;

      void main(void) {
        float alpha = smoothstep(threshold - smoothness, threshold + smoothness,
                                 texture(buffer, bufferUv).a);
        outColor = vec4(color.rgb, color.a * alpha);
      }
    """)

  runGameWhile not window.closeRequested:

    window.pollEvents do (event: InputEvent):
      if event.kind in {iekMousePress, iekMouseRelease}:
        placing = event.kind == iekMousePress
      elif event.kind == iekKeyPress:
        if event.key == keySlash:
          debugDraw = not debugDraw

    update:
      if placing:
        space.spawnBox(window.mouse)
      var oob: seq[Body]
      space.update(secondsPerUpdate)
      space.eachBody do (body: Body):
        if body.position.y > 500:
          oob.add(body)
      for body in oob:
        space.delBody(body)

    draw step:
      var frame = window.render()
      frame.clearColor(colWhite)

      var effect = effectBuffer.render()
      effect.clearColor(rgba(0, 0, 0, 0))

      graphics.resetShape()
      space.eachBody do (body: Body):
        if body of UserBody[FluidObj]:
          const rs = vec2f(ParticleSize * 10)
          graphics.sprite(blobSprite, body.position - rs / 2, size = rs,
                          tint = colDarkTurquoise)
      graphics.draw(effect)
      effectBuffer.apply(alphaThreshold, uniforms {
        threshold: 0.15f,
        smoothness: 0.02f,
        color: colDarkTurquoise.rgba32f.Vec4f,
      })
      effectBuffer.drawTo(frame)

      graphics.resetShape()
      for (a, b) in floorSegments:
        graphics.line(a, b, thickness = 2, colorA = colBlack, colorB = colBlack)
      graphics.draw(frame)

      if debugDraw:
        graphics.resetShape()
        space.debugDraw(graphics.debugDrawOptions())
        graphics.draw(frame)

      frame.finish()

when isMainModule: main()

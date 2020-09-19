## rapid/graphics - laser test
## this tests multi-target HDR post-processing effects.

import std/monotimes
import std/times

import aglet
import aglet/window/glfw
import rapid/graphics
import rapid/graphics/postprocess

const
  ThresholdSplitSource = glsl"""
    #version 330 core

    in vec2 bufferUv;
    in vec2 pixelPosition;

    uniform sampler2D buffer0;
    uniform sampler2D buffer1;  // unused
    uniform float threshold;

    layout (location = 0) out vec4 original;
    layout (location = 1) out vec4 crossed;

    float luma(vec4 color) {
      return (0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b) * color.a;
    }

    void main() {
      vec4 texel = texture(buffer0, bufferUv);
      original = texel;

      float luminosity = luma(texel);
      vec4 crossedColor = texel * step(threshold, luminosity);
      crossedColor.a = luminosity - threshold;
      crossed = crossedColor;
    }
  """
  BlurCrossedSource = glsl"""
    #version 330 core

    in vec2 bufferUv;
    in vec2 pixelPosition;

    uniform sampler2D buffer0;  // original pixels
    uniform sampler2D buffer1;  // pixels that crossed the threshold
    uniform vec2 bufferSize;
    uniform vec2 blurDirection;
    uniform int blurSamples;

    layout (location = 0) out vec4 original;
    layout (location = 1) out vec4 blurred;

    vec4 texturePixel(sampler2D tex, vec2 pix) {
      pix /= bufferSize;
      pix.y = 1.0 - pix.y;
      return texture(tex, pix);
    }

    float gaussian(float x) {
      return pow(2.71828, -(x*x / 0.125));
    }

    void main() {
      original = texture(buffer0, bufferUv);

      float start = -floor(float(blurSamples) / 2.0);
      float end = start + float(blurSamples);
      vec4 sum = vec4(0.0);
      float den = 0.0;
      for (float i = start; i <= end; ++i) {
        vec2 offset = blurDirection * i;
        float factor = gaussian(i / -start);
        sum += texturePixel(buffer1, pixelPosition + offset) * factor;
        den += factor;
      }
      sum /= den;
      blurred = sum;
    }
  """
  SumBuffersSource = glsl"""
    #version 330 core

    in vec2 bufferUv;
    in vec2 pixelPosition;

    uniform sampler2D buffer0;
    uniform sampler2D buffer1;

    out vec4 summed;

    void main() {
      vec4 bloom = texture(buffer1, bufferUv);
      summed = texture(buffer0, bufferUv) + bloom * bloom.a;
    }
  """

proc laser(graphics: Graphics, a, b: Vec2f, glowColor, coreColor: Rgba32f) =
  graphics.line(a, b, 32, lcRound, glowColor, glowColor)
  graphics.line(a, b, 16, lcRound, coreColor, coreColor)

var
  fxThresholdSplit: PostProcess
  fxBlurCrossed: PostProcess
  fxSumBuffers: PostProcess

proc bloom(buffer: EffectBuffer,
           threshold: float32 = 1.0,
           size = 32.Natural) =
  buffer.apply(fxThresholdSplit, uniforms {
    threshold: threshold,
  })
  buffer.apply(fxBlurCrossed, uniforms {
    blurDirection: vec2f(1.0, 0.0),
    blurSamples: size.int32,
  })
  buffer.apply(fxBlurCrossed, uniforms {
    blurDirection: vec2f(0.0, 1.0),
    blurSamples: size.int32,
  })
  buffer.apply(fxSumBuffers, NoUniforms)

proc main() =

  const
    GlowColor1 = rgba(0.0, 1.0, 0.88, 5.0)
    GlowColor2 = rgba(1.0, 0.0, 0.25, 5.0)
    CoreColor = rgba(1.0, 1.0, 1.0, 1.0)

  var agl = initAglet()
  agl.initWindow()

  let
    window = agl.newWindowGlfw(800, 600, "laser", winHints())
    graphics = window.newGraphics()
    effects = window.newEffectBuffer(window.framebufferSize,
                                     colorTargets = 2, hdr = on)
    dpAdditive = defaultDrawParams().derive:
      blend blendAdditive

  var bloomEnabled = true

  fxThresholdSplit = window.newPostProcess(ThresholdSplitSource)
  fxBlurCrossed = window.newPostProcess(BlurCrossedSource)
  fxSumBuffers = window.newPostProcess(SumBuffersSource)

  window.swapInterval = 0

  var
    lastTime = getMonoTime()
    timeAccum = 0.0
    framesSinceLastReport = 0
  const ReportInterval = 500
  while not window.closeRequested:
    let
      currentTime = getMonoTime()
      deltaTime = currentTime - lastTime
      deltaMillis = deltaTime.inNanoseconds.int / 1_000_000
    lastTime = currentTime
    timeAccum += deltaMillis
    framesSinceLastReport.inc()
    if framesSinceLastReport > ReportInterval:
      echo timeAccum / ReportInterval, " ms (",
           ReportInterval / (timeAccum / 1000), " fps)"
      framesSinceLastReport = 0
      timeAccum = 0

    var frame = window.render()
    frame.clearColor(rgba(0, 0, 0, 255))

    var target = effects.render()
    target.clearColor(rgba(0, 0, 0, 0))
    graphics.transform:
      graphics.translate(window.size.vec2f / 2)
      graphics.resetShape()
      graphics.laser(a = vec2f(0), b = window.size.vec2f / 2 - window.mouse,
                     GlowColor1, CoreColor)
      graphics.laser(a = vec2f(0), b = window.mouse - window.size.vec2f / 2,
                     GlowColor2, CoreColor)
      graphics.draw(target, dpAdditive)
    if bloomEnabled: effects.bloom()
    effects.drawTo(frame)

    frame.finish()

    window.pollEvents do (event: InputEvent):
      case event.kind
      of iekWindowFrameResize:
        echo "resize to ", event.size
        effects.resize(event.size)
        echo effects.size
      of iekKeyPress:
        if event.key == keyB:
          bloomEnabled = not bloomEnabled
      else: discard

when isMainModule: main()

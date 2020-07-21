## Post-processing filters and a ping-pong buffer.

import aglet
from aglet/gl import OpenGl

import context

type
  EffectVertex = object
    position, uv: Vec2f
  PostProcess* = distinct Program[EffectVertex]
    ## Post-processing effect.
  EffectBuffer* = ref object
    ## Ping-pong framebuffer for post-processing effects.
    window: Window
    size: Vec2i
    colorTargetCount: Positive
    hdr: bool
    a, b: MultiFramebuffer
    fullscreenRect: Mesh[EffectVertex]
    drawParams: DrawParams
    passthrough: Program[EffectVertex]
  EffectTarget* = object of Target
    ## Target for rendering to an effect buffer.
    buffer: EffectBuffer

const
  PostProcessVertexShader = glsl"""
    #version 330 core

    in vec2 position;
    in vec2 uv;

    uniform vec2 bufferSize;

    out vec2 bufferUv;
    out vec2 pixelPosition;

    void main(void) {
      gl_Position = vec4(position, 0.0, 1.0);

      bufferUv = uv;

      vec2 invertedUv = uv;
      uv.y = 1.0 - uv;
      pixelPosition = invertedUv * bufferSize;
    }
  """
  PassthroughVertexShader = glsl"""
    #version 330 core

    in vec2 position;
    in vec2 uv;

    out vec2 bufferUv;

    void main(void) {
      gl_Position = vec4(position, 0.0, 1.0);
      bufferUv = uv;
    }
  """
  PassthroughFragmentShader = glsl"""
    #version 330 core

    in vec2 bufferUv;

    uniform sampler2D buffer;

    out vec2 color;

    void main(void) {
      color = texture(buffer, bufferUv);
    }
  """

proc newPostProcess*(window: Window, source: GlslSource): PostProcess =
  ## Creates a new post-processing shader program.
  ## ``source`` is a string contatining GLSL source code for the fragment
  ## shader. The fragment shader has some extra input variables it can use:
  ##
  ## - ``in vec2 bufferUv`` – UV coordinates for sampling from
  ##   the ``buffer`` texture
  ## - ``in vec2 pixelPosition`` –  ``textureUv``, but transformed to
  ##   screen coordinates
  ## - ``uniform vec2 bufferSize`` – the effect buffer's size
  ## - ``uniform sampler2D buffer`` – the effect buffer texture

  window.newProgram[:EffectVertex](PostProcessVertexShader, source).PostProcess

proc size*(buffer: EffectBuffer): Vec2i {.inline.} =
  ## Returns the size of the effect buffer as a vector.
  buffer.size

proc width*(buffer: EffectBuffer): int32 {.inline.} =
  ## Returns the width of the effect buffer.
  buffer.size.x

proc height*(buffer: EffectBuffer): int32 {.inline.} =
  ## Returns the height of the effect buffer.
  buffer.size.y

template createColor(window: Window, size: Vec2i, hdr: bool): ColorSource =

  if hdr:
    window.newTexture2D[:Rgba32f](size).source
  else:
    window.newTexture2D[:Rgba8](size).source

template createFramebuffer(window: Window, size: Vec2i,
                           colorTargetCount: Positive,
                           hdr: bool): MultiFramebuffer =

  var colorSources: seq[ColorSource]
  for i in 0..<colorTargetCount:
    colorSources.add(createColor(window, size, hdr))

  let
    depthSource = window.newRenderbuffer[:Depth32](size)
    stencilSource = window.newRenderbuffer[:Stencil8](size)

  window.newFramebuffer(colorSources, depthSource, stencilSource)

proc resize*(buffer: EffectBuffer, size: Vec2i) =
  ## Resizes the effect buffer. This resets the contents of the buffer,
  ## so be careful!

  buffer.size = size
  buffer.a = createFramebuffer(buffer.window, buffer.size,
                               buffer.colorTargetCount, buffer.hdr)
  buffer.b = createFramebuffer(buffer.window, buffer.size,
                               buffer.colorTargetCount, buffer.hdr)

proc newEffectBuffer*(window: Window, size: Vec2i,
                      colorTargets = 1.Positive, hdr = off): EffectBuffer =
  ## Creates a new effect buffer with the given size. ``colorTargets`` allows
  ## you to control how many color outputs fragment shaders can use. ``hdr``
  ## controls whether the buffer uses float32 RGBA instead of uint8 RGBA, thus
  ## enabling values outside of 0.0..1.0 to be output by post-processing
  ## effects. Useful for effects like bloom.

  result = EffectBuffer(colorTargetCount: colorTargets)
  result.window = window
  result.hdr = hdr
  result.resize(size)
  result.fullscreenRect = window.newMesh(
    primitive = dpTriangleStrip,
    usage = muStatic,
    vertices = [
      EffectVertex(position: vec2f(-1,  1), uv: vec2f(0, 1)),
      EffectVertex(position: vec2f( 1,  1), uv: vec2f(1, 1)),
      EffectVertex(position: vec2f(-1, -1), uv: vec2f(0, 0)),
      EffectVertex(position: vec2f( 1, -1), uv: vec2f(1, 0)),
    ],
  )
  result.drawParams = defaultDrawParams().derive:
    blend blendAlphaPremult
  result.passthrough =
    window.newProgram[:EffectVertex](PassthroughVertexShader,
                                     PassthroughFragmentShader)

proc render*(buffer: EffectBuffer): EffectTarget =
  ## Returns a rendering target that draws to the buffer.

  let aTarget = buffer.a.render()
  result.size = buffer.size
  result.gl = aTarget.gl
  result.buffer = buffer
  result.useImpl = proc (target: Target, gl: OpenGl) =
    # ↓ java programming in a nutshell
    target.EffectTarget.buffer.a.render().useImpl(target, gl)

proc sampler*(buffer: EffectBuffer,
              minFilter, magFilter: TextureMagFilter = fmLinear,
              wrapS, wrapT = twClampToEdge,
              borderColor = rgba(0, 0, 0, 0),
              colorTarget = 0.Natural): Sampler =
  ## Sample from the given effect buffer. Use this for rendering the effect
  ## buffer onto the screen.
  ## ``colorTarget`` controls which target to sample from.

  let texture = buffer.a.color(colorTarget).Texture
  texture.sampler(
    minFilter, magFilter,
    wrapS, wrapT, wrapR = twClampToBorder,
    borderColor
  )

proc apply*[U: UniformSource](buffer: EffectBuffer,
                              effect: PostProcess, uniforms: U,
                              minFilter, magFilter: TextureMagFilter = fmLinear,
                              wrapS, wrapT = twClampToEdge,
                              borderColor = rgba(0, 0, 0, 0)) =
  ## Applies an effect to the surface's buffer, passing the given uniforms into
  ## the shader program.
  ##
  ## The following extra uniforms are passed along:
  ## - ``?bufferSize: vec2`` – the size of the effect buffer
  ## - ``?buffer: sampler2D[]`` – samplers for the effect buffer's color
  ##    attachments. This is an array only if the effect buffer has >1 color
  ##    attachment
  ##
  ## This procedure also accepts parameters for how the color attachments should
  ## be sampled by the ``?buffer`` uniform.

  var
    bTarget = buffer.b.render()
    samplers {.global, threadvar.}: seq[Sampler]
  for colorTarget in 0..<buffer.colorTargetCount:
    samplers.add(buffer.sampler(minFilter, magFilter,
                                wrapS, wrapT,
                                borderColor,
                                colorTarget))
  bTarget.draw(effect.Program, buffer.fullscreenRect, aglet.uniforms {
    ?bufferSize: buffer.size.vec2f,
    ?buffer: samplers,
    ..uniforms,
  }, buffer.drawParams)

  swap(buffer.a, buffer.b)

proc drawTo*(buffer: EffectBuffer, target: Target,
             minFilter, magFilter: TextureMagFilter = fmLinear,
             wrapS, wrapT = twClampToEdge,
             borderColor = rgba(0, 0, 0, 0),
             colorTarget = 0.Natural) =
  ## Draws the contents of the ``buffer``'s target ``colorTarget``
  ## onto ``target``, using the given sampling parameters.

  target.draw(buffer.passthrough, buffer.fullscreenRect, aglet.uniforms {
    buffer: buffer.sampler(minFilter, magFilter,
                           wrapS, wrapT,
                           borderColor,
                           colorTarget),
  }, buffer.drawParams)

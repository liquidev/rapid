#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module provides a post-processing effect surface.

import ../gfx
import ../gfx/opengl
import ../lib/glad/gl
import ../res/textures

const
  REffectVshSrc = """
    #version 330 core

    layout (location = 0) in vec2 rapid_vPos;
    layout (location = 1) in vec4 rapid_vCol;
    layout (location = 2) in vec2 rapid_vUV;

    out vec2 rapid_vfUV;

    void main(void) {
      gl_Position = vec4(rapid_vPos.x, rapid_vPos.y, 0.0, 1.0);
      rapid_vfUV = rapid_vUV;
    }
  """
  REffectLibSrc = """
    #version 330 core

    in vec2 rapid_vfUV;

    uniform sampler2D rapid_surface;

    uniform float rapid_width;
    uniform float rapid_height;

    out vec4 rapid_fCol;

    vec4 rPixel(vec2 pos) {
      return texture(rapid_surface, vec2(pos.x / rapid_width,
                                         pos.y / rapid_height));
    }

    vec4 rEffect(vec2 scrPos);

    void main(void) {
      rapid_fCol = rEffect(gl_FragCoord.xy);
    }
  """

type
  RFxSurface* = ref object
    baseVertSh, baseFragSh: RShader
    target, auxA, auxB, a, b: RCanvas
    ctx: RGfxContext
    prevFbs: FbPair
  REffect* = ref object
    program: RProgram

proc reset(fx: RFxSurface) =
  fx.a = fx.auxA
  fx.b = fx.auxB

proc newAuxCanvas(fx: RFxSurface, conf = DefaultTextureConfig): RCanvas =
  let canvas = newRCanvas(fx.target.width, fx.target.height, conf)
  fx.target.onResize do (_: RCanvas, width, height: float):
    canvas.resize(width, height)
  result = canvas

proc newRFxSurface*(target: RCanvas, conf = DefaultTextureConfig): RFxSurface =
  ## Creates a new effect surface.
  result = RFxSurface(target: target)
  result.auxA = result.newAuxCanvas(conf)
  result.auxB = result.newAuxCanvas(conf)
  result.reset()

proc newREffect*(fx: RFxSurface, effect: string): REffect =
  ## Creates a new post-processing effect.
  runnableExamples:
    let myEffect = gfx.newREffect("""
      vec4 rEffect(vec2 pos) {
        return rPixel(pos + sin(pos.x / rapid_height * 3.0) * 8.0);
      }
    """)
  var program = newRProgram()
  if fx.baseVertSh.int == 0:
    fx.baseVertSh = newRShader(shVertex, REffectVshSrc)
  if fx.baseFragSh.int == 0:
    fx.baseFragSh = newRShader(shFragment, REffectLibSrc)
  let fsh = newRShader(shFragment, """
    uniform float rapid_width;
    uniform float rapid_height;

    vec4 rPixel(vec2 pos);
  """ & effect)
  program.attach(fx.baseVertSh)
  program.attach(fx.baseFragSh)
  program.attach(fsh)
  program.link()
  glDeleteShader(fsh.GLuint)
  program.uniform("rapid_surface", 0)
  result = REffect(program: program)

template paramProc(T: typedesc): untyped {.dirty.} =
  proc param*(eff: REffect, name: string, val: T) =
    eff.program.uniform(name, val)
paramProc(float)
paramProc(Vec2f)
paramProc(Vec3f)
paramProc(Vec4f)
paramProc(int)
paramProc(Mat4f)

proc begin*(fx: RFxSurface, ctx: RGfxContext,
            copyTarget = false) =
  ## Begins drawing to an effect surface.
  doAssert fx.ctx.isNil,
    "Cannot begin() an effect surface twice. Call finish() first"
  fx.ctx = ctx
  fx.prevFbs = currentGlc.framebuffers
  currentGlc.framebuffer = fx.a.id
  if copyTarget:
    currentGlc.withFramebuffers((fx.target.id, fx.a.id)):
      glBlitFramebuffer(0, 0, fx.target.width.GLint, fx.target.height.GLint,
                        0, 0, fx.a.width.GLint, fx.a.height.GLint,
                        GL_COLOR_BUFFER_BIT,
                        GL_NEAREST)
    ctx.renderTo(fx.b): fx.ctx.clear(gray(0, 0))
  else:
    ctx.renderTo(fx.a): fx.ctx.clear(gray(0, 0))
    ctx.renderTo(fx.b): fx.ctx.clear(gray(0, 0))

proc effect*(fx: RFxSurface, eff: REffect, stencil = false) =
  ## Applies an effect to the contents on the effect surface.
  let
    prevProgram = fx.ctx.program
    prevTexture = fx.ctx.texture
    prevBlendMode = fx.ctx.blendMode
  if stencil:
    currentGlc.withFramebuffers((fx.a.id, fx.b.id)):
      glBlitFramebuffer(0, 0, fx.a.width.GLint, fx.a.height.GLint,
                        0, 0, fx.b.width.GLint, fx.b.height.GLint,
                        GL_STENCIL_BUFFER_BIT, GL_NEAREST)
  fx.ctx.renderTo(fx.b):
    fx.ctx.clear(gray(0, 0))
    fx.ctx.transform:
      fx.ctx.resetTransform()
      fx.ctx.texture = fx.a
      fx.ctx.program = eff.program
      fx.ctx.blendMode = bmPremultAlpha
      fx.ctx.begin()
      fx.ctx.rect(-1, 1, 2, -2)
      fx.ctx.draw()
      fx.ctx.blendMode = prevBlendMode
      fx.ctx.program = prevProgram
      fx.ctx.texture = prevTexture
  swap(fx.a, fx.b)
  currentGlc.framebuffer = fx.a.id

proc finish*(fx: RFxSurface,
             replaceTarget = false) =
  ## Finishes drawing to the effect surface, and draws the image drawn onto it
  ## to the target canvas. If ``replaceTarget`` is true, the pixels will be
  ## copied directly without any blending. This may save performance in some
  ## cases.
  let
    prevTexture = fx.ctx.texture
    prevBlendMode = fx.ctx.blendMode
  if replaceTarget:
    currentGlc.withFramebuffers((fx.a.id, fx.target.id)):
      glBlitFramebuffer(0, 0, fx.a.width.GLint, fx.a.height.GLint,
                        0, 0, fx.target.width.GLint, fx.target.height.GLint,
                        GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT,
                        GL_NEAREST)
  else:
    renderTo(fx.ctx, fx.target):
      transform(fx.ctx):
        fx.ctx.resetTransform()
        fx.ctx.texture = fx.a
        fx.ctx.blendMode = bmPremultAlpha
        fx.ctx.begin()
        fx.ctx.rect(0, 0, fx.target.width, fx.target.height)
        fx.ctx.draw()
        fx.ctx.blendMode = prevBlendMode
        fx.ctx.texture = prevTexture
  fx.reset()
  fx.ctx = nil
  currentGlc.framebuffers = fx.prevFbs

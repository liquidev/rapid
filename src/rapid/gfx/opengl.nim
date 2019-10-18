#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Common OpenGL things.

import ../lib/glad/gl
import ../lib/sdl

type
  GLError* = object of Defect
  GLContext* = ref object
    ## An object used for storing OpenGL state.
    window*: ptr sdl.Window
    fTex2D: GLuint
    fFramebuffers: FbPair
    fRenderbuffer: GLuint
    fSrcBlend, fDestBlend: GLenum
    fStencilFunc: StencilFunc
    fStencilOp: StencilOp
    fViewport: Viewport
  FbPair* = tuple[read, draw: GLuint]
  BlendFunc* = tuple[src, dest: GLenum]
  StencilFunc* = tuple[fn: GLenum, refer: GLint, mask: GLuint]
  StencilOp* = tuple[fail, zfail, zpass: GLenum]
  Viewport* = tuple[x, y: GLint, w, h: GLsizei]

# TODO: Merge global state into a state object
var currentGlc*: GLContext

proc makeCurrent*(ctx: GLContext) =
  if not ctx.isNil: glfw.makeContextCurrent(ctx.window)
  currentGlc = ctx

template with*(ctx: GLContext, body: untyped) =
  let prevCtx = currentGlc
  ctx.makeCurrent()
  body
  prevCtx.makeCurrent()

proc tex2D*(ctx: GLContext): GLuint =
  result = ctx.fTex2D

proc `tex2D=`*(ctx: GLContext, tex: GLuint) =
  glBindTexture(GL_TEXTURE_2D, tex)
  ctx.fTex2D = tex

proc framebuffers*(ctx: GLContext): FbPair =
  result = ctx.fFramebuffers

proc `framebuffers=`*(ctx: GLContext, fbs: FbPair) =
  glBindFramebuffer(GL_READ_FRAMEBUFFER, fbs.read)
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fbs.draw)
  ctx.fFramebuffers = fbs

proc `framebuffer=`*(ctx: GLContext, fb: GLuint) =
  glBindFramebuffer(GL_FRAMEBUFFER, fb)
  ctx.fFramebuffers = (fb, fb)

proc renderbuffer*(ctx: GLContext): GLuint =
  result = ctx.fRenderbuffer

proc `renderbuffer=`*(ctx: GLContext, rb: GLuint) =
  glBindRenderbuffer(GL_RENDERBUFFER, rb)
  ctx.fRenderbuffer = rb

proc blendFunc*(ctx: GLContext): BlendFunc =
  result = (ctx.fSrcBlend, ctx.fDestBlend)

proc blendFunc*(ctx: GLContext, src, dest: GLenum) =
  glBlendFunc(src, dest)
  ctx.fSrcBlend = src
  ctx.fDestBlend = dest

proc `stencilFunc=`*(ctx: GLContext, fn: StencilFunc) =
  glStencilFunc(fn.fn, fn.refer, fn.mask)
  ctx.fStencilFunc = fn

proc stencilFunc*(ctx: GLContext): StencilFunc =
  result = ctx.fStencilFunc

proc `stencilOp=`*(ctx: GLContext, op: StencilOp) =
  glStencilOp(op.fail, op.zfail, op.zpass)
  ctx.fStencilOp = op

proc stencilOp*(ctx: GLContext): StencilOp =
  result = ctx.fStencilOp

proc `viewport=`*(ctx: GLContext, vp: Viewport) =
  glViewport(vp.x, vp.y, vp.w, vp.h)
  ctx.fViewport = vp

proc viewport*(ctx: GLContext): Viewport =
  result = ctx.fViewport

template withFor(name, field, T) {.dirty.} =
  template `with name`*(ctx: GLContext, val: T, body) =
    let prev = ctx.field
    ctx.field = val
    body
    ctx.field = prev

withFor(Tex2D, tex2D, GLuint)
withFor(Framebuffers, framebuffers, FbPair)
withFor(Renderbuffer, renderbuffer, GLuint)
withFor(StencilFunc, stencilFunc, StencilFunc)
withFor(StencilOp, stencilOp, StencilOp)
withFor(Viewport, viewport, Viewport)

template withBlendFunc*(ctx: GLContext, src, dest: GLenum, body) =
  let
    prevSrc = ctx.fSrcBlend
    prevDest = ctx.fDestBlend
  ctx.blendFunc(src, dest)
  body
  ctx.blendFunc(prevSrc, prevDest)

template withFramebuffer*(ctx: GLContext, fb: GLuint, body) =
  let prevFbs = ctx.framebuffers
  ctx.framebuffer = fb
  body
  if prevFbs.read != prevFbs.draw:
    ctx.framebuffers = prevFbs
  else:
    ctx.framebuffer = prevFbs.read

proc newGLContext*(win: glfw.Window): GLContext =
  GLContext(
    window: win,
    fTex2D: 0,
    fFramebuffers: (0.GLuint, 0.GLuint),
    fSrcBlend: GL_ONE, fDestBlend: GL_ZERO,
    fStencilFunc: (GL_ALWAYS, 0.GLint, 255.GLuint),
    fStencilOp: (GL_KEEP, GL_KEEP, GL_KEEP)
  )

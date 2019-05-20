#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## Common OpenGL things.

import ../lib/glad/gl
from ../lib/glfw import nil

type
  GLError* = object of Exception
  GLContext* = ref object
    ## An object used for storing OpenGL state.
    window*: glfw.Window
    tex2Did*: GLuint

# I know global variables are bad, but the current OpenGL context is global to
# the current process.
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
  result = ctx.tex2Did

proc `tex2D=`*(ctx: GLContext, tex: GLuint) =
  glBindTexture(GL_TEXTURE_2D, tex)
  ctx.tex2Did = tex

template withTex2D*(ctx: GLContext, tex: GLuint, body: untyped) =
  let prevTex = ctx.tex2D
  glBindTexture(GL_TEXTURE_2D, tex)
  ctx.tex2D = tex
  body
  glBindTexture(GL_TEXTURE_2D, prevTex)
  ctx.tex2D = prevTex

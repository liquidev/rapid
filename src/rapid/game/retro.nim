## A fixed-size pixel canvas that scales to the size of the window.

import aglet

import ../graphics/meshes
import ../graphics/programs
import ../graphics/vertex_types

type
  Retro* = ref object
    window: Window
    canvas: Texture2D[Rgba8]
    framebuffer: SimpleFramebuffer
      ## this framebuffer always has depth and stencil attachments

    program: Program[Vertex2dUv]
    rect: Mesh[Vertex2dUv]
    drawParams: DrawParams

    scale: Positive
    position: Vec2f

proc newRetro*(window: Window, size: Vec2i): Retro =
  ## Creates a new retro canvas with the given size.

  result = Retro(scale: 1)
  result.window = window
  result.canvas = window.newTexture2D[:Rgba8](size)

  var renbuf = window.newRenderbuffer[:Depth24Stencil8](size)
  result.framebuffer = window.newFramebuffer(result.canvas, renbuf)

  result.program = window.programProjection(Vertex2dUv)
  result.rect = window.newMesh[:Vertex2dUv](muStatic, dpTriangleStrip)
  result.drawParams = defaultDrawParams()

{.push inline.}

proc size*(retro: Retro): Vec2i =
  ## Returns the size of the retro canvas as a vector.
  retro.canvas.size

proc width*(retro: Retro): int =
  ## Returns the width of the retro canvas.
  retro.size.x

proc height*(retro: Retro): int =
  ## Returns the height of the retro canvas.
  retro.size.y

proc onScreenPosition*(retro: Retro): Vec2f =
  ## Returns the on-screen position of the retro.
  retro.position

proc onScreenSize*(retro: Retro): Vec2f =
  ## Returns the on-screen size of the retro.
  retro.size.vec2f * retro.scale.float32

proc onScreenWidth*(retro: Retro): float32 =
  ## Returns the on-screen width of the retro.
  retro.onScreenSize.x

proc onScreenHeight*(retro: Retro): float32 =
  ## Returns the on-screen height of the retro.
  retro.onScreenSize.y

proc render*(retro: Retro): FramebufferTarget =
  ## Returns the rendering target of the retro's framebuffer.
  retro.framebuffer.render()

proc recalculateScaleAndPosition(retro: Retro) =
  ## Recalculates the scale and position of the retro canvas.

  let (w, h) = (retro.window.width, retro.window.height)
  retro.scale = max(1, min(w div retro.width, h div retro.height))
  retro.position = retro.window.size.vec2f / 2 - retro.onScreenSize / 2

{.pop.}

proc draw*(retro: Retro, target: Target) =
  ## Calculates the correct position for rendering and draws the retro canvas
  ## onto the given target.

  retro.recalculateScaleAndPosition()
  retro.rect.uploadRectangle(rectf(retro.position, retro.onScreenSize))

  let (w, h) = (retro.window.width.float32, retro.window.height.float32)
  target.draw(retro.program, retro.rect, uniforms [used] {
    projection: ortho(0f, w, h, 0f, -1f, 1f),
    sampler: retro.framebuffer.sampler(magFilter = fmNearest),
  }, retro.drawParams)

###
# rapid game engine
# a game engine optimized for rapid prototyping
# copyright (c) 2018, iLiquid
###

import
  # C libraries
  glad/gl,
  # low-level wrappers, boilerplate code
  gfx/color, gfx/globjects,
  # high-level code
  gfx/gfx,
  gfx/window

when isMainModule:
  var win = newRWindow("Rapid Test Game", 800, 600)
  win.debug(true)
  win.loop do (ctx: var RGfxContext):
    ctx.clear(color(0, 0, 255))
    ctx.begin()
    ctx.vertex(0.0, 1.0)   # top
    ctx.vertex(-1.0, -1.0) # bottom left
    ctx.vertex(1.0, -1.0)  # bottom right
    ctx.draw(prTris)

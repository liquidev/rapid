###
# rapid game engine
# a game engine optimized for rapid prototyping
# copyright (c) 2018, iLiquid
###

import
  # C libraries
  lib/glad/gl,
  # low-level wrappers, boilerplate code
  gfx/color, gfx/globjects,
  # high-level code
  gfx/gfx, gfx/window,
  data/data

export
  color
export
  gfx, window

when isMainModule:
  var win = newRWindow("Rapid Test Game", 800, 600)
  win.debug(true)
  win.loop do (ctx: var RGfxContext):
    ctx.clear(color(0, 0, 0))
    ctx.begin()
    ctx.color(color(0, 255, 0))
    ctx.circle(ctx.width / 4, ctx.height / 4, 64)
    ctx.color(color(255, 0, 255))
    ctx.rect(32, 32, 128, 64)
    ctx.draw(prTris)

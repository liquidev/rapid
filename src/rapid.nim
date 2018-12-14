###
# rapid game engine
# a game engine optimized for rapid prototyping
# copyright (c) 2018, iLiquid
###

import
  #[ GLAD ]# glad/gl,
  # low-level wrappers, boilerplate code
  gfx/color, gfx/globjects,
  # high-level code
  gfx/gfx,
  gfx/window

proc rGame*(game: proc ()) =
  game()

when isMainModule:
  rGame do:
    var win = newRWindow("Rapid Test Game", 800, 600)
    win.loop do (ctx: var RGfxContext):
      ctx.clear(color(0, 0, 255))
      ctx.begin()
      ctx.vertex(0.0, 0.5)
      ctx.vertex(-0.5, -0.5)
      ctx.vertex(0.5, 0.5)
      ctx.draw(prTris)

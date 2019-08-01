import rapid/math/interpolation
import rapid/gfx
import rapid/audio/samplerutils

var
  win = initRWindow()
    .size(256, 256)
    .open()
  surf = win.openGfx()

const
  Vals = [0.0, 1.0, 0.5, 0.5, 1.0, 0.0]

surf.loop:
  draw ctx, step:
    ctx.clear(gray 0)
    ctx.begin()
    for x in 0..<win.width:
      let
        (l, r) = interpChannels(Vals, x / win.width * (Vals.len / 2 - 1), hermite)
      ctx.point((x.float, l * surf.height, rgb(255, 0, 255)))
      ctx.point((x.float, r * surf.height, rgb(0, 255, 0)))
    ctx.draw(prPoints)
  update step:
    discard

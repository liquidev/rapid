import os

import rapid/gfx

var
  win = initRWindow()
    .size(800, 128)
    .title("tloop")
    .open()
  surface = win.openGfx()

var
  x, vel = 0.0
  points: seq[float]
  t = time()

surface.loop:
  draw ctx, step:
    ctx.clear(gray(0))

    ctx.begin()
    ctx.color = rgb(255, 0, 0)
    ctx.rect(x, 0, 2, 128)
    ctx.draw()

    for p in points:
      ctx.begin()
      ctx.color = gray(255)
      ctx.rect(p, 0, 1, 64)
      ctx.draw()

    if time() - t > 1:
      points.add(x)
      t = time()

    if points.len >= 4:
      sleep(1000)
      echo points
      quit(0)
  update step:
    vel += step / 40
    x += vel * step

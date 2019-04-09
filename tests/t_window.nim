import unittest
import rapid
import lib/glad/gl

suite "windows":
  test "creation":
    var
      win = initRWindow()
        .size(640, 480)
        .title("A rapid window")
        .open()
      tc = (
        minFilter: fltLinear, magFilter: fltLinear,
        wrap: wrapRepeat)
      data = dataSpec:
        "rapid" <- image("logo-4x.png", tc)
      gfx = win.openGfx()
      ctx = gfx.ctx

    data.dir = "sampleData"
    data.loadAll()
    gfx.data = data

    proc draw(step: float) =
      ctx.clear(rgb(0, 0, 0))
      ctx.begin()
      ctx.texture = "rapid"
      ctx.rect(32, 32, float(gfx.width - 64), float(gfx.height - 64))
      ctx.draw()

    win.loop(draw, proc (delta: float) = discard)

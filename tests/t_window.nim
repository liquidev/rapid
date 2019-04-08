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
      gfx = win.openGfx()

    win.loop(
      proc (step: float) =
        var ctx = gfx.ctx
        ctx.clear(rgb(0, 0, 255))
        ctx.begin()
        ctx.tri((0.0, 0.5), (-0.5, -0.5), (0.5, -0.5))
        ctx.draw(),
      proc (delta: float) =
        discard
    )

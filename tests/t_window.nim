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
        drawExample(gfx),
      proc (delta: float) =
        discard
    )

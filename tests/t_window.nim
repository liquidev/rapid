import unittest
import rapid

suite "windows":
  test "creation":
    var win = initRWindow()
      .size(640, 480)
      .title("A rapid window")
      .open()

    win.loop(
      proc (step: float) =
        discard,
      proc (delta: float) =
        discard
    )

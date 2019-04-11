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
        minFilter: fltNearest, magFilter: fltNearest,
        wrap: wrapRepeat)
      data = dataSpec:
        "rapid" <- image("logo-4x.png", tc)
      gfx = win.openGfx()
      ctx = gfx.ctx

    data.dir = "sampleData"
    data.loadAll()
    gfx.data = data

    var
      x, y = 0.0
      pressed = false

    win.onCursorMove do (win: RWindow, cx, cy: float):
      x = cx
      y = cy

    win.onMousePress do (win: RWindow, btn: MouseButton, mode: int):
      pressed = true
    win.onMouseRelease do (win: RWindow, btn: MouseButton, mode: int):
      pressed = false

    proc draw(step: float) =
      ctx.activate()
      if pressed:
        ctx.begin()
        ctx.color = col(colWhite)
        ctx.texture = "rapid"
        ctx.rect(win.mouseX, win.mouseY, 64, 64)
        ctx.draw()

    win.loop(draw, proc (delta: float) = discard)

import rapid/gfx
import rapid/res/textures

const
  Pixelated = (minFilter: fltNearest, magFilter: fltNearest,
               wrapH: wrapRepeat, wrapV: wrapRepeat).RTextureConfig

var
  win = initRWindow()
    .size(256, 256)
    .title("Canvas resizing test")
    .open()
  sur = win.openGfx()
  canvas = gfx.newRCanvas(64, 64, Pixelated)

sur.loop:
  draw ctx, step:
    discard step
    ctx.clear(gray(0))
    ctx.renderTo(canvas):
      ctx.clear(gray(32))
      ctx.begin()
      ctx.lcircle(32, 16, 8)
      ctx.draw(prLineShape)
    ctx.begin()
    ctx.texture = canvas
    ctx.rect(0, 0, sur.width, sur.height)
    ctx.draw()
    ctx.noTexture()
  update step:
    discard step

/**
 ~ rapid examples: #01 - opening a window
 ~ copyright (c) iLiquid, 2018
 */

var win = RWindow.new()
  .size(800, 600)
  .open() // a window must be opened explicitly

// the main loop is started using win.loop
win.loop {|ctx| // ctx is an RGfxContext, which is used for drawing
  // clearing the window is as simple as this:
  ctx.clear(RColor.rgb(255, 255, 255))
}

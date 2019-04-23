# rapid

A game engine written in Nim, optimized for rapid game development and
easy prototyping.

## Installing

To install rapid, use the following command:
```
$ nimble install https://github.com/liquid600pgm/rapid
```

## Examples

### Opening a window

```nim
import color
import rapid

# Building a window is fairly straightforward:
var win = initRWindow()
  .title("My Game")
  .size(800, 600)
  .open()

# We need to get a handle to the underlying framebuffer in order to draw on the
# screen
var
  gfx = win.gfx
  ctx = gfx.ctx

proc draw(step: float) =
  ctx.activate()
  ctx.clear(col(colWhite))

proc update(delta: float) =
  discard

# Then we can begin a game loop:
win.loop(draw, update)
```

### Loading data

```nim
import rapid

var win = initRWindow()
  .title("My Game")
  .size(800, 600)
  .open()

var gfx = win.gfx

var data = dataSpec:
  "hello" <- image("hello.png")
# An non-macro approach can be used:
# data.image("hello", "hello.png")

# The data is loaded from a folder called ``data`` (for development), or the
# rapid bundle embedded in the executable with RDK.

# A different loading path can be specified using:
# data.dir = "some/other/data/folder"
# Keep in mind, that this folder won't be loaded from if there's a bundle
# embedded into the executable. It isn't required to embed a bundle, however.

# The ``load()`` iterator can be used for loading with progress reporting
data.loadAll()

gfx.data = data

proc draw(step: float) =
  gfx.clear(colBlack)
  gfx.texture("hello")
  gfx.uvRect(0, 0, 1, 1)
  gfx.rect(32, 32, 32, 32)

proc update(delta: float) =
  discard
```

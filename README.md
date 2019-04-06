# rapid

A game engine written in Nim, optimized for rapid game development and
easy prototyping.

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
var gfx = win.gfx

# Then we can begin a game loop:
win.loop:
  draw(step):
    gfx.clear(colWhite)
  update(delta):
    discard
```

### Loading data

```nim
import rapid

var win = initRWindow()
  .title("My Game")
  .size(800, 600)
  .open()

var gfx = win.gfx

var data = newRData:
  "hello" <- image("hello.png")
# An non-macro approach can be used:
# data.image("hello.png")

# The data is loaded from a folder called ``data`` (for development), or the
# rapid bundle embedded in the executable with RDK.

# A different loading path can be specified using:
# data.dir = "some/other/data/folder"
# Keep in mind, that this folder won't be loaded from if there's a bundle
# embedded into the executable. It isn't required to embed a bundle, however.

data.loadAll() # ``load()`` can be used for concurrent loading if needed

gfx.data = data

win.loop:
  draw(step):
    gfx.clear(colBlack)
    gfx.texture("hello")
    gfx.uvRect(0, 0, 1, 1)
    gfx.rect(32, 32, 32, 32)
```

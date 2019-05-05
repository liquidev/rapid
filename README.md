# rapid

A game engine written in Nim, optimized for rapid game development and
easy prototyping.

## Installing

To install rapid, use the following command:
```
$ nimble install https://github.com/liquid600pgm/rapid
```

### Linux

On Linux, the development headers for the following libraries must be installed:
 - GL
 - X11
 - Xrandr
 - Xxf86vm
 - Xi
 - Xcursor
 - Xinerama

#### Debian and Ubuntu
```
sudo apt install \
  libgl-dev libx11-dev libxrandr-dev libxxf86vm-dev libxi-dev libxcursor-dev \
  libxinerama-dev
```

#### openSUSE
```
sudo zypper in \
  Mesa-libGL-devel libX11-devel libXrandr-devel libXxf86vm-devel \
  libXinerama-devel libXi-devel libXcursor-devel
```

## Examples

### Opening a window

```nim
import rapid/gfx/surface

# Building a window is fairly straightforward:
var win = initRWindow()
  .title("My Game")
  .size(800, 600)
  .open()

# We need to get a handle to the underlying framebuffer in order to draw on the
# screen
var gfx = win.openGfx()

# Then we can begin a game loop
gfx.loop:
  draw ctx, step:
    ctx.clear(gray(255))
  update step:
    discard
```

### Loading data

```nim
import rapid/gfx/surface
import rapid/res/textures

var win = initRWindow()
  .title("My Game")
  .size(800, 600)
  .open()

var gfx = win.openGfx()

let
  # As of now, only PNGs are supported
  hello = newRTexture("data/hello.png")

gfx.loop:
  draw ctx, step:
    ctx.clear(gray(0))
    ctx.texture = hello
    ctx.rect(32, 32, 32, 32)
  update step:
    discard
```

# rapid

A game engine written in Nim, optimized for rapid game development and easy
prototyping. Made for convenience while coding, not striking performance.

## Goals

 - Be easy to understand, even for beginners,
 - Have an easy-to-use, convenient, yet flexible API,
 - Support as many platforms as possible,
 - Compile all C libraries statically to avoid dependency hell/linker errors,
 - Make game development a fun task for everyone.

## Features

 - Graphics
   - Windowing (using GLFW)
   - Easy-to-use graphics context
   - Post-processing effects
   - Texture atlas support
   - Texture packer
   - Text rendering
   - Backends
     - [x] OpenGL
     - [ ] WebGL
 - Audio
   - Node-based audio
     - [x] Sampler - basic audio sampling
     - [x] Wave - audio file decoding
       - [ ] WAV (own decoder)
       - [x] Vorbis (using libogg and libvorbis)
     - [x] Osc - audio synthesis using oscillators
       - [ ] Pulse
       - [x] Sine
       - [ ] Tri
       - [ ] Saw
       - [ ] Wave
     - [x] Mixer
     - Effects
     - DSP
 - Resource loading
   - PNG images
   - TTF/OTF fonts
 - Game logic
   - Built-in game loop macro
   - [x] AABB-based tilemap worlds
     - Physics
     - Collision detection and response
   - [ ] Line collision-based worlds

## Installing

To install rapid, use the following command:
```
$ nimble install rapid
```

#### Why doesn't rapid have a release?

rapid is an engine I develop along with my games, and so, it is constantly
evolving. It's difficult to mark major milestones in the engine's development,
since every single feature is important.

I plan to release version 0.1.0 whenever compiling on Windows works properly.
Currently, it's broken since rapid/audio's dependency—soundio—does not want to
compile under MinGW. I hope to resolve this problem as soon as I can, since it's
very annoying not being able to release games for the most popular platform
out there.


### Windows

rapid should work fine on Windows out of the box, no outside dependencies.

### Linux

On Linux, the development headers for the following libraries must be installed:

- for `rapid/gfx`:
  - GL
  - X11
  - Xrandr
  - Xxf86vm
  - Xi
  - Xcursor
  - Xinerama
- for `rapid/audio`*:
  - ALSA
  - PulseAudio
  - Jack

\* Each dependency is optional, but highly recommended to increase distro
compatibility.

If a dependency of `rapid/audio` is not present, a warning will be displayed and
the respective backend will be unavailable. **To hear anything, you need at**
**least one backend available.**

#### Debian and Ubuntu
```sh
# rapid/gfx
sudo apt install \
  libgl-dev libx11-dev libxrandr-dev libxxf86vm-dev libxi-dev libxcursor-dev \
  libxinerama-dev
# rapid/audio
# TODO: rapid/audio deps on ubuntu
```

#### Fedora
```sh
# rapid/gfx
sudo dnf install \
  mesa-libGL-devel libX11-devel libXrandr-devel libXxf86vm-devel \
  libXinerama-devel libXi-devel libXcursor-devel
# rapid/audio
sudo dnf install \
  alsa-lib-devel pulseaudio-libs-devel jack-audio-connection-kit-devel
```

#### openSUSE
```sh
# rapid/gfx
sudo zypper in \
  Mesa-libGL-devel libX11-devel libXrandr-devel libXxf86vm-devel \
  libXinerama-devel libXi-devel libXcursor-devel
# rapid/audio
# TODO: rapid/audio deps on suse
```

## Examples

### Opening a window

```nim
import rapid/gfx

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
import rapid/gfx
import rapid/res/textures

var win = initRWindow()
  .title("My Game")
  .size(800, 600)
  .open()

var gfx = win.openGfx()

let
  # As of now, only PNGs are supported
  hello = loadRTexture("data/hello.png")

gfx.loop:
  draw ctx, step:
    ctx.clear(gray(0))
    ctx.texture = hello
    ctx.rect(32, 32, 32, 32)
  update step:
    discard
```

### Drawing in batches

rapid does not have a distinct sprite batch, you just add more than 1 shape and
call `draw()`.

```nim
import rapid/gfx
import rapid/gfx/texpack
import rapid/res/textures

var win = initRWindow()
  .title("My Game")
  .size(800, 600)
  .open()

var gfx = win.openGfx()

let
  # RImages are not textures, but rather raw image data
  sheet1 = loadRImage("spritesheet1.png")
  sheet2 = loadRImage("spritesheet2.png")

# You usually want to use a texture packer here. Its job is to place multiple
# images onto a single texture as efficiently as possible. rapid's packer
# doesn't use the most performance nor space efficient algorithm, but it allows
# for dynamic insertion of textures, and so, is suitable for rendering text
# without pre-rendering the whole font
var packer = newRTexturePacker(128, 128)
let
  sprite1 = packer.place [
    # Placing an array allows the packer to sort the textures by size, which
    # allows for more efficient packing. It also binds the texture only once,
    # so it's slightly more performant (although not much).
    sheet1.subimg(0, 0, 8, 8),
    sheet1.subimg(0, 8, 8, 8),
    sheet1.subimg(0, 16, 8, 8),
    sheet1.subimg(0, 24, 8, 8)
  ]
  sprite2 = packer.place [
    sheet2.subimg(0, 0, 16, 16),
    sheet2.subimg(16, 0, 8, 8)
  ]

gfx.loop:
  draw ctx, step:
    ctx.clear(gray(0))

    ctx.begin()
    ctx.texture = packer.texture
    for y in 0..<4:
      for x in 0..<16:
        ctx.rect(x * 8, y * 8, 8, 8, sprite1[y])
    ctx.rect(32, 32, 16, 16, sprite2[0])
    ctx.draw()
  update step:
    discard

```

### Audio playback

rapid provides a natural API for audio playback. It revolves around the idea of
connecting different samplers together to produce sound, while maintaining
easy-to-understand code without global state.

To use rapid/audio, compile your program with ``--threads:on``. You can easily
add this to nim.cfg or config.nims to save yourself the hassle of passing the
argument each time you want to compile your program.

```nim
import os

import rapid/audio/device
import rapid/audio/samplers/[wave, mixer]

var
  dev = newRAudioDevice("My game")
  # rapid/audio does not provide an implicit mixer within the device, so we must
  # create our own
  mix = newRMixer()
  # Only Ogg Vorbis decoding is supported
  jump = newRWave("data/jump.ogg")
  jumpTrack = mix.add(jump) # Attach the sampler to the mixer
  # We load the wave using the ``admStream`` audio decode mode, to load the
  # file dynamically during playback and avoid long loading times
  music = newRWave("data/music.ogg", admStream)
  musicTrack = mix.add(music)

# First, we must attach the root sampler to the device. In this case, we use
# our previously created mixer.
dev.attach(mix)
# Then, we can start audio playback.
dev.start()

# Start playing the music immediately
music.play()

# To prevent the program from closing immediately, we use a while true loop.
while true:
  # Play our jump sample every second
  jump.play()
  sleep(1000)

```

## Tips

 - Don't worry about using global variables. They are a very useful tool,
   especially for game resource storage. You should only avoid them in
   libraries, which should use objects for state.
 - Draw in batches whenever possible. This reduces the amount of time the CPU
   has to spend sending data to the GPU, making your game run better.
 - Compile your game with `--opt:speed`. The performance vs compile time
   tradeoff is not as terrible as you might think, especially when using
   `nim c` instead of `nim cpp` (or something else).

## Contributing

When contributing code, please follow the [coding style guidelines](code_style.md).

## Legal

The rapid game engine is licensed under the MIT license. It makes use of
third-party libraries, which must be properly attributed within software making
use of rapid.

The `lib/licenses` module has the licenses available at compile-time. Check it
out for instructions on including the licenses in your software.

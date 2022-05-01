<p align="center">
  <img src="logo-8x.png">
</p>

A game engine written in Nim, optimized for making cool games fast.
Made for convenience while coding and better performance than all-in-one
solutions like Godot.

**Note:** As of June 2021, I'm not longer actively working on rapid.
I'm still going to accept pull requests, but I'm not working towards
adding anything myself, as I've gotten bored of the project and
eventually tired of Nim altogether.
If anyone contributes often enough to the repository I can give them
contributor status to make working on the project easier.

## Goals

- Be easy to understand,
- Have a rich set of flexible APIs,
- Compile all C libraries statically to avoid dependency hell/linker errors,
- Make game development a fun task for everyone.

## Features

- `rapid/graphics`
  - _Almost stateless_ graphics context API – the only state you ever have
    to worry about is the shape buffer
    - Supports text rendering using FreeType
    - Has a built-in polyline renderer for drawing wires, graphs, etc.
  - Post-processing effects with HDR rendering support
  - Built in texture packer
- `rapid/game`
  - Fixed timestep game loop
  - Fixed-size and infinite-size tilemaps
- `rapid/ec`
  - Minimal [entity-component][gpp component] decoupling pattern implementation
- `rapid/physics`
  - `chipmunk` – General-purpose physics engine, using
    [Chipmunk2D][chipmunk repo]
  - `simple` – Simple and fast AABB-based physics engine
- `rapid/input`
  - Simplified input event distribution using procs like
    `mouseButtonJustPressed` + callback support
- `rapid/math`
  - Common math utilities for vector math, axis-aligned bounding boxes,
    interpolation, and type-safe units
- `rapid/ui` – [Fidget][fidget repo]-style UI framework for games
  and applications

  [gpp component]: https://gameprogrammingpatterns.com/component.html
  [chipmunk repo]: https://github.com/slembcke/Chipmunk2D
  [fidget repo]: https://github.com/treeform/fidget

### Coming soon

- `rapid/audio` – Sound mixer with real-time effect support

## Installing

Note that the new version of rapid (2020) is still under development, so you
will have to install a specific commit from the master branch. The current
release version is not supported anymore.

To install rapid, use the following command:
```bash
$ nimble install "rapid@#3e831cb"  # change the commit hash to the latest commit
```

In your `.nimble` file:
```nim
requires "rapid#3e831cb"
```

Pinning to a specific commit rather than `#head` is recommended, because `#head`
doesn't name a specific point in development. This means that two different
packages may end up requiring `#head`, and the `#head` that's installed locally
may not match the `#head` that's required by the package. Thanks nimble,
you're the best.

### Linux

On Linux, the development headers for the following libraries must be installed:

- for `rapid/graphics`:
  - GL
  - X11
  - Xrandr
  - Xxf86vm
  - Xi
  - Xcursor
  - Xinerama

#### Debian and Ubuntu
```sh
sudo apt install \
  libgl-dev libx11-dev libxrandr-dev libxxf86vm-dev libxi-dev libxcursor-dev \
  libxinerama-dev
```

#### Fedora
```sh
sudo dnf install \
  mesa-libGL-devel libX11-devel libXrandr-devel libXxf86vm-devel \
  libXinerama-devel libXi-devel libXcursor-devel
```

#### openSUSE
```sh
sudo zypper in \
  Mesa-libGL-devel libX11-devel libXrandr-devel libXxf86vm-devel \
  libXinerama-devel libXi-devel libXcursor-devel
```

## Examples

For examples, look in the `tests` directory.

## Tips

 - Draw in batches whenever possible. This reduces the amount of time the CPU
   has to spend sending draw calls to the GPU, making your game run better.
   In general, whenever you have some object that doesn't change often, prefer
   an aglet `Mesh` rather than rapid's `Graphics`.
 - Compile your game with `--opt:speed`. Nim's rather primitive stack trace
   system can slow programs down by quite a bit, so compiling with speed
   optimizations enabled can be quite important to maintain playable
   performance. Though if your game's so CPU-heavy that it becomes unplayable
   without `--opt:speed`, you're doing something wrong. Go fix your code.

## Contributing

When contributing code, please follow the [coding style guidelines](code_style.md).

### Super Secret Messages hidden in plain sight

#### A message to Araq

Fast incremental compilation when


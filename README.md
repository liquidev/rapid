# rapid

A game engine written in Nim, optimized for rapid game development and easy
prototyping. Made for convenience while coding and decent performance.

## Goals

 - Be easy to understand,
 - Have a flexible API,
 - Compile all C libraries statically to avoid dependency hell/linker errors,
 - Make game development a fun task for everyone.

## Installing

To install rapid, use the following command:
```
$ nimble install rapid
```

### Windows

rapid should work fine on Windows out of the box, no outside dependencies.

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

#### A message to disruptek

Incremental compilation when

#### A message to future me reading this

YOU should finish that darned X11/EGL backend in aglet too. GLFW init times
are a pain because somebody thought it would be a good idea to parse the entire
SDL game controller database every time on startup. That somebody should be
fired, in my opinion.

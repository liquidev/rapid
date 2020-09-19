# rapid

A game engine written in Nim, optimized for rapid game development and easy
prototyping. Made for convenience while coding and decent performance.

## Goals

 - Be easy to understand,
 - Have an flexible API,
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

- for `rapid/gfx`:
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

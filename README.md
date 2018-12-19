# rapid

A game engine written in Nim, optimized for rapid game development and prototyping.

## Goals

 - **Speed.** rapid is supposed to be a fast game engine, by providing a thin, yet high-level binding to OpenGL.
 - **Expressiveness.** To make development much easier, a game engine must be expressive.
   rapid's classes have short, often abbreviated names, to make coding much faster and more fun.
   They also have readable bindings, avoiding unnecessarily long names, prefixes, and use Wren's language features to make code as readable as possible.
 - **Ease of use.** rapid is easy to understand and use. Opening a game window is just a few lines of code (see below).
 - **Clarity.** Any code making use of rapid is easily understandable, because rapid doesn't do anything under the hood if you don't tell it to.
   The lack of any implicit loading code execution makes rapid much more controllable without the need for any kind of configuration files (even though rapid supports them).

## Examples

*Note: At this point in time, these examples don't work. They're merely a draft of what I'd like the API to be in the end.*

### Opening a window
```dart
var win = RWindow.new()
  .size(800, 600)
  .open()

win.loop {|ctx|
  ctx.clear(RColor.rgb(255, 255, 255))
}
```

### Drawing primitives
```dart
var win = RWindow.new()
  .size(800, 600)
  .open()

win.loop {|ctx|
  ctx.clear(RColor.rgb(255, 255, 255))
  ctx.color(RColor.cBlue)
  ctx.begin() // a draw operation must begin by clearing the vertex buffer
  ctx.rect(32, 32, 64, 64)
  ctx.draw() // uses RGfx.prIndices by default
}
```

Check out more examples in the `/examples` directory!

## Roadmap

rapid is still largely unfinished, but here's a roadmap of its upcoming/completed features:
 - [x] Object-oriented OpenGL wrapper (in progress)
 - [ ] Simple-to-use Processing-like graphics context (in-progress)
   - [x] Colors
   - [x] Batched/queued draw calls
   - [ ] Simple shader API
 - [ ] Game resource management
   - [x] Clean resource loader definition DSL (in progress)
   - [ ] Resource "lifetimes"
 - [ ] Game entities
   - [ ] Simple physics
   - [ ] Animated sprites
 - [ ] Maps
   - [ ] Quadtree-based collision maps
   - [ ] Editor
 - [ ] GUIs
   - [ ] Node-based user interfaces
   - [ ] Event-based input
 - [ ] Wren bindings
 - [ ] Game bundles
   - [ ] File format
   - [ ] Executable fusing

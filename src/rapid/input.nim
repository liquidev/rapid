## Simplified input handling.

import std/unicode

import aglet

type
  PressState = enum
    psJustPressed
    psDown
    psJustReleased
    psJustRepeated

  Input* = ref object
    ## Input state manager.
    window: Window

    keys: array[high(Key).int, set[PressState]]
      # ↑ this wastes a bunch of memory because Key is an enum with holes
      # so some combinations will never be set
      # on the other hand set[PressState] is just 1 byte so eh
      # it's not a big deal
    mouseButtons: array[MouseButton, set[PressState]]

    cWindowMove: seq[WindowMoveCallback]
    cWindowResize: seq[WindowResizeCallback]
    cWindowClose: seq[WindowCloseCallback]
    cWindowRedraw: seq[WindowRedrawCallback]
    cWindowFocus: seq[WindowFocusCallback]
    cWindowIconify: seq[WindowIconifyCallback]
    cWindowMaximize: seq[WindowMaximizeCallback]
    cWindowScale: seq[WindowScaleCallback]
    cKeyPress: seq[KeyCallback]
    cKeyRelease: seq[KeyCallback]
    cKeyRepeat: seq[KeyCallback]
    cCharInput: seq[CharInputCallback]
    cMouseButtonPress: seq[MouseButtonCallback]
    cMouseButtonRelease: seq[MouseButtonCallback]
    cMouseMove: seq[MouseMoveCallback]
    cMouseEnter: seq[MouseEnterCallback]
    cMouseScroll: seq[MouseScrollCallback]
    cFileDrop: seq[FileDropCallback]

  WindowMoveCallback* = proc (newPosition: Vec2f)
    ## Triggered when the window is moved.
    ##
    ## :newPosition:
    ##   The window's new position.
  WindowResizeCallback* = proc (newSize: Vec2f)
    ## Triggered when the window is resized.
    ##
    ## :newSize:
    ##   The window's new size.
  WindowCloseCallback* = proc ()
    ## Triggered when the window is closed.
  WindowRedrawCallback* = proc ()
    ## Triggered when the window needs to be redrawn.
  WindowFocusCallback* = proc (focused: bool)
    ## Triggered when the window is focused/unfocused.
    ##
    ## :focused:
    ##   Whether the window is now focused or not.
  WindowIconifyCallback* = proc (iconified: bool)
    ## Triggered when the window is iconified/restored.
    ##
    ## :iconified:
    ##   ``true`` when the window has been iconified, ``false`` if it's been
    ##   restored.
  WindowMaximizeCallback* = proc (maximized: bool)
    ## Triggered when the window is maximized or unmaximized.
    ##
    ## :maximized:
    ##   Whether the window is now maximized.
  WindowScaleCallback* = proc (scale: Vec2f)
    ## Triggered when the window's DPI scaling needs to change.
    ##
    ## :scale:
    ##   The new DPI scale that should be applied.
  KeyCallback* = proc (key: Key, scancode: int, mods: set[ModKey])
    ## Triggered when a key is pressed or released.
    ##
    ## :key:
    ##   The key that's been pressed or released.
    ##
    ## :scancode:
    ##   The key's scancode.
    ##
    ## :mods:
    ##   Modifier keys that were held.
  CharInputCallback* = proc (rune: Rune)
    ## Triggered on character input (when typing text).
    ##
    ## :rune:
    ##   The Unicode character that's been typed.
  MouseButtonCallback* = proc (button: MouseButton, mods: set[ModKey])
    ## Triggered when a mouse button is pressed or released.
    ##
    ## :button:
    ##   The mouse button that's been pressed or released.
    ##
    ## :mods:
    ##   The modifier keys that were held.
  MouseMoveCallback* = proc (newPosition: Vec2f)
    ## Triggered when the mouse cursor moves.
    ##
    ## :newPosition:
    ##   The new position the mouse cursor has moved to.
    ##
    ## :delta:
    ##   The change in position.
  MouseEnterCallback* = proc (entered: bool)
    ## Triggered when the mouse cursor enters or leaves the window.
    ##
    ## :entered:
    ##   ``true`` if the cursor entered the window, ``false`` if it left the
    ##   window.
  MouseScrollCallback* = proc (delta: Vec2f)
    ## Triggered when the scroll wheel is used.
    ##
    ## :delta:
    ##   The amount scrolled.
  FileDropCallback* = proc (paths: seq[string])
    ## Triggered when files are dropped onto the window.
    ##
    ## :paths:
    ##   The paths to files that have been dropped.

proc newInput*(window: Window): Input =
  ## Creates a new input handler.

  new result
  result.window = window

proc process*(input: Input, event: InputEvent) =
  ## Processes an input event. This should be called from the callback passed to
  ## ``window.pollEvents``.

  template trigger(group, expr: untyped) =
    for it {.inject.} in input.group:
      expr

  case event.kind
  of iekWindowMove:
    trigger cWindowMove, it(event.windowPos.vec2f)

  of iekWindowFrameResize:
    trigger cWindowResize, it(event.size.vec2f)

  of iekWindowClose:
    trigger cWindowClose, it()

  of iekWindowRedraw:
    trigger cWindowRedraw, it()

  of iekWindowFocus:
    trigger cWindowFocus, it(event.focused)

  of iekWindowIconify:
    trigger cWindowIconify, it(event.iconified)

  of iekWindowMaximize:
    trigger cWindowMaximize, it(event.maximized)

  of iekWindowScale:
    trigger cWindowScale, it(event.scale)

  of iekKeyPress:
    input.keys[event.key.int].incl({psJustPressed, psDown})
    trigger cKeyPress, it(event.key, event.scancode, event.kMods)

  of iekKeyRelease:
    input.keys[event.key.int].incl(psJustReleased)
    input.keys[event.key.int].excl(psDown)
    trigger cKeyRelease, it(event.key, event.scancode, event.kMods)

  of iekKeyRepeat:
    input.keys[event.key.int].incl(psJustRepeated)
    trigger cKeyRepeat, it(event.key, event.scancode, event.kMods)

  of iekKeyChar:
    trigger cCharInput, it(event.rune)

  of iekMousePress:
    input.mouseButtons[event.button].incl({psJustPressed, psDown})
    trigger cMouseButtonPress, it(event.button, event.bMods)

  of iekMouseRelease:
    input.mouseButtons[event.button].incl(psJustReleased)
    input.mouseButtons[event.button].excl(psDown)
    trigger cMouseButtonRelease, it(event.button, event.bMods)

  of iekMouseMove:
    trigger cMouseMove, it(event.mousePos)

  of iekMouseEnter, iekMouseLeave:
    trigger cMouseEnter, it(event.kind == iekMouseEnter)

  of iekMouseScroll:
    trigger cMouseScroll, it(event.scrollPos)

  of iekFileDrop:
    trigger cFileDrop, it(event.filePaths)

  of iekWindowResize: discard  # use frameResize

proc finishTick[T](states: var array[T, set[PressState]]) {.inline.} =
  for state in mitems(states):
    state.excl(psJustPressed)
    state.excl(psJustReleased)
    state.excl(psJustRepeated)

proc finishTick*(input: Input) =
  ## Finishes the current update tick. This should be called at the end of an
  ## *input frame*. An input frame is dependent on the context where the input
  ## handler is accessed; if the input handler is accessed inside of your update
  ## loop, this must be called at the end of your update loop. If the input
  ## handler is accessed in your draw loop, this must be called at the end of
  ## your draw loop. Because the call frequencies of the update and draw loops
  ## differ, one input handler *must not* be used in both update and draw loops,
  ## instead, two separate handlers must be used.

  finishTick(input.keys)
  finishTick(input.mouseButtons)

{.push inline.}

proc keyJustPressed*(input: Input, key: Key): bool =
  ## Returns whether the given key has been pressed in the current input tick.
  psJustPressed in input.keys[key.int]

proc keyJustPressed*(input: Input, keys: set[Key]): bool =
  ## Returns whether any of the given keys has just been pressed.

  for key in keys:
    if input.keyJustPressed(key): return true

proc keyIsDown*(input: Input, key: Key): bool =
  ## Returns whether the given key is being held down in the current input tick.
  psDown in input.keys[key.int]

proc keyIsDown*(input: Input, keys: set[Key]): bool =
  ## Returns whether any of the given keys is down.

  for key in keys:
    if input.keyIsDown(key): return true

proc keyJustReleased*(input: Input, key: Key): bool =
  ## Returns whether the given key has just been released in the current input
  ## tick.
  psJustReleased in input.keys[key.int]

proc keyJustReleased*(input: Input, keys: set[Key]): bool =
  ## Returns whether any of the given keys has just been released.

  for key in keys:
    if input.keyJustReleased(key): return true

proc keyJustRepeated*(input: Input, key: Key): bool =
  ## Returns whether the given key has just been repeated in the current input
  ## tick.
  psJustRepeated in input.keys[key.int]

proc keyJustRepeated*(input: Input, keys: set[Key]): bool =
  ## Returns whether any of the given keys has just been repeated.

  for key in keys:
    if input.keyJustRepeated(key): return true

proc mouseButtonJustPressed*(input: Input, button: MouseButton): bool =
  ## Returns whether the given mouse button has been pressed in the current
  ## input tick.
  psJustPressed in input.mouseButtons[button]

proc mouseButtonJustPressed*(input: Input, buttons: set[MouseButton]): bool =
  ## Returns whether any of the given mouse buttons has just been pressed.

  for button in buttons:
    if input.mouseButtonJustPressed(button): return true

proc mouseButtonIsDown*(input: Input, button: MouseButton): bool =
  ## Returns whether the given mouse button is being held down in the current
  ## input tick.
  psDown in input.mouseButtons[button]

proc mouseButtonIsDown*(input: Input, buttons: set[MouseButton]): bool =
  ## Returns whether any of the given mouse buttons has is down.

  for button in buttons:
    if input.mouseButtonIsDown(button): return true

proc mouseButtonJustReleased*(input: Input, button: MouseButton): bool =
  ## Returns whether the given mouse button has been released in the current
  ## input tick.
  psJustReleased in input.mouseButtons[button]

proc mouseButtonJustReleased*(input: Input, buttons: set[MouseButton]): bool =
  ## Returns whether any of the given mouse buttons has just been released.

  for button in buttons:
    if input.mouseButtonJustReleased(button): return true

proc mousePosition*(input: Input): Vec2f =
  ## Returns the position of the mouse in the window.
  input.window.mouse

proc osMousePosition*(input: Input): Vec2f =
  ## Returns the position of the mouse on the screen, relative to the window.
  ## This is a bit slower than ``mousePosition`` as it has to ask the window
  ## manager about the mouse's position, while ``mousePosition`` simply returns
  ## the mouse position cached from input events.
  input.window.pollMouse

proc onWindowMove*(input: Input, callback: WindowMoveCallback) =
  ## Adds a callback triggered when the window is moved.
  input.cWindowMove.add(callback)

proc onWindowResize*(input: Input, callback: WindowResizeCallback) =
  ## Adds a callback triggered when the window is resized.
  input.cWindowResize.add(callback)

proc onWindowClose*(input: Input, callback: WindowCloseCallback) =
  ## Adds a callback triggered when the window is closed.
  input.cWindowClose.add(callback)

proc onWindowRedraw*(input: Input, callback: WindowRedrawCallback) =
  ## Adds a callback triggered when the window needs to be redrawn.
  input.cWindowRedraw.add(callback)

proc onWindowFocus*(input: Input, callback: WindowFocusCallback) =
  ## Adds a callback triggered when the window's focus state changes.
  input.cWindowFocus.add(callback)

proc onWindowIconify*(input: Input, callback: WindowIconifyCallback) =
  ## Adds a callback triggered when the window is iconified or restored.
  input.cWindowIconify.add(callback)

proc onWindowMaximize*(input: Input, callback: WindowMaximizeCallback) =
  ## Adds a callback triggered when the window is maximized or unmaximized.
  input.cWindowMaximize.add(callback)

proc onWindowScale*(input: Input, callback: WindowScaleCallback) =
  ## Adds a callback triggered when the window's DPI scale needs to change.
  input.cWindowScale.add(callback)

proc onKeyPress*(input: Input, callback: KeyCallback) =
  ## Adds a callback triggered when a key is pressed.
  input.cKeyPress.add(callback)

proc onKeyRelease*(input: Input, callback: KeyCallback) =
  ## Adds a callback triggered when a key is released.
  input.cKeyRelease.add(callback)

proc onKeyRepeat*(input: Input, callback: KeyCallback) =
  ## Adds a callback triggered when a key is repeated.
  input.cKeyRelease.add(callback)

proc onCharInput*(input: Input, callback: CharInputCallback) =
  ## Adds a callback triggered when characters are input.
  input.cCharInput.add(callback)

proc onMouseButtonPress*(input: Input, callback: MouseButtonCallback) =
  ## Adds a callback triggered when a mouse button is pressed.
  input.cMouseButtonPress.add(callback)

proc onMouseButtonRelease*(input: Input, callback: MouseButtonCallback) =
  ## Adds a callback triggered when a mouse button is released.
  input.cMouseButtonRelease.add(callback)

proc onMouseMove*(input: Input, callback: MouseMoveCallback) =
  ## Adds a callback triggered when the mouse is moved.
  input.cMouseMove.add(callback)

proc onMouseEnter*(input: Input, callback: MouseEnterCallback) =
  ## Adds a callback triggered when the mouse enters or exits the window.
  input.cMouseEnter.add(callback)

proc onMouseScroll*(input: Input, callback: MouseScrollCallback) =
  ## Adds a callback triggered when the scroll wheel is moved.
  input.cMouseScroll.add(callback)

proc onFileDrop*(input: Input, callback: FileDropCallback) =
  ## Adds a callback triggered when files are dropped onto the window.
  input.cFileDrop.add(callback)

{.pop.}

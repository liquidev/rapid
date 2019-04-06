#~~
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2018, iLiquid
#~~

## This module has everything related to windows.

import deques
import os
import tables
import times
import unicode

import ../lib/glad/gl
from ../lib/glfw/glfw import nil
import opengl

export glfw.Key
export glfw.MouseButton
export times.cpuTime
export unicode.Rune

#~~
# OpenGL Initialization
#~~

type
  InitErrorKind = enum
    ieOK = "Init successful"
    ieGlfwInitFailed = "Failed to initialize GLFW"
  GLFWError* = object of Exception
    code: int

proc initGl(): InitErrorKind =
  if glfw.init() == 0:
    return ieGlfwInitFailed
  addQuitProc() do:
    glfw.terminate()
  discard glfw.setErrorCallback() do (errCode: int32, msg: cstring) {.cdecl.}:
    var err = newException(GLFWError, $msg)
    err.code = int errCode
    raise err
  return ieOK

#~~
# Windows
#~~

type
  #~~
  # Building
  #~~
  WindowOptions = object
    width, height: Natural
    title: string
    resizable, visible, decorated, focused, floating, maximized: bool
  #~~
  # Events
  #~~
  # Gosh, turning a callback-based event system into an event queue and back is
  # a pain. Why, GLFW, why!?
  # This is needed to satisfy Nim's memory safety constrains, even though using
  # callbacks directly in this circumstance would be perfectly memory safe.
  # PRs aiming to improve this are very welcome.
  #~~
  WindowEventKind = enum
    wevCharMods
    wevCursorEnter
    wevCursorMove
    wevFilesDropped
    wevKey
    wevMouseButton
    wevScroll
    wevWindowClose
    wevWindowSize
  WindowEvent = object
    case kind: WindowEventKind
    of wevCharMods:
      modsRune: Rune
      charMods: int
    of wevCursorEnter:
      cursorEntered: bool
    of wevCursorMove:
      posX, posY: float
    of wevFilesDropped:
      filenames: seq[string]
    of wevKey:
      keyAction: glfw.KeyAction
      key: glfw.Key
      keyScancode: int
      keyMods: int
    of wevMouseButton:
      buttonAction: glfw.KeyAction
      button: glfw.MouseButton
      buttonMods: int
    of wevScroll:
      scrollX, scrollY: float
    of wevWindowSize:
      width, height: Natural
    else: discard
  RCharFn* = proc (win: var RWindow, rune: Rune)
  RCursorEnterFn* = proc (win: var RWindow)
  RCursorMoveFn* = proc (win: var RWindow, x, y: float)
  RFilesDroppedFn* = proc (win: var RWindow, filenames: seq[string])
  RKeyFn* = proc (win: var RWindow, key: glfw.Key, scancode: int, mods: int)
  RMouseFn* = proc (win: var RWindow, button: glfw.MouseButton, mods: int)
  RScrollFn* = proc (win: var RWindow, x, y: float)
  RCloseFn* = proc (win: var RWindow): bool
  RResizeFn* = proc (win: var RWindow, width, height: Natural)
  WindowCallbacks = object
    onChar: seq[RCharFn]
    onCursorEnter, onCursorLeave: seq[RCursorEnterFn]
    onCursorMove: seq[RCursorMoveFn]
    onFilesDropped: seq[RFilesDroppedFn]
    onKeyPress, onKeyRelease, onKeyRepeat: seq[RKeyFn]
    onMousePress, onMouseRelease: seq[RMouseFn]
    onScroll: seq[RScrollFn]
    onClose: seq[RCloseFn]
    onResize: seq[RResizeFn]
  #~~
  # Windows
  #~~
  RWindowObj = object
    id: int
    handle: glfw.Window
    options: ref WindowOptions
    callbacks: WindowCallbacks
  RWindow* = ref RWindowObj

using
  wopt: WindowOptions

var glInitialized = false

proc initRWindow*(): WindowOptions =
  if not glInitialized:
    let status = initGl()
    if status != ieOK:
      quit($status, int(status))
    glInitialized = true
  result = WindowOptions(
    width: 800, height: 600,
    title: "rapid"
  )

proc size*(wopt; width, height: int): WindowOptions =
  result = wopt
  result.width = width
  result.height = height

proc title*(wopt; title: string): WindowOptions =
  result = wopt
  result.title = title

template builderBool(param: untyped): untyped {.dirty.} =
  proc param*(wopt; param: bool): WindowOptions =
    result = wopt
    result.param = param
builderBool(resizable)
builderBool(visible)
builderBool(decorated)
builderBool(focused)
builderBool(floating)
builderBool(maximized)

# ugh global state
# unfortunately, this is required because of Nim's memory safety constrains
var windowEvents: seq[Deque[WindowEvent]]

proc glfwCallbacks(win: var RWindow) =
  let id = win.id
  discard glfw.setCharModsCallback(win.handle,
    proc (w: glfw.Window, ch: cuint, mods: int32) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevCharMods,
        modsRune: Rune(ch),
        charMods: mods
      ))
  )
  discard glfw.setCursorEnterCallback(win.handle,
    proc (w: glfw.Window, entered: int32) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevCursorEnter,
        cursorEntered: entered == 1
      ))
  )
  discard glfw.setCursorPosCallback(win.handle,
    proc (w: glfw.Window, x, y: cdouble) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevCursorMove,
        posX: x, posY: y
      ))
  )
  discard glfw.setDropCallback(win.handle,
    proc (w: glfw.Window, n: int32, files: cstringArray) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevFilesDropped,
        filenames: cstringArrayToSeq(files, n)
      ))
  )
  discard glfw.setKeyCallback(win.handle,
    proc (w: glfw.Window, key, scan, action, mods: int32) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevKey,
        keyAction: glfw.KeyAction(action),
        key: glfw.Key(key),
        keyScancode: scan,
        keyMods: mods
      ))
  )
  discard glfw.setMouseButtonCallback(win.handle,
    proc (w: glfw.Window, button, action, mods: int32) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevMouseButton,
        buttonAction: glfw.KeyAction(action),
        button: glfw.MouseButton(button),
        buttonMods: mods
      ))
  )
  discard glfw.setScrollCallback(win.handle,
    proc (w: glfw.Window, x, y: cdouble) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevScroll,
        scrollX: x, scrollY: y
      ))
  )
  discard glfw.setWindowSizeCallback(win.handle,
    proc (w: glfw.Window, width, height: int32) {.cdecl.} =
      windowEvents[id].addLast(WindowEvent(
        kind: wevWindowSize,
        width: width, height: height
      )))

converter toInt32(hint: glfw.Hint): int32 =
  int32(hint)

proc open*(wopt): RWindow =
  result = RWindow()

  result.id = len(windowEvents)
  windowEvents.add(initDeque[WindowEvent]())

  new(result.options)
  result.options[] = wopt

  let
    mon = glfw.getPrimaryMonitor()
    mode = glfw.getVideoMode(mon)

  glfw.windowHint(glfw.hRedBits, mode.redBits)
  glfw.windowHint(glfw.hGreenBits, mode.greenBits)
  glfw.windowHint(glfw.hBlueBits, mode.blueBits)

  glfw.windowHint(glfw.hClientApi, int32 glfw.oaOpenglEsApi)
  glfw.windowHint(glfw.hContextVersionMajor, 2)
  glfw.windowHint(glfw.hContextVersionMinor, 0)
  result.handle = glfw.createWindow(
    int32 wopt.width, int32 wopt.height,
    wopt.title,
    nil, nil
  )

  glfwCallbacks(result)

proc `=destroy`(win: var RWindowObj) =
  glfw.destroyWindow(win.handle)

proc calcMillisPerFrame(win: RWindow): float =
  let
    mon = glfw.getPrimaryMonitor()
    mode = glfw.getVideoMode(mon)
  result = 1000 / mode.refreshRate

type
  RDrawProc* = proc (step: float)
  RUpdateProc* = proc (delta: float)

proc processEvents(win: var RWindow) =
  template run(name, body: untyped) {.dirty.} =
    for fn in win.callbacks.name: body
  var queue = windowEvents[win.id]
  while queue.len > 0:
    let ev = queue.popFirst()
    case ev.kind
    of wevCharMods:
      run(onChar): fn(win, ev.modsRune)
    of wevCursorEnter:
      if ev.cursorEntered:
        run(onCursorEnter): fn(win)
      else:
        run(onCursorLeave): fn(win)
    of wevCursorMove:
      run(onCursorMove): fn(win, ev.posX, ev.posY)
    of wevFilesDropped:
      run(onFilesDropped): fn(win, ev.filenames)
    of wevKey:
      case ev.keyAction
      of glfw.kaDown:
        run(onKeyPress): fn(win, ev.key, ev.keyScancode, ev.keyMods)
      of glfw.kaUp:
        run(onKeyRelease): fn(win, ev.key, ev.keyScancode, ev.keyMods)
      of glfw.kaRepeat:
        run(onKeyRepeat): fn(win, ev.key, ev.keyScancode, ev.keyMods)
    of wevMouseButton:
      case ev.buttonAction
      of glfw.kaDown:
        run(onMousePress): fn(win, ev.button, ev.buttonMods)
      of glfw.kaUp:
        run(onMouseRelease): fn(win, ev.button, ev.buttonMods)
      else: discard
    of wevScroll:
      run(onScroll): fn(win, ev.scrollX, ev.scrollY)
    of wevWindowClose:
      run(onClose):
        let close = fn(win)
        glfw.setWindowShouldClose(win.handle, int32 close)
    of wevWindowSize:
      run(onResize): fn(win, ev.width, ev.height)

  windowEvents[win.id].clear()

proc loop*(win: var RWindow,
           draw: RDrawProc, update: RUpdateProc) =
  glfw.makeContextCurrent(win.handle)
  if not gladLoadGLES2(glfw.getProcAddress):
    raise newException(GLError, "Couldn't load OpenGL procs")

  glfw.swapInterval(1)

  let millisPerUpdate = calcMillisPerFrame(win)
  var
    previous = float(glfw.getTime())
    lag = 0.0
  while glfw.windowShouldClose(win.handle) == 0:
    glfw.swapBuffers(win.handle)

    let
      current = float(glfw.getTime())
      elapsed = current - previous
    previous = current
    lag += elapsed

    glfw.pollEvents()
    processEvents(win)

    while lag >= millisPerUpdate:
      update(elapsed / millisPerUpdate)
      lag -= millisPerUpdate

    draw(lag / millisPerUpdate)

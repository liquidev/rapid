#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## This module has everything related to windows.
## **Do not import this directly, it's included by the surface module.**

import deques
import macros
import os
import tables
import times
import unicode

import ../debug
import ../lib/glad/gl
from ../lib/glfw import nil
import opengl

export glfw.Key
export glfw.KeyAction
export glfw.ModifierKey
export glfw.MouseButton
export times.cpuTime
export unicode.Rune

#--
# OpenGL Initialization
#--

type
  InitErrorKind = enum
    ieOK = "Init successful"
    ieGlfwInitFailed = "Failed to initialize GLFW"
    ieGladLoadFailed = "Failed to load OpenGL procs"
  GLFWError* = object of Exception
    code: int

proc initGlfw(): InitErrorKind =
  if glfw.init() == 0:
    return ieGlfwInitFailed
  addQuitProc() do:
    glfw.terminate()
  discard glfw.setErrorCallback do (errCode: int32, msg: cstring):
    var err = newException(GLFWError, $msg)
    err.code = int errCode
    raise err
  return ieOK

proc onGlDebug(source, kind: GLenum, id: GLuint, severity: GLenum,
               length: GLsizei, msgPtr: ptr GLchar,
               userParam: pointer) {.stdcall.} =
  var msg = newString(length)
  copyMem(msg[0].unsafeAddr, msgPtr, length)
  debug("GL | kind ", kind, ", severity ", severity, ": ", msg)
  when defined(glDebugBacktrace):
    writeStackTrace()

proc initGl(win: glfw.Window): InitErrorKind =
  glfw.makeContextCurrent(win)
  if not gladLoadGL(glfw.getProcAddress):
    return ieGladLoadFailed
  if GLAD_GL_KHR_debug:
    glEnable(GL_DEBUG_OUTPUT)
    glDebugMessageCallback(onGlDebug, nil)
  return ieOK

#--
# Window building
#--

type
  #--
  # Building
  #--
  WindowOptions = object
    width, height: Natural
    title: string
    resizable, visible, decorated, focused, floating, maximized: bool
  #--
  # Events
  #--
  RCharFn* = proc (win: RWindow, rune: Rune, mods: int)
  RCursorEnterFn* = proc (win: RWindow)
  RCursorMoveFn* = proc (win: RWindow, x, y: float)
  RFilesDroppedFn* = proc (win: RWindow, filenames: seq[string])
  RKeyFn* = proc (win: RWindow, key: glfw.Key, scancode: int, mods: int)
  RMouseFn* = proc (win: RWindow, button: glfw.MouseButton, mods: int)
  RScrollFn* = proc (win: RWindow, x, y: float)
  RCloseFn* = proc (win: RWindow): bool
  RResizeFn* = proc (win: RWindow, width, height: Natural)
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
  #--
  # Windows
  #--
  RWindowObj = object
    handle*: glfw.Window
    callbacks: WindowCallbacks
    context*: GLContext
  RWindow* = ref RWindowObj

using
  wopt: WindowOptions

proc initRWindow*(): WindowOptions =
  ## Initializes a new ``RWindow``.
  once:
    let status = initGlfw()
    if status != ieOK:
      raise newException(GLFWError, $status)
  result = WindowOptions(
    width: 800, height: 600,
    title: "rapid",
    resizable: true, visible: true,
    decorated: true, focused: true,
    floating: false, maximized: false
  )

proc size*(wopt; width, height: int): WindowOptions =
  ## Builds the window with the specified dimensions.
  result = wopt
  result.width = width
  result.height = height

proc title*(wopt; title: string): WindowOptions =
  ## Builds the window with the specified title.
  result = wopt
  result.title = title

template builderBool(param: untyped, doc: untyped): untyped {.dirty.} =
  proc param*(wopt; param: bool): WindowOptions =
    doc
    result = wopt
    result.param = param
builderBool(resizable):
  ## Defines if the built window will be resizable.
builderBool(visible):
  ## Defines if the built window will be visible.
builderBool(decorated):
  ## Defines if the built window will be decorated.
builderBool(focused):
  ## Defines if the built window will be focused.
builderBool(floating):
  ## Defines if the built window will float (stay on top of other windows).
builderBool(maximized):
  ## Defines if the built window will be maximized.

proc glfwCallbacks(win: var RWindow) =
  win.callbacks = WindowCallbacks()
  template run(name, body: untyped): untyped {.dirty.} =
    let win = cast[RWindow](glfw.getWindowUserPointer(w))
    for fn in win.callbacks.name: body
  discard glfw.setCharModsCallback(win.handle,
    proc (w: glfw.Window, uchar: cuint, mods: int32) =
      run(onChar): fn(win, Rune(uchar), int mods))
  discard glfw.setCursorEnterCallback(win.handle,
    proc (w: glfw.Window, entered: int32) =
      if entered == 1:
        run(onCursorEnter, fn(win))
      else:
        run(onCursorLeave, fn(win)))
  discard glfw.setCursorPosCallback(win.handle,
    proc (w: glfw.Window, x, y: cdouble) =
      run(onCursorMove, fn(win, x, y)))
  discard glfw.setDropCallback(win.handle,
    proc (w: glfw.Window, n: int32, files: cstringArray) =
      run(onFilesDropped, fn(win, cstringArrayToSeq(files, n))))
  discard glfw.setKeyCallback(win.handle,
    proc (w: glfw.Window, key, scan, action, mods: int32) =
      case glfw.KeyAction(action)
      of glfw.kaDown:
        run(onKeyPress, fn(win, glfw.Key(key), int scan, int mods))
      of glfw.kaUp:
        run(onKeyRelease, fn(win, glfw.Key(key), int scan, int mods))
      of glfw.kaRepeat:
        run(onKeyRepeat, fn(win, glfw.Key(key), int scan, int mods)))
  discard glfw.setMouseButtonCallback(win.handle,
    proc (w: glfw.Window, button, action, mods: int32) =
      case glfw.KeyAction(action)
      of glfw.kaDown:
        run(onMousePress, fn(win, glfw.MouseButton(button), int mods))
      of glfw.kaUp:
        run(onMouseRelease, fn(win, glfw.MouseButton(button), int mods))
      else: discard)
  discard glfw.setScrollCallback(win.handle,
    proc (w: glfw.Window, x, y: cdouble) =
      run(onScroll, fn(win, x, y)))
  discard glfw.setWindowCloseCallback(win.handle,
    proc (w: glfw.Window) =
      var close = true
      run(onClose): close = close and fn(win)
      glfw.setWindowShouldClose(w, int32 close))
  discard glfw.setWindowSizeCallback(win.handle,
    proc (w: glfw.Window, width, height: int32) =
      run(onResize, fn(win, width, height)))

converter toInt32(hint: glfw.Hint): int32 =
  int32 hint

proc open*(wopt): RWindow =
  ## Builds a window using the specified options and opens it.
  ## The window will always have an OpenGL 3.3 (or newer) context.
  ## rapid only ever makes use of 3.3 procs, however.
  result = RWindow()

  let
    mon = glfw.getPrimaryMonitor()
    mode = glfw.getVideoMode(mon)

  glfw.windowHint(glfw.hRedBits, mode.redBits)
  glfw.windowHint(glfw.hGreenBits, mode.greenBits)
  glfw.windowHint(glfw.hBlueBits, mode.blueBits)
  glfw.windowHint(glfw.hAlphaBits, 8)
  glfw.windowHint(glfw.hDepthBits, 24)
  glfw.windowHint(glfw.hStencilBits, 8)

  glfw.windowHint(glfw.hResizable, wopt.resizable.int32)
  glfw.windowHint(glfw.hVisible, false.int32)
  glfw.windowHint(glfw.hDecorated, wopt.decorated.int32)
  glfw.windowHint(glfw.hFocused, wopt.focused.int32)
  glfw.windowHint(glfw.hFloating, wopt.floating.int32)
  glfw.windowHint(glfw.hMaximized, wopt.maximized.int32)

  glfw.windowHint(glfw.hContextVersionMajor, 3)
  glfw.windowHint(glfw.hContextVersionMinor, 3)
  glfw.windowHint(glfw.hOpenglProfile, glfw.opCoreProfile.int32)
  glfw.windowHint(glfw.hOpenglDebugContext, 1)
  result.handle = glfw.createWindow(
    wopt.width.int32, wopt.height.int32,
    wopt.title,
    nil, nil
  )
  result.context = GLContext(
    window: result.handle
  )

  # center the window
  glfw.setWindowPos(result.handle,
    int32(mode.width / 2 - wopt.width / 2),
    int32(mode.height / 2 - wopt.height / 2))

  if wopt.visible: glfw.showWindow(result.handle)

  once:
    let status = initGl(result.handle)
    if status != ieOK:
      raise newException(GLError, $status)

  glfw.setWindowUserPointer(result.handle, cast[pointer](result))
  glfwCallbacks(result)

proc destroy*(win: RWindow) =
  ## Destroys a window.
  glfw.destroyWindow(win.handle)

#--
# Window attributes
#--

proc close*(win: var RWindow) =
  ## Tells the window it should close. This doesn't immediately close the window;
  ## the application might prevent the window from being closed.
  glfw.setWindowShouldClose(win.handle, 1)

proc pos*(win: RWindow): tuple[x, y: int] =
  var x, y: int32
  glfw.getWindowPos(win.handle, addr x, addr y)
  result = (int x, int y)
proc x*(win: RWindow): int = win.pos().x
proc y*(win: RWindow): int = win.pos().y
proc `pos=`*(win: var RWindow, pos: tuple[x, y: int]) =
  glfw.setWindowSize(win.handle, int32 pos.x, int32 pos.y)
proc `x=`*(win: var RWindow, x: int) = win.pos = (x, win.x)
proc `y=`*(win: var RWindow, y: int) = win.pos = (y, win.y)

type
  IntDimensions* = tuple[width, height: int]
proc size*(win: RWindow): IntDimensions =
  var w, h: int32
  glfw.getWindowSize(win.handle, addr w, addr h)
  result = (int w, int h)
proc width*(win: RWindow): int = win.size().width
proc height*(win: RWindow): int = win.size().height
proc `size=`*(win: var RWindow, size: IntDimensions) =
  glfw.setWindowSize(win.handle, int32 size.width, int32 size.height)
proc `width=`*(win: var RWindow, width: int) = win.size = (width, win.width)
proc `height=`*(win: var RWindow, height: int) = win.size = (win.width, height)
proc limitSize*(win: var RWindow, min, max: IntDimensions) =
  glfw.setWindowSizeLimits(win.handle,
    int32 min.width, int32 min.height, int32 max.width, int32 max.height)

proc fbSize*(win: RWindow): IntDimensions =
  var w, h: int32
  glfw.getFramebufferSize(win.handle, addr w, addr h)
  result = (int w, int h)

proc iconify*(win: var RWindow) = glfw.iconifyWindow(win.handle)
proc restore*(win: var RWindow) = glfw.restoreWindow(win.handle)
proc maximize*(win: var RWindow) = glfw.maximizeWindow(win.handle)
proc show*(win: var RWindow) = glfw.showWindow(win.handle)
proc hide*(win: var RWindow) = glfw.hideWindow(win.handle)
proc focus*(win: var RWindow) = glfw.focusWindow(win.handle)

proc focused*(win: RWindow): bool =
  result = bool glfw.getWindowAttrib(win.handle, glfw.hFocused)
proc iconified*(win: RWindow): bool =
  result = bool glfw.getWindowAttrib(win.handle, glfw.Iconified)
proc maximized*(win: RWindow): bool =
  result = bool glfw.getWindowAttrib(win.handle, glfw.hMaximized)
proc visible*(win: RWindow): bool =
  result = bool glfw.getWindowAttrib(win.handle, glfw.hVisible)
proc decorated*(win: RWindow): bool =
  result = bool glfw.getWindowAttrib(win.handle, glfw.hDecorated)
proc floating*(win: RWindow): bool =
  result = bool glfw.getWindowAttrib(win.handle, glfw.hFloating)

#~~
# Input
#~~

template callbackProc(name, T, doc: untyped): untyped {.dirty.} =
  proc name*(win: var RWindow, callback: T) =
    doc
    win.callbacks.name.add(callback)
callbackProc(onChar, RCharFn):
  ## Adds a callback executed when a character is typed on the keyboard.
callbackProc(onCursorEnter, RCursorEnterFn):
  ## Adds a callback executed when the cursor enters the window.
callbackProc(onCursorLeave, RCursorEnterFn):
  ## Adds a callback executed when the cursor leaves the window.
callbackProc(onCursorMove, RCursorMoveFn):
  ## Adds a callback executed when the cursor moves in the window.
callbackProc(onFilesDropped, RFilesDroppedFn):
  ## Adds a callback executed when files are dropped onto the window.
callbackProc(onKeyPress, RKeyFn):
  ## Adds a callback executed when a key is pressed on the keyboard.
callbackProc(onKeyRelease, RKeyFn):
  ## Adds a callback executed when a key is released on the keyboard.
callbackProc(onKeyRepeat, RKeyFn):
  ## Adds a callback executed when a repeat is triggered by holding down a key \
  ## on the keyboard.
callbackProc(onMousePress, RMouseFn):
  ## Adds a callback executed when a mouse button is pressed.
callbackProc(onMouseRelease, RMouseFn):
  ## Adds a callback executed when a mouse button is released.
callbackProc(onScroll, RScrollFn):
  ## Adds a callback executed when the scroll wheel is moved.
callbackProc(onClose, RCloseFn):
  ## Adds a callback executed when there's an attempt to close the window.
  ## The callback should return ``true`` if the window is to be closed, or \
  ## ``false`` if closing should be canceled.
callbackProc(onResize, RResizeFn):
  ## Adds a callback executed when the window is resized.

proc key*(win: RWindow, key: glfw.Key): glfw.KeyAction =
  glfw.KeyAction(glfw.getKey(win.handle, int32(key)))

proc mouseButton*(win: RWindow, btn: glfw.MouseButton): glfw.KeyAction =
  glfw.KeyAction(glfw.getMouseButton(win.handle, int32(btn)))

proc mousePos*(win: RWindow): tuple[x, y: float] =
  var x, y: float64
  glfw.getCursorPos(win.handle, addr x, addr y)
  result = (x, y)
proc mouseX*(win: RWindow): float = win.mousePos.x
proc mouseY*(win: RWindow): float = win.mousePos.y

proc `mousePos=`*(win: var RWindow, x, y: float) =
  glfw.setCursorPos(win.handle, float64 x, float64 y)

proc makeCurrent*(win: RWindow) =
  ## Makes the window the current one for drawing actions.
  win.context.makeCurrent()

template with*(win: RWindow, body: untyped) =
  ## Does the specified actions on the window's contents.
  ## ``render`` should be preferred over this.
  let prevGlc = currentGlc
  win.makeCurrent()
  body
  prevGlc.makeCurrent()

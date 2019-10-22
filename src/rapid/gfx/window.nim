#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## This module has everything related to windows.
## **Do not import this directly, it's included by the gfx module.**
##
## You can use ``-d:RGlDebugOutput`` to enable OpenGL debug output.

import times
import unicode

import glm

import ../lib/glad/gl
import ../lib/sdl/[sdl_init, sdl_error, sdl_keyboard, sdl_video]
import ../debug
import ../shutdown
import window/window_enums
import window/window_lowlevel
import opengl

export window_enums
export times.cpuTime
export unicode.Rune

#--
# Initialization
#--

proc onGlDebug(source, kind: GLenum, id: GLuint, severity: GLenum,
               length: GLsizei, msgPtr: ptr GLchar,
               userParam: pointer) {.stdcall, used.} =
  var msg = newString(length)
  copyMem(msg[0].unsafeAddr, msgPtr, length)
  let kindStr =
    case kind.int
    of 0x824c: "error"
    of 0x824d: "deprecated behavior"
    of 0x824e: "undefined behavior"
    of 0x824f: "portability"
    of 0x8250: "performance"
    of 0x8251: "marker"
    of 0x8252: "push group"
    of 0x8253: "pop group"
    of 0x8254: "other"
    else: "<unknown type>"
  case severity.int
  of 0x9146: error("(GL) ", kindStr, ": ", msg)
  of 0x9147, 0x9148: warn("(GL) ", kindStr, ": ", msg)
  of 0x826B: info("(GL) ", kindStr, ": ", msg)
  else: discard
  when defined(glDebugBacktrace):
    writeStackTrace()

proc initGl(win: ptr Window) =
  doAssert gladLoadGL(GL_GetProcAddress), "OpenGL could not be loaded"
  when defined(RGlDebugOutput):
    if GLAD_GL_KHR_debug:
      glEnable(GL_DEBUG_OUTPUT)
      glDebugMessageCallback(onGlDebug, nil)
    else:
      warn("KHR_debug is not present. OpenGL debug info will not be available")
  if not GLAD_GL_ARB_separate_shader_objects:
    error("ARB_separate_shader_objects is not available. ",
          "Please update your graphics drivers")
    quit(QuitFailure)
  return ieOK

#--
# Window building
#--

type
  # Building
  WindowOptions = object
    width, height: Natural
    title: string
    fullscreen: bool
    resizable, visible, decorated, maximized, minimized: bool
    antialiasLevel: int
  # Events
  RModKeys* = set[RModKey]
  RCharProc* = proc (rune: Rune, mods: RModKeys)
  RCursorEnterProc* = proc ()
  RCursorMoveProc* = proc (x, y: float)
  RFilesDroppedProc* = proc (filenames: seq[string])
  RKeyProc* = proc (key: RKeycode, scancode: RScancode, mods: RModKeys)
  RMouseProc* = proc (button: RMouseButton, mods: RModKeys)
  RScrollProc* = proc (x, y: float)
  RCloseProc* = proc (): bool
  RResizeProc* = proc (width, height: Natural)
  WindowCallbacks = object
    onChar: seq[RCharProc]
    onCursorEnter, onCursorLeave: seq[RCursorEnterProc]
    onCursorMove: seq[RCursorMoveProc]
    onFilesDropped: seq[RFilesDroppedProc]
    onKeyPress, onKeyRelease, onKeyRepeat: seq[RKeyProc]
    onMousePress, onMouseRelease: seq[RMouseProc]
    onScroll: seq[RScrollProc]
    onClose: seq[RCloseProc]
    onResize: seq[RResizeProc]
  # Windows
  RWindowObj = object
    handle: ptr Window
    callbacks: WindowCallbacks
    fClose: bool
    keyState: ptr UncheckedArray[uint8]
  RWindow* = ref RWindowObj

using
  wopt: WindowOptions

proc initRWindow*(): WindowOptions =
  ## Initializes a new ``RWindow``.
  once:
    sdlTry initSubSystem(0x20 #[SDL_INIT_VIDEO]#)
  result = WindowOptions(
    width: 800, height: 600,
    title: "rapid",
    resizable: true, visible: true,
    decorated: true, maximized: false,
    fullscreen: false
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
builderBool(fullscreen):
  ## Defines if the built window will be fullscreen.
  ## This creates a window in 'borderless fullscreen', meaning that the video
  ## mode of your monitor is not changed. The window simply fills your entire
  ## desktop.
builderBool(resizable):
  ## Defines if the built window will be resizable.
builderBool(visible):
  ## Defines if the built window will be visible.
builderBool(decorated):
  ## Defines if the built window will be decorated.
builderBool(minimized):
  ## Defines if the built window will be minimized.
builderBool(maximized):
  ## Defines if the built window will be maximized.

proc antialiasLevel*(wopt; level: int): WindowOptions =
  ## Builds the window with the specified antialiasing level.
  result = wopt
  result.antialiasLevel = level

converter toModsSet(mods: int32): RModKeys =
  result = {}
  const
    Shifts = KMOD_LSHIFT or KMOD_RSHIFT
    Ctrls = KMOD_LCTRL or KMOD_RCTRL
    Alts = KMOD_LALT or KMOD_RALT
    Guis = KMOD_LGUI or KMOD_RGUI
  if (mods and Shifts) > 0: result.incl(rmkShift)
  if (mods and Ctrls) > 0: result.incl(rmkCtrl)
  if (mods and Alts) > 0: result.incl(rmkAlt)
  if (mods and Guis) > 0: result.incl(rmkGui)
  if (mods and KMOD_NUM) > 0: result.incl(rmkNumLock)
  if (mods and KMOD_CAPS) > 0: result.incl(rmkCapsLock)
  if (mods and KMOD_MODE) > 0: result.incl(rmkMode)

proc open*(wopt): RWindow =
  ## Builds a window using the specified options and opens it.
  new(result) do (win: RWindow):
    destroyWindow(win.handle)

  let mode = primaryDisplay()

  # glfw.windowHint(glfw.hRedBits, mode.redBits)
  # glfw.windowHint(glfw.hGreenBits, mode.greenBits)
  # glfw.windowHint(glfw.hBlueBits, mode.blueBits)
  # glfw.windowHint(glfw.hAlphaBits, 8)
  # glfw.windowHint(glfw.hDepthBits, 24)
  # glfw.windowHint(glfw.hStencilBits, 8)
  # if wopt.antialiasLevel != 0:
  #   glfw.windowHint(glfw.hSamples, wopt.antialiasLevel.int32)

  var winFlags = WINDOW_OPENGL.uint32
  if wopt.fullscreen: winFlags = winFlags or WINDOW_FULLSCREEN_DESKTOP.uint32
  if not wopt.visible: winFlags = winFlags or WINDOW_HIDDEN.uint32
  if not wopt.decorated: winFlags = winFlags or WINDOW_BORDERLESS.uint32
  if wopt.minimized: winFlags = winFlags or WINDOW_MINIMIZED.uint32
  if wopt.maximized: winFlags = winFlags or WINDOW_MAXIMIZED.uint32
  if wopt.resizable: winFlags = winFlags or WINDOW_RESIZABLE.uint32

  # glfw.windowHint(glfw.hContextVersionMajor, 3)
  # glfw.windowHint(glfw.hContextVersionMinor, 3)
  # glfw.windowHint(glfw.hOpenglProfile, glfw.opCoreProfile.int32)
  # glfw.windowHint(glfw.hOpenglDebugContext, 1)
  const
    PosCentered = 0x2FFF0000.cint #[SDL_WINDOWPOS_CENTERED]#
  result.handle = createWindow(wopt.title, PosCentered, PosCentered,
                               wopt.width.cint, wopt.height.cint, winFlags)

  once initGl(result.handle)

#--
# Window attributes
#--

proc shouldClose*(win: RWindow): bool =
  ## Returns whether the window should close.
  win.fClose
proc `shouldClose=`*(win: RWindow, close: bool) =
  ## Sets whether the window should be closed.
  win.fClose = true

proc close*(win: RWindow) =
  ## An alias for ``win.shouldClose = true``.
  win.shouldClose = true

proc pos*(win: RWindow): Vec2[float] =
  var x, y: cint
  getWindowPosition(win.handle, addr x, addr y)
  result = vec2(x.float, y.float)
proc x*(win: RWindow): float = win.pos.x
proc y*(win: RWindow): float = win.pos.y
proc `pos=`*(win: RWindow, pos: Vec2[float]) =
  setWindowPosition(win.handle, pos.x.cint, pos.y.cint)
proc `x=`*(win: RWindow, x: float) = win.pos = vec2(x, win.x)
proc `y=`*(win: RWindow, y: float) = win.pos = vec2(y, win.y)

proc size*(win: RWindow): Vec2[float] =
  var w, h: cint
  getWindowSize(win.handle, addr w, addr h)
  result = vec2(w.float, h.float)
proc width*(win: RWindow): float = win.size.x
proc height*(win: RWindow): float = win.size.y
proc `size=`*(win: RWindow, size: Vec2[float]) =
  setWindowSize(win.handle, size.x.cint, size.y.cint)
proc `width=`*(win: RWindow, width: float) =
  win.size = vec2(width, win.width)
proc `height=`*(win: RWindow, height: float) =
  win.size = vec2(win.width, height)

proc minSize*(win: RWindow): Vec2[float] =
  var w, h: cint
  getWindowMinimumSize(win.handle, addr w, addr h)
  result = vec2(w.float, h.float)
proc maxSize*(win: RWindow): Vec2[float] =
  var w, h: cint
  getWindowMaximumSize(win.handle, addr w, addr h)
  result = vec2(w.float, h.float)
proc `minSize=`*(win: RWindow, size: Vec2[float]) =
  setWindowMinimumSize(win.handle, size.x.cint, size.y.cint)
proc `maxSize=`*(win: RWindow, size: Vec2[float]) =
  setWindowMaximumSize(win.handle, size.x.cint, size.y.cint)

proc iconify*(win: RWindow) = minimizeWindow(win.handle)
proc restore*(win: RWindow) = restoreWindow(win.handle)
proc maximize*(win: RWindow) = maximizeWindow(win.handle)
proc show*(win: RWindow) = showWindow(win.handle)
proc hide*(win: RWindow) = hideWindow(win.handle)
proc focus*(win: RWindow) = raiseWindow(win.handle)

proc focused*(win: RWindow): bool =
  result = (getWindowFlags(win.handle) and WINDOW_INPUT_FOCUS.uint32) != 0
proc iconified*(win: RWindow): bool =
  result = (getWindowFlags(win.handle) and WINDOW_MINIMIZED.uint32) != 0
proc maximized*(win: RWindow): bool =
  result = (getWindowFlags(win.handle) and WINDOW_MAXIMIZED.uint32) != 0
proc visible*(win: RWindow): bool =
  result = (getWindowFlags(win.handle) and WINDOW_HIDDEN.uint32) == 0
proc decorated*(win: RWindow): bool =
  result = (getWindowFlags(win.handle) and WINDOW_BORDERLESS.uint32) == 0

#~~
# Input
#~~

template callbackProc(name, T, doc: untyped): untyped {.dirty.} =
  proc name*(win: RWindow, callback: T) =
    doc
    win.callbacks.name.add(callback)
callbackProc(onChar, RCharProc):
  ## Adds a callback executed when a character is typed on the keyboard.
callbackProc(onCursorEnter, RCursorEnterProc):
  ## Adds a callback executed when the cursor enters the window.
callbackProc(onCursorLeave, RCursorEnterProc):
  ## Adds a callback executed when the cursor leaves the window.
callbackProc(onCursorMove, RCursorMoveProc):
  ## Adds a callback executed when the cursor moves in the window.
callbackProc(onFilesDropped, RFilesDroppedProc):
  ## Adds a callback executed when files are dropped onto the window.
callbackProc(onKeyPress, RKeyProc):
  ## Adds a callback executed when a key is pressed on the keyboard.
callbackProc(onKeyRelease, RKeyProc):
  ## Adds a callback executed when a key is released on the keyboard.
callbackProc(onKeyRepeat, RKeyProc):
  ## Adds a callback executed when a repeat is triggered by holding down a key \
  ## on the keyboard.
callbackProc(onMousePress, RMouseProc):
  ## Adds a callback executed when a mouse button is pressed.
callbackProc(onMouseRelease, RMouseProc):
  ## Adds a callback executed when a mouse button is released.
callbackProc(onScroll, RScrollProc):
  ## Adds a callback executed when the scroll wheel is moved.
callbackProc(onClose, RCloseProc):
  ## Adds a callback executed when there's an attempt to close the window.
  ## The callback should return ``true`` if the window is to be closed, or \
  ## ``false`` if closing should be canceled.
callbackProc(onResize, RResizeProc):
  ## Adds a callback executed when the window is resized.

proc pollEvents*(win: RWindow) =
  ## Polls any events, and updates any internal state structs.
  var event:
  win.keyState = cast[ptr UncheckedArray[uint8]](getKeyboardState(nil))

proc key*(win: RWindow, key: RScancode): bool =
  assert win.keyState != nil, "Attempt to use `key` before `pollEvents`"


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

proc time*(): float =
  ## Returns the current process's time.
  ## This should be used instead of ``cpuTime()``, because it properly deals \
  ## with the game loop.
  result = glfw.getTime().float

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

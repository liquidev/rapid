from unicode import toUtf8

import ../lib/glad/gl
import glfw

import gfx

type
  RWindow* = object
    glwindow: Window
    gfx: RGfx
    events: RWindowEvents
    gldebug: bool
    fps, dt: float64
  RWindowEvents = object
    onChar: proc (character: string)
    onKeyDown: proc (key: Key, scancode: int32)
    onKeyUp: proc (key: Key, scancode: int32)
    onKeyRepeat: proc (key: Key, scancode: int32)
    onMousePress: proc (button: MouseButton)
    onMouseRelease: proc (button: MouseButton)
    onMouseMove: proc (x, y: float)
    onMouseEnter: proc ()
    onMouseLeave: proc ()
    onMouseWheel: proc (x, y: float)
    onResize: proc (width, height: int)
    onClose: proc (): bool

###
# RWindow
###

proc newRWindow*(title: string, width, height: int): RWindow =
  glfw.initialize()

  var winconf = DefaultOpenglWindowConfig
  winconf.size = (w: width, h: height)
  winconf.title = title

  winconf.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  winconf.version = glv33
  var win = newWindow(winconf)

  var rwin = RWindow(
    glwindow: win,
    gfx: newRGfx(width, height),
    events: RWindowEvents(
      onChar: proc (character: string) = discard,
      onKeyDown: proc (key: Key, scancode: int32) = discard,
      onKeyUp: proc (key: Key, scancode: int32) = discard,
      onKeyRepeat: proc (key: Key, scancode: int32) = discard,
      onMousePress: proc (button: MouseButton) = discard,
      onMouseRelease: proc (button: MouseButton) = discard,
      onMouseMove: proc (x, y: float) = discard,
      onMouseLeave: proc () = discard,
      onMouseEnter: proc () = discard,
      onMouseWheel: proc (x, y: float) = discard,
      onResize: proc (width, height: int) = discard,
      onClose: proc (): bool = return true
    )
  )

  if not gladLoadGL(getProcAddress):
    quit "rd fatal: couldn't create gl context"

  return rwin

proc debug*(self: var RWindow, state: bool) =
  self.gldebug = state

proc debugCallback(
    source: GLenum, etype: GLenum,
    id: GLuint, severity: GLenum,
    length: GLsizei, message: ptr GLchar,
    userParam: pointer) {.stdcall.} =
  echo "rd/gl debug | type: " & $etype & "; severity: " & $severity & "; message: " & $message

proc registerCallbacks(self: RWindow) =
  var win = self.glwindow
  win.charCb = proc (w: Window, codePoint: Rune) = self.events.onChar(codePoint.toUTF8())
  win.keyCb = proc (w: Window, key: Key, scancode: int32, action: KeyAction, mods: set[ModifierKey]) =
    case action:
    of kaDown: self.events.onKeyDown(key, scancode)
    of kaRepeat: self.events.onKeyRepeat(key, scancode)
    of kaUp: self.events.onKeyUp(key, scancode)
  win.mouseButtonCb = proc (w: Window, button: MouseButton, pressed: bool, modKeys: set[ModifierKey]) =
    if pressed: self.events.onMousePress(button)
    else: self.events.onMouseRelease(button)
  win.cursorPositionCb = proc (w: Window, pos: tuple[x, y: float64]) = self.events.onMouseMove(pos.x, pos.y)
  win.cursorEnterCb = proc (w: Window, entered: bool) =
    if entered: self.events.onMouseEnter()
    else: self.events.onMouseLeave()
  win.scrollCb = proc (w: Window, off: tuple[x, y: float64]) = self.events.onMouseWheel(off.x, off.y)
  win.windowCloseCb = proc (w: Window) =
    let close = self.events.onClose()
    win.shouldClose = close
  win.windowSizeCb = proc (w: Window, size: tuple[w, h: int32]) =
    var wg = self.gfx
    wg.resize(size.w, size.h)
    self.events.onResize(size.w, size.h)

  if self.gldebug:
    glEnable(GL_DEBUG_OUTPUT)
    glDebugMessageCallback(debugCallback, cast[pointer](0))

proc loop*(self: var RWindow, loopf: proc (ctx: var RGfxContext)) =
  var win = self.glwindow
  self.registerCallbacks()

  var gfx = self.gfx
  gfx.start()

  glfw.swapInterval(1)

  var ptime: float64
  while not win.shouldClose:
    self.dt = getTime() - ptime

    win.swapBuffers()
    glfw.pollEvents()

    gfx.render do (ctx: var RGfxContext):
      loopf(ctx)

    ptime = getTime()
    self.fps = 1 / self.dt

  glfw.terminate()

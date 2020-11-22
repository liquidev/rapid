## Simple UI framework inspired by `fidget <https://github.com/treeform/fidget/>`.

import std/unicode

import aglet

import graphics
import input

type
  HorizontalAlignmentPosition* = enum
    apLeft
    apCenter
    apRight

  VerticalAlignmentPosition* = enum
    apTop
    apMiddle
    apBottom

  Alignment* = tuple
    horizontal: HorizontalAlignmentPosition
    vertical: VerticalAlignmentPosition

  BoxLayout* = enum
    blFreeform
    blHorizontal
    blVertical

  Box* = object
    ## A layout box.

    rect*: Rectf

    # rendering
    color*: Color
    font*: Font
    fontSize*: Vec2f

    # layout
    case layout*: BoxLayout
    of blFreeform: discard
    of blHorizontal, blVertical:
      layoutPosition*: Vec2f
      spacing*: float32

  Ui* = ref object of RootObj
    graphics: Graphics
    input: Input

    stack: seq[Box]
    textInputBuffer: seq[Rune]

  LayoutError* = object of FieldDefect

proc init*(ui: Ui, window: Window, graphics: Graphics = nil) =
  ## Initializes a UI instance. If ``graphics`` is nil, a new graphics context
  ## is created.

  ui.graphics = graphics
  ui.input = window.newInput()

  if ui.graphics == nil:
    ui.graphics = window.newGraphics()

  ui.input.onCharInput proc (rune: Rune) =
    ui.textInputBuffer.add(rune)

proc newUi*(window: Window, graphics: Graphics = nil): Ui =
  ## Creates and initializes a new UI instance.

  new result
  result.init(window, graphics)


# resources, if you ever need to do some manual drawing

proc graphics*(ui: Ui): Graphics {.inline.} =
  ## Returns the graphics context of the UI.
  ui.graphics


# boxes and layout

{.push inline.}

proc currentBox*(ui: Ui): var Box =
  ## Returns the box at the top of the stack.
  ui.stack[^1]

proc padH*(ui: Ui, padding: float32) =
  ## Pads the current box with the given amount of horizontal padding.

  var rect = ui.currentBox.rect
  rect.position += vec2f(padding, 0)
  rect.size -= vec2f(padding, 0) * 2
  ui.currentBox.rect = rect

proc padV*(ui: Ui, padding: float32) =
  ## Pads the current box with the given amount of vertical padding.

  var rect = ui.currentBox.rect
  rect.position += vec2f(0, padding)
  rect.size -= vec2f(0, padding) * 2
  ui.currentBox.rect = rect

proc pad*(ui: Ui, padding: float32) =
  ## Pads the current box with the given amount of padding.

  var rect = ui.currentBox.rect
  rect.position += vec2f(padding)
  rect.size -= vec2f(padding) * 2
  ui.currentBox.rect = rect

proc align*(ui: Ui, alignment: Alignment) =
  ## Aligns the current box inside of the parent box according to the given
  ## alignment.
  ## Note that there must be a parent box for this to work. If there is no
  ## parent box, an exception is raised.

  assert ui.stack.len > 1, "the root box cannot be aligned"

  let parent = ui.stack[^2].rect
  var rect = ui.currentBox.rect

  # horizontal
  rect.position.x =
    case alignment.horizontal
    of apLeft: parent.left
    of apCenter: parent.width / 2 - rect.width / 2
    of apRight: parent.right - rect.width

  # vertical
  rect.position.y =
    case alignment.vertical
    of apTop: parent.top
    of apMiddle: parent.height / 2 - rect.height / 2
    of apBottom: parent.height - rect.height

  ui.currentBox.rect = rect

proc offset*(ui: Ui, v: Vec2f) =
  ## Offsets the layout position by the given vector.
  ui.currentBox.layoutPosition += v

proc spacing*(ui: Ui): float32 =
  ## Returns the current box's spacing.
  ui.currentBox.spacing

proc `spacing=`*(ui: Ui, newSpacing: float32) =
  ## Sets the spacing between boxes inside of the current box.
  ## This is only applicable for boxes with horizontal or vertical layout.
  ui.currentBox.spacing = newSpacing

proc size*(ui: Ui): Vec2f =
  ## Returns the size of the current box.
  ui.currentBox.rect.size

proc width*(ui: Ui): float32 =
  ## Returns the width of the current box.
  ui.size.x

proc height*(ui: Ui): float32 =
  ## Returns the height of the current box.
  ui.size.y

{.pop.}

proc pushBox*(ui: Ui, position, size: Vec2f, layout: BoxLayout) =
  ## Pushes a new box onto the box stack.
  ## Prefer the ``box`` template over this, as it automatically pops the box
  ## off the stack too.

  var box = Box(layout: layout)
  box.rect.position = ui.currentBox.rect.position + position
  box.rect.size = size
  box.color = ui.currentBox.color
  box.font = ui.currentBox.font
  box.fontSize = ui.currentBox.fontSize
  ui.stack.add(box)

proc pushBox*(ui: Ui, size: Vec2f, layout: BoxLayout) =
  ## Pushes a new box onto the box stack, with the position following the
  ## current box's layout settings.
  ## This updates the parent box's layout position if applicable.

  var parent = addr ui.currentBox

  case parent.layout
  of blFreeform:
    ui.pushBox(vec2f(0, 0), size, layout)
  of blHorizontal, blVertical:
    ui.pushBox(parent.layoutPosition, size, layout)
    case parent.layout
    of blHorizontal:
      parent.layoutPosition.x += size.x + parent.spacing
    of blVertical:
      parent.layoutPosition.y += size.y + parent.spacing
    else: assert false

proc popBox*(ui: Ui) {.inline.} =
  ## Pops the topmost box off the stack.
  discard ui.stack.pop()

template box*(ui: Ui, position, size: Vec2f, layout: BoxLayout, body: untyped) =
  ## Pushes a new box onto the stack, executes the body, and then pops the box
  ## off the stack.
  ## Boxes are positioned relative to each other, eg. when the current box is at
  ## (8, 8) and a position of (8, 8) is passed into this template, the new box
  ## will be positioned at (16, 16) relative to the root box.
  ## Prefer this over using ``pushBox`` and ``popBox`` manually.

  block:
    ui.pushBox(position, size, layout)
    `body`
    ui.popBox()

template box*(ui: Ui, size: Vec2f, layout: BoxLayout, body: untyped) =
  ## Same as the above, but uses the auto-layout version of ``pushBox``.

  block:
    ui.pushBox(size, layout)
    `body`
    ui.popBox()


# rendering

{.push inline.}

proc color*(ui: Ui): Color =
  ## Returns the current box's draw color.
  ui.currentBox.color

proc `color=`*(ui: Ui, color: Color) =
  ## Sets the draw color for the current box.
  ui.currentBox.color = color

proc fill*(ui: Ui, color: Color = ui.color) =
  ## Fills the current box with the given color.
  ui.graphics.rectangle(ui.currentBox.rect, color)

proc outline*(ui: Ui, color: Color = ui.color, thickness: float32 = 1) =
  ## Outlines the current box with the given color and thickness.

  var rect = ui.currentBox.rect
  rect.position -= vec2f(0.5)
  ui.graphics.lineRectangle(rect, thickness, color)

proc rightBorder*(ui: Ui, color: Color = ui.color, thickness: float32 = 1) =
  ## Draws the right border of the current box.

  var rect = ui.currentBox.rect
  rect.position -= vec2f(0.5)
  ui.graphics.line(rect.topRight, rect.bottomRight, thickness,
                   lcSquare, color, color)

proc bottomBorder*(ui: Ui, color: Color = ui.color, thickness: float32 = 1) =
  ## Draws the right border of the current box.

  var rect = ui.currentBox.rect
  rect.position -= vec2f(0.5)
  ui.graphics.line(rect.bottomLeft, rect.bottomRight, thickness,
                   lcSquare, color, color)

proc leftBorder*(ui: Ui, color: Color = ui.color, thickness: float32 = 1) =
  ## Draws the left border of the current box. Note that drawing all four
  ## borders does not form a perfect rectangle, use ``outline`` instead.

  var rect = ui.currentBox.rect
  rect.position -= vec2f(0.5)
  ui.graphics.line(rect.topLeft, rect.bottomLeft, thickness,
                   lcSquare, color, color)

proc topBorder*(ui: Ui, color: Color = ui.color, thickness: float32 = 1) =
  ## Draws the top border of the current box.

  var rect = ui.currentBox.rect
  rect.position -= vec2f(0.5)
  ui.graphics.line(rect.topLeft, rect.topRight, thickness,
                   lcSquare, color, color)

proc font*(ui: Ui): Font =
  ## Returns the current box's font.
  ui.currentBox.font

proc `font=`*(ui: Ui, font: Font) =
  ## Sets the current box's font. This also sets the font size.

  ui.currentBox.font = font
  ui.currentBox.fontSize = font.size

proc fontSize*(ui: Ui): Vec2f =
  ## Returns the current box's font size.
  ui.currentBox.fontSize

proc `fontSize=`*(ui: Ui, size: Vec2f) =
  ## Sets the current box's font size.
  ui.currentBox.fontSize = size

proc fontWidth*(ui: Ui): float32 =
  ## Returns the current box's font width.
  ui.fontSize.x

proc `fontWidth=`*(ui: Ui, width: float32) =
  ## Sets the current box's font width. A value of ``0`` means that the font
  ## width should be the same as the font height.
  ui.currentBox.fontSize.x = width

proc fontHeight*(ui: Ui): float32 =
  ## Returns the current box's font height.
  ui.fontSize.y

proc `fontHeight=`*(ui: Ui, height: float32) =
  ## Sets the current box's font height.
  ui.currentBox.fontSize.y = height

proc text*(ui: Ui, text: Text, color: Color = ui.color,
           alignment: Alignment = (apLeft, apTop)) =
  ## Draws text in the current box, with the given color, alignment, and size.
  ## The box's area is used as the text's alignment box.

  assert not ui.font.isNil, "cannot draw text without a font set"

  ui.graphics.text(ui.font, ui.currentBox.rect.position, text,
                   alignment.horizontal.HorzTextAlign,
                   alignment.vertical.VertTextAlign,
                   alignBox = ui.currentBox.rect.size,
                   ui.fontHeight, ui.fontWidth, color)

{.pop.}

template drawInBox*(ui: Ui, body: untyped) =
  ## Begins drawing in the current box.
  ## This translates the transform matrix to the box's position on the screen
  ## and creates a variable called ``graphicsVar`` containing the UI's graphics
  ## context, then executes the body and undoes the translation.
  ##
  ## This template should not be nested. Nesting can lead to incorrectly applied
  ## translations, so be careful!

  block:
    ui.graphics.translate(ui.currentBox.rect.position)
    `body`
    ui.graphics.translate(-ui.currentBox.rect.position)


# input

{.push inline.}

proc mousePosition*(ui: Ui): Vec2f =
  ## Returns the position of the mouse relative to the current box.
  ui.input.mousePosition - ui.currentBox.rect.position

proc mouseInBox*(ui: Ui): bool =
  ## Returns whether the mouse position is in the current box's area.
  ui.mousePosition.x >= 0 and ui.mousePosition.x < ui.currentBox.rect.width and
  ui.mousePosition.y >= 0 and ui.mousePosition.y < ui.currentBox.rect.height

proc mouseButtonIsDown*(ui: Ui, button: MouseButton): bool =
  ## Returns whether the given mouse button is held down.
  ui.input.mouseButtonIsDown(button)

proc mouseButtonJustPressed*(ui: Ui, button: MouseButton): bool =
  ## Returns whether the given mouse button has just been pressed.
  ui.input.mouseButtonJustPressed(button)

proc mouseButtonJustReleased*(ui: Ui, button: MouseButton): bool =
  ## Returns whether the given mouse button has just been released.
  ui.input.mouseButtonJustReleased(button)

proc keyIsDown*(ui: Ui, key: Key): bool =
  ## Returns whether the given key is being held down.
  ui.input.keyIsDown(key)

proc keyJustPressed*(ui: Ui, key: Key): bool =
  ## Returns whether the given key has just been pressed.
  ui.input.keyJustPressed(key)

proc keyJustReleased*(ui: Ui, key: Key): bool =
  ## Returns whether the given key has just been released.
  ui.input.keyJustReleased(key)

proc keyJustRepeated*(ui: Ui, key: Key): bool =
  ## Returns whether the given key has just been repeated.
  ui.input.keyJustRepeated(key)

template mouseHover*(ui: Ui, body: untyped) =
  ## Convenience/readability template, shortcut for ``if ui.mouseInBox``.

  if ui.mouseInBox:
    `body`

template mouseDown*(ui: Ui, button: MouseButton, body: untyped) =
  ## Convenience/readability template, shortcut for
  ## ``if ui.mouseInBox and ui.mouseButtonIsDown``.

  if ui.mouseInBox and ui.mouseButtonIsDown(button):
    `body`

template mousePressed*(ui: Ui, button: MouseButton, body: untyped) =
  ## Convenience/readability template, shortcut for
  ## ``if ui.mouseInBox and ui.mouseButtonJustPressed``.

  if ui.mouseInBox and ui.mouseButtonJustPressed(button):
    `body`

template mouseReleased*(ui: Ui, button: MouseButton, body: untyped) =
  ## Convenience/readability template, shortcut for
  ## ``if ui.mouseInBox and ui.mouseButtonJustPressed``.

  if ui.mouseInBox and ui.mouseButtonJustReleased(button):
    `body`

template keyPressed*(ui: Ui, key: Key, body: untyped) =
  ## Convenience/readability template, shortcut for ``if ui.keyJustPressed``.

  if ui.keyJustPressed(key):
    `body`

template keyReleased*(ui: Ui, key: Key, body: untyped) =
  ## Convenience/readability template, shortcut for ``if ui.keyJustReleased``.

  if ui.keyJustReleased(key):
    `body`

template keyTyped*(ui: Ui, key: Key, body: untyped) =
  ## Convenience/readability template, shortcut for
  ## ``if ui.keyJustPressed or ui.keyJustRepeated``.

  if ui.keyJustPressed(key) or ui.keyJustRepeated(key):
    `body`

{.pop.}

iterator textInput*(ui: Ui): Rune =
  ## Iterates over text input in the current frame.

  for r in ui.textInputBuffer:
    yield r

proc flushTextInput*(ui: Ui) =
  ## Flushes the text input buffer (resets it) so that any further calls to
  ## ``textInput`` will yield no characters.
  ui.textInputBuffer.setLen(0)


# general frameworking

proc processEvent*(ui: Ui, event: InputEvent) {.inline.} =
  ## Processes the given input event. This should be called from the callback
  ## passed to ``window.pollEvents``.

  ui.input.process(event)

proc begin*(ui: Ui, target: Target) =
  ## Begins constructing the UI. This creates a new root Box, with the size
  ## inherited from the given ``target``.
  ## This also resets the UI's graphics context's shape buffer.

  ui.graphics.resetShape()
  ui.stack.setLen(0)
  ui.stack.add Box(
    rect: rectf(vec2f(0, 0), target.size.vec2f),
  )

proc draw*(ui: Ui, target: Target) =
  ## Finishes the input tick, and draws the UI onto the given target.
  ## This also flushes text input.

  ui.input.finishTick()
  ui.flushTextInput()
  ui.graphics.draw(target)

## Extra math oriented around rectangles.

import aglet/rect
import glm/vec

export rect

type
  RectangleSide* = enum
    ## The side of a rectangle.
    rsRight
    rsBottom
    rsLeft
    rsTop

proc topLeft*[T](rect: Rect[T]): Vec2[T] {.inline.} =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position

proc topRight*[T](rect: Rect[T]): Vec2[T] {.inline.} =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position + vec2(rect.width, T 0)

proc bottomRight*[T](rect: Rect[T]): Vec2[T] {.inline.} =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position + rect.size

proc bottomLeft*[T](rect: Rect[T]): Vec2[T] {.inline.} =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position + vec2(T 0, rect.height)

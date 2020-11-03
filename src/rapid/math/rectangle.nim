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

{.push inline.}

proc topLeft*[T](rect: Rect[T]): Vec2[T] =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position

proc topRight*[T](rect: Rect[T]): Vec2[T] =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position + vec2(rect.width, T 0)

proc bottomRight*[T](rect: Rect[T]): Vec2[T] =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position + rect.size

proc bottomLeft*[T](rect: Rect[T]): Vec2[T] =
  ## Returns the position of the top-left corner of the rectangle.
  rect.position + vec2(T 0, rect.height)

proc rectSides*[T](left, top, right, bottom: T): Rect[T] =
  ## Helper for creating a rect with the given sides.
  rect[T](left, top, right - left, bottom - top)

proc intersects*[T](a, b: Rect[T]): bool =
  ## Returns whether the two rectangles intersect.
  a.left < b.right and b.left < a.right and
  a.top < b.bottom and b.top < a.bottom

{.pop.}

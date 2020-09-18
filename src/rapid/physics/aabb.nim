## Simple AABB-based collision detection and response.

import std/sugar

import aglet/rect

export rect

type
  XCheckDirection* = enum
    cdLeft, cdRight
  YCheckDirection* = enum
    cdUp, cdDown

func orderLowToHigh*[T](slice: var Slice[T]) {.inline.} =
  ## Orders a slice so that `a` is its lower bound and `b` is its higher bound.
  if slice.b > slice.a:
    swap slice.a, slice.b

func intersects*[T](x, y: Slice[T]): bool {.inline.} =
  ## Returns whether two 1D slices intersect.

  let (x, y) = (dup(x, orderLowToHigh), dup(y, orderLowToHigh))
  result = x.a < y.b and y.a < x.b

func xIntersects*[T](a, b: Rect[T]): bool {.inline.} =
  ## Returns whether two rectangles intersect on the X axis.
  (a.left..a.right).intersects(b.left..b.right)

func yIntersects*[T](a, b: Rect[T]): bool {.inline.} =
  ## Returns whether two rectangles intersect on the Y axis.
  (a.top..a.bottom).intersects(b.top..b.bottom)

func intersects*[T](a, b: Rect[T]): bool {.inline.} =
  ## Returns whether two rectangles intersect on both X and Y axes.
  a.xIntersects(b) and a.yIntersects(b)

proc resolveCollisionX*[T](subject: var Rect[T], collider: Rect[T],
                           direction: XCheckDirection): bool =
  ## Resolves collision on the X axis for the given moving subject and collider.
  ## ``direction`` signifies the movement direction of the subject.
  ## This doesn't need to be called if the subject is not moving.

  if not subject.yIntersects(collider): return false

  case direction
  of cdLeft:
    if subject.left < collider.right:
      result = true
      subject.position.x = collider.right
  of cdRight:
    if subject.right > collider.left:
      result = true
      subject.position.x = collider.x - subject.width

proc resolveCollisionY*[T](subject: var Rect[T], collider: Rect[T],
                           direction: YCheckDirection): bool =
  ## Resolves collision on the Y axis for the given moving subject and collider.

  if not subject.xIntersects(collider): return false

  case direction
  of cdUp:
    if subject.top < collider.bottom:
      result = true
      subject.position.y = collider.bottom
  of cdDown:
    if subject.bottom > collider.top:
      result = true
      subject.position.y = collider.y - subject.height

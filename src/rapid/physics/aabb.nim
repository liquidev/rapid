## Simple AABB-based collision detection and response.

import aglet/rect
import glm/vec

export rect

type
  XCheckDirection* = enum
    cdLeft, cdRight
  YCheckDirection* = enum
    cdUp, cdDown

{.push inline.}

func xIntersects*[T](a, b: Rect[T]): bool =
  ## Returns whether two rectangles intersect on the X axis.
  a.left < b.right and b.left < a.right

func yIntersects*[T](a, b: Rect[T]): bool =
  ## Returns whether two rectangles intersect on the Y axis.
  a.top < b.bottom and b.top < a.bottom

func intersects*[T](a, b: Rect[T]): bool =
  ## Returns whether two rectangles intersect on both X and Y axes.
  a.xIntersects(b) and a.yIntersects(b)

func rectSides*[T](left, top, right, bottom: T): Rect[T] =
  ## Constructs a rectangle from its sides.
  rect(left, top, right - left, bottom - top)

{.pop.}

proc resolveCollisionX*[T](subject: var Rect[T], collider: Rect[T],
                           direction: XCheckDirection, speed: float32): bool =
  ## Resolves collision on the X axis for the given moving subject and collider.
  ## ``direction`` signifies the movement direction of the subject.
  ## This doesn't need to be called if the subject is not moving.

  case direction
  of cdLeft:
    let wall = rectSides(
      collider.right - speed, collider.top + 1,
      collider.right, collider.bottom - 1,
    )
    result = subject.intersects(wall)
    subject.position.x = collider.right
  of cdRight:
    let wall = rectSides(
      collider.left, collider.top + 1,
      collider.left + speed, collider.bottom - 1,
    )
    result = subject.intersects(wall)
    subject.position.x = collider.left - subject.width

proc resolveCollisionY*[T](subject: var Rect[T], collider: Rect[T],
                           direction: YCheckDirection, speed: float32): bool =
  ## Resolves collision on the Y axis for the given moving subject and collider.

  case direction
  of cdUp:
    let wall = rectSides(
      collider.left + 1, collider.bottom - speed,
      collider.right - 1, collider.bottom,
    )
    result = subject.intersects(wall)
    subject.position.y = collider.bottom
  of cdDown:
    let wall = rectSides(
      collider.left + 1, collider.top,
      collider.right - 1, collider.top + speed,
    )
    result = subject.intersects(wall)
    subject.position.y = collider.top - subject.height

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## A minimal axis aligned bounding box implementation for collision detection.

import glm/vec

type
  RAABounds* = object
    x*, y*, width*, height*: float

proc newRAABB*(x, y, w, h: float): RAABounds =
  ## Create a new axis aligned bounding box.
  result = RAABounds(
    x: x, y: y, width: w, height: h
  )

proc left*(aabb: RAABounds): float =
  ## Calculate the left side of the box.
  aabb.x
proc right*(aabb: RAABounds): float =
  ## Calculate the right side of the box.
  aabb.x + aabb.width
proc top*(aabb: RAABounds): float =
  ## Calculate the top of the box.
  aabb.y
proc bottom*(aabb: RAABounds): float =
  ## Calculate the bottom of the box.
  aabb.y + aabb.height

proc intersects*(a, b: RAABounds): bool =
  ## Check whether two boxes intersect.
  result =
    a.left < b.right and b.left < a.right and
    a.top < b.bottom and b.top < a.bottom

proc intersectsWhole*(a, b: RAABounds): bool =
  ## Check whether one box is fully inside another box.
  result =
    a.left >= b.left and a.right < b.right and
    a.top >= b.top and a.bottom < b.bottom

proc has*(b: RAABounds, p: Vec2[float]): bool =
  ## Check whether the box contains the point ``p`` inside of it.
  result =
    p.x >= b.x and p.y >= b.y and p.x < b.x + b.width and p.y < b.y + b.height

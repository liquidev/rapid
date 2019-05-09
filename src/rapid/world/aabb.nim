#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## A minimal axis aligned bounding box implementation for collision detection.

import glm

type
  RAABounds* = object
    x*, y*, width*, height*: float

proc newRAABB*(x, y, w, h: float): RAABounds =
  result = RAABounds(
    x: x, y: y, width: w, height: h
  )

proc left*(aabb: RAABounds): float = aabb.x
proc right*(aabb: RAABounds): float = aabb.x + aabb.width
proc top*(aabb: RAABounds): float = aabb.y
proc bottom*(aabb: RAABounds): float = aabb.y + aabb.height

proc intersects*(a, b: RAABounds): bool =
  result =
    a.left < b.right and b.left < a.right and
    a.top < b.bottom and b.top < a.bottom

proc intersectsWhole*(a, b: RAABounds): bool =
  result =
    a.left >= b.left and a.right < b.right and
    a.top >= b.top and a.bottom < b.bottom

proc has*(b: RAABounds, p: Vec2f): bool =
  result =
    p.x >= b.x and p.y >= b.y and p.x < b.x + b.width and p.y < b.y + b.height

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

## A minimal axis aligned bounding box implementation for collision detection.

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
    a.x < b.x + b.width and b.x < a.x + a.width and
    a.y < b.y + b.height and b.y < a.y + a.height

## Extra vector math.

import glm/vec

func perpClockwise*[T](v: Vec2[T]): Vec2[T] =
  ## Returns a vector clockwise perpendicular to ``v``.
  vec2(v.y, -v.x)

func perpCounterClockwise*[T](v: Vec2[T]): Vec2[T] =
  ## Returns a vector counter-clockwise perpendicular to ``v``.
  vec2(-v.y, v.x)

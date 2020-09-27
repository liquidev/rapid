## Extra vector math.

import std/hashes
import std/math

import glm/vec

import units
import util

func perpClockwise*[T](v: Vec2[T]): Vec2[T] {.inline.} =
  ## Returns a vector clockwise perpendicular to ``v``.
  vec2(v.y, -v.x)

func perpCounterClockwise*[T](v: Vec2[T]): Vec2[T] {.inline.} =
  ## Returns a vector counter-clockwise perpendicular to ``v``.
  vec2(-v.y, v.x)

func angle*[T: SomeFloat](v: Vec2[T]): Radians {.inline.} =
  ## Returns the angle of the vector from (0, 0) to (v.x, v.y).
  arctan2(v.y, v.x).radians

func toVector*(angle: Radians): Vec2f {.inline.} =
  ## Converts an angle to a vector.
  vec2f(cos(angle), sin(angle))

type
  IntersectResult* = enum
    irParallel     ## the lines are parallel
    irCoincide     ## the lines concide
    irInsideBoth   ## the intersection lies inside both segments
    irOutside0     ## the intersection lies outside segment 0
    irOutside1     ## the intersection lies outside segment 1
    irOutsideBoth  ## the intersection lies outside both segments

func lineIntersect*(a0, b0, a1, b1: Vec2f): (IntersectResult, Vec2f) =
  ## Calculates the intersection point of two lines.

  # actually I have no idea how this algorithm works
  # literally translated it from C from that polyline tesselation article
  # (see graphics/context_polyline.nim for link)

  const Epsilon = 0.0000001

  let
    den = (b1.y - a1.y) * (b0.x - a0.x) - (b1.x - a1.x) * (b0.y - a0.y)
    numA = (b1.x - a1.x) * (a0.y - a1.y) - (b1.y - a1.y) * (a0.x - a1.x)
    numB = (b0.x - a0.x) * (a0.y - a1.y) - (b0.y - a0.y) * (a0.x - a1.x)

  if numA.closeTo(Epsilon) and numB.closeTo(Epsilon) and den.closeTo(Epsilon):
    return (irCoincide, (a0 + b0) * 0.5)

  if den.closeTo(Epsilon):
    return (irParallel, vec2f(0))

  let
    muA = numA / den
    muB = numB / den
  result[1] = a0 + muA * (b0 - a0)

  let
    out1 = muA notin 0.0..1.0
    out2 = muB notin 0.0..1.0

  result[0] =
    if out1 and out2: irOutsideBoth
    elif out1: irOutside0
    elif out2: irOutside1
    else: irInsideBoth

func angleBetweenLines*(a0, b0, a1, b1: Vec2f): Radians {.inline.} =
  ## Returns the angle between the lines (a0, b0) and (a1, b1).
  let
    da = a1 - a0
    db = b1 - b0
  result = arctan2(da.x * db.y - da.y * db.x, dot(da, db)).radians

func bisector*[T](anchor, a, b: Vec2[T]): Vec2[T] {.inline.} =
  ## Calculates the bisector of the angle in the corner ``a, anchor, b``, and
  ## returns it as a vector.
  let
    normA = normalize(a - anchor)
    normB = normalize(b - anchor)
    bisectorVector = normA + normB
  if bisectorVector == vec2(T 0):
    # avoid division by zero
    normB.perpCounterClockwise
  else:
    normalize(bisectorVector)

func hash*[N, T](vec: Vec[N, T]): Hash =
  ## Returns the hash of the vector.
  var h: Hash
  for x in vec.arr:
    h = h !& hash(x)
  !$h

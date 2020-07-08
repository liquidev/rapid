## Polyline renderer. This has lots of moving parts so separating it into a
## different module lets it live outside of the core graphics context functions.

# implemented based on:
# https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation

# also `nim check` is gonna throw millions of errors at me as I'm writing this.
# blame ALE

proc polyline*(graphics: Graphics, points: openArray[Vec2f],
               thickness: float32 = 1.0, cap = lcButt, join: LineJoin = ljMiter,
               color = rgba32f(1, 1, 1, 1), miterLimit = 45.degrees.toRadians) =
  ## Draws a polyline spanning the given set of points. This is the "expensive"
  ## line triangulator that produces nice results at the cost of performance.
  ## Use sparingly for drawing graphs, complex outlines, etc.
  ## Because the miter line join can cause the line to go infinitely high up
  ## with small angles, there's also a *miter limit*. If the angle between two
  ## lines is less than the miter limit, the join is switched to a bevel joint.

  if points.len == 1:
    case cap
    of lcButt, lcSquare:
      graphics.point(points[0], thickness / 2, color)
    of lcRound:
      graphics.circle(points[0], thickness / 2, color,
                      points = max(8, thickness * Pi * 0.25).PolygonPoints)
    return
  elif points.len == 2:
    graphics.line(points[0], points[1], thickness, cap, color, color)
    return

  func signedArea(p1, p2, p3: Vec2f): float64 =
    (p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)

  proc anchor(graphics: Graphics, a, b, c: Vec2f,
              thickness: float32, join: LineJoin, color: Rgba32f,
              miterLimit: Radians) {.nimcall.} =
    ## Draws a single "anchor", (two lines with one bend).
    var t: array[2, Vec2f]
    t[0] = perpCounterClockwise(b - a)
    t[1] = perpCounterClockwise(c - b)
    if signedArea(a, b, c) > 0:
      t[0] = -t[0]
      t[1] = -t[1]
    t[0] = t[0].normalize
    t[1] = t[1].normalize
    t[0] *= thickness
    t[1] *= thickness

    let
      a0 = graphics.addVertex(a + t[0], color)
      a1 = graphics.addVertex(a - t[0], color)
      c0 = graphics.addVertex(c + t[1], color)
      c1 = graphics.addVertex(c - t[1], color)
      aT = graphics.addVertex(b + t[0], color)
      bT = graphics.addVertex(b + t[1], color)
      (_, vPpoint) = lineIntersect(a + t[0], b + t[0], c + t[1], b + t[1])
      vP = graphics.addVertex(vPpoint, color)
      nvP = graphics.addVertex(b - (vPpoint - b), color)

    let
      intersection = lineIntersect(c + t[1], c - t[1], b - t[0], a - t[0])
      degenerated = intersection[0] == irInsideBoth

    if not degenerated:
      graphics.addIndices([a0, a1, nvP, a0, nvP, aT])
      graphics.addIndices([c0, c1, nvP, c0, nvP, bT])
    else:
      let tp = graphics.addVertex(intersection[1], color)
      graphics.addIndices([a0, a1, bT, bT, aT, a0])
      graphics.addIndices([tp, bT, c0])

    case join
    of ljBevel, ljMiter:
      if not degenerated:
        graphics.addIndices([nvP, aT, bT])
        if join == ljMiter:
          graphics.addIndices([vP, aT, bT])
      else:
        graphics.addIndices([graphics.addVertex(b, color), aT, bT])
    of ljRound:
      discard  # TODO

  for index in 0..<points.len - 2:
    let
      a =
        if index == 0: points[index]
        else: (points[index] + points[index + 1]) / 2
      b = points[index + 1]
      c =
        if index == points.len - 3: points[index + 2]
        else: (points[index + 1] + points[index + 2]) / 2
    anchor(graphics, a, b, c, thickness, join, color, miterLimit)

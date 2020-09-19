## Polyline renderer. This has lots of moving parts so separating it into a
## different module lets it live outside of the core graphics context functions.

# implemented based on:
# https://www.codeproject.com/Articles/226569/Drawing-polylines-by-tessellation

# also `nim check` is gonna throw millions of errors at me as I'm writing this.
# blame ALE

proc polyline*(graphics: Graphics, points: openArray[Vec2f],
               thickness: float32 = 1.0, cap = lcButt, join: LineJoin = ljMiter,
               close = false, color = rgba32f(1, 1, 1, 1)) =
  ## Draws a polyline spanning the given set of points. This is the "expensive"
  ## line triangulator that produces nice results at the cost of performance.
  ## Use sparingly for drawing graphs, complex outlines, etc.
  ##
  ## This can also be used for drawing closed polygon outlines, using the
  ## ``close`` parameter.
  ##
  ## This algorithm is not perfect. It produces some overdraw when drawing round
  ## caps and round joints, so you should not use those with transparent colors.

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
              thickness: float32, join: LineJoin, color: Rgba32f) {.nimcall.} =
    ## Draws a single "anchor", (two lines with one bend).
    var t: array[2, Vec2f]
    t[0] = perpCounterClockwise(b - a)
    t[1] = perpCounterClockwise(c - b)
    if signedArea(a, b, c) > 0:
      t[0] = -t[0]
      t[1] = -t[1]
    t[0] = t[0].normalize
    t[1] = t[1].normalize
    t[0] *= thickness / 2
    t[1] *= thickness / 2

    let
      a0 = a + t[0]
      a1 = a - t[0]
      c0 = c + t[1]
      c1 = c - t[1]
      aT = b + t[0]
      bT = b + t[1]
      (_, vPv) = lineIntersect(a + t[0], b + t[0], c + t[1], b + t[1])
      nvP = b - (vPv - b)
      a0v = graphics.addVertex(a0, color)
      a1v = graphics.addVertex(a1, color)
      c0v = graphics.addVertex(c0, color)
      c1v = graphics.addVertex(c1, color)
      aTv = graphics.addVertex(aT, color)
      bTv = graphics.addVertex(bT, color)
      nvPv = graphics.addVertex(nvP, color)
      bv = graphics.addVertex(b, color)

    let
      intersection = lineIntersect(c + t[1], c - t[1], b - t[0], a - t[0])
      degenerated = intersection[0] == irInsideBoth

    if not degenerated:
      graphics.addIndices([a0v, a1v, nvPv, a0v, nvPv, aTv])
      graphics.addIndices([c0v, c1v, nvPv, c0v, nvPv, bTv])
    else:
      let tp = graphics.addVertex(intersection[1], color)
      graphics.addIndices([a0v, a1v, bTv, bTv, aTv, a0v])
      graphics.addIndices([tp, bTv, c0v])

    let
      jointBottomVertex =
        if degenerated: bv
        else: nvPv
    case join
    of ljBevel, ljMiter:
      if not degenerated:
        graphics.addIndices([jointBottomVertex, aTv, bTv])
        if join == ljMiter:
          let vPv = graphics.addVertex(vPv, color)
          graphics.addIndices([vPv, aTv, bTv])
    of ljRound:
      let
        startAngle = angle(aT - b)
        endAngle = angle(bT - b)
        pointCount =
          int(float32(endAngle - startAngle).abs * (thickness / 2))
      # ↓ this is a global for memory efficiency
      var rimIndices {.global, threadvar.}: seq[VertexIndex]
      rimIndices.setLen(0)
      rimIndices.add(aTv)
      for pointIndex in 0..<pointCount:
        let
          angle = float32(pointIndex / max(1, pointCount - 1))
            .mapRange(0, 1, startAngle.float32, endAngle.float32)
            .radians
          point = b + angle.toVector * (thickness / 2)
        rimIndices.add(graphics.addVertex(point, color))
      rimIndices.add(bTv)
      for index in 0..<rimIndices.len - 1:
        let
          rimIndex1 = rimIndices[index]
          rimIndex2 = rimIndices[index + 1]
        graphics.addIndices([jointBottomVertex, rimIndex1, rimIndex2])

  proc squareCap(point: var Vec2f, center: Vec2f, amount: float32) {.nimcall.} =
    ## Extends ``point`` ``amount`` pixels from ``center`` to create
    ## a square cap.
    let
      direction = point - center
      normDirection = direction.normalize
    point += normDirection * amount

  template getPoint(index: int): Vec2f =
    var i = index
    if i >= points.len:
      i -= points.len
    points[i]

  let lastIndex = points.len - 1 - ord(not close) * 2
  for index in 0..lastIndex:
    let
      b = getPoint(index + 1)
      a =
        if index == 0 and not close:
          var point = getPoint(index)
          if not close and cap == lcSquare:
            squareCap(point, b, thickness / 2)
          point
        else: (getPoint(index) + b) / 2
      c =
        if index == lastIndex and not close:
          var point = getPoint(index + 2)
          if cap == lcSquare:
            squareCap(point, b, thickness / 2)
          point
        else:
          (getPoint(index + 2) + b) / 2
    anchor(graphics, a, b, c, thickness, join, color)

  proc roundCap(graphics: Graphics, cap, next: Vec2f,
                radius: float32, color: Rgba32f) {.nimcall.} =
    ## Adds an arc at ``cap`` facing opposite of ``next`` with the given
    ## ``radius`` to create a round cap.
    let
      direction = cap - next
      angle = direction.angle
      angleCcw = angle - radians(Pi / 2)
    graphics.arc(cap, radius, angleCcw, angleCcw + Pi.radians, color,
                 points = PolygonPoints(max(6, 2 * Pi * radius * 0.25)))

  if cap == lcRound:
    roundCap(graphics, points[0], points[1], thickness / 2, color)
    roundCap(graphics, points[^1], points[^2], thickness / 2, color)

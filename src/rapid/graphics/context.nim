## This module implements a simple hardware-accelerated 2D vector graphics
## renderer. It should primarily be used for UIs and rapid prototyping.
## Full-blown games should use aglet Meshes for things that don't change their
## geometry.

import std/colors
import std/options

import aglet

import ../math as rmath
import ../wrappers/freetype
import atlas_texture
import color

export color
export rmath

type
  RawVertexIndex = uint16
  VertexIndex* = distinct RawVertexIndex
    ## Index of a vertex, returned by ``addVertex``.

  Vertex2D* = object
    ## Vertex data, as represented in graphics memory and shaders.
    position: Vec2f
    color: Vec4f
    uv: Vec2f

  Sprite* = object
    ## A mostly opaque sprite handle.
    id: uint32
    fSize: Vec2i

  Batch* = object
    ## Info for a *batch*. Batches are a low-level component of the graphics
    ## context. They allow for multiple draw calls to be executed in a single
    ## call to the ``draw`` procedure, to allow for features like switching the
    ## texture mid-draw.
    range: Slice[int]
    sampler: Option[Sampler]

  Graphics* = ref object
    ## Hardware accelerated 2D vector graphics renderer.
    window: Window

    mesh: Mesh[Vertex2D]
    vertexBuffer: seq[Vertex2D]
    indexBuffer: seq[RawVertexIndex]
    batches: seq[Batch]

    fDefaultProgram: Program[Vertex2D]
    fDefaultDrawParams: DrawParams

    transformEnabled: bool
    fTransformMatrix: Mat3f

    spriteAtlas: AtlasTexture[Rgba8]
    spriteRects: seq[Rectf]
    fSpriteMinFilter: TextureMinFilter
    fSpriteMagFilter: TextureMagFilter

    freetype: FtLibrary


# Blending modes

const
  blendAlpha* = blendMode(blendAdd(bfSrcAlpha, bfOneMinusSrcAlpha),
                          blendAdd(bfOne, bfOneMinusSrcAlpha))
  blendAlphaPremult* = blendMode(blendAdd(bfOne, bfOneMinusSrcAlpha),
                                 blendAdd(bfOne, bfOneMinusSrcAlpha))
  blendAdditive* = blendMode(blendAdd(bfOne, bfOne),
                             blendAdd(bfOne, bfOne))


# Vertex

proc position*(vertex: Vertex2D): Vec2f {.inline.} =
  ## Returns the vertex's position.
  vertex.position

proc color*(vertex: Vertex2D): Rgba32f {.inline.} =
  ## Returns the vertex's tint color.
  vertex.color.Rgba32f

proc vertex*(position: Vec2f,
             color = rgba(1, 1, 1, 1),
             uv = vec2f(0, 0)): Vertex2D {.inline.} =
  ## Constructs a 2D vertex.
  Vertex2D(position: position, color: color.Vec4f, uv: uv)


proc position*(index: VertexIndex, graphics: Graphics): Vec2f {.inline.} =
  ## Returns the position of the vertex at the given index.
  ## For debugging purposes only.
  graphics.vertexBuffer[index.int].position

proc color*(index: VertexIndex, graphics: Graphics): Rgba32f {.inline.} =
  ## Returns the color of the vertex at the given index.
  ## For debugging purposes only.
  graphics.vertexBuffer[index.int].color.Rgba32f

proc uv*(index: VertexIndex, graphics: Graphics): Vec2f {.inline.} =
  ## Returns the texture coordinates of the vertex at the given index.
  ## For debugging purposes only.
  graphics.vertexBuffer[index.int].uv


proc `$`*(index: VertexIndex): string {.inline.} =
  ## Stringifies a vertex index for debugging purposes.
  "VertexIndex(" & $index.RawVertexIndex & ")"


# Graphics

proc defaultProgram*(graphics: Graphics): Program[Vertex2D] {.inline.} =
  ## Returns the default program used for drawing using using the
  ## graphics context.
  graphics.fDefaultProgram

proc `defaultProgram=`*(graphics: Graphics,
                        newProgram: Program[Vertex2D]) {.inline.} =
  ## Sets the default program used for drawing using the graphics context.
  ##
  ## Using this to adjust the program on the fly is bad practice. This should
  ## only be used once to adjust the default program to your use case, and
  ## alternate programs should be specified directly in ``draw`` calls.
  graphics.fDefaultProgram = newProgram

proc defaultDrawParams*(graphics: Graphics): DrawParams {.inline.} =
  ## Returns the default draw parameters for drawing using the
  ## graphics context.
  graphics.fDefaultDrawParams

proc `defaultDrawParams=`*(graphics: Graphics,
                           newParams: DrawParams) {.inline.} =
  ## Sets the default draw parameters used for drawing using the graphics
  ## context.
  ##
  ## Using this to adjust the draw parameters on the fly is bad practice. This
  ## should only be used once to adjust the default draw parameters to your use
  ## case, and alternate sets of draw parameters should be specified directly in
  ## ``draw`` calls.
  graphics.fDefaultDrawParams = newParams

proc transformMatrix*(graphics: Graphics): Mat3f {.inline.} =
  ## Returns the transform matrix for vertices.
  graphics.fTransformMatrix

proc `transformMatrix=`*(graphics: Graphics, newMatrix: Mat3f) {.inline.} =
  ## Returns the transform matrix for vertices.
  graphics.transformEnabled = true
  graphics.fTransformMatrix = newMatrix

proc translate*(graphics: Graphics, translation: Vec2f) {.inline.} =
  ## Translates the transform matrix by the given vector.

  graphics.transformEnabled = true
  # it's strange that nim-glm uses rows as columns in these constructors but ok
  graphics.fTransformMatrix *= mat3f(
    vec3f(1.0, 0.0, 0.0),
    vec3f(0.0, 1.0, 0.0),
    vec3f(translation.x, translation.y, 1.0),
  )

proc translate*(graphics: Graphics, x, y: float32) {.inline.} =
  ## Shortcut for translating using separate X and Y coordinates.

  graphics.translate(vec2(x, y))

proc scale*(graphics: Graphics, scale: Vec2f) {.inline.} =
  ## Scales the transform matrix by the given factors.

  graphics.transformEnabled = true
  graphics.fTransformMatrix *= mat3f(
    vec3f(scale.x, 0.0, 0.0),
    vec3f(0.0, scale.y, 0.0),
    vec3f(0.0, 0.0, 1.0),
  )

proc scale*(graphics: Graphics, x, y: float32) {.inline.} =
  ## Shortcut for scaling using separate X and Y factors.

  graphics.scale(vec2(x, y))

proc scale*(graphics: Graphics, xy: float32) {.inline.} =
  ## Shortcut for scaling the X and Y axes uniformly using a single factor.

  graphics.scale(vec2(xy))

proc rotate*(graphics: Graphics, angle: Radians) {.inline.} =
  ## Rotates the transform matrix by ``angle`` radians.

  graphics.transformEnabled = true
  graphics.fTransformMatrix *= mat3f(
    vec3f(cos(angle), sin(angle), 0.0),
    vec3f(-sin(angle), cos(angle), 0.0),
    vec3f(0.0, 0.0, 1.0),
  )

proc resetTransform*(graphics: Graphics) {.inline.} =
  ## Resets the transform matrix.

  graphics.transformEnabled = false
  graphics.fTransformMatrix = mat3f()

template transform*(graphics: Graphics, body: untyped) =
  ## Saves the current transform matrix, executes the body, and restores the
  ## transform matrix to the previously saved state.

  block:  # separate the scope to not surprise users
    let
      enabled = graphics.transformEnabled
      matrix = graphics.fTransformMatrix

    body

    graphics.transformEnabled = enabled
    graphics.fTransformMatrix = matrix

proc addVertex*(graphics: Graphics, vertex: Vertex2D): VertexIndex =
  ## Adds a vertex to the graphics context's shape buffer.

  var vertex = vertex
  if graphics.transformEnabled:
    vertex.position = xy(graphics.fTransformMatrix * vec3f(vertex.position, 1))
  result = graphics.vertexBuffer.len.VertexIndex
  graphics.vertexBuffer.add(vertex)

proc addVertex*(graphics: Graphics, position: Vec2f,
                color: Rgba32f, uv: Vec2f): VertexIndex {.inline.} =
  ## Shorthand for initializing a vertex and adding it to the graphics context's
  ## shape buffer.

  graphics.addVertex(vertex(position, color, uv))

proc addVertex*(graphics: Graphics,
                position: Vec2f,
                color = rgba(1, 1, 1, 1)): VertexIndex {.inline.} =
  ## Shorthand for adding a vertex with UV coordinates positioned at the center
  ## of the white pixel on the graphics context's sprite atlas.

  graphics.addVertex(position, color,
                     vec2f(0.5, 0.5) / graphics.spriteAtlas.size.vec2f)

proc addIndex*(graphics: Graphics, index: VertexIndex) {.inline.} =
  ## Adds an index into the graphics context's shape buffer.

  graphics.indexBuffer.add(index.RawVertexIndex)

proc addIndices*(graphics: Graphics,
                 indices: openArray[VertexIndex]) {.inline.} =
  ## Adds multiple indices to the graphics context's shape buffer in one go.

  for index in indices:
    graphics.indexBuffer.add(index.RawVertexIndex)

proc resetShape*(graphics: Graphics) =
  ## Resets the graphics context's shape buffer.

  graphics.vertexBuffer.setLen(0)
  graphics.indexBuffer.setLen(0)
  graphics.batches.setLen(0)
  graphics.batches.add(Batch(range: 0..0))

proc triangle*(graphics: Graphics, a, b, c: Vec2f,
               color = rgba(1, 1, 1, 1)) =
  ## Adds a triangle to the graphics context's shape buffer,
  ## tinted with the given color.

  var
    e = graphics.addVertex(a, color)
    f = graphics.addVertex(b, color)
    g = graphics.addVertex(c, color)
  graphics.addIndices([e, f, g])

proc quad*(graphics: Graphics, a, b, c, d: Vec2f,
           color = rgba(1, 1, 1, 1)) =
  ## Adds a quad to the graphics context's shape buffer, tinted with the given
  ## color. The vertices must be wound clockwise.

  var
    e = graphics.addVertex(a, color)
    f = graphics.addVertex(b, color)
    g = graphics.addVertex(c, color)
    h = graphics.addVertex(d, color)
  graphics.addIndices([e, f, g, g, h, e])

proc rectangle*(graphics: Graphics, rect: Rectf,
                color = rgba(1, 1, 1, 1)) =
  ## Adds a rectangle to the graphics context's shape buffer, tinted with the
  ## given color.

  graphics.quad(rect.topLeft, rect.topRight,
                rect.bottomRight, rect.bottomLeft,
                color)

proc rectangle*(graphics: Graphics, position, size: Vec2f,
                color = rgba(1, 1, 1, 1)) {.inline.} =
  ## Shortcut for adding a rectangle to the graphics context's shape buffer
  ## using position and size vectors, tinted with the given color.

  graphics.rectangle(rectf(position, size), color)

proc rectangle*(graphics: Graphics, x, y, width, height: float32,
                color = rgba(1, 1, 1, 1)) {.inline.} =
  ## Shortcut for adding a rectangle to the graphics context's shape buffer
  ## using separate X and Y coordinates, a width, and a height, tinted with
  ## the given color.

  graphics.rectangle(rectf(x, y, width, height), color)

proc point*(graphics: Graphics, center: Vec2f, size: float32 = 1.0,
            color = rgba(1, 1, 1, 1)) {.inline.} =
  ## Adds a point at the given position, with the given size and color.

  # this draws a square not only to mimic OpenGL behavior, but because drawing a
  # circle is much more costly without using a geometry shader.
  graphics.rectangle(center - vec2f(size) / 2, vec2f(size), color)

type
  PolygonPoints* = range[3..high(int)]
  ArcMode* = enum
    ## Arc rendering mode.
    amOpen
      ## last vertex goes directly to the first vertex in fill arcs only
    amChord
      ## last vertex goes directly to the first vertex in
      ## both fill and line arcs
    amPie
      ## last vertex goes to center, then to the first vertex

proc arc*(graphics: Graphics, center, radii: Vec2f,
          startAngle, endAngle: Radians, color = rgba(1, 1, 1, 1),
          points = 16.PolygonPoints, mode = amChord) =
  ## Adds an arc to the graphics context's shape buffer using vectors for its
  ## center and X/Y radii, with a starting angle ``startAngle`` and ending angle
  ## ``endAngle``, tinted with the given color. ``points`` controls the number
  ## of vertices along the arc's perimeter; arcs with a smaller surface area
  ## should use less points, as there are less pixels.

  # rimIndices is a global because we want to reuse the memory across calls
  var rimIndices {.global, threadvar.}: seq[VertexIndex]
  rimIndices.setLen(0)
  let pointCountOffset = ord(mode in {amOpen, amChord})
  for pointIndex in 0..<points:
    let
      angle = float32(pointIndex / (points - pointCountOffset))
        .mapRange(0, 1, startAngle.float32, endAngle.float32)
        .radians
      point = center + angle.toVector * radii
    rimIndices.add(graphics.addVertex(point, color))
  case mode
  of amOpen, amChord:
    let startIndex = rimIndices[0]
    for index in countdown(rimIndices.len - 1, 1):
      let
        rimIndex1 = rimIndices[index]
        rimIndex2 = rimIndices[index - 1]
      graphics.addIndices([startIndex, rimIndex1, rimIndex2])
  of amPie:
    let startIndex = graphics.addVertex(center, color)
    for index, rimIndex1 in rimIndices:
      let rimIndex2 =
        # ↓ this is about 2x faster than using mod
        if index + 1 == rimIndices.len:
          rimIndices[0]
        else:
          rimIndices[index + 1]
      graphics.addIndices([startIndex, rimIndex1, rimIndex2])

proc arc*(graphics: Graphics, center: Vec2f, radius: float32,
          startAngle, endAngle: Radians, color = rgba(1, 1, 1, 1),
          points = 16.PolygonPoints, mode = amChord) {.inline.} =
  ## Shortcut for adding an arc with the same radius for X and Y coordinates.

  graphics.arc(center, vec2f(radius), startAngle, endAngle, color, points, mode)

proc arc*(graphics: Graphics, centerX, centerY, radiusX, radiusY: float32,
          startAngle, endAngle: Radians, color = rgba(1, 1, 1, 1),
          points = 16.PolygonPoints, mode = amChord) {.inline.} =
  ## Shortcut for adding an arc using separate center X and Y coordinates and
  ## separate X and Y radii.

  graphics.arc(vec2f(centerX, centerY), vec2f(radiusX, radiusY),
               startAngle, endAngle, color, points, mode)

proc arc*(graphics: Graphics, centerX, centerY, radius: float32,
          startAngle, endAngle: Radians, color = rgba(1, 1, 1, 1),
          points = 16.PolygonPoints, mode = amChord) {.inline.} =
  ## Shortcut for adding an arc using separate center X and Y coordinates and
  ## a single radius used both for X and Y components.

  graphics.arc(vec2f(centerX, centerY), vec2f(radius), startAngle, endAngle,
               color, points, mode)

proc ellipse*(graphics: Graphics, center: Vec2f, radii: Vec2f,
              color = rgba(1, 1, 1, 1), points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for adding an arc from 0° to 360°, with the given center and X/Y
  ## radii, tinted with the given color, with the specified amount of points.

  graphics.arc(center, radii, startAngle = 0.degrees, endAngle = 360.degrees,
               color, points)

proc ellipse*(graphics: Graphics, centerX, centerY, radiusX, radiusY: float32,
              color = rgba(1, 1, 1, 1), points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for adding an ellipse to the graphics context's shape buffer
  ## using separate center X and Y coordinates, and separate X and Y radii,
  ## tinted with the given color.

  graphics.ellipse(vec2f(centerX, centerY), vec2f(radiusX, radiusY),
                   color, points)

proc circle*(graphics: Graphics, center: Vec2f, radius: float32,
             color = rgba(1, 1, 1, 1), points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for adding a circle using the ``ellipse`` procedure.

  graphics.ellipse(center, vec2f(radius), color, points)

proc circle*(graphics: Graphics, centerX, centerY, radius: float32,
             color = rgba(1, 1, 1, 1), points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for adding a circle using separate center X and Y coordinates.

  graphics.ellipse(vec2f(centerX, centerY), vec2f(radius), color, points)

type
  LineCap* = enum
    lcButt
    lcRound
    lcSquare
  LineJoin* = enum
    ljMiter
    ljBevel
    ljRound

proc line*(graphics: Graphics, a, b: Vec2f, thickness: float32 = 1.0,
           cap = lcButt, colorA, colorB = rgba(1, 1, 1, 1)) =
  ## Adds a line between ``a`` and ``b``, with the given thickness and colors.
  ## Keep in mind that this is a "quick'n'dirty" line triangulator, and it isn't
  ## suited very well for drawing polylines. For that, use ``polyline``.

  # implementation detail: this does not use GL's line rasterizer as it does not
  # guarantee that all line widths are supported. this makes drawing lines less
  # efficient, but at least developers can expect consistent behavior on all
  # graphics cards.

  if a == b: return  # prevent division by 0 if length == 0

  let
    direction = b - a
    normDirection = normalize(direction)
    baseOffset = normDirection * (thickness / 2)
    offsetCw = baseOffset.perpClockwise
    offsetCcw = baseOffset.perpCounterClockwise
    capOffset =
      case cap
      of lcButt, lcRound: vec2f(0)
      of lcSquare: baseOffset
    e = graphics.addVertex(a + offsetCw - capOffset, colorA)
    f = graphics.addVertex(a + offsetCcw - capOffset, colorA)
    g = graphics.addVertex(b + offsetCcw + capOffset, colorB)
    h = graphics.addVertex(b + offsetCw + capOffset, colorB)
  graphics.addIndices([e, f, g, g, h, e])

  if cap == lcRound:
    let
      angle = direction.angle
      angleCw = angle + radians(Pi / 2)
      angleCcw = angle - radians(Pi / 2)
    graphics.arc(a, thickness / 2, angleCw, angleCw + Pi.radians, colorA,
                 points = PolygonPoints(max(6, 2 * Pi * thickness * 0.25)))
    graphics.arc(b, thickness / 2, angleCcw, angleCcw + Pi.radians, colorB,
                 points = PolygonPoints(max(6, 2 * Pi * thickness * 0.25)))

include context_polyline

proc lineTriangle*(graphics: Graphics, a, b, c: Vec2f,
                   thickness: float32 = 1.0, color = rgba(1, 1, 1, 1))
                  {.inline.} =
  ## Adds a triangle outline, with the given points and stroke thickness,
  ## tinted with the given color.

  graphics.polyline([a, b, c], thickness, close = true, color = color)

proc lineQuad*(graphics: Graphics, a, b, c, d: Vec2f,
               thickness: float32 = 1.0, color = rgba(1, 1, 1, 1)) {.inline.} =
  ## Adds a quad outline, with the given points and stroke thickness,
  ## tinted with the given color.

  graphics.polyline([a, b, c, d], thickness, close = true, color = color)

proc lineRectangle*(graphics: Graphics, rect: Rectf,
                    thickness: float32 = 1.0, color = rgba(1, 1, 1, 1)) =
  ## Adds a rectangle outline, with the given thickness and color.
  ## Note that this is faster than drawing an equivalent quad, as the joints in
  ## a rectangle are at 90° angles, which makes vertices simple to calculate.

  let
    offsetLR = vec2f(thickness / 2)
    offsetRL = vec2f(-offsetLR.x, offsetLR.y)
    eInside = graphics.addVertex(rect.topLeft + offsetLR, color)
    fInside = graphics.addVertex(rect.topRight + offsetRL, color)
    gInside = graphics.addVertex(rect.bottomRight - offsetLR, color)
    hInside = graphics.addVertex(rect.bottomLeft - offsetRL, color)
    eOutside = graphics.addVertex(rect.topLeft - offsetLR, color)
    fOutside = graphics.addVertex(rect.topRight - offsetRL, color)
    gOutside = graphics.addVertex(rect.bottomRight + offsetLR, color)
    hOutside = graphics.addVertex(rect.bottomLeft + offsetRL, color)
  graphics.addIndices([
    # quad ef
    eInside, fInside, fOutside, fOutside, eOutside, eInside,
    # quad fg
    fInside, gInside, gOutside, gOutside, fOutside, fInside,
    # quad gh
    gInside, hInside, hOutside, hOutside, gOutside, gInside,
    # quad he
    hInside, eInside, eOutside, eOutside, hOutside, hInside,
  ])

proc lineRectangle*(graphics: Graphics, position, size: Vec2f,
                    thickness: float32 = 1.0, color = rgba(1, 1, 1, 1))
                   {.inline.} =
  ## Shortcut for drawing a line rectangle using separate position and size
  ## vectors.

  graphics.lineRectangle(rectf(position, size), thickness, color)

proc lineRectangle*(graphics: Graphics, x, y, width, height: float32,
                    thickness: float32 = 1.0, color = rgba(1, 1, 1, 1))
                   {.inline.} =
  ## Shortcut for drawing a line rectangle using separate X/Y coordinates for
  ## position and size.

  graphics.lineRectangle(rectf(x, y, width, height), thickness, color)

proc lineArc*(graphics: Graphics, center, radii: Vec2f,
              startAngle, endAngle: Radians,
              thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
              points = 16.PolygonPoints, mode = amOpen, cap = lcButt) =
  ## Adds an arc outline using vectors for its center and X/Y radii, with a
  ## starting angle ``startAngle`` and ending angle ``endAngle``, tinted with
  ## the given color. ``points`` controls the number of vertices along the arc's
  ## perimeter; arcs with a smaller radius should use less points, as there are
  ## less pixels.

  # ↓ this is a global to reuse memory across calls
  var rimPositions {.global, threadvar.}: seq[Vec2f]
  rimPositions.setLen(0)
  for pointIndex in 0..<points:
    let
      angle = float32(pointIndex / (points - 1))
        .mapRange(0, 1, startAngle.float32, endAngle.float32)
        .radians
      point = center + angle.toVector * radii
    rimPositions.add(point)
  if mode == amPie:
    rimPositions.add(center)
  graphics.polyline(rimPositions, thickness, cap, join = ljMiter,
                    close = mode in {amChord, amPie},
                    color)

proc lineArc*(graphics: Graphics, center: Vec2f, radius: float32,
              startAngle, endAngle: Radians,
              thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
              points = 16.PolygonPoints, mode = amOpen, cap = lcButt)
             {.inline.} =
  ## Shortcut for adding an arc outline with the same radius for X and Y
  ## coordinates.

  graphics.lineArc(center, vec2f(radius), startAngle, endAngle, thickness,
                   color, points, mode, cap)

proc lineArc*(graphics: Graphics, centerX, centerY, radiusX, radiusY: float32,
              startAngle, endAngle: Radians,
              thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
              points = 16.PolygonPoints, mode = amOpen, cap = lcButt)
             {.inline.} =
  ## Shortcut for adding an arc outline using separate center X and Y
  ## coordinates and separate X and Y radii.

  graphics.lineArc(vec2f(centerX, centerY), vec2f(radiusX, radiusY),
                   startAngle, endAngle, thickness, color, points, mode, cap)

proc lineArc*(graphics: Graphics, centerX, centerY, radius: float32,
              startAngle, endAngle: Radians,
              thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
              points = 16.PolygonPoints, mode = amOpen, cap = lcButt)
             {.inline.} =
  ## Shortcut for adding an arc outline using separate center X and Y
  ## coordinates and a single radius used both for X and Y components.

  graphics.lineArc(vec2f(centerX, centerY), vec2f(radius),
                   startAngle, endAngle, thickness, color, points, mode, cap)

proc lineEllipse*(graphics: Graphics, center: Vec2f, radii: Vec2f,
                  thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
                  points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for drawing an arc outline from 0° to 360°.

  graphics.lineArc(center, radii,
                   startAngle = 0.degrees, endAngle = 360.degrees,
                   thickness, color, points)

proc lineEllipse*(graphics: Graphics,
                  centerX, centerY, radiusX, radiusY: float32,
                  thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
                  points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for drawing an ellipse outline with separate X and Y coordinates
  ## for the position and the radius.

  graphics.lineEllipse(vec2f(centerX, centerY), vec2f(radiusX, radiusY),
                       thickness, color, points)

proc lineCircle*(graphics: Graphics, center: Vec2f, radius: float32,
                 thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
                 points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for adding a circle outline using the ``lineEllipse`` procedure.

  graphics.lineEllipse(center, vec2f(radius), thickness, color, points)

proc lineCircle*(graphics: Graphics, centerX, centerY, radius: float32,
                 thickness: float32 = 1.0, color = rgba(1, 1, 1, 1),
                 points = 32.PolygonPoints) {.inline.} =
  ## Shortcut for adding a circle outline using separate center X and Y
  ## coordinates.

  graphics.lineCircle(vec2f(centerX, centerY), radius, thickness, color, points)

proc spriteMinFilter*(graphics: Graphics): TextureMinFilter {.inline.} =
  ## Returns the current sprite minification filter.
  graphics.fSpriteMinFilter

proc `spriteMinFilter=`*(graphics: Graphics, newFilter: TextureMinFilter)
                        {.inline.} =
  ## Sets the current sprite minification filter.
  ## Texture filtering modes apply to the ``draw`` calls succeeding them. This
  ## means that you cannot use multiple filtering modes in a single draw call.
  graphics.fSpriteMinFilter = newFilter

proc spriteMagFilter*(graphics: Graphics): TextureMagFilter {.inline.} =
  ## Returns the current sprite magnification filter.
  graphics.fSpriteMagFilter

proc `spriteMagFilter=`*(graphics: Graphics, newFilter: TextureMagFilter)
                        {.inline.} =
  ## Sets the current sprite magnification filter.
  ## Texture filtering modes apply to the ``draw`` calls succeeding them. This
  ## means that you cannot use multiple filtering modes in a single draw call.
  graphics.fSpriteMagFilter = newFilter

proc size*(sprite: Sprite): Vec2i {.inline.} =
  ## Returns the size of the sprite as a vector.
  sprite.fSize

proc width*(sprite: Sprite): int32 =
  ## Returns the width of the sprite.
  sprite.size.x

proc height*(sprite: Sprite): int32 =
  ## Returns the height of the sprite.
  sprite.size.x

proc addSprite*(graphics: Graphics, size: Vec2i, data: ptr Rgba8): Sprite =
  ## Adds a sprite to the graphics context's sprite atlas with the provided
  ## graphics data, and returns a handle to the newly created sprite.
  ## Raises an error if the sprite won't fit onto the sprite atlas.
  ##
  ## This procedure deals with pointers, and so, it is inherently **unsafe**.
  ## Prefer the ``openArray`` and ``BinaryImageBuffer`` versions.

  let rect = graphics.spriteAtlas.add(size, data)
  result = Sprite(id: graphics.spriteRects.len.uint32, fSize: size)
  graphics.spriteRects.add(rect)

proc addSprite*(graphics: Graphics,
                size: Vec2i, data: openArray[Rgba8]): Sprite =
  ## Adds a sprite to the graphics context's sprite atlas and returns a handle
  ## to it.

  graphics.addSprite(size, data[0].unsafeAddr)

proc addSprite*(graphics: Graphics, image: BinaryImageBuffer): Sprite =
  ## Adds a sprite to the graphics context's sprite atlas and returns a handle
  ## to it.

  graphics.addSprite(vec2i(image.width, image.height),
                     cast[ptr Rgba8](image.data[0].unsafeAddr))

proc sprite*(graphics: Graphics, sprite: Sprite, rect: Rectf,
             tint = rgba(1, 1, 1, 1)) =
  ## Draws a sprite at the given rectangle, tinted with the given color.

  let
    spriteRect = graphics.spriteRects[sprite.id]
    e = graphics.addVertex(rect.topLeft, tint, spriteRect.topLeft)
    f = graphics.addVertex(rect.topRight, tint, spriteRect.topRight)
    g = graphics.addVertex(rect.bottomRight, tint, spriteRect.bottomRight)
    h = graphics.addVertex(rect.bottomLeft, tint, spriteRect.bottomLeft)
  graphics.addIndices([e, f, g, g, h, e])

proc sprite*(graphics: Graphics, sprite: Sprite, position, size: Vec2f,
             tint = rgba(1, 1, 1, 1)) {.inline.} =
  ## Shortcut for drawing a sprite using separate position and size vectors.

  graphics.sprite(sprite, rectf(position, size), tint)

proc sprite*(graphics: Graphics, sprite: Sprite, x, y, width, height: float32,
             tint = rgba(1, 1, 1, 1)) {.inline.} =
  ## Shortcut for drawing a sprite using separate X and Y coordinates, and
  ## a separated width and height.

  graphics.sprite(sprite, rectf(x, y, width, height), tint)

proc sprite*(graphics: Graphics, sprite: Sprite, position: Vec2f,
             scale: float32 = 1, tint = rgba(1, 1, 1, 1)) {.inline.} =
  ## Shortcut for drawing a sprite using a vector for position. This proc
  ## ensures that the aspect ratio remains correct by using a single
  ## ``scale`` parameter.
  ## Note that using this parameter is much faster than using an equivalent
  ## transform matrix.

  graphics.sprite(sprite, rectf(position, sprite.size.vec2f * scale), tint)

proc sprite*(graphics: Graphics, sprite: Sprite, x, y: float32,
             scale: float32 = 1, tint = rgba(1, 1, 1, 1)) {.inline.} =
  ## Shortcut for drawing a scaled sprite using separate X and Y coordinates for
  ## position.

  graphics.sprite(sprite, vec2f(x, y), scale, tint)

proc currentBatch*(graphics: Graphics): Batch =
  ## Returns the currently running batch.
  graphics.batches[^1]

proc len(batch: Batch): int =
  ## Returns the amount of indices in the batch.
  batch.range.b - batch.range.a

proc finalizeBatch(graphics: Graphics) =
  ## Finalizes the batch by setting its last index to the index's buffer's last
  ## element.

  if graphics.indexBuffer.len <= 0: return
  graphics.batches[^1].range.b = graphics.indexBuffer.len - 1
  let range = graphics.currentBatch.range
  if range.b - range.a <= 0:
    graphics.batches.setLen(graphics.batches.len - 1)

proc batchNewSampler*(graphics: Graphics, newSampler: Sampler) =
  ## Temporarily change the sprite atlas sampler. Used for rendering text and
  ## other things that require the use of a separate texture.
  ##
  ## This is a low-level detail of how text rendering is implemented. Prefer
  ## higher-level APIs instead.

  graphics.finalizeBatch()
  if graphics.currentBatch.sampler.isSome and
     graphics.currentBatch.sampler.get == newSampler:
    return
  let eboLen = graphics.indexBuffer.len
  graphics.batches.add(Batch(range: eboLen..eboLen,
                             sampler: some(newSampler)))

proc batchNewCopy*(graphics: Graphics, batch: Batch) =
  ## Copies the given ``batch`` and appends it to the end of the batch buffer.

  let eboLen = graphics.indexBuffer.len
  var copy = batch
  copy.range = eboLen..eboLen
  graphics.finalizeBatch()
  graphics.batches.add(copy)

include context_text

const
  DefaultVertexShader* = glsl"""
    #version 330 core

    in vec2 position;
    in vec4 color;
    in vec2 uv;

    uniform mat4 projection;

    out Vertex {
      vec4 color;
      vec2 uv;
    } toFragment;

    void main(void) {
      gl_Position = projection * vec4(position, 0.0, 1.0);
      toFragment.color = color;
      toFragment.uv = uv;
    }
  """
  DefaultFragmentShader* = glsl"""
    #version 330 core

    in Vertex {
      vec4 color;
      vec2 uv;
    } vertex;

    uniform sampler2D spriteAtlas;

    out vec4 fbColor;

    void main(void) {
      fbColor = vertex.color * texture(spriteAtlas, vertex.uv);
    }
  """

type
  GraphicsUniforms* = tuple
    ## Extra uniforms passed into shader programs when ``draw`` is used.
    projection: Mat4f        ## the projection matrix
    `?targetSize`: Vec2f     ## the size of the target
    `?spriteAtlas`: Sampler  ## the sprite atlas texture

proc uniforms(graphics: Graphics, target: Target): GraphicsUniforms =
  ## Returns some extra uniforms related to the graphics context.
  result = GraphicsUniforms aglet.uniforms {
    projection: ortho(left = 0'f32, top = 0'f32,
                      right = target.width.float32,
                      bottom = target.height.float32,
                      zNear = -1.0, zFar = 1.0),
    ?targetSize: target.size.vec2f,
    ?spriteAtlas: graphics.spriteAtlas.sampler(
      minFilter = graphics.spriteMinFilter,
      magFilter = graphics.spriteMagFilter,
      wrapS = twClampToBorder,
      wrapT = twClampToBorder,
    )
  }

proc updateMesh(graphics: Graphics) =
  ## Updates the internal mesh with client-side shape data.
  graphics.mesh.uploadVertices(graphics.vertexBuffer)
  graphics.mesh.uploadIndices(graphics.indexBuffer)

proc useBatch(uniforms: var GraphicsUniforms, batch: Batch) =
  if batch.sampler.isSome:
    uniforms.`?spriteAtlas` = batch.sampler.get

proc applyBatchSettings[U: UniformSource](graphics: Graphics, batch: Batch,
                                          uniforms: var U) =
  ## Applies the batch's new settings to the uniform source.

  when U is GraphicsUniforms:
    useBatch(uniforms, batch)
  elif U is object | tuple:
    for name, field in fieldPairs(uniforms):
      when name.len >= 2 and name[0..1] == "..":
        when field is GraphicsUniforms:
          useBatch(field, batch)
        elif field is object | tuple:
          graphics.applyBatchSettings(batch, field)
  else:
    {.error: "unsupported uniform source. use aglet.uniforms {}".}

# this proc used to use default parameters but Nim/#11274 prevented me from
# doing so, so now there's a bajillion overloads to fulfill all the common
# use cases
proc draw*[U: UniformSource](graphics: Graphics, target: Target,
                             program: Program, uniforms: U,
                             drawParams: DrawParams) =
  ## Draws the graphics context's shape buffer onto the given target.
  ## Optionally, a program, uniforms, and draw parameters can be specified.
  ## By default, some extra uniforms are passed into the shader via
  ## ``graphics.uniforms(target)``.

  # don't try to draw anything if there are no vertices
  if graphics.vertexBuffer.len == 0: return

  graphics.finalizeBatch()
  graphics.updateMesh()
  let baseUniforms = graphics.uniforms(target)
  for batch in graphics.batches:
    var batchUniforms = aglet.uniforms {
      ..uniforms,
      ..baseUniforms,
    }
    graphics.applyBatchSettings(batch, batchUniforms)
    target.draw(program, graphics.mesh[batch.range], batchUniforms, drawParams)

proc draw*[U: UniformSource](graphics: Graphics, target: Target,
                             program: Program, uniforms: U) {.inline.} =
  ## Shortcut to ``draw`` that uses ``graphics.defaultDrawParams`` as
  ## the draw parameters.

  graphics.draw(target, program, uniforms, graphics.defaultDrawParams)

proc draw*(graphics: Graphics, target: Target,
           drawParams: DrawParams) {.inline.} =
  ## Shortcut to ``draw`` that uses ``graphics.defaultProgram`` for the program
  ## and ``graphics.uniforms(target)`` as the uniform source.

  graphics.draw(target, graphics.defaultProgram, NoUniforms,
                drawParams)

proc draw*(graphics: Graphics, target: Target) {.inline.} =
  ## Shortcut to ``draw`` that uses ``graphics.defaultProgram`` for the shader
  ## program, ``graphics.uniforms(target)`` as the uniform source, and
  ## ``graphics.defaultDrawParams`` as the draw parameters.

  graphics.draw(target, graphics.defaultProgram, NoUniforms,
                graphics.defaultDrawParams)

proc newGraphics*(window: Window, spriteAtlasSize = 1024.Positive): Graphics =
  ## Creates a new graphics context.
  new(result)

  result.window = window

  result.mesh =
    window.newMesh[:Vertex2D](usage = muDynamic, primitive = dpTriangles)
  result.resetShape()

  result.fDefaultProgram =
    window.newProgram[:Vertex2D](DefaultVertexShader, DefaultFragmentShader)
  result.fDefaultDrawParams = defaultDrawParams().derive:
    blend blendAlpha

  result.fTransformMatrix = mat3f()

  result.spriteAtlas =
    window.newAtlasTexture[:Rgba8](vec2i(spriteAtlasSize.int32))
  # we need a single white pixel for the default color
  block whitePixel:
    result.spriteAtlas.padding = 0
    discard result.spriteAtlas.add(vec2i(1), [rgba8(255, 255, 255, 255)])
    result.spriteAtlas.padding = 1
  result.fSpriteMinFilter = fmNearestMipmapLinear
  result.fSpriteMagFilter = fmLinear

  result.initFreetype()

## This module implements a simple hardware-accelerated 2D vector graphics
## renderer. It should primarily be used for UIs and rapid prototyping.
## Full-blown games should use aglet Meshes for things that don't change their
## geometry.

import std/colors

import aglet

import ../math/units
import ../math/vector

export colors except rgb  # use pixeltypes.rgba32f or pixeltypes.rgba instead

export units, vector

type
  RawVertexIndex = uint16
  VertexIndex* = distinct RawVertexIndex
    ## Index of a vertex, returned by ``addVertex``.

  Vertex2D* = object
    ## A vertex, as represented in graphics memory and shaders.
    position: Vec2f
    color: Vec4f

  Graphics* = ref object
    ## Hardware accelerated 2D vector graphics renderer.
    window: Window
    mesh: Mesh[Vertex2D]
    vertexBuffer: seq[Vertex2D]
    indexBuffer: seq[RawVertexIndex]

    fDefaultProgram: Program[Vertex2D]
    fDefaultDrawParams: DrawParams

    transformEnabled: bool
    fTransformMatrix: Mat3f



# Blending modes

const
  blendAlpha* = blendMode(blendAdd(bfSrcAlpha, bfOneMinusSrcAlpha),
                          blendAdd(bfSrcAlpha, bfOneMinusSrcAlpha))
  blendAlphaPremult* = blendMode(blendAdd(bfOne, bfOneMinusSrcAlpha),
                                 blendAdd(bfOne, bfOneMinusSrcAlpha))


# Vertex

proc position*(vertex: Vertex2D): Vec2f =
  ## Returns the vertex's position.
  vertex.position

proc color*(vertex: Vertex2D): Rgba32f =
  ## Returns the vertex's tint color.
  vertex.color.Rgba32f

proc vertex*(position: Vec2f, color = rgba32f(1, 1, 1, 1)): Vertex2D =
  ## Constructs a 2D vertex.
  Vertex2D(position: position, color: color.Vec4f)


# Graphics

proc defaultProgram*(graphics: Graphics): Program[Vertex2D] =
  ## Returns the default program used for drawing using using the
  ## graphics context.
  graphics.fDefaultProgram

proc `defaultProgram=`*(graphics: Graphics, newProgram: Program[Vertex2D]) =
  ## Sets the default program used for drawing using the graphics context.
  ##
  ## Using this to adjust the program on the fly is bad practice. This should
  ## only be used once to adjust the default program to your use case, and
  ## alternate programs should be specified directly in ``draw`` calls.
  graphics.fDefaultProgram = newProgram

proc defaultDrawParams*(graphics: Graphics): DrawParams =
  ## Returns the default draw parameters for drawing using the
  ## graphics context.
  graphics.fDefaultDrawParams

proc `defaultDrawParams=`*(graphics: Graphics, newParams: DrawParams) =
  ## Sets the default draw parameters used for drawing using the graphics
  ## context.
  ##
  ## Using this to adjust the draw parameters on the fly is bad practice. This
  ## should only be used once to adjust the default draw parameters to your use
  ## case, and alternate sets of draw parameters should be specified directly in
  ## ``draw`` calls.
  graphics.fDefaultDrawParams = newParams

proc transformMatrix*(graphics: Graphics): Mat3f =
  ## Returns the transform matrix for vertices.
  graphics.fTransformMatrix

proc `transformMatrix=`*(graphics: Graphics, newMatrix: Mat3f) =
  ## Returns the transform matrix for vertices.
  graphics.transformEnabled = true
  graphics.fTransformMatrix = newMatrix

proc translate*(graphics: Graphics, translation: Vec2f) =
  ## Translates the transform matrix by the given vector.

  graphics.transformEnabled = true
  # it's strange that nim-glm uses rows as columns in these constructors but ok
  graphics.fTransformMatrix *= mat3f(
    vec3f(1.0, 0.0, 0.0),
    vec3f(0.0, 1.0, 0.0),
    vec3f(translation.x, translation.y, 1.0),
  )

proc translate*(graphics: Graphics, x, y: float32) =
  ## Shortcut for translating using separate X and Y coordinates.

  graphics.translate(vec2(x, y))

proc scale*(graphics: Graphics, scale: Vec2f) =
  ## Scales the transform matrix by the given factors.

  graphics.transformEnabled = true
  graphics.fTransformMatrix *= mat3f(
    vec3f(scale.x, 0.0, 0.0),
    vec3f(0.0, scale.y, 0.0),
    vec3f(0.0, 0.0, 1.0),
  )

proc scale*(graphics: Graphics, x, y: float32) =
  ## Shortcut for scaling using separate X and Y factors.

  graphics.scale(vec2(x, y))

proc scale*(graphics: Graphics, xy: float32) =
  ## Shortcut for scaling the X and Y axes uniformly using a single factor.

  graphics.scale(vec2(xy))

proc rotate*(graphics: Graphics, angle: Radians) =
  ## Rotates the transform matrix by ``angle`` radians.

  graphics.transformEnabled = true
  graphics.fTransformMatrix = mat3f(
    vec3f(cos(angle), sin(angle), 0.0),
    vec3f(-sin(angle), cos(angle), 0.0),
    vec3f(0.0, 0.0, 1.0),
  )

proc resetTransform*(graphics: Graphics) =
  ## Resets the transform matrix.

  graphics.transformEnabled = false
  graphics.fTransformMatrix = mat3f()

template transform*(graphics: Graphics, body: untyped) =
  ## Saves the current transform matrix, executes the body, and restores the
  ## transform matrix to the previously saved state.

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

proc addVertex*(graphics: Graphics,
                position: Vec2f, color = rgba32f(1, 1, 1, 1)): VertexIndex =
  ## Shorthand for initializing a vertex and adding it to the graphics context's
  ## shape buffer.

  graphics.addVertex(vertex(position, color))

proc addIndex*(graphics: Graphics, index: VertexIndex) =
  ## Adds an index into the graphics context's shape buffer.

  graphics.indexBuffer.add(index.RawVertexIndex)

proc addIndices*(graphics: Graphics, indices: openArray[VertexIndex]) =
  ## Adds multiple indices to the graphics context's shape buffer in one go.

  for index in indices:
    graphics.indexBuffer.add(index.RawVertexIndex)

proc resetShape*(graphics: Graphics) =
  ## Resets the graphics context's shape buffer.

  graphics.vertexBuffer.setLen(0)
  graphics.indexBuffer.setLen(0)

proc triangle*(graphics: Graphics, a, b, c: Vec2f,
               color = rgba32f(1, 1, 1, 1)) =
  ## Adds a triangle to the graphics context's shape buffer,
  ## tinted with the given color.

  var
    e = graphics.addVertex(a, color)
    f = graphics.addVertex(b, color)
    g = graphics.addVertex(c, color)
  graphics.addIndices([e, f, g])

proc quad*(graphics: Graphics, a, b, c, d: Vec2f,
           color = rgba32f(1, 1, 1, 1)) =
  ## Adds a quad to the graphics context's shape buffer, tinted with the given
  ## color. The vertices must be wound clockwise.

  var
    e = graphics.addVertex(a, color)
    f = graphics.addVertex(b, color)
    g = graphics.addVertex(c, color)
    h = graphics.addVertex(d, color)
  graphics.addIndices([e, f, g, g, h, e])

proc rectangle*(graphics: Graphics, rect: Rectf,
                color = rgba32f(1, 1, 1, 1)) =
  ## Adds a rectangle to the graphics context's shape buffer, tinted with the
  ## given color.

  graphics.quad(
    rect.position,
    rect.position + vec2f(rect.width, 0),
    rect.position + rect.size,
    rect.position + vec2f(0, rect.height),
    color
  )

proc rectangle*(graphics: Graphics, position, size: Vec2f,
                color = rgba32f(1, 1, 1, 1)) =
  ## Shortcut for adding a rectangle to the graphics context's shape buffer
  ## using position and size vectors, tinted with the given color.

  graphics.rectangle(rectf(position, size), color)

proc rectangle*(graphics: Graphics, x, y, width, height: float32,
                color = rgba32f(1, 1, 1, 1)) =
  ## Shortcut for adding a rectangle to the graphics context's shape buffer
  ## using separate X and Y coordinates, a width, and a height, tinted with
  ## the given color.

  graphics.rectangle(rectf(x, y, width, height), color)

proc ellipse*(graphics: Graphics, center: Vec2f, radii: Vec2f,
              color = rgba32f(1, 1, 1, 1), points = 16.Natural) =
  ## Adds an ellipse to the graphics context's shape buffer using vectors for
  ## its center and X/Y radii, tinted with the given color. ``points`` controls
  ## the number of vertices along the ellipse's perimeter; smaller ellipses
  ## should use less points, as there are less pixels, while larger ellipses
  ## should use more points, to appear more smooth.

  let centerIndex = graphics.addVertex(center, color)
  var rimIndices: seq[VertexIndex]
  for pointIndex in 0..<points:
    let
      angle = radians(pointIndex / points * (2 * Pi))
      point = center + vec2f(cos(angle) * radii.x, sin(angle) * radii.y)
    rimIndices.add(graphics.addVertex(point, color))
  for index, rimIndex1 in rimIndices:
    let rimIndex2 =
      # ↓ this is about 2x faster than using mod
      if index + 1 == rimIndices.len:
        rimIndices[0]
      else:
        rimIndices[index + 1]
    graphics.addIndices([centerIndex, rimIndex1, rimIndex2])

proc ellipse*(graphics: Graphics, centerX, centerY, radiusX, radiusY: float32,
              color = rgba32f(1, 1, 1, 1), points = 16.Natural) =
  ## Shortcut for adding an ellipse to the graphics context's shape buffer
  ## using separate center X and Y coordinates, and separate X and Y radii,
  ## tinted with the given color.

  graphics.ellipse(vec2f(centerX, centerY), vec2f(radiusX, radiusY),
                   color, points)

proc circle*(graphics: Graphics, center: Vec2f, radius: float32,
             color = rgba32f(1, 1, 1, 1),
             points = Natural(2 * Pi * abs(radius) * 0.25)) =
  ## Shortcut for adding a circle using the ``ellipse`` procedure.

  graphics.ellipse(center, vec2f(radius), color, points)

proc circle*(graphics: Graphics, centerX, centerY: float32, radius: float32,
             color = rgba32f(1, 1, 1, 1),
             points = Natural(2 * Pi * abs(radius) * 0.25)) =
  ## Shortcut for adding a circle using separate center X and Y coordinates.

  graphics.ellipse(vec2f(centerX, centerY), vec2f(radius), color, points)

proc point*(graphics: Graphics, center: Vec2f, size: float32 = 1.0,
            color = rgba32f(1, 1, 1, 1)) =
  ## Adds a point at the given position, with the given size and color.

  graphics.rectangle(center - vec2f(size) / 2, vec2f(size), color)

proc line*(graphics: Graphics, a, b: Vec2f, thickness: float32 = 1.0,
           colorA, colorB = rgba32f(1, 1, 1, 1)) =
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
    e = graphics.addVertex(a + offsetCw, colorA)
    f = graphics.addVertex(a + offsetCcw, colorA)
    g = graphics.addVertex(b + offsetCcw, colorB)
    h = graphics.addVertex(b + offsetCw, colorB)
  graphics.addIndices([e, f, g, g, h, e])

proc line*(graphics: Graphics, a, b: Vec2f, thickness: float32 = 1.0,
           color = rgba32f(1, 1, 1, 1)) =
  ## Shortcut for adding a line with a solid color.

  graphics.line(a, b, thickness, color, color)

const
  DefaultVertexShader* = glsl"""
    #version 330 core

    in vec2 position;
    in vec4 color;

    uniform mat4 projection;

    out Vertex {
      vec4 color;
    } toFragment;

    void main(void) {
      gl_Position = projection * vec4(position, 0.0, 1.0);
      toFragment.color = color;
    }
  """
  DefaultFragmentShader* = glsl"""
    #version 330 core

    in Vertex {
      vec4 color;
    } vertex;

    out vec4 fbColor;

    void main(void) {
      fbColor = vertex.color;
    }
  """

type
  GraphicsUniforms* = object
    ## Extra uniforms for use with aglet's ``uniforms`` macro.
    projection*: Mat4f
    `?targetSize`*: Vec2f

proc uniforms*(graphics: Graphics, target: Target): GraphicsUniforms =
  ## Returns some extra uniforms related to the graphics context:
  ##  - ``projection: mat4`` – the projection matrix
  ##  - ``?targetSize: vec2`` – the size of the target
  result = GraphicsUniforms(
    projection: ortho(left = 0'f32, top = 0'f32,
                      right = target.width.float32,
                      bottom = target.height.float32,
                      zNear = -1.0, zFar = 1.0),
    `?targetSize`: target.size.vec2f
  )

proc updateMesh(graphics: Graphics) =
  ## Updates the internal mesh with client-side shape data.
  graphics.mesh.uploadVertices(graphics.vertexBuffer)
  graphics.mesh.uploadIndices(graphics.indexBuffer)

proc draw*[U: UniformSource](graphics: Graphics, target: Target,
                             uniforms: U,
                             program = graphics.defaultProgram,
                             drawParams = graphics.defaultDrawParams) =
  ## Draws the graphics context's shape buffer onto the given target.
  ## Optionally, a program, uniforms, and draw parameters can be specified.
  ## When specifying uniforms, always add ``..graphics.uniforms``.
  ## Otherwise, shader programs won't compile!

  graphics.updateMesh()
  target.draw(program, graphics.mesh, uniforms, drawParams)

proc draw*(graphics: Graphics, target: Target,
           program = graphics.defaultProgram,
           drawParams = graphics.defaultDrawParams) =
  ## Overload of ``draw`` that uses ``graphics.uniforms(target)`` as the
  ## uniform source.
  # workaround to Nim/#14913 which causes a compiler crash when trying to use a
  # default value for a concept parameter

  graphics.updateMesh()
  target.draw(program, graphics.mesh, graphics.uniforms(target),
              graphics.defaultDrawParams)

proc newGraphics*(window: Window): Graphics =
  ## Creates a new graphics context.
  new(result)
  result.window = window
  result.mesh =
    window.newMesh[:Vertex2D](usage = muDynamic, primitive = dpTriangles)
  result.fDefaultProgram =
    window.newProgram[:Vertex2D](DefaultVertexShader, DefaultFragmentShader)
  result.fDefaultDrawParams = defaultDrawParams().derive:
    blend blendAlpha
  result.fTransformMatrix = mat3f()

converter rgba32f*(color: Color): Rgba32f =
  ## Converts an stdlib color to an aglet RGBA float32 pixel.
  let (r, g, b) = color.extractRgb
  result = rgba32f(r / 255, g / 255, b / 255, 1)

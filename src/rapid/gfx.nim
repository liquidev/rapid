## This module implements a simple hardware-accelerated 2D vector graphics
## renderer. It should primarily be used for UIs, etc.

import std/colors

import aglet

export colors except rgb  # use pixeltypes.rgba32f or pixeltypes.rgba instead

type

  RawVertexIndex = uint16
  VertexIndex* = distinct RawVertexIndex

  Vertex2D* = object
    ## A vertex, as represented in graphics memory and shaders.
    position: Vec2f
    color: Vec4f

  Vectorial* = ref object
    ## Hardware accelerated 2D vector graphics renderer.
    window: Window
    mesh: Mesh[Vertex2D]
    vertexBuffer: seq[Vertex2D]
    indexBuffer: seq[RawVertexIndex]
    defaultProgram: Program[Vertex2D]
    defaultDrawParams: DrawParams


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


# Vectorial

proc size*(vectorial: Vectorial): Vec2f =
  ## Returns the size of the vectorial as a vector.
  ## This returns the size of the parent window, but as a more convenient
  ## vector of floats.
  result = vectorial.window.size.vec2f

proc width*(vectorial: Vectorial): float32 =
  ## Returns the width of the vectorial.
  result = vectorial.size.x

proc height*(vectorial: Vectorial): float32 =
  ## Returns the height of the vectorial.
  result = vectorial.size.y

proc defaultProgram*(vectorial: Vectorial): Program[Vertex2D] =
  ## Returns the default program used for drawing using the vectorial.
  vectorial.defaultProgram

proc defaultDrawParams*(vectorial: Vectorial): DrawParams =
  ## Returns the default draw parameters for drawing with the vectorial.
  vectorial.defaultDrawParams

proc addVertex*(vectorial: Vectorial, vertex: Vertex2D): VertexIndex =
  ## Adds a vertex to the vectorial's shape buffer.
  result = vectorial.vertexBuffer.len.VertexIndex
  vectorial.vertexBuffer.add(vertex)

proc addVertex*(vectorial: Vectorial,
                position: Vec2f, color = rgba32f(1, 1, 1, 1)): VertexIndex =
  ## Shorthand for initializing a vertex and adding it to the vectorial's
  ## shape buffer.
  result = vectorial.vertexBuffer.len.VertexIndex
  vectorial.vertexBuffer.add(vertex(position, color))

proc addIndex*(vectorial: Vectorial, index: VertexIndex) =
  ## Adds an index into the vectorial's shape buffer.
  vectorial.indexBuffer.add(index.RawVertexIndex)

proc addIndices*(vectorial: Vectorial, indices: openArray[VertexIndex]) =
  ## Adds multiple indices to the vectorial's shape buffer in one go.
  for index in indices:
    vectorial.indexBuffer.add(index.RawVertexIndex)

proc resetShape*(vectorial: Vectorial) =
  ## Resets the vectorial's shape buffer.
  vectorial.vertexBuffer.setLen(0)
  vectorial.indexBuffer.setLen(0)

proc triangle*(vectorial: Vectorial, a, b, c: Vec2f,
               color = rgba32f(1, 1, 1, 1)) =
  ## Adds a triangle to the vectorial's shape buffer, tinted with the given
  ## color.
  var
    e = vectorial.addVertex(a, color)
    f = vectorial.addVertex(b, color)
    g = vectorial.addVertex(c, color)
  vectorial.addIndices([e, f, g])

proc quad*(vectorial: Vectorial, a, b, c, d: Vec2f,
           color = rgba32f(1, 1, 1, 1)) =
  ## Adds a quad to the vectorial's shape buffer, tinted with the given color.
  ## The vertices must be wound clockwise.
  var
    e = vectorial.addVertex(a, color)
    f = vectorial.addVertex(b, color)
    g = vectorial.addVertex(c, color)
    h = vectorial.addVertex(d, color)
  vectorial.addIndices([e, f, g, g, h, e])

proc rectangle*(vectorial: Vectorial, rect: Rectf,
                color = rgba32f(1, 1, 1, 1)) =
  ## Adds a rectangle to the vectorial's shape buffer, tinted with the given
  ## color.
  vectorial.quad(
    rect.position,
    rect.position + vec2f(rect.width, 0),
    rect.position + rect.size,
    rect.position + vec2f(0, rect.height),
    color
  )

proc rectangle*(vectorial: Vectorial, position, size: Vec2f,
                color = rgba32f(1, 1, 1, 1)) =
  ## Shortcut for adding a rectangle to the vectorial's shape buffer using
  ## position and size vectors, tinted with the given color.
  vectorial.rectangle(rectf(position, size), color)

proc rectangle*(vectorial: Vectorial, x, y, width, height: float32,
                color = rgba32f(1, 1, 1, 1)) =
  ## Shortcut for adding a rectangle to the vectorial's shape buffer using
  ## separate X and Y coordinates, a width, and a height, tinted with the given
  ## color.
  vectorial.rectangle(rectf(x, y, width, height), color)

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
  VectorialUniforms* = object
    ## Extra uniforms for use with aglet's ``uniforms`` macro.
    projection*: Mat4f
    `?targetSize`*: Vec2f

proc uniforms*(vectorial: Vectorial, target: Target): VectorialUniforms =
  ## Adds some extra uniforms from the vectorial to ``input``:
  ##  - ``projection: mat4`` – the projection matrix
  ##  - ``?targetSize: vec2`` – the size of the target
  result = VectorialUniforms(
    projection: ortho(left = 0'f32, top = 0'f32,
                      right = target.width.float32,
                      bottom = target.height.float32,
                      zNear = -1.0, zFar = 1.0),
    `?targetSize`: target.size.vec2f
  )

proc updateMesh(vectorial: Vectorial) =
  ## Updates the internal mesh with client-side shape data.
  vectorial.mesh.uploadVertices(vectorial.vertexBuffer)
  vectorial.mesh.uploadIndices(vectorial.indexBuffer)

proc draw*[U: UniformSource](vectorial: Vectorial, target: Target,
                             uniforms: U,
                             program = vectorial.defaultProgram,
                             drawParams = vectorial.defaultDrawParams) =
  ## Draws the vectorial's shape buffer onto the given target.
  ## Optionally, a program, uniforms, and draw parameters can be specified.
  ## When specifying uniforms, always add a ``..vectorial.uniforms``.
  ## Otherwise the drawing results will be incorrect!

  vectorial.updateMesh()
  target.draw(program, vectorial.mesh, uniforms, drawParams)

proc draw*(vectorial: Vectorial, target: Target,
           program = vectorial.defaultProgram,
           drawParams = vectorial.defaultDrawParams) =
  ## Overload of ``draw`` that uses ``vectorial.uniforms(target)`` as the
  ## uniform source.

  vectorial.updateMesh()
  target.draw(program, vectorial.mesh, vectorial.uniforms(target),
              vectorial.defaultDrawParams)

proc newVectorial*(window: Window): Vectorial =
  ## Creates a new vectorial.
  new(result)
  result.window = window
  result.mesh =
    window.newMesh[:Vertex2D](usage = muDynamic, primitive = dpTriangles)
  result.defaultProgram =
    window.newProgram[:Vertex2D](DefaultVertexShader, DefaultFragmentShader)
  result.defaultDrawParams = defaultDrawParams().derive:
    blend blendAlpha

converter rgba32f*(color: Color): Rgba32f =
  ## Converts an stdlib color to an aglet RGBA float32 pixel.
  let (r, g, b) = color.extractRgb
  result = rgba32f(r / 255, g / 255, b / 255, 1)

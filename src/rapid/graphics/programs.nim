## Commonly used shader programs.

import aglet

import vertex_types

const
  vert2DUvDirect = glsl"""
    #version 330 core

    in vec2 position;
    in vec2 uv;

    out vec2 vuv;

    void main(void)
    {
      gl_Position = vec4(position, 0.0, 1.0);
      vuv = uv;
    }
  """

  vert2DColorUvDirect = glsl"""
    #version 330 core

    in vec2 position;
    in vec2 uv;
    in vec4 color;

    out vec2 vuv;
    out vec4 vcolor;

    void main(void)
    {
      gl_Position = vec4(position, 0.0, 1.0);
      vuv = uv;
      vcolor = color;
    }
  """

  vert2DUvProjection = glsl"""
    #version 330 core

    in vec2 position;
    in vec2 uv;

    uniform mat4 projection;

    out vec2 vuv;

    void main(void)
    {
      gl_Position = projection * vec4(position, 0.0, 1.0);
      vuv = uv;
    }
  """

  vert2DColorUvProjection = glsl"""
    #version 330 core

    in vec2 position;
    in vec2 uv;
    in vec4 color;

    uniform mat4 projection;

    out vec2 vuv;
    out vec4 vcolor;

    void main(void)
    {
      gl_Position = projection * vec4(position, 0.0, 1.0);
      vuv = uv;
      vcolor = color;
    }
  """

  fragTextured = glsl"""
    #version 330 core

    in vec2 vuv;

    uniform sampler2D sampler;

    out vec4 color;

    void main(void)
    {
      color = texture(sampler, vuv);
    }
  """

  fragColoredTextured = glsl"""
    #version 330 core

    in vec2 vuv;
    in vec4 vcolor;

    uniform sampler2D sampler;

    out vec4 color;

    void main(void)
    {
      color = texture(sampler, vuv) * vcolor;
    }
  """

proc programDirect*(window: Window, _: type Vertex2dUv): auto =
  ## Creates a shader program for drawing 2D graphics without any matrices,
  ## directly using normalized device coordinates.
  ##
  ## Uniforms
  ## ========
  ##
  ## - ``sampler: Sampler2D`` – the sampler to use for texturing

  window.newProgram[:_](
    vertexSrc = vert2DUvDirect,
    fragmentSrc = fragTextured,
  )

proc programDirect*(window: Window, _: type Vertex2dColorUv): auto =

  window.newProgram[:_](
    vertexSrc = vert2DColorUvDirect,
    fragmentSrc = fragColoredTextured,
  )

proc programProjection*(window: Window, _: type Vertex2dUv): auto =
  ## Creates a shader program for drawing 2D graphics with a projection matrix
  ## only.
  ##
  ## Uniforms
  ## ========
  ##
  ## - ``projection: Mat4`` – the projection matrix applied to vertices
  ## - ``sampler: Sampler2D`` – the sampler to use for texturing

  window.newProgram[:_](
    vertexSrc = vert2DUvProjection,
    fragmentSrc = fragTextured,
  )

proc programProjection*(window: Window, _: type Vertex2dColorUv): auto =

  window.newProgram[:_](
    vertexSrc = vert2DColorUvProjection,
    fragmentSrc = fragColoredTextured,
  )

## Commonly-used meshes.

import aglet

import ../math/rectangle

import vertex_types

proc uploadRectangle*(mesh: Mesh[Vertex2dUv], position = rectf(-1, -1, 2, 2),
                      uv = rectf(0, 0, 1, 1)) =
  ## Uploads rectangle vertices to the given mesh.
  ## This sets the mesh's primitive to a triangle strip.

  mesh.primitive = dpTriangleStrip
  mesh.uploadVertices([
    Vertex2dUv(position: position.topLeft,     uv: uv.bottomLeft),
    Vertex2dUv(position: position.topRight,    uv: uv.bottomRight),
    Vertex2dUv(position: position.bottomLeft,  uv: uv.topLeft),
    Vertex2dUv(position: position.bottomRight, uv: uv.topRight),
  ])

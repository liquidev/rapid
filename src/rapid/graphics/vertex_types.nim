import glm/vec

type
  Vertex2dColor* {.packed.} = object
    ## Vertex with a position and color.
    position*: Vec2f
    color*: Vec4f

  Vertex2dUv* {.packed.} = object
    ## Vertex with a position and texture coordinates.
    position*: Vec2f
    uv*: Vec2f

  Vertex2dColorUv* {.packed.} = object
    ## Vertex with a position, color, and texture coordinates.
    position*: Vec2f
    color*: Vec4f
    uv*: Vec2f

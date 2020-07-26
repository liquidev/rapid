## Graphics components.

import ../../graphics/context

type
  SpriteGraphic* = object
    ## Sprite graphic component. Signifies that an entity should be drawn as a
    ## sprite.
    graphics*: Graphics
    sprite*: Sprite
  RectShapeGraphic* = object
    ## Rect shape graphic component. Signifies that an entity should be drawn as
    ## a filled rectangle.

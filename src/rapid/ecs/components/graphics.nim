## Graphics components.

import ../../graphics/context

type
  CompSprite* = object
    ## Sprite rendering component. Signifies that an entity should be drawn as a
    ## sprite.
    graphics*: Graphics
    sprite*: Sprite
  CompRectShape* = object
    ## "Flag" component. Signifies that an entity should be drawn as a
    ## filled rectangle.

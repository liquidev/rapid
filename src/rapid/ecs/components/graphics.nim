## Graphics components.

import aglet/pixeltypes

import ../../graphics/context

type
  GraphicColor* = object
    ## Color component.
    color*: Rgba32f
  SpriteGraphic* = object
    ## Sprite graphic component. Signifies that an entity should be drawn as a
    ## sprite.
    graphics*: Graphics
    sprite*: Sprite
  FillRectGraphic* = object
    ## Filled rect shape graphic component. Signifies that an entity should be
    ## drawn as a filled rectangle.

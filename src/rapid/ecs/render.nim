## Rendering-related systems.

import ../graphics
import components/basic
import components/graphics as comp_graphics
import system_macro

system drawSprites:
  ## Draws sprites from the ``SpriteGraphic`` component.

  requires:
    let
      position: Position
      size: Size
      sprite: SpriteGraphic

  proc draw(graphics: Graphics) =
    assert graphics == sprite.graphics
    graphics.sprite(sprite.sprite, position.position, size.size)

system drawFillRects:
  ## Draws filled rectangles from the ``GraphicColor`` and ``FillRectGraphic``
  ## components.

  requires:
    let
      position: Position
      size: Size
      color: GraphicColor
      _: FillRectGraphic

  proc draw(graphics: Graphics) =


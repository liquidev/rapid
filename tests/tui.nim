import aglet
import aglet/window/glfw
import rapid/game
import rapid/graphics
import rapid/ui

import unicode

const
  black = hex"#181818"
  cherry = hex"#ED124D"
  transparent = rgba(0, 0, 0, 0)

template button(ui: Ui, size: Vec2f, label: string, action: untyped) =

  ui.box(size, blFreeform):
    ui.outline(cherry)
    ui.color = transparent

    ui.mouseHover(): ui.color = cherry.withAlpha(0.2)
    ui.mouseDown(mbLeft): ui.color = cherry.withAlpha(0.4)

    ui.mouseReleased(mbLeft):
      `action`

    ui.fill()

    ui.text(label, color = black, alignment = (apCenter, apMiddle))

type
  Slider = object
    pressed: bool
    value: float32

converter value(slider: Slider): float32 = slider.value

template slider(ui: Ui, bwidth: float32, slider: var Slider, extra: untyped) =

  ui.box(vec2f(bwidth, 24), blFreeform):
    ui.drawInBox:
      let x = 6 + value * (bwidth - 12)
      let y = ui.height / 2
      ui.graphics.line(vec2f(0, y), vec2f(ui.width, y), thickness = 2,
                       colorA = cherry, colorB = cherry)
      ui.graphics.circle(x, 12, radius = 6, color = cherry)
    ui.mouseDown(mbLeft):
      let x = ui.mousePosition.x / (bwidth - 1)
      slider.value = x
    `extra`

proc main() =

  var aglet = initAglet()
  aglet.initWindow()

  const LatoTtf = slurp("sampleData/Lato-Regular.ttf")

  var
    window = aglet.newWindowGlfw(800, 600, "rapid/ui",
                                 winHints(msaaSamples = 8))
    ui = window.newUi()
    font = ui.graphics.newFont(LatoTtf, 14)

  ui.graphics.defaultDrawParams = ui.graphics.defaultDrawParams.derive:
    multisample on

  var
    slider = Slider(value: 0.5)

  runGameWhile not window.closeRequested:

    window.pollEvents proc (event: InputEvent) =
      ui.processEvent(event)

    update: discard

    draw step:
      var frame = window.render()
      frame.clearColor(colWhite)

      ui.begin(frame)
      ui.font = font

      ui.box(ui.size, blVertical):
        ui.pad(16)
        ui.spacing = 8
        ui.fontHeight = 14

        ui.box(size = vec2f(ui.width, 32), blHorizontal):
          ui.spacing = 8
          for i in 1..5:
            ui.button(size = vec2f(32, 32), label = $i):
              echo "clicked: ", i

        ui.button(size = vec2f(128, 32), label = "Hello"):
          echo "hello"

        ui.slider(256, sliderValue): discard

      ui.draw(frame)

      frame.finish()

when isMainModule: main()

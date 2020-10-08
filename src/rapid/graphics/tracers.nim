## Global "tracers" for debugging purposes.

import aglet/pixeltypes

import ../math/vector
import context

type
  TracerTag* = enum
    # symbols would be nicer for this but i was unable to create a decent
    # implementration
    ttPhysics
    ttCollision
    ttOther

  TracerKind = enum
    trkPoint
    trkLine
    trkRectangle
    trkCircle
    trkText

  Tracer = object
    tags: set[TracerTag]
    color: Rgba32f
    thickness: float32
    case kind: TracerKind
    of trkPoint:
      point: Vec2f
    of trkLine:
      lineA, lineB: Vec2f
    of trkRectangle:
      rectangle: Rectf
    of trkCircle:
      circleCenter: Vec2f
      circleRadius: float32
    of trkText:
      textPosition: Vec2f
      text: string
      textAlignment: tuple[h: HorzTextAlign, v: VertTextAlign]
      textAlignBox: Vec2f

const allTracers* = {TracerTag.low..TracerTag.high}

when not defined(rapidEnableTracers) or defined(nimdoc):

  {.push inline.}

  proc resetTracers*() =
    ## Clears the list of tracers.
    ## This should be called in the update block of your game loop.

  proc tracePoint*(tags: set[TracerTag], point: Vec2f,
                   size: float32 = 1, color: Rgba32f = colRed) =
    ## Adds a point tracer with the given tags.

  proc traceLine*(tags: set[TracerTag], a, b: Vec2f,
                  thickness: float32 = 1, color: Rgba32f = colRed) =
    ## Adds a line tracer with the given tags.

  proc traceRectangle*(tags: set[TracerTag], rectangle: Rectf,
                       thickness: float32 = 1, color: Rgba32f = colRed) =
    ## Adds a rectangle tracer with the given tags.

  proc traceCircle*(tags: set[TracerTag], center: Vec2f, radius: float32,
                    thickness: float32 = 1, color: Rgba32f = colRed) =
    ## Adds a circle tracer with the given tags.

  proc traceText*(tags: set[TracerTag], position: Vec2f, text: string,
                  horzAlignment = taLeft, vertAlignment = taTop,
                  alignBox = vec2f(0), color = colWhite) =
    ## Adds a text tracer with the given tags.

  {.pop.}

  proc tracers*(graphics: Graphics, tags: set[TracerTag],
                textFont: Font = nil) =
    ## Draws tracers with the given tags onto the given graphics context.
    ## If ``textFont`` is not nil, text will be drawn with the given font.
    ## Otherwise no text is drawn.

else:

  var
    gTracers: array[2048, Tracer]
    gTracerCount: uint32

  {.push inline.}

  proc resetTracers*() =
    gTracerCount = 0

  proc tracePoint*(tags: set[TracerTag], point: Vec2f,
                   size: float32 = 1, color: Rgba32f = colRed) =

    gTracers[gTracerCount] = Tracer(tags: tags, color: color,
                                    thickness: size,
                                    kind: trkPoint,
                                    point: point)
    inc(gTracerCount)

  proc traceLine*(tags: set[TracerTag], a, b: Vec2f,
                  thickness: float32 = 1, color: Rgba32f = colRed) =

    gTracers[gTracerCount] = Tracer(tags: tags, color: color,
                                    thickness: thickness,
                                    kind: trkLine,
                                    lineA: a, lineB: b)
    inc(gTracerCount)

  proc traceRectangle*(tags: set[TracerTag], rectangle: Rectf,
                       thickness: float32 = 1, color: Rgba32f = colRed) =

    gTracers[gTracerCount] = Tracer(tags: tags, color: color,
                                    thickness: thickness,
                                    kind: trkRectangle,
                                    rectangle: rectangle)
    inc(gTracerCount)

  proc traceCircle*(tags: set[TracerTag], center: Vec2f, radius: float32,
                    thickness: float32 = 1, color: Rgba32f = colRed) =

    gTracers[gTracerCount] = Tracer(tags: tags, color: color,
                                    thickness: thickness,
                                    kind: trkCircle,
                                    circleCenter: center,
                                    circleRadius: radius)
    inc(gTracerCount)

  proc traceText*(tags: set[TracerTag], position: Vec2f, text: string,
                  horzAlignment = taLeft, vertAlignment = taTop,
                  alignBox = vec2f(0), color = colWhite) =

    gTracers[gTracerCount] = Tracer(tags: tags, color: color,
                                    kind: trkText,
                                    textPosition: position,
                                    text: text,
                                    textAlignment: (horzAlignment,
                                                    vertAlignment),
                                    textAlignBox: alignBox)
    inc(gTracerCount)

  {.pop.}

  proc tracers*(graphics: Graphics, tags: set[TracerTag],
                textFont: Font = nil) =

    for index in 0..<gTracerCount:
      let t = gTracers[index]
      if card(t.tags * tags) == 0: continue
      case t.kind
      of trkPoint:
        graphics.point(t.point, t.thickness, t.color)
      of trkLine:
        graphics.line(t.lineA, t.lineB, t.thickness,
                      colorA = t.color, colorB = t.color)
      of trkRectangle:
        graphics.lineRectangle(t.rectangle, t.thickness, t.color)
      of trkCircle:
        graphics.lineCircle(t.circleCenter, t.circleRadius,
                            t.thickness, t.color)
      of trkText:
        if textFont != nil:
          graphics.text(textFont, t.textPosition, t.text,
                        t.textAlignment.h, t.textAlignment.v, t.textAlignBox,
                        color = t.color)

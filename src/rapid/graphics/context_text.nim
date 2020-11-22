## Text rendering submodule.

import std/tables
import std/unicode

type
  Text* = string | seq[Rune]

  Glyph {.byref.} = object
    advance: Vec2f
    size, offset: Vec2i
    atlasRect: Rectf

  FontFlag = enum
    ffScalable
    ffVertical
    ffKerned
  Font* = ref object
    ## A font face.
    face: FtFace
    flags: set[FontFlag]
    fSize: Vec2f
    atlas: AtlasTexture[Red8]
    glyphs: Table[GlyphIndex, Glyph]
    kerning: Table[KerningIndex, Vec2f]
    hinting: bool
    widths: Table[WidthIndex, float32]
    fLineSpacing, fTabWidth: float32

  HorzTextAlign* = enum
    ## Horizontal text alignment.
    taLeft
    taCenter
    taRight
  VertTextAlign* = enum
    ## Vertical text alignment.
    taTop
    taMiddle
    taBottom

  GlyphIndex = tuple[rune: Rune, size: Vec2f, subpixelOffset: float32]
  KerningIndex = tuple[left, right: Rune, size: Vec2f]
  WidthIndex = tuple[text: string, size: Vec2f]
  TypesetGlyph = tuple[glyph: Glyph, pen: Vec2f]

  FreetypeError* = object of ValueError

template check(expr: FtError) =
  let error = expr
  if error != fteOk:
    raise newException(FreetypeError, $error)

proc initFreetype(graphics: Graphics) {.inline.} =
  check initFreetype(graphics.freetype)

proc setSizes(font: Font) {.inline.} =
  check font.face.setCharSize(Ft26dot6(font.fSize.x * 64),
                              Ft26dot6(font.fSize.y * 64),
                              horz_resolution = 72,
                              vert_resolution = 72)

proc size*(font: Font): Vec2f {.inline.} =
  ## Returns the size of the font as a vector.
  font.fSize

proc `size=`*(font: Font, newSize: Vec2f) {.inline.} =
  ## Sets the size of the font in points. A point is equal to 1/72 inch.
  font.fSize = newSize
  font.setSizes()

proc width*(font: Font): float32 {.inline.} =
  ## Returns the width of the font in points.
  if font.size.x <= 0: font.size.y
  else: font.size.x

proc `width=`*(font: Font, newWidth: float32) {.inline.} =
  ## Sets the width of the font in points. When the width is 0, it is the same
  ## as the height of the font.
  font.fSize.x = newWidth
  font.setSizes()

proc height*(font: Font): float32 {.inline.} =
  ## Returns the height of the font in points.
  font.size.y

proc `height=`*(font: Font, newHeight: float32) {.inline.} =
  ## Sets the height of the font in points.
  font.fSize.y = newHeight
  font.setSizes()

proc pixelHeight*(font: Font): float32 {.inline.} =
  ## Retrieves the design height of the font in pixels.
  (font.face.size.metrics.ascender + font.face.size.metrics.descender) / 64 - 1

proc lineSpacing*(font: Font): float32 {.inline.} =
  ## Returns the line spacing multiplier.
  font.fLineSpacing

proc `lineSpacing=`*(font: Font, newSpacing: float32) {.inline.} =
  ## Sets the line spacing multiplier.
  font.fLineSpacing = newSpacing

proc lineHeight*(font: Font): float32 {.inline.} =
  ## Returns the height of a line, in pixels.
  font.pixelHeight * font.lineSpacing

proc tabWidth*(font: Font): float32 {.inline.} =
  ## Returns the tab width of the font, in pixels.
  font.fTabWidth

proc `tabWidth=`*(font: Font, newWidth: float32) {.inline.} =
  ## Sets the tab width of the font, in pixels.
  font.fTabWidth = newWidth

proc getGlyph(font: Font, rune: Rune, subpixelOffset: float32 = 0): Glyph =
  ## Retrieves a glyph from the font. Renders it if the glyph doesn't exist.

  let tableIndex = GlyphIndex (rune, font.size, subpixelOffset)
  if tableIndex notin font.glyphs:

    var
      offsetVector = FtVector(x: FtPos(subpixelOffset * 64))
      flags: int32 = ftLoadRender
    if font.hinting == off:
      flags = flags or ftLoadNoHinting
    font.face.setTransform(nil, addr offsetVector)
    check font.face.loadChar(culong(rune), flags)

    let pixels = cast[ptr Red8](font.face.glyph.bitmap.buffer)
    var glyph = Glyph(
      advance: vec2f(font.face.glyph.advance.x / 64,
                     font.face.glyph.advance.y / 64),
      offset: vec2i(font.face.glyph.bitmap_left,
                    font.face.glyph.bitmap_top),
      size: vec2i(font.face.glyph.bitmap.width.int32,
                  font.face.glyph.bitmap.rows.int32),
    )
    if glyph.size.x > 0 and glyph.size.y > 0:
      glyph.atlasRect = font.atlas.add(glyph.size, pixels)

    font.glyphs[tableIndex] = glyph

  result = font.glyphs[tableIndex]

proc getKerning(font: Font, left, right: Rune): Vec2f =
  ## Returns the offset that should be applied to ``right`` if it's standing
  ## to the right of ``left``.

  # XXX: this doesn't handle RTL layouts properly

  if ffKerned notin font.flags: return  # no sense to check all that for fonts
                                        # without kerning
  if left == Rune(0): return  # first character, no kerning to apply

  let index = KerningIndex (left, right, font.size)
  if index notin font.kerning:
    var kerningVector: FtVector
    let
      leftIndex = font.face.getCharIndex(left.culong)
      rightIndex = font.face.getCharIndex(right.culong)
    check font.face.getKerning(leftIndex, rightIndex, 0, kerningVector)
    result = vec2f(kerningVector.x / 64, kerningVector.y / 64)
    font.kerning[index] = result
  else:
    result = font.kerning[index]

iterator runes(str: seq[Rune]): Rune =
  ## Implementation of runes for runes.

  for rune in str:
    yield rune

iterator typeset(font: Font, text: Text,
                 firstGlyphOffset: var Vec2f): TypesetGlyph =
  ## The Iterator That Does The Magic. Renders glyphs if necessary, and returns
  ## their positions. The final position is the complete size of the string.

  let subpixelStep: float32 =
    if font.width <= 20: 0.1
    else: 1.0

  var
    pen = vec2f(0)
    previous = Rune(0)
    i = 0
  for rune in runes(text):
    case rune
    of Rune '\l':  # line feed
      pen.x = 0
      pen.y += font.lineHeight
    of Rune '\c':  # carriage return
      pen.x = 0
    of Rune '\t':  # horizontal tab
      var column = pen.x / font.tabWidth
      if column - trunc(column) <= 0.0001: column += 1
      pen.x = ceil(column) * font.tabWidth
    else:
      let
        kerning = font.getKerning(previous, rune)
        kernedX = pen.x + kerning.x
        subpixel = quantize(kernedX - trunc(kernedX), subpixelStep)
        glyph = font.getGlyph(rune, subpixel)
        offset = vec2f(glyph.offset.x.float32, -glyph.offset.y.float32)
      if i == 0: firstGlyphOffset = offset
      yield TypesetGlyph (glyph, pen + offset + kerning)
      pen += glyph.advance
      previous = rune
    inc(i)

proc textWidth*(font: Font, text: Text,
                fontHeight, fontWidth: float32 = 0): float32 =
  ## Returns the width of the given text.

  if text.len == 0: return

  let oldSize = font.size
  if fontHeight != 0:
    font.size = vec2f(fontHeight, fontWidth)
  var firstGlyphOffset: Vec2f
  for (glyph, pen) in font.typeset(text, firstGlyphOffset):
    result = pen.x + glyph.size.x.float32
  result += firstGlyphOffset.x
  font.size = oldSize

proc drawGlyph(graphics: Graphics, baselinePosition: Vec2f,
               glyph: Glyph, pen: Vec2f, color: Rgba32f) {.inline.} =
  ## Renders a single glyph.

  let
    position = floor(baselinePosition + pen)
    rect = rectf(position, glyph.size.vec2f)
    atlasRect = glyph.atlasRect
    e = graphics.addVertex(rect.topLeft, color, atlasRect.topLeft)
    f = graphics.addVertex(rect.topRight, color, atlasRect.topRight)
    g = graphics.addVertex(rect.bottomRight, color, atlasRect.bottomRight)
    h = graphics.addVertex(rect.bottomLeft, color, atlasRect.bottomLeft)
  graphics.addIndices([e, f, g, g, h, e])

proc text*(graphics: Graphics, font: Font, position: Vec2f, text: Text,
           horzAlignment = taLeft, vertAlignment = taTop, alignBox = vec2f(0),
           fontHeight, fontWidth: float32 = 0, color = rgba(1, 1, 1, 1)) =
  ## Draws text at the given position, tinted with the given color.
  ## If ``fontHeight`` is equal to zero, the rendering uses the
  ## font's size. Otherwise, it uses the specified size.
  ##
  ## Text alignment
  ## --------------
  ##
  ## rapid makes it easy to align text inside of rectangles through its
  ## "align box" concept. Alignment isn't done relative to the text's position,
  ## but rather relative to the align box's boundaries. For instance, to center
  ## text perfectly inside of a 64×64 rectangle, set
  ## ``horzAlignment = taCenter``, ``vertAlignment = taMiddle``, and
  ## ``alignBox = vec2f(64, 64)``.
  ## Due to how the position calculations are made, if ``alignBox == vec2f(0)``,
  ## the text will be aligned relative to ``position`` only.

  let
    defaultBatch = graphics.currentBatch
    oldSize = font.size
    sampler = font.atlas.sampler(
      minFilter = graphics.spriteMinFilter,
      magFilter = graphics.spriteMagFilter,
    )
  if fontHeight != 0:
    font.size = vec2f(fontWidth, fontHeight)
  graphics.batchNewSampler(sampler)

  var position = position
  position.x =
    case horzAlignment
    of taLeft: position.x
    of taCenter:
      alignBox.x / 2 + position.x - font.textWidth(text) / 2
    of taRight: alignBox.x + position.x - font.textWidth(text)
  position.y =
    case vertAlignment
    of taTop: position.y + font.pixelHeight
    of taMiddle: alignBox.y / 2 + position.y + font.pixelHeight / 2
    of taBottom: alignBox.y + position.y

  var firstGlyphOffset: Vec2f
  for (glyph, pen) in font.typeset(text, firstGlyphOffset):
    if glyph.size.x > 0 and glyph.size.y > 0:
      graphics.drawGlyph(position, glyph, pen, color)

  graphics.batchNewCopy(defaultBatch)
  font.size = oldSize

proc text*(graphics: Graphics, font: Font, x, y: float32, text: Text,
           horzAlignment = taLeft, vertAlignment = taTop,
           alignWidth, alignHeight: float32 = 0,
           fontHeight, fontWidth: float32 = 0, color = rgba(1, 1, 1, 1)) =
  ## Shortcut for drawing text with separate X and Y coordinates.

  graphics.text(font, vec2f(x, y), text,
                horzAlignment, vertAlignment, vec2f(alignWidth, alignHeight),
                fontHeight, fontWidth, color)

proc newFont*(graphics: Graphics, data: string,
              height: float32, width: float32 = 0,
              lineSpacing: float32 = 1.4, tabWidth: float32 = 96,
              hinting = on, atlasSize = 256.Positive): Font =
  ## Creates and reads a font from an in-memory buffer.

  assert data.len > 0, "no font data to read"

  new(result) do (font: Font):
    check font.face.destroy()
  check newMemoryFace(graphics.freetype, data[0].unsafeAddr, data.len.clong,
                      face_index = 0, result.face)

  template getFlag(freetypeFlag, rapidFlag) =
    if (result.face.face_flags and freetypeFlag) > 0:
      result.flags.incl(rapidFlag)
  getFlag(ftFaceFlagScalable, ffScalable)
  getFlag(ftFaceFlagVertical, ffVertical)
  getFlag(ftFaceFlagKerning, ffKerned)

  result.size = vec2f(width, height)

  result.atlas = graphics.window.newAtlasTexture[:Red8](vec2i(atlasSize.int32))
  result.atlas.texture.swizzleMask = [ccOne, ccOne, ccOne, ccRed]

  result.lineSpacing = lineSpacing
  result.tabWidth = tabWidth
  result.hinting = hinting

proc loadFont*(graphics: Graphics, filename: string,
               height: float32, width: float32 = 0,
               lineSpacing: float32 = 1.4, tabWidth: float32 = 96,
               hinting = on, atlasSize = 256.Positive): Font {.inline.} =
  ## Creates and loads a font from a file.

  graphics.newFont(readFile(filename), height, width,
                   lineSpacing, tabWidth, hinting, atlasSize)

const FreeTypeLicense* = slurp("../wrappers/extern/freetype/docs/FTL.TXT")
  ## The FreeType license. rapid uses this library for rendering glyphs, and
  ## you're legally required to credit FreeType somewhere in your application's
  ## credits if you're using rapid/graphics to draw text.

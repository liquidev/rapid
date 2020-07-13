## Text rendering submodule.

type
  FreetypeError* = object of ValueError
  FontFlag = enum
    ffScalable
    ffVertical
    ffKerned
  Font* = ref object
    face: FtFace
    flags: set[FontFlag]
    fSize: Vec2f
    atlas: AtlasTexture[Red8]

template check(expr: FtError) =
  let error = expr
  if error != fteOk:
    raise newException(FreetypeError, $error)

proc initFreetype(graphics: Graphics) =
  check initFreetype(graphics.freetype)

proc setSizes(font: Font) =
  check font.face.setCharSize(Ft26dot6(font.fSize.x),
                              Ft26dot6(font.fSize.y * 64),
                              horz_resolution = 72,
                              vert_resolution = 72)

proc size*(font: Font): Vec2f =
  ## Returns the size of the font as a vector.
  font.fSize

proc `size=`*(font: Font, newSize: Vec2f) =
  ## Sets the size of the font in points. A point is equal to 1/72 inch.
  font.fSize = newSize
  font.setSizes()

proc width*(font: Font): float32 =
  ## Returns the width of the font in points.
  if font.size.x <= 0: font.size.y
  else: font.size.x

proc `width=`*(font: Font, newWidth: float32) =
  ## Sets the width of the font in points. When the width is 0, it is the same
  ## as the height of the font.
  font.fSize.x = newWidth
  font.setSizes()

proc height*(font: Font): float32 =
  ## Returns the height of the font in points.
  font.size.y

proc `height=`*(font: Font, newHeight: float32) =
  ## Sets the height of the font in points.
  font.fSize.y = newHeight
  font.setSizes()

proc newFont*(graphics: Graphics, data: string,
              height: float32, width: float32 = 0): Font =
  ## Creates and reads a font from an in-memory buffer.

  assert data.len > 0, "no font data to read"

  new(result) do (font: Font):
    check font.face.destroy()
  check newMemoryFace(graphics.freetype, data[0].unsafeAddr, data.len,
                      face_index = 0, result.face)

  template getFlag(freetypeFlag, rapidFlag) =
    if (result.face.face_flags and freetypeFlag) > 0:
      result.flags.incl(rapidFlag)
  getFlag(ftFaceFlagScalable, ffScalable)
  getFlag(ftFaceFlagVertical, ffVertical)
  getFlag(ftFaceFlagKerning, ffKerned)

  result.size = vec2f(width, height)

proc loadFont*(graphics: Graphics, filename: string,
               height: float32, width: float32 = 0,
               atlasSize = 256.Positive): Font =
  ## Creates and loads a font from a file.
  graphics.newFont(readFile(filename), height, width)

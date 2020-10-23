## Atlas texture. Allows for dynamic packing of smaller images to a larger
## texture stored on the GPU.

import std/options

import aglet

import ../algorithm/rect_packer
import ../graphics/image

type
  AtlasTexture*[T: ColorPixelType] = ref object
    ## A texture that stores multiple smaller textures.
    texture: Texture2D[T]
    packer: RectPacker
    padding: uint8
  PackError* = object of ValueError

proc size*(atlas: AtlasTexture): Vec2i {.inline.} =
  ## Returns the size of the texture, as a vector.
  atlas.texture.size

proc width*(atlas: AtlasTexture): Vec2i {.inline.} =
  ## Returns the width of the texture.
  atlas.size.x

proc height*(atlas: AtlasTexture): Vec2i {.inline.} =
  ## Returns the height of the texture.
  atlas.size.y

proc padding*(atlas: AtlasTexture): uint8 {.inline.} =
  ## Returns the amount of padding around each packed image, in pixels.
  atlas.padding

proc `padding=`*(atlas: AtlasTexture, newPadding: uint8) {.inline.} =
  ## Sets the amount of padding around each packed image, in pixels.
  atlas.padding = newPadding

proc texture*[T: ColorPixelType](atlas: AtlasTexture[T]): Texture2D[T]
                                {.inline.} =
  ## Returns the texture the atlas is packing to.
  atlas.texture

proc add*[T: ColorPixelType](atlas: AtlasTexture[T],
                             size: Vec2i, data: ptr T): Rectf =
  ## Packs a single image from ``data``, with the given ``size``, and returns
  ## its texture coordinate rectangle.
  ## This procedure deals with pointers and so, it is inherently **unsafe**.
  ## Prefer the ``openArray`` or ``BinaryImageBuffer`` versions instead.

  let
    paddedSize = size + vec2i(atlas.padding.int32) * 2
    maybeIntRect = atlas.packer.pack(paddedSize)
  if maybeIntRect.isSome:
    var intRect = maybeIntRect.get
    intRect.position += vec2i(atlas.padding.int32)
    intRect.size -= vec2i(atlas.padding.int32) * 2
    atlas.texture.subImage(intRect.position, intRect.size, data)
    result = rectf(intRect.position.vec2f / atlas.size.vec2f,
                   intRect.size.vec2f / atlas.size.vec2f)
  else:
    raise newException(PackError, "cannot pack image: no space left on texture")

proc add*[T: ColorPixelType](atlas: AtlasTexture[T],
                             size: Vec2i, data: openArray[T]): Rectf =
  ## Safe version of ``add`` that accepts an ``openArray``.

  result = atlas.add(size, data[0].unsafeAddr)

proc add*[T: ColorPixelType,
          I: BinaryImageBuffer](atlas: AtlasTexture[T],
                                image: I): Rectf =
  ## Safe, generic version of ``add`` that accepts a ``BinaryImageBuffer``.
  ## This can be used with ``rapid/graphics/image``.

  result = atlas.add(vec2i(image.width, image.height),
                     cast[ptr T](image.data[0].unsafeAddr))

proc sampler*(atlas: AtlasTexture,
              minFilter: TextureMinFilter = fmNearestMipmapLinear,
              magFilter: TextureMagFilter = fmLinear,
              wrapS, wrapT = twClampToEdge,
              borderColor = rgba(0, 0, 0, 0)): Sampler =
  ## Creates a sampler for the given atlas texture, with the given parameters.
  ## Refer to aglet's documentation for details.
  result = atlas.texture.sampler(
    minFilter, magFilter,
    wrapS, wrapT, wrapR = twClampToEdge,
    borderColor,
  )

proc newAtlasTexture*[T: ColorPixelType](window: Window,
                                         size: Vec2i): AtlasTexture[T] =
  ## Creates a new, empty atlas texture with the given size.

  new(result)

  # ensure the buffer is zeroed – this is important for padding support.
  let zeroBuffer = cast[ptr T](alloc0(size.x * size.y * sizeof(T)))
  result.texture = window.newTexture2D[:T](size, zeroBuffer)
  dealloc(zeroBuffer)

  result.packer.init(size)
  result.padding = 1  # having one pixel of padding is better than no padding

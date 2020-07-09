## Atlas texture. Allows for dynamic packing of smaller images to a larger
## texture stored on the GPU.

import aglet

import ../algorithm/rect_packer

type
  AtlasTexture*[T: ColorPixelType] = ref object
    ## A texture that stores multiple smaller textures.
    texture: Texture2D[T]
    packer: RectPacker
    padding: uint8

proc padding*(atlas: AtlasTexture): uint8 =
  ## Returns the amount of padding around each packed image, in pixels.
  atlas.padding

proc `padding=`*(atlas: AtlasTexture, newPadding: uint8) =
  ## Sets the amount of padding around each packed image, in pixels.
  atlas.padding = newPadding

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

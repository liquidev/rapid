import tables
import os, ospaths

import dsl
export dsl.RTexconfMeta

import nimPNG

type
  RData* = object
    texconfs*: TableRef[string, RTexconfMeta]
    images*: TableRef[string, RImage]
  RImage* = object
    width*, height*: int
    data*: string
    config*: RTexconfMeta

proc loadImage(data: var RData, parentPath: string, img: RImgMeta) =
  if existsFile(parentPath / img.file):
    let (dir, name, ext) = splitFile(parentPath / img.file)
    case ext
    of ".png":
      let png = loadPNG32(parentPath / img.file)
      data.images.add(img.id, RImage(
        width: png.width, height: png.height,
        data: png.data,
        config: data.texconfs[img.texture]
      ))
    of ".apng":
      raise newException(ValueError, "rd: " & ext & " APNG animated sprites are not yet supported")
    else:
      raise newException(ValueError, "rd: " & ext & " format not supported. Use one of: .png")
  else:
    raise newException(IOError, "rd: file " & (parentPath / img.file) & " doesn't exist")

proc loadDataFromMeta(path: string, meta: RMetaData): RData =
  result = RData(
    texconfs: newTable[string, RTexconfMeta](),
    images: newTable[string, RImage]()
  )
  for cfg in meta.texconfs: result.texconfs.add(cfg.id, cfg)
  for img in meta.images:
    loadImage(result, path, img)

proc loadRData*(path: string = "data"): RData =
  ## Loads resources according to ``path``/resources.yaml.
  let meta = parseData(readFile(path / "resources.yaml"))
  result = loadDataFromMeta(path, meta)

when defined(testDataLoading):
  let data = loadRData("examples/10-resources/data")
  echo "Sample data successfully loaded"

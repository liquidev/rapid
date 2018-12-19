import strutils, re

import yaml/dom

type
  RMetaData* = object
    images*: seq[RImgMeta]
    texconfs*: seq[RTexconfMeta]
  RImgMeta* = object
    id*, file*, texture*: string
  RTexInterp* = enum
    tiNearest, tiLinear
  RTexconfMeta* = object
    id*: string
    interpMin*, interpMag*: RTexInterp
    mipmaps*: bool

let
  reDef = re"([a-z]+)\s+(\w+|~|\*)(?:\s+(.*))?"
  reInherit = re"of\s+(\w+|~|\*)"
  reImg = re"(.+?\.(?:[pP][nN][gG]))(?:\s+~(\w+|))?"

proc dImg(data: var RMetaData, ident: string, node: YamlNode) =
  if node.content =~ reImg:
    let file = matches[0]
    var texture = matches[1]
    if texture == "": texture = "~"
    data.images.add(RImgMeta(id: ident, file: file, texture: texture))

proc dTexconf(data: var RMetaData, ident, rest: string, node: YamlNode) =
  var parent = RTexconfMeta(
    id: "__rd__",
    interpMin: tiLinear, interpMag: tiLinear,
    mipmaps: true
  )
  if rest =~ reInherit:
    let inherited = matches[0]
    for t in data.texconfs:
      if t.id == inherited: parent = t; break
  var conf = RTexconfMeta(
    id: ident,
    interpMin: parent.interpMin, interpMag: parent.interpMag,
    mipmaps: parent.mipmaps
  )
  for k, v in pairs(node):
    case k.content
    of "interpMin": conf.interpMin = parseEnum[RTexInterp]("ti" & v.content.capitalizeAscii)
    of "interpMag": conf.interpMag = parseEnum[RTexInterp]("ti" & v.content.capitalizeAscii)
    of "mipmaps": conf.mipmaps = parseBool(v.content)
  data.texconfs.add(conf)

proc parseData*(rd: string): RMetaData =
  result = RMetaData()

  var dom: YamlDocument
  try:
    dom = loadDom(rd) # TODO: use events
    for k, v in pairs(dom.root):
      if k.content =~ reDef:
        let
          rtype = matches[0]
          ident = matches[1]
          rest = matches[2]
          node = v
        case rtype
        of "img": dImg(result, ident, node)
        of "texconf": dTexconf(result, ident, rest, node)
      else:
        raise newException(KeyError, "rd: a resdef key must be a valid definition (type ident ...)")
  except: raise

  echo result

when defined(testDataDSL):
  const sampleData = slurp("../../examples/10-resources/data/resources.yaml")
  discard parseData(sampleData)

## Dynamic rectangle packer using a skyline packing algorithm.

import std/options

import aglet

import ../math as rmath

type
  Node = object
    position: Vec2i
    width: int32
  RectPacker* = object
    ## Dynamic 2D atlas texture.
    size: Vec2i
    nodes: seq[Node]

# shortcuts to reduce verbosity
proc x(node: Node): int32 {.inline.} = node.position.x
proc y(node: Node): int32 {.inline.} = node.position.y

proc size*(packer: RectPacker): Vec2i {.inline.} =
  ## Returns the size of the packer, as a vector.
  packer.size

proc width*(packer: RectPacker): int32 {.inline.} =
  ## Returns the width of the packer.
  packer.size.x

proc height*(packer: RectPacker): int32 {.inline.} =
  ## Returns the height of the packer.
  packer.size.y

# algorithm stolen from fontstash
# https://github.com/memononen/fontstash/blob/master/src/fontstash.h#L608
# thank you for the pointer, @mrgaturus!

proc addSkylineLevel(packer: var RectPacker, index: int, rect: Recti) =

  # insert node
  let node = Node(position: vec2i(rect.x, rect.y + rect.height),
                  width: rect.width)
  packer.nodes.insert(node, index)

  # delete skyline segments that fall under the shadow of the new segment
  block:
    var i = index + 1
    while i < packer.nodes.len:
      if packer.nodes[i].x < packer.nodes[i - 1].x + packer.nodes[i - 1].width:
        let shrink =
          packer.nodes[i - 1].x + packer.nodes[i - 1].width - packer.nodes[i].x
        packer.nodes[i].position.x += shrink
        packer.nodes[i].width -= shrink
        if packer.nodes[i].width <= 0:
          packer.nodes.delete(i)
          dec(i)
        else:
          break
      else:
        break
      inc(i)

  # merge same height skyline segments that are next to each other
  block:
    var i = 0
    while i < packer.nodes.len - 1:
      if packer.nodes[i].y == packer.nodes[i + 1].y:
        packer.nodes[i].width += packer.nodes[i + 1].width
        packer.nodes.delete(i + 1)
        dec(i)
      inc(i)

proc rectFits(packer: RectPacker, index: int, size: Vec2i): Option[int32] =
  ## Checks if there's enough space at the location of skyline span at the given
  ## ``index``. Returns ``Some(y)``, where y is the max height of all skyline
  ## spans under that location, or ``None`` if no space was found.

  var
    position = packer.nodes[index].position
    spaceLeft = size.x

  if position.x + size.x > packer.width:
    return int32.none

  var i = index
  while spaceLeft > 0:
    if i == packer.nodes.len:
      return int32.none
    position.y = max(position.y, packer.nodes[i].y)
    if position.y + size.y > packer.height:
      return int32.none
    spaceLeft -= packer.nodes[i].width
    inc(i)
  result = some(position.y)

proc pack*(packer: var RectPacker, size: Vec2i): Option[Recti] =
  ## Packs a rectangle to the packer's bin and returns ``Some(rect)``. If the
  ## rectangle doesn't fit, returns ``None``.

  var
    bestSize = packer.size
    bestPosition = Vec2i.none
    bestIndex = int.none

  for index, node in packer.nodes:
    let maybeY = packer.rectFits(index, size)
    if maybeY.isSome:
      let y = maybeY.get
      if y + size.y < bestSize.y or
         (y + size.y == bestSize.y and node.width < bestSize.x):
        bestIndex = some(index)
        bestSize = vec2i(node.width, y + size.y)
        bestPosition = some(vec2i(node.x, y))

  if bestIndex.isNone:
    return Recti.none

  let rect = recti(bestPosition.get, size)
  packer.addSkylineLevel(bestIndex.get, rect)
  result = some(rect)

proc init*(packer: var RectPacker, size: Vec2i) =
  ## Initializes a rect packer.

  packer.size = size
  packer.nodes.setLen(0)
  packer.nodes.add(Node(width: size.x))

proc initRectPacker*(size: Vec2i): RectPacker =
  ## Creates and initializes a rect packer.
  result.init(size)

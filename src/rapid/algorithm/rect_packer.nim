## Dynamic rectangle packer using a skyline packing algorithm.

# thank you @mrgaturus for this!

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
proc x(node: Node): int32 = node.position.x
proc y(node: Node): int32 = node.position.y

proc size*(packer: RectPacker): Vec2i =
  ## Returns the size of the packer, as a vector.
  packer.size

proc width*(packer: RectPacker): int32 =
  ## Returns the width of the packer.
  packer.width

proc height*(packer: RectPacker): int32 =
  ## Returns the height of the packer.
  packer.height

proc rectFits(packer: RectPacker, index: Natural, size: Vec2i): Option[int32] =
  ## Checks whether the given rect fits within the node at ``index``. Returns
  ## ``Some(y)`` if it fits, or ``None`` if it doesn't fit.

  # return none if it's out of bounds
  if packer.nodes[index].x + size.x > packer.width:
    return int32.none

  # find space for the rectangle
  var
    y = packer.nodes[index].y
    spaceLeft = size.x
    index = index
  while spaceLeft > 0:
    if index == packer.nodes.len:
      # reached the end, no space available
      # XXX: this should probably be reported somehow.
      return int32.none
    y = max(y, packer.nodes[index].y)
    if y + size.y > packer.height:
      # reached the bottom, out of bounds
      return int32.none
    spaceLeft -= packer.nodes[index].width
    inc(index)
  # rectangle fits
  result = some(y)

proc addNode(packer: var RectPacker, index: Natural, rect: Recti) =
  ## Adds a new node.

  # add the node
  block addNode:
    let node = Node(position: vec2i(rect.x, rect.y), width: rect.width)
    packer.nodes.insert(node, index)

  # remove segments that are under the new segment
  block removeOldSegments:
    var index = index + 1
    while index < packer.nodes.len:
      let
        previousNode = packer.nodes[index - 1]
        currentNode = packer.nodes[index]
      if currentNode.x < previousNode.x + previousNode.width:
        let shrink = previousNode.x - currentNode.x + previousNode.width
        packer.nodes[index].position.x += shrink
        packer.nodes[index].width -= shrink
        if currentNode.x <= 0:
          packer.nodes.delete(index)
          dec(index)
        else: break
      else: break
      inc(index)

  # merge segments that have the same height and are next to each other
  block mergeSegments:
    var index = 0
    while index < packer.nodes.len:
      let
        nextNode = packer.nodes[index + 1]
        currentNode = packer.nodes[index]
      if currentNode.y == nextNode.y:
        packer.nodes[index].width += nextNode.width
        packer.nodes.delete(index + 1)
        dec(index)
      inc(index)

proc pack*(packer: var RectPacker, size: Vec2i): Option[Recti] =
  ## Packs a rectangle of the given ``size`` onto the rect packer's surface.
  ## Returns ``None`` if the rectangle could not be packed.

  var
    bestIndex = -1
    bestPosition = vec2i(-1)

  block findBest:
    var bestSize = packer.size
    for index, node in packer.nodes:
      let maybeY = packer.rectFits(index, size)
      if maybeY.isSome:
        let y = maybeY.get
        if y + size.y <= bestSize.y and node.width < bestSize.x:
          bestIndex = index
          bestPosition = vec2i(node.x, y)
          bestSize = vec2i(node.width, y + size.y)

  if bestIndex != -1:
    let rect = recti(vec2i(bestPosition), size)
    packer.addNode(bestIndex, rect)
    result = some(rect)

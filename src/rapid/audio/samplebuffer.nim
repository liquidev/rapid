#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## A ``seq`` living on the stack. Keep in mind that its capacity is limited
## and determined by ``RSampleBufferSize``.

import audiosettings

type
  SampleBuffer* = object
    fData: array[RSampleBufferSize, float]
    fLen: int

proc len*(sb: SampleBuffer): int =
  ## Returns the length of the sample buffer.
  sb.fLen

proc `[]`*(sb: SampleBuffer, i: int): float =
  ## Retrieves a sample from the buffer. This does not do any bound checking on
  ## the buffer's length, so it's possible to access elements beyond
  ## ``sb.len - 1``.
  ## This also prevents overflows; if ``i`` is out of bounds, the value
  ## retrieved will be 0.
  result =
    if i in 0..<RSampleBufferSize: sb.fData[i]
    else: 0


proc `[]=`*(sb: var SampleBuffer, i: int, val: float) =
  ## Sets an element in the buffer. This does not do any bound checking on the
  ## buffer's length, so it's possible to set elements beyoud ``sb.len - 1``.
  ## This also prevents overflows; if ``i`` is out of bounds, the value
  ## retrieved will be 0.
  if i in 0..<RSampleBufferSize:
    sb.fData[i] = val

proc add*(sb: var SampleBuffer, x: float, n = 1) =
  ## Adds ``n`` of ``x`` to the ring buffer.
  for i in 0..<n:
    sb[sb.fLen] = x
    inc(sb.fLen)

proc add*(sb: var SampleBuffer, list: openarray[float]) =
  ## Adds all elements from ``list`` to the ring buffer.
  for x in list:
    sb.add(x)

proc reset*(sb: var SampleBuffer) =
  ## Resets the sample buffer to 0 length. This does not delete its elements,
  ## however, and they can be read just fine!
  sb.fLen = 0

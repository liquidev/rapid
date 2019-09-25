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

proc add*(sb: var SampleBuffer, x: float, n = 1) =
  ## Adds ``n`` of ``x`` to the ring buffer.
  for i in 1..n:
    sb.fData[sb.fLen] = x
    inc(sb.fLen)

proc add*(sb: var SampleBuffer, list: openarray[float]) =
  ## Adds all elements from ``list`` to the ring buffer.
  for x in list:
    sb.add(x)

proc `[]`*(sb: SampleBuffer, i: int): float =
  ## Retrieves a sample from the buffer. This does not do any bound checking on
  ## the buffer's length, so it's possible to access elements beyond
  ## ``sb.len - 1``.
  result = sb.fData[i]

proc `[]=`*(sb: var SampleBuffer, i: int, val: float) =
  ## Sets an element in the buffer. This does not do any bound checking on the
  ## buffer's length, so it's possible to set elements beyoud ``sb.len - 1``.
  sb.fData[i] = val

proc reset*(sb: var SampleBuffer) =
  ## Resets the sample buffer to 0 length. This does not delete its elements,
  ## however, and they can be read just fine!
  sb.fLen = 0

proc len*(sb: SampleBuffer): int =
  ## Returns the length of the sample buffer.
  sb.fLen

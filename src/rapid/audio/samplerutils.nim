#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Utilities for creating samplers.

import math

import ../math/interpolation

proc fill*[T](s: var seq[T], amt: int, val: T) =
  ## Fill the given sequence with ``amt`` of ``val``.
  for n in 0..<amt:
    s.add(val)

func interpChannels*(audio: openarray[float], t: float,
                     fn: InterpFunc): tuple[l, r: float] =
  ## Interpolate interleaved audio channels.
  ## **Note:** This is currently broken and will result in poor audio quality
  ## with certain audio files.
  let
    t = clamp(t, 0, audio.len.float / 2 - 1)
    lt = t * 2
    rt = t * 2 + 1
    li0 = max(0, floor(lt).int)
    li1 = min(audio.len - 1, ceil(lt).int)
    ri0 = max(0, floor(rt).int)
    ri1 = min(audio.len - 1, ceil(rt).int)
  (l: interp(audio[li0], audio[li1], lt mod 1, fn),
   r: interp(audio[ri0], audio[ri1], rt mod 1, fn))

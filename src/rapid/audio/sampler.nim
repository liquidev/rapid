#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Samplers are high-performance audio sampling objects.
## They are semi low-level, to avoid audio slowdowns and underruns.
## This is a base implementation which outputs silence.

import macros

type
  RSampler* = ref object of RootObj

method sample*(sampler: RSampler, dest: var seq[float], count: int) {.base.} =
  ## Write samples to the destination.
  ## This base implementation writes zeros (producing silence).
  ## Every implementation must write samples to 2 channels interleaved, like:
  ##
  ## ```
  ## [L, R, L, R, L, R, ...]
  ## ```
  ##
  ## Other channel layouts are not supported to avoid unnecessary complexity.
  ##
  ## No system calls (like heap allocation) must be made in a ``sample``
  ## implementation. System calls are slow and will result in a buffer
  ## underflow due to the lack of samples being supplied on time, which will
  ## result in a segmentation fault.
  ## Every ``sample`` implementation *must* be sure that when the proc returns
  ## the length of ``dest`` is equal to ``count * 2``. If that isn't the case,
  ## that means there's a sample leak somewhere and a segfault will occur due to
  ## a buffer underflow.
  dest.setLen(0)
  for n in 0..<count:
    dest.add([0.0, 0.0])

proc initRSampler*(sampler: var RSampler) =
  ## Initialize a silent sampler.
  discard

proc newRSampler*(): RSampler =
  ## Create a silent sampler.
  result = RSampler()
  result.initRSampler()

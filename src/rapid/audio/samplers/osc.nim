#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## An oscillator sampler.

import math

import ../audiosettings
import ../sampler
import ../samplerutils

type
  ROscKind* = enum
    oscSine
    oscPulse
    oscTri
    oscSaw
  ROscObj* = object of RSampler
    freq*: float
    case kind*: ROscKind
    of oscSine:
      sineRadians*: float
    of oscPulse:
      pulseWidth*: float
    else: discard

    playing: bool
  ROsc* = ref ROscObj

method sample*(osc: ROsc, dest: var seq[float], count: int) =
  dest.setLen(0)
  if osc.playing:
    let secondsPerSample = 1 / OutputSampleRate
    case osc.kind
    of oscSine:
      let
        radiansPerSecond = osc.freq * 2 * PI
        radiansPerSample = radiansPerSecond * secondsPerSample
      for n in 0..<count:
        let val = sin(osc.sineRadians)
        dest.add([val, val])
        osc.sineRadians += radiansPerSample
    else: discard
  else:
    dest.fill(count * 2, 0.0)

proc initROsc*(osc: ROsc, kind: ROscKind) =
  osc[] = ROscObj(kind: kind) # avoid case transitions
  osc.initRSampler()
  osc.playing = false
  osc.freq = 440
  if kind == oscPulse:
    osc.pulseWidth = 0.5

proc newROsc*(kind: ROscKind): ROsc =
  new(result)
  result.initROsc(kind)

proc play*(osc: ROsc) =
  osc.playing = true

proc play*(osc: ROsc, freq: float) =
  osc.freq = freq
  osc.playing = true

proc stop*(osc: ROsc) =
  osc.playing = false

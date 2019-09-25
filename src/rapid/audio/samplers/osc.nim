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
      sineRadians: float
    of oscPulse:
      # TODO: Pulse oscillator
      pulseWidth*: float
    else: discard

    playing: bool
  ROsc* = ref ROscObj

method sample*(osc: ROsc, dest: var SampleBuffer, count: int) =
  ##
  if osc.playing:
    let secondsPerSample = 1 / ROutputSampleRate
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
    dest.add(0.0, count * 2)

proc initROsc*(osc: ROsc, kind: ROscKind) =
  ## Initialize an oscillator with the specified kind.
  osc[] = ROscObj(kind: kind) # avoid case transitions
  osc.initRSampler()
  osc.playing = false
  osc.freq = 440
  if kind == oscPulse:
    osc.pulseWidth = 0.5

proc newROsc*(kind: ROscKind): ROsc =
  ## Create a new oscillator of the specified kind.
  new(result)
  result.initROsc(kind)

proc play*(osc: ROsc) =
  ## Play the oscillator's tone.
  osc.playing = true

proc play*(osc: ROsc, freq: float) =
  ## Play the oscillator's tone at the given frequency.
  osc.freq = freq
  osc.playing = true

proc stop*(osc: ROsc) =
  ## Stop playback.
  osc.playing = false

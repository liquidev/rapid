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
    # TODO: oscTri
    # TODO: oscSaw
  ROscObj* = object of RSampler
    fFreq: float
    case kind*: ROscKind
    of oscSine:
      sineRadians: float
    of oscPulse:
      pulseTime: float
      fPulseWidth: float

    playing: bool
  ROsc* = ref ROscObj

proc freq*(osc: ROsc): float =
  ## Returns the oscillation frequency.
  osc.fFreq
proc `freq=`*(osc: ROsc, freq: float) =
  ## Sets the oscillation frequency
  osc.fFreq = freq

proc pulseWidth*(osc: ROsc): float =
  ## Returns the pulse width.
  osc.fPulseWidth
proc `pulseWidth=`*(osc: ROsc, width: float) =
  ## Sets the pulse width (duty cycle). The passed parameter should be a value
  ## 0..1, but other values do not cause problems.
  ## The default width is 0.5 (50%), which produces a square wave.
  ## This can only be used with ``oscPulse`` oscillators.
  osc.fPulseWidth = width

method sample*(osc: ROsc, dest: var SampleBuffer, count: int) =
  template sinePrep() {.dirty.} =
    let
      radiansPerSecond = osc.freq * 2 * PI
      radiansPerSample = radiansPerSecond * secondsPerSample
  template sineLoop() {.dirty.} =
    let val = sin(osc.sineRadians)
    dest.add([val, val])
    osc.sineRadians += radiansPerSample

  let secondsPerSample = 1 / ROutputSampleRate
  if osc.playing:
    case osc.kind
    of oscSine:
      sinePrep
      for n in 0..<count:
        sineLoop
    of oscPulse:
      for n in 0..<count:
        let val =
          if osc.pulseTime > osc.pulseWidth: 1.0
          else: -1.0
        dest.add([val, val])
        osc.pulseTime =
          floorMod(osc.pulseTime + secondsPerSample * osc.freq, 1.0)
  else:
    case osc.kind
    of oscSine:
      sinePrep
      while osc.sineRadians mod PI > 0.05:
        sineLoop
    of oscPulse: discard
    dest.add(0.0, count * 2 - dest.len)

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

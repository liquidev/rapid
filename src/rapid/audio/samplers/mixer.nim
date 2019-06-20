#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## A basic mixer with track support.

import ../sampler
import ../samplerutils

type
  RMixer* = ref object of RSampler
    tracks*: seq[RTrack]
    buffer: seq[float]
  RTrack* = ref object
    sampler: RSampler
    pVolume: float
    pMute: bool

method sample*(mixer: RMixer, dest: var seq[float], count: int) =
  dest.setLen(0)
  dest.fill(count * 2, 0.0)
  for t in mixer.tracks:
    if not t.pMute:
      t.sampler.sample(mixer.buffer, count)
      for i, s in mixer.buffer:
        dest[i] += s * t.pVolume

proc initRMixer*(mixer: RMixer) =
  mixer.initRSampler()

proc newRMixer*(): RMixer =
  result = RMixer()
  result.initRMixer()

proc add*(mixer: RMixer, sampler: RSampler,
          volume = 0.8, mute = false): RTrack =
  result = RTrack(
    sampler: sampler,
    pVolume: volume,
    pMute: mute
  )
  mixer.tracks.add(result)

proc volume*(track: RTrack): float =
  result = track.pVolume

proc `volume=`*(track: RTrack, volume: float) =
  track.pVolume = volume

proc muted*(track: RTrack): bool =
  result = track.pMute

proc `muted=`*(track: RTrack, mute: bool) =
  track.pMute = mute

proc solo*(mixer: RMixer, track: RTrack) =
  for t in mixer.tracks:
    t.muted = t == track

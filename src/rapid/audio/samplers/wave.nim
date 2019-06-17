#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Wave file sampler. Samples an audio file.
## Currently, the only supported format is Ogg Vorbis.

import ../sampler

include wave/decoder

type
  RWave* = ref object of RSampler
    decoder: RAudioDecoder
    playing: bool

method sample*(wave: RWave, dest: var seq[float], count: int) =
  ## Reads ``count`` samples of the wave file into ``dest``, if it's playing.
  ## Otherwise, outputs silence.
  # TODO: Sample rate conversion
  dest.setLen(0)
  if wave.playing:
    wave.decoder.decode(dest, count)
  else:
    for n in 0..<count:
      dest.add([0.0, 0.0])

proc initRWave*(wave: RWave, filename: string) =
  ## Initializes a wave file sampler.
  wave.initRSampler()
  wave.decoder = newRAudioDecoder(filename)
  wave.playing = false

proc newRWave*(filename: string): RWave =
  ## Creates a new wave file sampler.
  new(result)
  result.initRWave(filename)

proc play*(wave: RWave) =
  ## Plays the wave file.
  wave.playing = true

proc pause*(wave: RWave) =
  ## Pauses the wave's playback.
  wave.playing = false

proc seek*(wave: RWave, time: float) =
  ## Seeks playback to a specified time (in seconds).
  wave.decoder.seekSample(int(time * wave.decoder.sampleRate.float))

proc stop*(wave: RWave) =
  ## Stops playback and rewinds to the beginning of the wave.
  wave.pause()
  wave.seek(0)

#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Wave file sampler. Samples an audio file.
## Currently, the only supported format is Ogg Vorbis.

import math

import wave/decoder
import ../audiosettings
import ../sampler
import ../../math/interpolation

export RAudioDecoderMode

type
  RWave* = ref object of RSampler
    decoder: RAudioDecoder
    playing, loop: bool
    interpolation: InterpFunc

proc printf(formatstr: cstring) {.importc: "printf", varargs,
header: "<stdio.h>".}

proc finished*(wave: RWave): bool =
  result = wave.decoder.atEnd

method sample*(wave: RWave, dest: var SampleBuffer, count: int) =
  ## Reads ``count`` samples of the wave file into ``dest``, if it's playing.
  ## Otherwise, outputs silence.
  if wave.playing:
    var convBuffer: SampleBuffer
    let rateRatio = wave.decoder.sampleRate / ROutputSampleRate
    wave.decoder.read(convBuffer, int(ceil(count.float * rateRatio)))
    if wave.loop and wave.finished:
      wave.decoder.seekSample(0)
    for n in 0..<count:
      let
        i = n.float * rateRatio
        # (l, r) = interpChannels(convBuffer, i, wave.interpolation)
        l = convBuffer[int(i * 2)]
        r = convBuffer[int(i * 2 + 1)]
      dest.add([l, r])
  else:
    for n in 0..<count:
      dest.add([0.0, 0.0])

proc initRWave*(wave: RWave, filename: string, decodeMode = admSample,
                interpolation = linear) =
  ## Initializes a wave file sampler.
  wave.initRSampler()
  wave.decoder = newRAudioDecoder(filename, decodeMode)
  wave.playing = false
  wave.interpolation = interpolation

proc newRWave*(filename: string, decodeMode = admSample,
               interpolation = hermite): RWave =
  ## Creates a new wave file sampler.
  new(result)
  result.initRWave(filename, decodeMode, interpolation)

proc play*(wave: RWave) =
  ## Plays the wave file.
  wave.playing = true

proc pause*(wave: RWave) =
  ## Pauses the wave's playback.
  wave.playing = false

proc seek*(wave: RWave, time: float) =
  ## Seeks playback to a specified time (in seconds).
  wave.decoder.seekSample(int(time * wave.decoder.sampleRate.float))

proc playing*(wave: RWave): bool = wave.playing

proc stop*(wave: RWave) =
  ## Stops playback and rewinds to the beginning of the wave.
  wave.pause()
  wave.seek(0)

proc loop*(wave: RWave): bool = wave.loop
proc `loop=`*(wave: RWave, enabled: bool) =
  wave.loop = enabled

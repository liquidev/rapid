import os

import rapid/audio/samplers/[osc, wave]
import rapid/audio/sampler
import rapid/audio/device

proc main() =
  var
    dev = newRAudioDevice()
    # osc = newROsc(oscSine)
    waveA = newRWave("sampleData/coin_48000.ogg")
    waveB = newRWave("sampleData/coin_44100.ogg")
    i = 0
  dev.attach(waveA)
  # osc.play(440)
  dev.start()
  waveA.play()
  while true:
    if waveA.finished:
      echo i mod 2
      waveA.stop()
      swap(waveA, waveB)
      sleep(300)
      dev.attach(waveA)
      waveA.play()
      inc(i)
    dev.poll()

main()

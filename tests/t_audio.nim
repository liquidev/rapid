import os

import rapid/audio/samplers/[osc, wave]
import rapid/audio/sampler
import rapid/audio/device

proc main() =
  var
    dev = newRAudioDevice()
    # osc = newROsc(oscSine)
    wave = newRWave("sampleData/coin_48000.ogg")
  dev.attach(wave)
  # osc.play(440)
  dev.start()
  wave.play()
  while true:
    if wave.finished:
      wave.stop()
      wave.play()
    dev.poll()

main()

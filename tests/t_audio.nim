import os

import rapid/audio/samplers/[osc, wave]
import rapid/audio/sampler
import rapid/audio/device

proc main() =
  var
    dev = newRAudioDevice()
    osc = newROsc(oscSine)
    # wave = newRWave("sampleData/coin_48000.ogg")
  dev.attach(osc)
  osc.play(440)
  dev.start()
  # wave.play()
  while true:
    sleep(100)
    osc.freq += 16
    dev.poll()

main()

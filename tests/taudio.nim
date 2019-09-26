import os

import rapid/audio/samplers/osc
import rapid/audio/device

var
  dev = newRAudioDevice()
  sine = newROsc(oscSine)
dev.attach(sine)
dev.start()

sine.play(freq = 440)

sleep(4000)

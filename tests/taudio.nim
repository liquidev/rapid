import os
import terminal

import rapid/audio/samplers/[wave, mixer, osc]
import rapid/audio/device
import rapid/gfx

var
  dev = newRAudioDevice()
  sine = newROsc(oscSine)
dev.attach(sine)
dev.start()

sine.play(freq = 440)

sleep(4000)

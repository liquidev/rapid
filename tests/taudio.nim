import os

import rapid/audio/samplers/osc
import rapid/audio/device

var
  dev = newRAudioDevice()
  oscl = newROsc(oscSine)
dev.attach(oscl)
dev.start()

oscl.play(freq = 440)

sleep(1000)

oscl.stop()

sleep(1000)

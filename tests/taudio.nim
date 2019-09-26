import os
import terminal

import rapid/audio/samplers/[wave, mixer]
import rapid/audio/device
import rapid/gfx

var
  dev = newRAudioDevice()
  coin1 = newRWave("sampleData/coin1.ogg")
  # coin2 = newRWave("sampleData/coin2.ogg")
  mix = newRMixer()
  track1 = mix.add(coin1)
  # track2 = mix.add(coin2)
dev.attach(mix)
dev.start()

while true:
  echo "playing sound"
  coin1.stop()
  # coin2.stop()
  coin1.play()
  # coin2.play()
  sleep(1000)

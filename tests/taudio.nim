import rapid/audio/samplers/[wave, mixer]
import rapid/audio/device
import rapid/gfx

var
  win = initRWindow().open()
  surf = win.openGfx()

  dev = newRAudioDevice()
  coin1 = newRWave("sampleData/coin1.ogg")
  coin2 = newRWave("sampleData/coin2.ogg")
  mix = newRMixer()
  track1 = mix.add(coin1)
  track2 = mix.add(coin2)
dev.attach(mix)
coin1.play()
coin2.play()

dev.start()

surf.loop:
  draw ctx, step:
    ctx.clear(gray(0))
  update step:
    discard

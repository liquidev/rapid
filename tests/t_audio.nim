import rapid/audio/samplers/wave
import rapid/audio/sampler
import rapid/audio/device

proc main() =
  var
    dev = newRAudioDevice()
    wave = newRWave("sampleData/coin.ogg")
  dev.attach(wave)
  dev.play()
  wave.play()
  while true:
    dev.wait()

main()

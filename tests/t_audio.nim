import os
import unittest

import rapid

suite "audio":
  test "playback":
    var
      audio = newRAudio()
      data = dataSpec:
        "bleep" <- sound("bleep.wav")

    data.dir = "sampleData"
    data.loadAll()
    audio.data = data

    audio.play("bleep")
    sleep(1000)

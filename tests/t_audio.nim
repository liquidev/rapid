import math
import os

import rapid/lib/soundio
import glm

var seconds = 0.0
proc writeCallback(outstream: ptr SoundIoOutStream,
                   frameCountMin: cint, frameCountMax: cint) {.cdecl.} =
  let
    layout = addr outstream.layout
    sampleRate = outstream.sample_rate
    secPerFrame = 1 / sampleRate

  var
    areas: ptr UncheckedArray[SoundIoChannelArea]
    framesLeft = frame_count_max
    err: int
  while framesLeft > 0:
    var frameCount = framesLeft
    err = soundio_outstream_begin_write(outstream,
          cast[ptr ptr SoundIoChannelArea](addr areas),
          addr frameCount)
    if err != 0: raise newException(IOError, $soundio_strerror(err.cint))
    if frameCount == 0: break

    var pitch = 440.0
    let radiansPerSecond = pitch * 2 * PI
    for frame in 0..<frameCount:
      let sample = sin((seconds + frame.float * secPerFrame) * radiansPerSecond)
      for channel in 0..<layout.channel_count:
        var
          area = areas[channel]
          p = cast[ptr int16](area.`ptr`[area.step * frame].unsafeAddr)
        p[] = int16(sample * high(int16).float)
    seconds = (seconds + secPerFrame * frameCount.float) mod 1

    err = soundio_outstream_end_write(outstream)
    if err != 0: raise newException(IOError, $soundio_strerror(err.cint))

    framesLeft -= frameCount

proc main() =
  var
    err: int
    soundio = soundio_create()

  if (err = soundio_connect(soundio); err != 0):
    quit "Could not connect to audio device"

  soundio_flush_events(soundio)

  let defaultOut = soundio_default_output_device_index(soundio)
  var device = soundio_get_output_device(soundio, defaultOut)
  echo device.name
  var outstream = soundio_outstream_create(device)
  outstream.format =
    when cpuEndian == littleEndian: SoundIoFormatS16LE
    else: SoundIoFormatS16BE
  outstream.write_callback = writeCallback

  if (err = soundio_outstream_open(outstream); err != 0):
    quit "Unable to open outstream"

  if outstream.layout_error != 0:
    quit "Unable to set layout"

  if (err = soundio_outstream_start(outstream); err != 0):
    quit "Unable to start playback"

  while true:
    soundio_wait_events(soundio)

  soundio_outstream_destroy(outstream)
  soundio_device_unref(device)
  soundio_destroy(soundio)

main()

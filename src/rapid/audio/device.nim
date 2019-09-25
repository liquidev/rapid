#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## The base audio device, used for outputting audio to your speakers.

import ../lib/soundio
import audiosettings
import sampler

when not compileOption("threads"):
  {.error: "rapid/audio must be compiled with --threads:on".}

type
  AudioError* = object of CatchableError
  RAudioDeviceObj = object
    sio: ptr SoundIo
    device: ptr SoundIoDevice
    ostream: ptr SoundIoOutStream
    sampler: RSampler
    pollThread: Thread[RAudioDevice]
    gcSetup: bool
  RAudioDevice* = ref RAudioDeviceObj

proc limit(val: float): float =
  result = clamp(val, -1.0, 1.0)

proc writeCallback(outstream: ptr SoundIoOutStream,
                   frameCountMin: cint, frameCountMax: cint) {.cdecl.} =
  var error: cint

  let layout = addr outstream.layout
  var
    areas: ptr UncheckedArray[SoundIoChannelArea]
    device = cast[RAudioDevice](outstream.userdata)

  if not device.gcSetup:
    setupForeignThreadGc()

  var framesLeft = frameCountMax
  while framesLeft > 0:
    var frameCount = framesLeft

    if (error = soundio_outstream_begin_write(outstream,
          cast[ptr ptr SoundIoChannelArea](addr areas), addr frameCount);
        error != 0):
      raise newException(AudioError,
        "Could not begin writing samples: " & $soundio_strerror(error))
    if frameCount == 0:
      break

    var buffer: SampleBuffer
    device.sampler.sample(buffer, frameCount)
    if layout.channel_count == 1: # mono
      for s in 0..<frameCount:
        let
          left = s * 2
          right = left + 1
          downmixed = (buffer[left] + buffer[right]) / 2
          s16 = int16(downmixed.limit() * high(int16).float)
        var
          pt = cast[ptr int16](areas[0].`ptr`[areas[0].step * s].unsafeAddr)
        pt[] = s16
    else: # stereo
      for s in 0..<frameCount:
        let
          left = s * 2
          right = left + 1
          ls16 = int16(buffer[left].limit() * high(int16).float)
          rs16 = int16(buffer[right].limit() * high(int16).float)
        var
          lpt = cast[ptr int16](areas[0].`ptr`[areas[0].step * s].unsafeAddr)
          rpt = cast[ptr int16](areas[1].`ptr`[areas[1].step * s].unsafeAddr)
        lpt[] = ls16
        rpt[] = rs16

    if (error = soundio_outstream_end_write(outstream); error != 0):
      raise newException(AudioError,
        "Could not finish writing samples: " & $soundio_strerror(error))

    framesLeft -= frameCount

proc errorCallback(outstream: ptr SoundIoOutStream, errcode: cint) {.cdecl.} =
  raise newException(AudioError, $soundio_strerror(errcode))

proc teardownDevice(device: ref RAudioDeviceObj) =
  soundio_outstream_destroy(device.ostream)
  soundio_device_unref(device.device)
  soundio_destroy(device.sio)

proc newRAudioDevice*(name = "rapid/audio device"): RAudioDevice =
  ## Creates a new audio device, with the specified name.
  var error: cint
  new(result, teardownDevice)

  result.sio = soundio_create()
  result.sio.app_name = name
  if (error = soundio_connect(result.sio); error != 0):
    raise newException(AudioError,
      "Could not connect to an audio backend: " & $soundio_strerror(error))
  soundio_flush_events(result.sio)

  let
    deviceIndex = soundio_default_output_device_index(result.sio)
    device = soundio_get_output_device(result.sio, deviceIndex)
  result.device = device

  var outstream = soundio_outstream_create(device)
  outstream.format =
    when cpuEndian == littleEndian: SoundIoFormatS16LE
    else: SoundIoFormatS16BE
  outstream.sample_rate = ROutputSampleRate
  outstream.software_latency = 0.1
  outstream.name = "rapid/audio"
  outstream.userdata = cast[pointer](result)
  outstream.write_callback = writeCallback
  outstream.error_callback = errorCallback
  result.ostream = outstream

  if (error = soundio_outstream_open(outstream); error != 0):
    raise newException(AudioError,
      "Could not open device output stream: " & $soundio_strerror(error))

  if outstream.layout_error != 0:
    raise newException(AudioError,
      "Could not set channel layout: " &
      $soundio_strerror(outstream.layout_error))

proc attach*(device: RAudioDevice, sampler: RSampler) =
  ## Attaches a sampler to the device. This must be done before starting audio
  ## playback, otherwise a buffer underflow will occur (because there's nothing
  ## to sample from).
  ## Only one sampler may be attached, attaching more than one time will
  ## overwrite the old attachment. See ``audio/samplers/mixer`` if you want to
  ## play from multiple samplers at once.
  device.sampler = sampler

proc rawStart(device: RAudioDevice) =
  var error: cint
  if (error = soundio_outstream_start(device.ostream); error != 0):
    raise newException(AudioError,
      "Unable to start playback: " & $soundio_strerror(error))

proc devicePollThread(device: RAudioDevice) {.thread.} =
  device.rawStart()
  while true:
    soundio_flush_events(device.sio)

proc start*(device: RAudioDevice) =
  ## Starts playback from the audio device, using the attached sampler to
  ## generate audio samples.
  ## This creates a new thread in which the device is polled for any events.
  createThread(device.pollThread, devicePollThread, device)

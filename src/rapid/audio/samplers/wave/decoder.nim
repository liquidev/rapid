#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Audio file decoder interface.

import os

import ../../../lib/oggvorbis
import ../../audiosettings

type
  AudioDecodeError* = object of Exception
  RAudioDecoderKind* = enum
    adkVorbis
  RAudioDecoderObj = object
    file*: File

    channels*: int
    sampleRate*: int
    atEnd*: bool

    buffer: seq[int16]

    case kind*: RAudioDecoderKind
    of adkVorbis:
      vorbisFile: OggVorbis_File
      vorbisCurrentSection: cint
  RAudioDecoder* = ref RAudioDecoderObj

const
  OggCallbacks = ov_callbacks(
    read_func:
      proc (buf: pointer, size, nmemb: cuint, file: pointer): cuint {.cdecl.} =
        result = cast[File](file).readBuffer(buf, size * nmemb).cuint,
    seek_func:
      proc (file: pointer, offset: ogg_int64_t, whence: cint): cint {.cdecl.} =
        try:
          cast[File](file).setFilePos(offset, whence.FileSeekPos)
          result = 0
        except IOError:
          result = -1,
    close_func: nil,
    tell_func:
      proc (file: pointer): clong {.cdecl.} =
        result = cast[File](file).getFilePos().clong
  )

proc closeVorbis(decoder: RAudioDecoder) =
  discard ov_clear(addr decoder.vorbisFile)

proc closeDecoder(decoder: ref RAudioDecoderObj) =
  case decoder.kind
  of adkVorbis: decoder.closeVorbis()
  decoder.file.close()

proc newRAudioDecoder*(filename: string): RAudioDecoder =
  ## Creates a new audio decoder reading from the specified file.
  new(result, closeDecoder)

  let (_, _, ext) = filename.splitFile()
  case ext
  of ".ogg":
    result = RAudioDecoder(kind: adkVorbis)
    if result.file.open(filename):
      if ov_open_callbacks(result.file, addr result.vorbisFile, nil, 0,
                           OggCallbacks) < 0:
        raise newException(AudioDecodeError, "Invalid Ogg/Vorbis file")

      let info = ov_info(addr result.vorbisFile, -1)
      result.channels = info.channels
      result.sampleRate = info.rate
    else:
      raise newException(IOError, "Could not open file for playback")
  else:
    raise newException(AudioDecodeError,
      "Invalid audio container (currently only Ogg is supported)")

  result.buffer = newSeqOfCap[int16](AudioBufferCap)

const
  ChannelMappings: array[1..8, array[2, int]] = [
    [0, 0], [0, 1], [0, 2], [0, 1],
    [0, 2], [0, 2], [0, 2], [0, 2]
  ] ## \
  ## An array of channel mappings from the source format (array index represents
  ## number of channels) to stereo.

proc decodeVorbis(decoder: RAudioDecoder, dest: var seq[float], count: int) =
  # decode raw s16le samples
  decoder.buffer.setLen(decoder.channels * count)
  var left = count
  while left > 0:
    let decoded = ov_read(
      addr decoder.vorbisFile,
      cast[cstring](decoder.buffer[0].unsafeAddr), left.cint,
      cint(cpuEndian == bigEndian), 2, 1,
      addr decoder.vorbisCurrentSection)
    if decoded == OV_HOLE:
      raise newException(AudioDecodeError,
        "Hole in Vorbis data stream, the audio file is probably corrupted")
    elif decoded == OV_EBADLINK:
      raise newException(AudioDecodeError,
        "Invalid Vorbis stream section, the audio file is probably corrupted")
    elif decoded == OV_EBADHEADER:
      raise newException(AudioDecodeError,
        "Vorbis file headers are invalid or corrupted")
    elif decoded == 0:
      decoder.atEnd = true
      for n in 0..<left:
        for o in 0..<decoder.channels:
          decoder.buffer.add(0)
      left = 0
    else:
      left -= count
  # remap channels to stereo
  for n in 0..<count:
    let
      i = n * decoder.channels
      l = i + ChannelMappings[decoder.channels][0]
      r = i + ChannelMappings[decoder.channels][1]
    dest.add([
      decoder.buffer[l] / high(int16),
      decoder.buffer[r] / high(int16)
    ])

proc decode*(decoder: RAudioDecoder, dest: var seq[float], count: int) =
  ## Decodes an amount of samples from the source file.
  case decoder.kind
  of adkVorbis:
    decoder.decodeVorbis(dest, count)

proc seekSampleVorbis(decoder: RAudioDecoder, sample: int) =
  let result = ov_pcm_seek(addr decoder.vorbisFile, sample.ogg_int64_t)
  if result != 0:
    raise newException(AudioDecodeError,
      case result
      of OV_ENOSEEK: "File is not seekable"
      of OV_EINVAL: "Attempt to seek a closed Vorbis file"
      of OV_EREAD: "Couldn't read from media"
      of OV_EFAULT: "libvorbisfile internal logic fault, possible stack/heap " &
                    "corruption"
      of OV_EBADLINK: "Invalid Vorbis stream section, the audio file is " &
                      "probably corrupted"
      else: "An unknown error occured while seeking")

proc seekSample*(decoder: RAudioDecoder, sample: int) =
  ## Seeks to the specified PCM sample. To seek to a point in time, use
  ## ``decoder.sampleRate * time``.
  case decoder.kind
  of adkVorbis:
    decoder.seekSampleVorbis(sample)
  decoder.atEnd = false

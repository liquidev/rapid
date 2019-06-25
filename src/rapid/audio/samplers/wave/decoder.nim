#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
# licensed under the MIT license - see LICENSE file for more information
#--

## Audio file decoder interface.

import os
import streams

import ../../../lib/oggvorbis
import ../../audiosettings
import ../../samplerutils

type
  AudioDecodeError* = object of Exception
  RAudioDecoderKind* = enum
    adkVorbis
  RAudioDecoderMode* = enum
    admSample
    admStream
  RAudioDecoderObj = object
    file*: File

    channels*: int
    sampleRate*: int
    atEnd*: bool

    case mode*: RAudioDecoderMode
    of admSample:
      sampleBuffer: seq[int16]
      sample: seq[int16]
      samplePos: int
    of admStream:
      discard

    case kind*: RAudioDecoderKind
    of adkVorbis:
      vorbisFile: OggVorbis_File
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

const
  ChannelRemapTable: array[1..8, array[2, int]] = [
    [0, 0], [0, 1], [0, 2], [0, 1],
    [0, 2], [0, 2], [0, 2], [0, 2]
  ]

proc preloadVorbis(decoder: RAudioDecoder) =
  var
    readBuffer: array[4096, uint8]
    u8buffer: seq[uint8]
    atEnd = false
    bitstream: cint
  while not atEnd:
    let decoded = ov_read(
      addr decoder.vorbisFile,
      cast[cstring](readBuffer[0].unsafeAddr), sizeof(readBuffer).cint,
      cint(cpuEndian == bigEndian), 2, 1,
      addr bitstream)
    if decoded == 0:
      atEnd = true
    elif decoded > 0:
      u8buffer.add(readBuffer[0..<decoded])
    else:
      raise newException(AudioDecodeError,
        "The Vorbis file is invalid or corrupted")
  decoder.sampleBuffer.setLen(int(u8buffer.len / sizeof(int16)))
  copyMem(decoder.sampleBuffer[0].unsafeAddr, u8buffer[0].unsafeAddr,
          u8buffer.len)
  for i in 0..<int(decoder.sampleBuffer.len / decoder.channels):
    let
      offset = i * decoder.channels
      leftOffset = offset + ChannelRemapTable[decoder.channels][0]
      rightOffset = offset + ChannelRemapTable[decoder.channels][1]
    decoder.sample.add([
      decoder.sampleBuffer[leftOffset],
      decoder.sampleBuffer[rightOffset]
    ])

proc preload(decoder: RAudioDecoder) =
  case decoder.kind
  of adkVorbis:
    decoder.samplePos = 0
    decoder.preloadVorbis()

proc closeVorbis(decoder: RAudioDecoder) =
  discard ov_clear(addr decoder.vorbisFile)

proc closeDecoder(decoder: ref RAudioDecoderObj) =
  case decoder.kind
  of adkVorbis: decoder.closeVorbis()
  decoder.file.close()

proc newRAudioDecoder*(filename: string, mode = admSample): RAudioDecoder =
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

  if mode == admSample:
    result.preload()
  else:
    discard # TODO: Sample streaming

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
  ## Seeks to the specified PCM sample.
  case decoder.mode
  of admSample:
    decoder.samplePos = sample
  of admStream:
    case decoder.kind
    of adkVorbis:
      decoder.seekSampleVorbis(sample)
  decoder.atEnd = false

proc sampleAt(decoder: RAudioDecoder, i: int): int16 =
  result =
    if i in 0..<decoder.sample.len: decoder.sample[i]
    else: 0

proc read*(decoder: RAudioDecoder, dest: var seq[float], count: int) =
  case decoder.mode
  of admSample:
    for i in decoder.samplePos..<decoder.samplePos + count:
      dest.add([
        decoder.sampleAt(i * 2) / high(int16),
        decoder.sampleAt(i * 2 + 1) / high(int16)
      ])
    decoder.samplePos += count
    if decoder.samplePos * 2 > decoder.sample.len:
      decoder.atEnd = true
  of admStream:
    discard # TODO: Implement streaming samples from disk
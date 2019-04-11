#--
# rapid
# a game engine optimized for rapid prototyping
# copyright (c) 2019, iLiquid
#--

import tables

import ../data/data
import ../lib/soloud

type
  RAudio* = ref object
    soloud: ptr Soloud
    data: RData

proc newRAudio*(): RAudio =
  new(result) do (obj: RAudio):
    Soloud_deinit(obj.soloud)
  result.soloud = Soloud_create()
  discard Soloud_init(result.soloud)

proc `data=`*(audio: RAudio, data: RData) =
  audio.data = data

proc play*(audio: RAudio, snd: string) =
  discard Soloud_play(audio.soloud, audio.data.sounds[snd])

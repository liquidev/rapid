## Things essential for any game out there. This module also has a few
## submodules for things that didn't fit into any other category:
##
## - ``rapid/game/tilemap`` – tilemap with collision detection

import std/monotimes
import std/times

template runGameWhile*(cond: bool, body: untyped,
                       updateFreq: float32 = 60): untyped =
  ## Starts a fixed timestep game loop.
  ## There are two important templates available inside the loop:
  ##
  ## - ``update: <body>`` – anything inside the `<body>` runs at a constant
  ##   tick rate of ``updateFreq``
  ## - ``draw <stepName>: <body>`` – calculates the interpolation coefficient
  ##   `<stepName>` and passes it to the `<body>`
  ##
  ## There are also a few variables available inside the loop:
  ##
  ## - ``time: float64`` – time elapsed since the start of the loop, in seconds
  ## - ``delta: float64`` – time elapsed since the last frame, in seconds
  ## - ``secondsPerUpdate: float32`` – time between updates
  ##
  ## **Example:**
  ##
  ## .. code-block:: nim
  ##
  ##  import std/os
  ##
  ##  runGameWhile true:  # the condition is usually ``not win.closeRequested``
  ##    echo (time: time, delta: delta)
  ##
  ##    # process input here
  ##
  ##    update:
  ##      # tick your entities here
  ##
  ##    draw step:
  ##      # draw your entities here
  ##
  ##    sleep(20)  # this is fulfilled by ``frame.finish()``, but we don't have
  ##               # a window in this example

  block:

    var
      startTime = getMonoTime()
      previousTime = getMonoTime()
      lag: float32 = 0.0

    while cond:
      let
        currentTime = getMonoTime()
        delta {.inject.} =
          float32(inMilliseconds(currentTime - previousTime).float64 * 0.001)
      previousTime = currentTime
      lag += delta

      let
        time {.inject.} =
          inMilliseconds(currentTime - startTime).float64 * 0.001
        secondsPerUpdate {.inject.} = 1'f32 / updateFreq

      template update(updateBody: untyped): untyped {.inject.} =

        block:
          while lag >= secondsPerUpdate:
            updateBody
            lag -= secondsPerUpdate

      template draw(stepName, drawBody: untyped): untyped {.inject.} =

        block:
          let stepName {.inject.} = lag / secondsPerUpdate
          drawBody

      body

when isMainModule:

  import std/os

  runGameWhile true:
    echo (time: time, delta: delta)
    update:
      echo "running update"
    draw step:
      echo "drawing with step ", step
    sleep(20)

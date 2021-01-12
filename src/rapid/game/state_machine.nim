## "Stack-based" game state machine.

type
  StateMachine*[S: ref] = object
    ## A state machine. ``S`` is a user-provided ref state type.
    stack: seq[S]

proc check[S](sm: var StateMachine[S]) =

  if sm.stack.len == 0:
    # can't use nil here for some reason?????????
    # in general i've found that nil literals trip the compiler up in some
    # cases so there isn't much i can do about this
    sm.stack.add(default(S))

proc current*[S](sm: var StateMachine[S]): S =
  ## Returns the topmost (current) state, or ``nil`` if there are no states.

  check sm
  result = sm.stack[^1]

proc set*[S](sm: var StateMachine[S], newState: S) =
  ## Swaps the topmost state to the given state.

  check sm
  sm.stack[^1] = newState

proc push*[S](sm: var StateMachine[S], newState: S) =
  ## Pushes a new state onto the stack.

  check sm
  if sm.stack[0] == nil:
    sm.stack[0] = newState
  else:
    sm.stack.add(newState)

proc pop*[S](sm: var StateMachine[S]) =
  ## Pops a state off the stack.

  check sm
  sm.stack.setLen(sm.len - 1)

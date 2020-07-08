## Various assorted math utilities that don't fit into any other module.

# ↓ I'd use slices here, but type conversions in Nim are rather funky when
#   dealing with generic types, which leads to verbose code containing lots of
#   type conversions
func mapRange*[T: SomeFloat](value, min0, max0, min1, max1: T): T =
  ## Remaps ``value`` from range ``min0..max0`` to ``min1..max1``.
  result = (value - min0) / (max0 - min0) * (max1 - min1) + min1

func closeTo*[T: SomeFloat](value, epsilon: T): bool =
  ## Returns whether ``value`` is close to ``epsilon``
  ## (``value in -epsilon..epsilon``).
  value in -epsilon..epsilon

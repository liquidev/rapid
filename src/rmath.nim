proc mapr*(s, a1, a2, b1, b2: float): float =
  ## Maps a number from range ``{ a1..a2 }`` to another number range ``{ b1..b2 }``.
  result = b1 + (s - a1) * (b2 - b1) / (a2 - a1)

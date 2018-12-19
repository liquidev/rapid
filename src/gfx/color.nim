type
  RColor* = object
    ri*, gi*, bi*, ai*: uint8
    rf*, gf*, bf*, af*: float

proc color*(r, g, b, a: uint8): RColor =
  return RColor(
    ri: r, gi: g, bi: b, ai: a,
    rf: r.float / 255.0, gf: g.float / 255.0, bf: b.float / 255.0, af: a.float / 255.0
  )

proc color*(r, g, b, a: float): RColor =
  return RColor(
    ri: r.uint8 * 255, gi: g.uint8 * 255, bi: b.uint8 * 255, ai: a.uint8 * 255,
    rf: r, gf: g, bf: b, af: a
  )

template color*(r, g, b, a: int): untyped =
  color(r.uint8, g.uint8, b.uint8, a.uint8)

template color*(r, g, b: int): untyped =
  color(r, g, b, 255)

template color*(r, g, b: float): untyped =
  color(r, g, b, 1.0)

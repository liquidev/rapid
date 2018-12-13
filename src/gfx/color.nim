type
  RColor* = object
    redi*, greeni*, bluei*, alphai*: uint8
    redf*, greenf*, bluef*, alphaf*: float

proc color*(r, g, b, a: uint8): RColor =
  return RColor(
    redi: r, greeni: g, bluei: b, alphai: a,
    redf: r.float / 255.0, greenf: g.float / 255.0, bluef: b.float / 255.0
  )

proc color*(r, g, b, a: float): RColor =
  return RColor(
    redi: r.uint8 * 255, greeni: g.uint8 * 255, bluei: b.uint8 * 255, alphai: a.uint8 * 255,
    redf: r, greenf: g, bluef: b, alphaf: a
  )

template color*(r, g, b, a: int): untyped =
  color(r.uint8, g.uint8, b.uint8, a.uint8)

template color*(r, g, b: int): untyped =
  color(r, g, b, 255)

template color*(r, g, b: float): untyped =
  color(r, g, b, 1.0)

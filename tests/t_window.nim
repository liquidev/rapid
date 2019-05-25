import glm

import times

import rapid/res/textures
import rapid/res/fonts
import rapid/gfx/texatlas
import rapid/gfx/surface
import rapid/gfx/text
import rapid/lib/glad/gl
import rapid/world/sprite
import rapid/world/tilemap

type
  Tile = object
    tileX, tileY: int
    solid: bool

proc initTile*(): Tile =
  result.tileX = 0
  result.tileY = 0
  result.solid = false

proc isSolid*(t: Tile): bool =
  result = t.solid

proc tt(x, y: int): Tile = Tile(tileX: x, tileY: y, solid: false)
proc at(): Tile = tt(0, 0)
proc st(x, y: int): Tile = Tile(tileX: x, tileY: y, solid: true)

type
  Player = ref object of RSprite
    win: RWindow

method draw(plr: var Player, ctx: var RGfxContext, step: float) =
  ctx.begin()
  ctx.color = gray(255)
  ctx.noTexture()
  transform(ctx):
    ctx.translate(plr.pos.x * 4 + 16, plr.pos.y * 4 + 16)
    # ctx.rotate(cpuTime() * 100)
    ctx.rect(-16, -16, 32, 32)
  ctx.draw()

method update(plr: var Player, step: float) =
  #echo plr
  const
    v = 0.3
    g = 0.2
  plr.force(vec2(0.0, g))
  if plr.win.key(keyLeft) == kaDown:
    plr.force(vec2(-v, 0.0))
  if plr.win.key(keyRight) == kaDown:
    plr.force(vec2(v, 0.0))
  plr.vel.x *= 0.8

proc newPlayer(win: var RWindow, x, y: float): Player =
  result = Player(win: win, width: 8, height: 8)

  let plr = result
  win.onKeyPress do (win: RWindow, key: Key, scancode: int, mods: RModKeys):
    if key == keyUp:
      plr.force(vec2(0.0, -3.0))

let Map = [
  [at(),     at(),     at(),     at(),     at(),     at(),     at(),     at()],
  [at(),     at(),     at(),     at(),     at(),     at(),     at(),     at()],
  [at(),     at(),     at(),     st(0, 1), st(2, 1), at(),     at(),     at()],
  [at(),     at(),     at(),     at(),     at(),     at(),     at(),     at()],
  [at(),     at(),     st(0, 1), st(1, 1), st(1, 1), st(2, 1), at(),     at()],
  [at(),     at(),     st(0, 1), st(2, 1), at(),     at(),     at(),     at()],
  [at(),     at(),     st(0, 1), st(2, 1), at(),     at(),     at(),     at()],
  [st(0, 1), st(1, 1), st(1, 1), st(1, 1), st(1, 1), st(1, 1), st(1, 1), st(2, 1)]
]

proc main() =
  var
    win = initRWindow()
      .size(640, 480)
      .title("A rapid window")
      .open()
    tc = (
      minFilter: fltNearest, magFilter: fltNearest,
      wrapH: wrapRepeat, wrapV: wrapRepeat)
    tileset = loadRTexture("sampleData/tileset.png", tc)
    rubik = newRFont("sampleData/Rubik-Regular.ttf", tc, 14)
    gfx = win.openGfx()
    map = newRTmWorld[Tile](Map[0].len, Map.len, 8, 8)

  let atl = newRAtlas(tileset, 8, 8, 1)

  map.implTile(initImpl = initTile, isSolidImpl = isSolid)
  map.init()
  map.load(Map)

  proc drawMap(ctx: var RGfxContext, wld: RTmWorld[Tile], step: float) =
    ctx.begin()
    ctx.texture = tileset
    for x, y, t in tiles(wld):
      ctx.rect(x.float * 32, y.float * 32, 32, 32, atl.rect(t.tileX, t.tileY))
    ctx.draw()
    wld.drawSprites(ctx, step)
  map.drawImpl = drawMap

  map.sprites.add(newPlayer(win, 0, 0))

  var
    x, y = 0.0
    pressed = false

  win.onCursorMove do (win: RWindow, cx, cy: float):
    x = cx
    y = cy

  win.onMousePress do (win: RWindow, btn: MouseButton, mods: RModKeys):
    pressed = true
  win.onMouseRelease do (win: RWindow, btn: MouseButton, mods: RModKeys):
    pressed = false

  let quantize = gfx.newREffect("""
    #define Quantize 4.0

    vec4 rEffect(vec2 pos) {
      vec2 quantized = floor(pos / Quantize) * Quantize;
      return rPixel(quantized + 0.5);
    }
  """)

  rubik.horzAlign = taCenter

  gfx.loop:
    draw ctx, step:
      ctx.clear(rgb(32, 32, 32))
      effects(ctx):
        map.draw(ctx, step)
        ctx.effect(quantize)
      ctx.text(rubik, gfx.width / 2, 0, "effect testing")
    update step:
      map.update(step)

main()

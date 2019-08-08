import glm

import random
import times

import rapid/res/[textures, fonts]
import rapid/gfx, rapid/gfx/[fxsurface, texatlas, text]
import rapid/lib/glad/gl
import rapid/world/[aabb, sprite, tilemap]

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

proc hitbox(x, y: float, t: Tile): RAABounds =
  result = newRAABB(x * 8, y * 8, 8, 8)

proc tt(x, y: int): Tile = Tile(tileX: x, tileY: y, solid: false)
proc at(): Tile = tt(0, 0)
proc st(x, y: int): Tile = Tile(tileX: x, tileY: y, solid: true)

type
  Player = ref object of RSprite
    win: RWindow

method draw(plr: Player, ctx: RGfxContext, step: float) =
  ctx.begin()
  ctx.color = rgb(0, 128, 255)
  ctx.noTexture()
  ctx.transform():
    ctx.translate(plr.pos.x * 4 + 16, plr.pos.y * 4 + 16)
    ctx.rect(-16, -16, 32, 32)
  ctx.color = gray(255)
  ctx.draw()

method update(plr: Player, step: float) =
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

proc drawWindow(ctx: RGfxContext, fx: RFxSurface, eff: REffect,
                x, y, w, h: float) =
  fx.begin(ctx, copyTarget = true)

  ctx.clearStencil(0)
  ctx.stencil(saReplace, 255):
    ctx.begin()
    ctx.rrect(x, y, w, h, 8)
    ctx.draw()

  ctx.stencilTest = (scEq, 255)
  fx.effect(eff, stencil = true)
  fx.effect(eff, stencil = true)
  ctx.noStencilTest()

  fx.finish()

  ctx.begin()
  ctx.color = gray(0, 128)
  ctx.rrect(x, y, w, h, 8)
  ctx.draw()

  ctx.begin()
  ctx.color = gray(255)
  ctx.lrrect(x, y, w, h, 8)
  ctx.draw(prLineShape)

proc main() =
  var
    win = initRWindow()
      .size(640, 480)
      .title("twindow")
      .open()
    tc = (
      minFilter: fltNearest, magFilter: fltNearest,
      wrapH: wrapRepeat, wrapV: wrapRepeat)
    tileset = loadRTexture("sampleData/tileset.png", tc)
    rubik = newRFont("sampleData/Rubik-Regular.ttf", 14, 14, tc)
    gfx = win.openGfx()
    map = newRTmWorld[Tile](Map[0].len, Map.len, 8, 8)
    mapCanvas = newRCanvas(win)
    fx = newRFxSurface(gfx.canvas)

  let atl = newRAtlas(tileset, 8, 8, 1)

  map.implTile(initImpl = initTile, isSolidImpl = isSolid, hitboxImpl = hitbox)
  map.init()
  map.load(Map)

  proc drawMap(ctx: RGfxContext, wld: RTmWorld[Tile], step: float) =
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

  let eff = fx.newREffect("""
    vec4 rEffect(vec2 pos) {
      vec4 avg = vec4(0.0);
      for (int y = -3; y <= 3; ++y) {
        for (int x = -3; x <= 3; ++x) {
          avg += rPixel(pos + vec2(x, y));
        }
      }
      avg /= 7.0 * 7.0;
      return avg;
    }
  """)

  rubik.horzAlign = taCenter

  render(gfx, ctx):
    ctx.clearStencil(255)
    ctx.lineSmooth = true
    ctx.lineWidth = 1

  gfx.loop:
    init ctx:
      discard ctx
    draw ctx, step:
      ctx.clear(gray(32))
      ctx.clearStencil(255)

      renderTo(ctx, mapCanvas):
        ctx.clear(gray(0, 0))
        map.draw(ctx, step)

      ctx.begin()
      ctx.texture = mapCanvas
      ctx.rect(0, 0, gfx.width.float, gfx.height.float)
      ctx.draw()
      ctx.noTexture()
      # ctx.drawWindow(fx, eff, 32, 32, 128, 128)
    update step:
      map.update(step)

main()

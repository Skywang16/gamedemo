"""Street furniture baked into terrain: fences, lamps, flower beds, hedges, stalls, crates.

Everything is drawn on the 32px cell grid with a dark outline, a lit upper-left edge and
a soft contact shadow, so objects sit on the ground instead of floating on it. The map
scripts add matching collision rectangles for the solid pieces (see SOLID below).
"""

from PIL import Image, ImageDraw
import random

CELL = 32
OUT = "#2f2a22"

# Kinds that block movement, as (width, height) in cells unless the entry says otherwise.
SOLID = {
    "lamp",
    "hedge",
    "crates",
    "barrel",
    "signpost",
    "hay",
    "trough",
    "stall",
    "rocks",
    "cart",
    "planter",
    "flowerbed",
}


def shade(layer, cx, cy, rx, ry, alpha=70):
    ImageDraw.Draw(layer).ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=(24, 36, 26, alpha))


def lamp(d, layer, x, y, w, h, rng):
    cx, base = x + CELL // 2, y + CELL - 4
    shade(layer, cx, base + 1, 9, 3)
    d.rectangle((cx - 5, base - 5, cx + 4, base), fill="#6a665c")
    d.rectangle((cx - 4, base - 5, cx + 3, base - 4), fill="#a29c8c")
    d.rectangle((cx - 2, base - 44, cx + 1, base - 5), fill=OUT)
    d.rectangle((cx - 1, base - 43, cx, base - 6), fill="#4a4a54")
    d.rectangle((cx - 7, base - 58, cx + 6, base - 44), fill=OUT)
    d.rectangle((cx - 5, base - 56, cx + 4, base - 46), fill="#f4d878")
    d.rectangle((cx - 4, base - 55, cx - 1, base - 50), fill="#fff4c0")
    d.polygon([(cx - 8, base - 58), (cx + 7, base - 58), (cx, base - 65)], fill=OUT)
    ImageDraw.Draw(layer).ellipse(
        (cx - 22, base - 74, cx + 21, base - 28), fill=(255, 226, 140, 26)
    )


def fence_run(d, layer, x0, y0, x1, y1, style="wood"):
    horizontal = y0 == y1
    cells = range(x0, x1 + 1) if horizontal else range(y0, y1 + 1)
    wood, light, dark = (
        ("#b98d57", "#dcb67a", "#6e4f30") if style == "wood" else ("#8a8678", "#b4b0a0", "#58554a")
    )
    for i in cells:
        cx = (i if horizontal else x0) * CELL + CELL // 2
        cy = (y0 if horizontal else i) * CELL + CELL // 2
        shade(layer, cx, cy + 12, 8, 3, 60)
    if horizontal:
        left, right = x0 * CELL + 4, (x1 + 1) * CELL - 4
        cy = y0 * CELL + CELL // 2
        for dy in (4, 12):
            d.rectangle((left, cy + dy - 8, right, cy + dy - 4), fill=dark)
            d.rectangle((left, cy + dy - 8, right, cy + dy - 6), fill=wood)
            d.line((left, cy + dy - 8, right, cy + dy - 8), fill=light)
    else:
        top, bottom = y0 * CELL + 2, (y1 + 1) * CELL - 2
        cx = x0 * CELL + CELL // 2
        d.rectangle((cx - 2, top, cx + 2, bottom), fill=dark)
        d.rectangle((cx - 2, top, cx, bottom), fill=wood)
        d.line((cx - 2, top, cx - 2, bottom), fill=light)
    for i in cells:
        cx = (i if horizontal else x0) * CELL + CELL // 2
        cy = (y0 if horizontal else i) * CELL + CELL // 2
        d.rectangle((cx - 3, cy - 12, cx + 3, cy + 12), fill=dark)
        d.rectangle((cx - 2, cy - 12, cx + 1, cy + 11), fill=wood)
        d.line((cx - 2, cy - 12, cx - 2, cy + 10), fill=light)
        d.rectangle((cx - 3, cy - 14, cx + 3, cy - 12), fill=light)


def flowerbed(d, layer, x, y, w, h, rng):
    px, py, pw, ph = x + 2, y + 6, w * CELL - 4, h * CELL - 8
    shade(layer, px + pw // 2, py + ph, pw // 2, 4, 60)
    d.rounded_rectangle((px, py, px + pw, py + ph), radius=4, fill="#5a3e28")
    d.rounded_rectangle((px + 2, py + 2, px + pw - 2, py + ph - 2), radius=3, fill="#7a5a3a")
    d.rounded_rectangle((px + 4, py + 4, px + pw - 4, py + ph - 3), radius=2, fill="#5a4030")
    colors = ["#e8587a", "#f4c84a", "#f4f0e8", "#a878d8", "#e8884a", "#78b8e8"]
    for _ in range(max(4, pw * ph // 90)):
        fx = rng.randrange(px + 7, px + pw - 7)
        fy = rng.randrange(py + 7, py + ph - 5)
        c = rng.choice(colors)
        d.line((fx, fy, fx, fy + 5), fill="#3f7a3a")
        d.rectangle((fx - 2, fy - 3, fx + 2, fy + 1), fill=c)
        d.point((fx, fy - 1), fill="#fff4b0")
        d.point((fx - 1, fy - 2), fill="#ffffff")


def hedge(d, layer, x, y, w, h, rng):
    shade(layer, x + w * CELL // 2, y + h * CELL - 3, w * CELL // 2, 4, 70)
    greens = ["#2f5a34", "#3f7040", "#528a4a", "#6aa058"]
    for i in range(w * 4):
        cx = x + 6 + i * 8
        cy = y + h * CELL - 14 + (i % 2) * 2
        d.ellipse((cx - 9, cy - 12, cx + 9, cy + 8), fill=OUT)
    for i in range(w * 4):
        cx = x + 6 + i * 8
        cy = y + h * CELL - 14 + (i % 2) * 2
        d.ellipse((cx - 8, cy - 11, cx + 8, cy + 7), fill=greens[1 + i % 2])
        d.ellipse((cx - 6, cy - 10, cx + 3, cy), fill=greens[2])
        d.point((cx - 3, cy - 7), fill=greens[3])
    for _ in range(w * 4):
        d.point(
            (x + rng.randrange(4, w * CELL - 4), y + h * CELL - rng.randrange(10, 26)),
            fill=rng.choice(["#f4e8a0", "#e8a8b8"]),
        )


def crates(d, layer, x, y, w, h, rng):
    shade(layer, x + 16 * w, y + 28, 14 * w, 4)
    for i in range(w):
        bx, by = x + 3 + i * 32, y + 12
        d.rectangle((bx, by, bx + 26, by + 18), fill=OUT)
        d.rectangle((bx + 1, by + 1, bx + 25, by + 17), fill="#b98d57")
        d.rectangle((bx + 1, by + 1, bx + 25, by + 4), fill="#dcb67a")
        d.line((bx + 1, by + 9, bx + 25, by + 9), fill="#7a5a36")
        d.line((bx + 13, by + 1, bx + 13, by + 17), fill="#7a5a36")
        if i % 2 == 0:
            d.rectangle((bx + 5, by - 8, bx + 21, by), fill=OUT)
            d.rectangle((bx + 6, by - 7, bx + 20, by - 1), fill="#a87c48")
            d.rectangle((bx + 6, by - 7, bx + 20, by - 5), fill="#c89c62")


def barrel(d, layer, x, y, w, h, rng):
    cx = x + 16
    shade(layer, cx, y + 28, 12, 4)
    d.ellipse((cx - 11, y + 4, cx + 11, y + 28), fill=OUT)
    d.rectangle((cx - 11, y + 10, cx + 11, y + 22), fill=OUT)
    d.rectangle((cx - 10, y + 10, cx + 10, y + 22), fill="#9a6a3a")
    d.ellipse((cx - 10, y + 5, cx + 10, y + 17), fill="#b88a52")
    d.ellipse((cx - 7, y + 7, cx + 7, y + 14), fill="#8a5e32")
    for yy in (13, 20):
        d.line((cx - 10, y + yy, cx + 10, y + yy), fill="#4a4a54", width=2)
    d.line((cx - 8, y + 11, cx - 8, y + 22), fill="#d0a060")


def signpost(d, layer, x, y, w, h, rng):
    cx = x + 16
    shade(layer, cx, y + 29, 9, 3)
    d.rectangle((cx - 2, y + 6, cx + 1, y + 29), fill=OUT)
    d.rectangle((cx - 1, y + 7, cx, y + 28), fill="#8a6038")
    d.polygon(
        [(cx - 14, y + 7), (cx + 8, y + 7), (cx + 14, y + 12), (cx + 8, y + 17), (cx - 14, y + 17)],
        fill=OUT,
    )
    d.polygon(
        [(cx - 13, y + 8), (cx + 7, y + 8), (cx + 12, y + 12), (cx + 7, y + 16), (cx - 13, y + 16)],
        fill="#d8b878",
    )
    d.line((cx - 11, y + 9, cx + 6, y + 9), fill="#f0d898")
    for k in range(3):
        d.line((cx - 10 + k * 6, y + 12, cx - 7 + k * 6, y + 12), fill="#6a4a28")


def hay(d, layer, x, y, w, h, rng):
    cx = x + 16
    shade(layer, cx, y + 28, 13, 4)
    d.ellipse((cx - 13, y + 6, cx + 13, y + 29), fill=OUT)
    d.ellipse((cx - 12, y + 7, cx + 12, y + 28), fill="#d8b858")
    d.ellipse((cx - 9, y + 9, cx + 3, y + 19), fill="#ecd480")
    for k in range(6):
        d.line((cx - 10 + k * 3, y + 12 + (k % 2) * 6, cx - 4 + k * 3, y + 24), fill="#a88828")
    d.arc((cx - 8, y + 11, cx + 8, y + 25), 20, 200, fill="#b89838")


def trough(d, layer, x, y, w, h, rng):
    shade(layer, x + w * 16, y + 28, w * 14, 4)
    d.rounded_rectangle((x + 3, y + 10, x + w * CELL - 3, y + 28), radius=3, fill=OUT)
    d.rounded_rectangle((x + 4, y + 11, x + w * CELL - 4, y + 27), radius=3, fill="#9a6a3a")
    d.rounded_rectangle((x + 7, y + 13, x + w * CELL - 7, y + 21), radius=2, fill="#4a86a8")
    d.line((x + 9, y + 15, x + w * CELL - 12, y + 15), fill="#9ad0e8")
    d.line((x + 4, y + 11, x + w * CELL - 4, y + 11), fill="#c89458")


def stall(d, layer, x, y, w, h, rng):
    px, pw = x + 4, w * CELL - 8
    shade(layer, x + w * 16, y + h * CELL - 5, w * 14, 5)
    d.rectangle((px + 2, y + 18, px + 6, y + h * CELL - 4), fill="#4a3220")
    d.rectangle((px + pw - 6, y + 18, px + pw - 2, y + h * CELL - 4), fill="#4a3220")
    d.rectangle((px + 6, y + h * CELL - 26, px + pw - 6, y + h * CELL - 6), fill=OUT)
    d.rectangle((px + 8, y + h * CELL - 24, px + pw - 8, y + h * CELL - 8), fill="#a87c48")
    d.rectangle((px + 8, y + h * CELL - 24, px + pw - 8, y + h * CELL - 21), fill="#d0a468")
    colors = rng.choice(
        [
            ("#c8403a", "#f4ecd8"),
            ("#3f7a9a", "#f4ecd8"),
            ("#4a9a52", "#f4ecd8"),
            ("#d89a30", "#f4ecd8"),
        ]
    )
    stripes = pw // 12
    for i in range(stripes):
        sx = px + i * (pw // stripes)
        d.polygon(
            [
                (sx, y + 6),
                (sx + pw // stripes, y + 6),
                (sx + pw // stripes - 1, y + 22),
                (sx + 1, y + 22),
            ],
            fill=colors[i % 2],
        )
    d.line((px, y + 6, px + pw, y + 6), fill=OUT, width=2)
    d.line((px, y + 22, px + pw, y + 22), fill=OUT, width=2)
    for i in range(stripes):
        sx = px + i * (pw // stripes)
        d.pieslice((sx, y + 18, sx + pw // stripes, y + 28), 0, 180, fill=colors[i % 2])
    goods = ["#d8402f", "#f0c53a", "#6aa850", "#e8884a", "#f4ecd8", "#a85a8a"]
    for i in range(pw // 12):
        gx = px + 10 + i * 12
        d.ellipse((gx, y + h * CELL - 32, gx + 8, y + h * CELL - 24), fill=rng.choice(goods))
        d.point((gx + 2, y + h * CELL - 31), fill="#ffffff")


def rocks(d, layer, x, y, w, h, rng):
    shade(layer, x + w * 16, y + h * CELL - 4, w * 13, 4)
    for _ in range(w * 3):
        cx = rng.randrange(x + 8, x + w * CELL - 8)
        cy = rng.randrange(y + h * CELL - 18, y + h * CELL - 6)
        r = rng.randrange(5, 10)
        d.ellipse((cx - r, cy - r + 2, cx + r, cy + r // 2 + 4), fill=OUT)
        d.ellipse(
            (cx - r + 1, cy - r + 3, cx + r - 1, cy + r // 2 + 3),
            fill=rng.choice(["#8a8a92", "#9a9aa2", "#7a7a84"]),
        )
        d.ellipse((cx - r + 2, cy - r + 4, cx, cy - 1), fill="#b8b8be")


def cart(d, layer, x, y, w, h, rng):
    shade(layer, x + w * 16, y + 28, w * 14, 4)
    d.rectangle((x + 5, y + 8, x + w * CELL - 5, y + 24), fill=OUT)
    d.rectangle((x + 7, y + 10, x + w * CELL - 7, y + 22), fill="#9a6a3a")
    d.rectangle((x + 7, y + 10, x + w * CELL - 7, y + 13), fill="#c89458")
    for i in range(6):
        d.line(
            (x + 10 + i * 8, y + 4 + (i % 2) * 3, x + 14 + i * 8, y + 12), fill="#d8b858", width=2
        )
    for wx in (x + 12, x + w * CELL - 12):
        d.ellipse((wx - 7, y + 17, wx + 7, y + 31), fill=OUT)
        d.ellipse((wx - 5, y + 19, wx + 5, y + 29), fill="#8a5e32")
        d.ellipse((wx - 1, y + 23, wx + 1, y + 25), fill=OUT)


def planter(d, layer, x, y, w, h, rng):
    cx = x + 16
    shade(layer, cx, y + 28, 11, 3)
    d.rectangle((cx - 9, y + 16, cx + 9, y + 28), fill=OUT)
    d.rectangle((cx - 8, y + 17, cx + 8, y + 27), fill="#b8704a")
    d.rectangle((cx - 8, y + 17, cx + 8, y + 19), fill="#d89870")
    for dx in (-6, 0, 6):
        d.ellipse((cx + dx - 5, y + 5, cx + dx + 5, y + 17), fill="#3f7a3a")
    for dx, c in ((-5, "#e8587a"), (1, "#f4c84a"), (6, "#f4f0e8")):
        d.ellipse((cx + dx - 2, y + 5, cx + dx + 2, y + 9), fill=c)


KINDS = {
    "lamp": lamp,
    "flowerbed": flowerbed,
    "hedge": hedge,
    "crates": crates,
    "barrel": barrel,
    "signpost": signpost,
    "hay": hay,
    "trough": trough,
    "stall": stall,
    "rocks": rocks,
    "cart": cart,
    "planter": planter,
}


def draw_decor(im, region):
    """Draws region["fences"] and region["decor"] onto the terrain image."""
    fences = region.get("fences", [])
    decor = region.get("decor", [])
    if not fences and not decor:
        return im
    rng = random.Random(991 + sum(map(ord, region["id"])))
    base = im.convert("RGBA")
    shadows = Image.new("RGBA", im.size, (0, 0, 0, 0))
    objects = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(objects)
    for f in fences:
        fence_run(d, shadows, f[0], f[1], f[2], f[3], f[4] if len(f) > 4 else "wood")
    # Back to front, so nearer objects overlap farther ones.
    for e in sorted(decor, key=lambda e: e["cell"][1]):
        KINDS[e["kind"]](
            d, shadows, e["cell"][0] * CELL, e["cell"][1] * CELL, e.get("w", 1), e.get("h", 1), rng
        )
    base.alpha_composite(shadows)
    base.alpha_composite(objects)
    return base.convert("RGB")

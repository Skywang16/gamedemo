"""The five shop rooms: a shared shell (floor, walls, windows, door, counter) plus furniture
drawn from tools/world/shop_layouts.py, so what you see is what blocks you.

Everything is drawn pixel by pixel with ImageDraw primitives: a light edge on the top and left, a
dark edge on the bottom and right (light comes from the upper left), and a one-pixel dark outline.
"""

from pathlib import Path
import random
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "world"))
from shop_layouts import SHOP_FURNITURE  # noqa: E402

CELL = 32


def hexrgb(c):
    c = c.lstrip("#")
    return tuple(int(c[i : i + 2], 16) for i in (0, 2, 4))


def tone(c, k):
    """Lighten (k > 1) or darken (k < 1) a colour."""
    r, g, b = hexrgb(c) if isinstance(c, str) else c
    if k >= 1:
        r, g, b = (int(v + (255 - v) * (k - 1)) for v in (r, g, b))
    else:
        r, g, b = (int(v * k) for v in (r, g, b))
    return "#%02x%02x%02x" % (min(r, 255), min(g, 255), min(b, 255))


THEMES = {
    "general_store": {
        "wall": "#a9bd94",
        "trim": "#6d8a5a",
        "floor": "#b48e5c",
        "rug": "#5e8456",
        "accent": "#3f704a",
        "tile": "plank",
        "windows": [540],
    },
    "blacksmith": {
        "wall": "#6e6e7a",
        "trim": "#44444e",
        "floor": "#7f7368",
        "rug": "#4a4038",
        "accent": "#c8603a",
        "tile": "slab",
        "windows": [],
    },
    "clinic": {
        "wall": "#dde6e1",
        "trim": "#9fb9b2",
        "floor": "#cfd0c0",
        "rug": "#a8c8c0",
        "accent": "#c83a3a",
        "tile": "check",
        "windows": [590],
    },
    "tackle_shop": {
        "wall": "#8fb0bf",
        "trim": "#4f7389",
        "floor": "#a58666",
        "rug": "#4a7a9a",
        "accent": "#3f5f84",
        "tile": "plank",
        "windows": [],
    },
    "tea_house": {
        "wall": "#cdaa7a",
        "trim": "#8a5a3a",
        "floor": "#8d6442",
        "rug": "#a8483a",
        "accent": "#7a3a2a",
        "tile": "plank",
        "windows": [],
    },
}

WOOD = "#b88a52"
WOOD_DARK = "#5a3e28"
OUTLINE = "#2c2018"


def rect(d, box, color):
    d.rectangle(box, fill=color)


def solid(d, box, base, outline=OUTLINE):
    """A lit block: light top/left edge, dark bottom/right edge, dark outline."""
    x0, y0, x1, y1 = box
    rect(d, box, outline)
    rect(d, (x0 + 1, y0 + 1, x1 - 1, y1 - 1), base)
    d.line((x0 + 1, y0 + 1, x1 - 1, y0 + 1), fill=tone(base, 1.35))
    d.line((x0 + 1, y0 + 1, x0 + 1, y1 - 1), fill=tone(base, 1.2))
    d.line((x0 + 1, y1 - 1, x1 - 1, y1 - 1), fill=tone(base, 0.7))
    d.line((x1 - 1, y0 + 1, x1 - 1, y1 - 1), fill=tone(base, 0.78))


_IM = None  # the image being drawn; shadows are blended into it


def blend(box, alpha, ellipse=False):
    """Darken the pixels in `box` by `alpha` (0-255) without replacing them."""
    x0, y0, x1, y1 = (int(v) for v in box)
    patch = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    pd = ImageDraw.Draw(patch)
    shape = pd.ellipse if ellipse else pd.rectangle
    shape((0, 0, x1 - x0 - 1, y1 - y0 - 1), fill=(0, 0, 0, alpha))
    _IM.alpha_composite(patch, (x0, y0))


def shadow(d, box):
    """A soft contact shadow under a piece of furniture (drawn first)."""
    x0, y0, x1, y1 = box
    blend((x0 + 3, y1 - 6, x1 + 4, y1 + 3), 56)


def planks(d, box, base, vertical=False):
    x0, y0, x1, y1 = box
    rect(d, box, base)
    step = 8
    if vertical:
        for x in range(x0 + step, x1, step):
            d.line((x, y0 + 1, x, y1 - 1), fill=tone(base, 0.78))
    else:
        for y in range(y0 + step, y1, step):
            d.line((x0 + 1, y, x1 - 1, y), fill=tone(base, 0.78))


# ---------------------------------------------------------------------------- the shell


def floor(d, kind, t):
    base = t["floor"]
    rect(d, (128, 128, 800, 512), base)
    if t["tile"] == "plank":
        for row, y in enumerate(range(128, 512, 24)):
            d.line((128, y, 800, y), fill=tone(base, 0.72), width=2)
            offset = (row * 53) % 128
            for x in range(128 + offset, 800, 128):
                d.line((x, y, x, y + 22), fill=tone(base, 0.82))
            rng = random.Random(row * 31 + len(kind))
            for _ in range(7):
                x = rng.randrange(132, 790)
                d.line((x, y + 8, x + rng.randrange(6, 18), y + 8), fill=tone(base, 1.12))
    elif t["tile"] == "slab":
        for row, y in enumerate(range(128, 512, 32)):
            for x in range(128 + (row % 2) * 32, 800, 64):
                rect(d, (x, y, x + 62, y + 30), tone(base, 1.04 if (x + y) % 128 else 0.94))
                d.line((x, y, x + 62, y), fill=tone(base, 1.18))
                d.line((x, y + 31, x + 63, y + 31), fill=tone(base, 0.66))
    else:
        for row, y in enumerate(range(128, 512, 32)):
            for col, x in enumerate(range(128, 800, 32)):
                rect(d, (x, y, x + 31, y + 31), tone(base, 1.1 if (row + col) % 2 else 0.95))
                d.line((x, y, x + 31, y), fill=tone(base, 1.25))
    # The floor falls into shade under the back wall.
    for i in range(10):
        blend((128, 128 + i, 800, 129 + i), 14 - i)


def walls(d, kind, t):
    wall, trim = t["wall"], t["trim"]
    rect(d, (96, 48, 832, 128), wall)
    for x in range(96, 832, 32):
        d.line((x, 56, x, 98), fill=tone(wall, 0.92))
    rect(d, (96, 98, 832, 128), trim)  # wainscot
    for x in range(104, 790, 48):
        rect(d, (x, 102, x + 36, 122), tone(trim, 1.1))
        d.rectangle((x, 102, x + 36, 122), outline=tone(trim, 0.7))
    rect(d, (96, 94, 832, 100), tone(trim, 1.3))
    rect(d, (96, 44, 832, 50), tone(wall, 0.6))
    rect(d, (96, 48, 128, 544), tone(wall, 0.85))
    rect(d, (800, 48, 832, 544), tone(wall, 0.8))
    rect(d, (96, 512, 832, 548), tone(wall, 0.7))
    for x in t["windows"]:
        rect(d, (x - 2, 58, x + 80, 108), "#4a3c2a")
        rect(d, (x + 3, 63, x + 75, 103), "#a8d0e0")
        rect(d, (x + 3, 63, x + 75, 76), "#cfe8f0")
        d.line((x + 39, 62, x + 39, 104), fill="#d8c390", width=4)
        d.line((x + 2, 83, x + 76, 83), fill="#d8c390", width=3)
        rect(d, (x - 4, 104, x + 82, 110), "#7a5a38")


def door(d, t):
    rect(d, (416, 512, 512, 548), "#3a2c20")
    rect(d, (424, 512, 504, 544), "#c9ac7a")
    for x in range(428, 504, 12):
        d.line((x, 514, x, 542), fill="#a88a58")
    rect(d, (352, 420, 575, 486), t["rug"])
    rect(d, (358, 426, 569, 480), tone(t["rug"], 1.15))
    d.rectangle((358, 426, 569, 480), outline=tone(t["rug"], 0.7), width=2)
    d.rectangle((366, 434, 561, 472), outline=tone(t["rug"], 1.4))


def counter(d, t):
    """The shop counter across the middle of the back; the keeper stands behind it."""
    blend((288, 224, 676, 234), 70)
    solid(d, (288, 160, 672, 224), WOOD_DARK)
    rect(d, (292, 164, 668, 190), "#d8b078")
    d.line((292, 190, 668, 190), fill="#a87c44", width=2)
    rect(d, (292, 192, 668, 220), WOOD)
    for x in range(300, 664, 64):
        d.rectangle((x, 196, x + 52, 216), outline="#7a5a36")
        d.rectangle((x + 4, 200, x + 48, 212), outline=tone(WOOD, 1.2))


# ---------------------------------------------------------------------------- pieces


def jar(d, x, y, body, lid="#7a5a38", h=22, w=14):
    rect(d, (x, y + 4, x + w, y + h), body)
    rect(d, (x + 2, y + 6, x + 4, y + h - 4), tone(body, 1.5))
    rect(d, (x - 1, y, x + w + 1, y + 5), lid)
    d.rectangle((x, y + 4, x + w, y + h), outline=tone(body, 0.55))


def bottle(d, x, y, body, h=24):
    rect(d, (x + 3, y, x + 7, y + 7), tone(body, 0.8))
    rect(d, (x + 2, y - 3, x + 8, y), "#c8a870")
    rect(d, (x, y + 7, x + 10, y + h), body)
    rect(d, (x + 2, y + 9, x + 3, y + h - 3), tone(body, 1.6))
    rect(d, (x + 1, y + 14, x + 9, y + 20), "#f4ecd0")
    d.rectangle((x, y + 7, x + 10, y + h), outline=tone(body, 0.5))


def shelf_unit(d, x0, y0, x1, rows, fill):
    """A wall shelf: boards with whatever `fill(d, x, y_board)` puts on each."""
    for r in range(rows):
        y = y0 + r * 26
        fill(d, x0, x1, y, r)
        rect(d, (x0 - 4, y + 22, x1 + 4, y + 27), "#7a5a38")
        d.line((x0 - 4, y + 22, x1 + 4, y + 22), fill="#b08a58")
        d.line((x0 - 4, y + 27, x1 + 4, y + 27), fill="#3e2a1a")


def sacks(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    for i, (dx, dy) in enumerate([(2, 30), (30, 34), (16, 6), (4, 6)]):
        base = ["#c8b078", "#bca06a", "#d2bc88", "#b89c64"][i]
        sx, sy = x + dx, y + dy
        d.ellipse((sx, sy + 6, sx + 28, sy + 30), fill=OUTLINE)
        d.ellipse((sx + 1, sy + 7, sx + 27, sy + 29), fill=base)
        d.ellipse((sx + 5, sy + 10, sx + 13, sy + 18), fill=tone(base, 1.3))
        rect(d, (sx + 9, sy + 2, sx + 19, sy + 9), tone(base, 0.8))
        d.line((sx + 8, sy + 10, sx + 20, sy + 10), fill="#7a5a38", width=2)


def barrel(d, x, y, w=26, h=32):
    blend((x - 1, y + h - 6, x + w + 1, y + h + 4), 56, ellipse=True)
    solid(d, (x, y + 6, x + w, y + h), "#9a6a3a")
    d.ellipse((x, y, x + w, y + 12), fill=OUTLINE)
    d.ellipse((x + 1, y + 1, x + w - 1, y + 11), fill="#c89a62")
    d.ellipse((x + 4, y + 3, x + w - 4, y + 9), fill="#6a4a2a")
    for yy in (y + 14, y + h - 8):
        rect(d, (x + 1, yy, x + w - 1, yy + 3), "#5a5a64")
    for xx in range(x + 7, x + w - 3, 7):
        d.line((xx, y + 12, xx, y + h - 2), fill="#7a5028")


def barrels(d, x, y, w, h):
    barrel(d, x + 4, y + 4)
    barrel(d, x + 34, y + 10)
    barrel(d, x + 16, y + 30, 28, 32)


def crate(d, x, y, size=30, base="#b08a50"):
    blend((x + 2, y + size - 2, x + size + 5, y + size + 3), 56)
    solid(d, (x, y, x + size, y + size), base)
    d.line((x + 3, y + 3, x + size - 3, y + size - 3), fill=tone(base, 0.65), width=2)
    d.line((x + size - 3, y + 3, x + 3, y + size - 3), fill=tone(base, 0.65), width=2)
    d.rectangle((x + 3, y + 3, x + size - 3, y + size - 3), outline=tone(base, 0.65))


def crates(d, x, y, w, h):
    crate(d, x + 2, y + 32)
    crate(d, x + 32, y + 32, 28, "#a07c46")
    crate(d, x + 10, y + 3, 30, "#c09a5c")


def produce(d, x, y, w, h):
    """A market table with baskets of fruit and vegetables."""
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x + 2, y + 18, x + w - 2, y + h - 2), "#8a6038")
    for i in range(3 if w > 80 else 2):
        bx = x + 6 + i * (w - 12) // (3 if w > 80 else 2)
        solid(d, (bx, y + 6, bx + 26, y + 30), "#c09a62")
        colors = [["#d8402f", "#e86a3a"], ["#e8c040", "#a8c840"], ["#7ab050", "#4a9a4a"]][i % 3]
        for k in range(6):
            cx, cy = bx + 4 + (k % 3) * 7, y + 8 + (k // 3) * 7
            d.ellipse((cx, cy, cx + 7, cy + 7), fill=colors[k % 2])
            d.point((cx + 2, cy + 2), fill="#ffffffa0")
    d.line((x + 4, y + h - 4, x + w - 4, y + h - 4), fill="#3e2a1a")


def anvil(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x + 18, y + 40, x + 46, y + 60), "#6a4a2a")  # stump
    d.polygon(
        [
            (x + 4, y + 18),
            (x + 60, y + 18),
            (x + 54, y + 28),
            (x + 44, y + 30),
            (x + 40, y + 42),
            (x + 24, y + 42),
            (x + 20, y + 30),
            (x + 10, y + 28),
        ],
        fill=OUTLINE,
    )
    d.polygon(
        [
            (x + 6, y + 19),
            (x + 58, y + 19),
            (x + 52, y + 27),
            (x + 42, y + 29),
            (x + 38, y + 40),
            (x + 26, y + 40),
            (x + 22, y + 29),
            (x + 12, y + 27),
        ],
        fill="#5a5a68",
    )
    d.line((x + 8, y + 20, x + 56, y + 20), fill="#a8a8b8", width=2)
    d.polygon([(x + 4, y + 18), (x - 8, y + 22), (x + 6, y + 26)], fill="#5a5a68")


def grindstone(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x + 6, y + 36, x + 58, y + 46), "#6a4a2a")
    for sx in (x + 8, x + 46):
        solid(d, (sx, y + 14, sx + 10, y + 46), "#7a5a38")
    d.ellipse((x + 14, y + 8, x + 50, y + 44), fill=OUTLINE)
    d.ellipse((x + 16, y + 10, x + 48, y + 42), fill="#a8a8b0")
    d.ellipse((x + 24, y + 18, x + 40, y + 34), fill="#7a7a86")
    d.arc((x + 18, y + 12, x + 46, y + 40), 200, 290, fill="#d8d8e0", width=2)


def water_barrel(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    barrel(d, x + 18, y + 20, 30, 38)
    d.ellipse((x + 22, y + 23, x + 44, y + 33), fill="#4a86a8")
    d.ellipse((x + 26, y + 25, x + 36, y + 29), fill="#9ad0e8")
    barrel(d, x + 2, y + 6, 22, 30)


def ingots(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    rows = [(0, "#c08050"), (1, "#a8a8b8"), (2, "#e0c050")]
    for r, color in rows:
        for i in range(3 - r // 2):
            bx, by = x + 6 + i * 26 + r * 4, y + 38 - r * 12
            solid(d, (bx, by, bx + 24, by + 11), color)
    solid(d, (x + 4, y + 50, x + w - 4, y + h - 2), "#5a3e28")


def worktable(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x, y, x + w, y + h), "#8a6038")
    rect(d, (x + 3, y + 3, x + w - 3, y + 10), "#c09060")
    d.line((x + 10, y + 6, x + 34, y + 6), fill="#5a5a68", width=3)  # tongs
    solid(d, (x + 50, y + 3, x + 56, y + 9), "#4a4a58")  # hammer head
    d.line((x + 53, y + 8, x + 53, y + 22), fill="#6a4a2a", width=3)
    solid(d, (x + 70, y + 3, x + 88, y + 10), "#d8d0c0")


def bed(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x, y, x + w, y + h), "#8a98a0")
    rect(d, (x + 4, y + 4, x + w - 4, y + h - 4), "#f4f0e4")
    rect(d, (x + 4, y + 4, x + 26, y + 20), "#fffdf4")
    d.rectangle((x + 4, y + 4, x + 26, y + 20), outline="#c8c0a8")
    rect(d, (x + 4, y + 22, x + w - 4, y + h - 4), "#a8c8d8")
    for i in range(x + 8, x + w - 6, 10):
        d.line((i, y + 24, i, y + h - 6), fill="#8ab0c4")
    d.line((x + 4, y + 22, x + w - 4, y + 22), fill="#d8ecf4", width=2)


def fern(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    pot_x = x + w // 2
    solid(d, (pot_x - 10, y + h - 20, pot_x + 10, y + h - 2), "#a8603a")
    for dx, dy, ex, ey in [
        (-14, -6, -2, -26),
        (-8, -20, -1, -30),
        (0, -26, 0, -32),
        (8, -20, 1, -30),
        (14, -6, 2, -26),
    ]:
        cx, cy = pot_x, y + h - 20
        d.line((cx, cy, cx + dx, cy + dy), fill="#3f8a40", width=3)
        d.ellipse((cx + dx - 6, cy + dy - 5, cx + dx + 6, cy + dy + 5), fill="#58a850")
        d.ellipse((cx + dx - 3, cy + dy - 3, cx + dx + 1, cy + dy), fill="#8fd080")


def bench(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x, y + 4, x + w, y + 20), "#9a7448")
    rect(d, (x + 3, y + 7, x + w - 3, y + 11), "#c09a62")
    for lx in (x + 4, x + w - 10):
        solid(d, (lx, y + 18, lx + 6, y + h - 1), "#6a4a2a")


def round_table(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    for sx, sy in [(x + 2, y + 34), (x + w - 22, y + 34), (x + 36, y + 2)]:
        d.ellipse((sx, sy, sx + 20, sy + 20), fill=OUTLINE)
        d.ellipse((sx + 1, sy + 1, sx + 19, sy + 17), fill="#a8483a")
        d.ellipse((sx + 4, sy + 3, sx + 12, sy + 8), fill="#c86a58")
    d.ellipse((x + 12, y + 10, x + w - 12, y + h - 6), fill=OUTLINE)
    d.ellipse((x + 13, y + 11, x + w - 13, y + h - 8), fill="#8a6038")
    d.ellipse((x + 16, y + 13, x + w - 18, y + h - 14), fill="#b88a58")
    cx = x + w // 2
    rect(d, (cx - 5, y + 24, cx + 5, y + 30), "#f4f0e4")  # cup
    d.rectangle((cx - 5, y + 24, cx + 5, y + 30), outline="#b8b0a0")
    rect(d, (cx + 10, y + 22, cx + 26, y + 32), "#c8603a")  # teapot
    rect(d, (cx + 14, y + 19, cx + 22, y + 22), "#7a3a2a")
    d.line((cx + 26, y + 25, cx + 31, y + 23), fill="#c8603a", width=2)


def stove(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x + 4, y + 22, x + w - 4, y + h - 2), "#4a4a54")
    rect(d, (x + 10, y + 36, x + 26, y + 50), "#1c1c22")
    d.ellipse((x + 14, y + 40, x + 22, y + 48), fill="#e8602a")
    solid(d, (x + 10, y + 6, x + 40, y + 24), "#c8703a")  # copper kettle
    rect(d, (x + 14, y + 2, x + 36, y + 8), "#a85a2a")
    d.line((x + 40, y + 12, x + 50, y + 8), fill="#c8703a", width=3)
    for i, off in enumerate((0, 6, 3)):
        d.ellipse((x + 20 + off, y - 6 - i * 5, x + 26 + off, y - 1 - i * 5), fill="#ffffff70")


def sofa(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x + 2, y + 2, x + w - 2, y + h - 2), "#7a3a2a")
    solid(d, (x + 10, y + 6, x + w - 4, y + h - 6), "#a8483a")
    for yy in range(y + 10, y + h - 8, 28):
        d.line((x + 12, yy + 24, x + w - 6, yy + 24), fill="#7a3a2a", width=2)
    solid(d, (x + 14, y + 12, x + 40, y + 36), "#e8c868")  # cushion


def bait_crates(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    crate(d, x + 2, y + 30, 30, "#7a98a8")
    crate(d, x + 32, y + 32, 28, "#6a8898")
    crate(d, x + 10, y + 4, 30, "#8aa8b8")
    for cx, cy in [(x + 14, y + 20), (x + 46, y + 44)]:
        d.ellipse((cx, cy, cx + 12, cy + 7), fill="#c88a6a")


def bait_barrels(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    barrel(d, x + 2, y + 10, 28, 34)
    barrel(d, x + 32, y + 20, 26, 34)
    d.line((x + 12, y + 24, x + 18, y + 34), fill="#c8c8c0", width=2)


def lure_table(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x, y + 4, x + w, y + h), "#8a6038")
    rect(d, (x + 3, y + 7, x + w - 3, y + 14), "#b08850")
    for i, c in enumerate(["#d8402f", "#f0c050", "#4a9aca", "#f4ecd8", "#6ab868"]):
        lx = x + 8 + i * 16
        d.ellipse((lx, y + 8, lx + 10, y + 14), fill=c)
        d.line((lx + 10, y + 11, lx + 14, y + 11), fill="#c8c8d0")


def tank(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    solid(d, (x, y + 10, x + w, y + h - 2), "#3a5a70")
    rect(d, (x + 5, y + 14, x + w - 5, y + h - 8), "#5aa0c0")
    for k in range(0, h - 24, 6):
        rect(d, (x + 5, y + 14 + k, x + w - 5, y + 18 + k), tone("#5aa0c0", 1.0 + 0.04 * (k // 6)))
    for fx, fy, col in [
        (x + 14, y + 30, "#f0d070"),
        (x + 50, y + 48, "#f08a50"),
        (x + 62, y + 26, "#f4ecd8"),
    ]:
        d.ellipse((fx, fy, fx + 18, fy + 9), fill=col)
        d.polygon([(fx + 18, fy + 4), (fx + 26, fy), (fx + 26, fy + 9)], fill=col)
        d.point((fx + 4, fy + 3), fill="#2a2a30")
    for bx, by in [(x + 30, y + 22), (x + 34, y + 16), (x + 70, y + 40)]:
        d.ellipse((bx, by, bx + 4, by + 4), outline="#d8f0f8")
    rect(d, (x + 2, y + 10, x + w - 2, y + 14), "#6a8aa0")


def rope(d, x, y, w, h):
    shadow(d, (x, y, x + w, y + h))
    for i in range(4):
        d.ellipse(
            (x + 6 + i * 2, y + 14 + i * 3, x + 56 - i * 2, y + 52 - i * 3),
            outline="#c8a868",
            width=3,
        )
    d.ellipse((x + 22, y + 28, x + 40, y + 38), fill="#a88848")
    d.line((x + 40, y + 34, x + 58, y + 50), fill="#c8a868", width=3)
    d.line((x + 58, y + 50, x + 54, y + 60), fill="#c8a868", width=3)


PIECES = {
    "sacks": sacks,
    "barrels": barrels,
    "crates": crates,
    "produce": produce,
    "anvil": anvil,
    "grindstone": grindstone,
    "water_barrel": water_barrel,
    "ingots": ingots,
    "worktable": worktable,
    "bed": bed,
    "fern": fern,
    "bench": bench,
    "round_table": round_table,
    "stove": stove,
    "sofa": sofa,
    "bait_crates": bait_crates,
    "bait_barrels": bait_barrels,
    "lure_table": lure_table,
    "tank": tank,
    "rope": rope,
}


# ---------------------------------------------------------------------------- wall decoration


def general_wall(d):
    def goods(d, x0, x1, y, r):
        palette = [
            ["#c8403a", "#e8c040", "#4a9a4a", "#e8e0c8"],
            ["#a87a3a", "#d8b060", "#7a9a5a", "#c8903a"],
        ][r % 2]
        for i, x in enumerate(range(x0, x1 - 12, 18)):
            jar(d, x, y + 2, palette[i % 4], h=20)

    shelf_unit(d, 140, 52, 270, 2, goods)
    shelf_unit(d, 690, 52, 790, 2, goods)
    rect(d, (300, 56, 420, 88), "#6a4a2a")
    d.text((312, 64), "HAWKE", fill="#f4e0a0")
    d.rectangle((300, 56, 420, 88), outline="#3e2a1a", width=2)
    for i, x in enumerate((440, 470, 500)):  # hanging herbs and sausages
        d.line((x, 52, x, 62), fill="#6a4a2a")
        d.ellipse((x - 8, 62, x + 8, 92), fill=["#a8483a", "#4a8a40", "#c8a050"][i])


def smith_wall(d):
    # Forge hearth with a hood, in the wall at the left; the smith works beside it.
    rect(d, (136, 50, 268, 128), "#4a4a54")
    solid(d, (144, 56, 260, 126), "#6a6a76")
    d.polygon([(130, 52), (274, 52), (252, 74), (152, 74)], fill="#3e3e48")
    rect(d, (160, 82, 244, 126), "#1c1c22")
    d.ellipse((168, 98, 236, 130), fill="#c8502a")
    d.ellipse((178, 104, 226, 128), fill="#f08a3a")
    d.ellipse((190, 110, 214, 126), fill="#f8d060")
    for x, h in ((176, 12), (196, 18), (220, 10)):
        d.polygon([(x, 100), (x + 8, 100 - h), (x + 14, 100)], fill="#f8a840")
    # Tool rack: hammers, tongs, an axe.
    rect(d, (300, 62, 640, 70), "#5a3e28")
    for i, x in enumerate(range(318, 630, 44)):
        kind = i % 3
        d.line((x, 70, x, 96), fill="#6a4a2a", width=3)
        if kind == 0:
            solid(d, (x - 9, 70, x + 9, 80), "#6a6a78")
        elif kind == 1:
            d.polygon([(x, 72), (x + 16, 80), (x, 90)], fill="#8a8a98")
        else:
            d.line((x - 6, 92, x + 6, 74), fill="#8a8a98", width=3)
            d.line((x + 6, 92, x - 6, 74), fill="#8a8a98", width=3)
    for x in (700, 740, 776):
        rect(d, (x, 72, x + 18, 100), "#4a4a58")
        d.line((x + 9, 60, x + 9, 72), fill="#8a8a98", width=3)


def clinic_wall(d):
    rect(d, (140, 54, 300, 126), "#cfd8d4")
    d.rectangle((140, 54, 300, 126), outline="#8a9a96", width=3)
    for r in range(3):
        d.line((144, 78 + r * 16, 296, 78 + r * 16), fill="#8a9a96", width=2)
    for i in range(7):
        bottle(
            d,
            148 + i * 21,
            56,
            ["#7ab868", "#c83a3a", "#a8c8e0", "#e8d8a8", "#c8a0d0", "#7ab868", "#e8c040"][i],
            h=16,
        )
        jar(d, 150 + i * 21, 82, ["#e8d8a8", "#a8c8e0", "#7ab868"][i % 3], h=14, w=10)
    rect(d, (700, 58, 790, 106), "#f4f0e4")  # eye chart
    d.rectangle((700, 58, 790, 106), outline="#8a9a96", width=3)
    for i, s in enumerate((4, 3, 3, 2, 2)):
        rect(d, (745 - s * 6, 64 + i * 8, 745 + s * 6, 68 + i * 8), "#3a3a44")
    rect(d, (420, 60, 540, 92), "#f4f0e4")
    rect(d, (470, 64, 490, 88), "#c83a3a")
    rect(d, (462, 72, 498, 80), "#c83a3a")


def tackle_wall(d):
    rect(d, (136, 56, 290, 100), "#6a4a2a")
    for i in range(5):  # rod rack
        x = 146 + i * 30
        d.line((x, 52, x + 18, 120), fill="#c8a868", width=3)
        d.ellipse((x + 4, 74, x + 12, 82), fill="#4a5a6a")
    # Net with floats.
    for x in range(318, 470, 12):
        d.line((x, 52, x + 6, 100), fill="#8a9aa0")
    for y in range(58, 100, 12):
        d.line((318, y, 470, y), fill="#8a9aa0")
    for x in (326, 374, 422, 462):
        d.ellipse((x, 56, x + 12, 68), fill="#d8402f")
    # Mounted fish and a lifebuoy.
    d.ellipse((560, 70, 600, 92), fill="#6a8aa0")
    d.polygon([(600, 80), (618, 68), (618, 94)], fill="#6a8aa0")
    d.line((566, 80, 590, 80), fill="#f4ecd8", width=2)
    d.ellipse((700, 60, 760, 116), outline="#e8e0c8", width=8)
    for a in (30, 120, 210, 300):
        d.arc((700, 60, 760, 116), a, a + 40, fill="#d8402f", width=8)


def tea_wall(d):
    def tea(d, x0, x1, y, r):
        for i, x in enumerate(range(x0, x1 - 16, 24)):
            if r == 0:
                rect(d, (x, y + 6, x + 18, y + 22), ["#7a3a2a", "#c8a050", "#4a7a4a"][i % 3])
                rect(d, (x + 2, y + 2, x + 16, y + 6), "#e8d8a8")
            else:
                d.ellipse((x, y + 6, x + 20, y + 22), fill=["#f4ecd8", "#c8603a", "#4a7a9a"][i % 3])
                rect(d, (x + 6, y + 2, x + 14, y + 8), "#7a3a2a")

    shelf_unit(d, 140, 52, 300, 2, tea)
    shelf_unit(d, 650, 52, 790, 2, tea)
    rect(d, (380, 56, 580, 94), "#7a3a2a")  # banner
    d.rectangle((380, 56, 580, 94), outline="#e8c868", width=2)
    d.text((408, 66), "THE COPPER KETTLE", fill="#f4e0a0")
    for x in (330, 600):
        d.line((x, 52, x, 70), fill="#6a4a2a")
        d.ellipse((x - 10, 70, x + 10, 94), fill="#c8703a")


WALLS = {
    "general_store": general_wall,
    "blacksmith": smith_wall,
    "clinic": clinic_wall,
    "tackle_shop": tackle_wall,
    "tea_house": tea_wall,
}


def room(kind):
    global _IM
    t = THEMES[kind]
    im = Image.new("RGBA", (960, 608), "#172a24")
    _IM = im
    d = ImageDraw.Draw(im)
    rect(d, (96, 44, 832, 548), OUTLINE)
    floor(d, kind, t)
    walls(d, kind, t)
    WALLS[kind](d)
    door(d, t)
    counter(d, t)
    for piece, x, y, w, h in sorted(SHOP_FURNITURE[kind], key=lambda p: p[2] + p[4]):
        PIECES[piece](d, x * CELL, y * CELL, w * CELL, h * CELL)
    return im


def build_shop_interiors(output):
    for kind in THEMES:
        room(kind).save(output / (kind + "_background.png"))

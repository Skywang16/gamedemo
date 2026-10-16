"""Crops by growth stage, produce icons, seed packets, fish, forage and dishes.

Everything is drawn on a 32x32 pixel grid from the specs in tools/content/specs.py.
Shapes are built from filled primitives and then given a one-pixel coloured outline,
so the whole set shares the same silhouette language as the hand-composed art.
"""

from PIL import Image, ImageChops, ImageDraw, ImageFilter
from .crops import crop as base_crop

OUTLINE = "#2f2a22"


def rgb(hex_color):
    h = hex_color.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    ca, cb = rgb(a), rgb(b)
    return "#%02x%02x%02x" % tuple(int(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))


def ramp(base):
    """(shadow, base, light, glint) from one colour."""
    return (mix(base, "#20181a", 0.38), base, mix(base, "#ffffff", 0.32), mix(base, "#ffffff", 0.6))


def blank(size=32):
    return Image.new("RGBA", (size, size), (0, 0, 0, 0))


def outlined(im, color=OUTLINE):
    """Adds a 1px outline around the opaque pixels, in a darkened tone of `color`."""
    alpha = im.getchannel("A")
    grown = alpha.filter(ImageFilter.MaxFilter(3))
    ring = ImageChops.subtract(grown, alpha)
    layer = Image.new("RGBA", im.size, color)
    layer.putalpha(ring)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(layer)
    out.alpha_composite(im)
    return out


def ball(d, cx, cy, rx, ry, base):
    s, b, lt, g = ramp(base)
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=s)
    d.ellipse((cx - rx, cy - ry, cx + rx - 1, cy + ry - 2), fill=b)
    d.ellipse((cx - rx + 1, cy - ry + 1, cx + rx // 2, cy + ry // 2 - 1), fill=lt)
    d.point((cx - rx // 2, cy - ry // 2), fill=g)


def leaf(d, x, y, tx, ty, width, base):
    """A pointed leaf from (x, y) to (tx, ty)."""
    s, b, lt, _g = ramp(base)
    dx, dy = tx - x, ty - y
    length = max((dx * dx + dy * dy) ** 0.5, 1)
    nx, ny = -dy / length * width, dx / length * width
    mx, my = x + dx * 0.5, y + dy * 0.5
    pts = [(x, y), (mx + nx, my + ny), (tx, ty), (mx - nx, my - ny)]
    d.polygon(pts, fill=b)
    d.polygon([(x, y), (mx + nx * 0.4, my + ny * 0.4 - 1), (tx, ty)], fill=lt)
    d.line((x, y, tx, ty), fill=s)


def stalk(d, x0, y0, x1, y1, base, width=2):
    d.line((x0, y0, x1, y1), fill=ramp(base)[0], width=width)
    d.line((x0 - 1, y0, x1 - 1, y1), fill=ramp(base)[2], width=1)


# ----------------------------------------------------------------- plant stages


def plant(spec, stage):
    _id, _name, _seasons, _days, _regrow, _sp, _sell, _en, family, green, fruit, shape, _d = spec
    if stage in ("seeds", "sprout"):
        return base_crop(stage)
    mature = stage == "mature"
    im = blank()
    d = ImageDraw.Draw(im)
    draw = {
        "leafy": _leafy,
        "root": _root,
        "vine": _vine,
        "gourd": _gourd,
        "tall": _tall,
        "bush": _bush,
    }[family]
    draw(d, mature, green, fruit, shape)
    return outlined(im, mix(green, "#101810", 0.65))


def _leafy(d, mature, green, fruit, shape):
    narrow = shape == "bunch" and fruit in ("#7ac05a",)
    angles = [(-12, -9), (12, -9), (-7, -13), (7, -13), (0, -15)]
    if mature:
        angles += [(-15, -5), (15, -5), (-3, -18), (4, -17)]
    for dx, dy in angles:
        if narrow:
            leaf(d, 16, 27, 16 + dx // 2, 27 + dy - 2, 1.4, green)
        else:
            leaf(d, 16, 27, 16 + dx, 27 + dy, 3.2 if mature else 2.4, green)
    if mature and fruit in ("#f0cf3a",):
        for x, y in [(10, 12), (16, 8), (21, 12), (14, 11)]:
            d.rectangle((x, y, x + 1, y + 1), fill=fruit)


def _root(d, mature, green, fruit, shape):
    angles = [(-9, -9), (9, -9), (-3, -12), (4, -12)] + ([(0, -15), (-12, -5)] if mature else [])
    for dx, dy in angles:
        leaf(d, 16, 24, 16 + dx, 24 + dy, 2.3 if mature else 1.8, green)
    if mature:
        _root_body(d, fruit, shape)


def _root_body(d, color, shape):
    if shape == "long_root":
        d.polygon([(11, 24), (21, 24), (19, 30), (15, 31), (12, 29)], fill=color)
        d.line((13, 25, 13, 29), fill=mix(color, "#ffffff", 0.4))
    elif shape == "lumpy":
        ball(d, 13, 27, 4, 3, color)
        ball(d, 19, 27, 4, 3, color)
        d.point((12, 26), fill=mix(color, "#000000", 0.4))
    else:
        ball(d, 16, 27, 6, 4, color)


def _vine(d, mature, green, fruit, shape):
    height = 24 if mature else 16
    stalk(d, 16, 28, 16, 28 - height, green)
    for i, y in enumerate(range(26, 28 - height, -5)):
        side = -1 if i % 2 == 0 else 1
        leaf(d, 16, y, 16 + side * 9, y - 4, 2.6, green)
    if mature:
        spots = [(11, 17), (21, 14), (12, 9), (20, 22)]
        for i, (x, y) in enumerate(spots):
            _fruit(d, x, y, fruit, shape, i)


def _fruit(d, x, y, color, shape, i=0):
    if shape == "sphere":
        ball(d, x, y, 3, 3, color)
    elif shape == "long":
        d.rounded_rectangle((x - 2, y - 1, x + 1, y + 6), radius=1, fill=color)
        d.line((x - 1, y, x - 1, y + 5), fill=mix(color, "#ffffff", 0.35))
    elif shape == "drop":
        ball(d, x, y + 2, 2, 4, color)
    elif shape == "cone":
        d.polygon([(x - 2, y - 1), (x + 2, y - 1), (x, y + 6)], fill=color)
        d.line((x - 1, y, x, y + 4), fill=mix(color, "#ffffff", 0.4))
    elif shape == "pods":
        d.arc((x - 4, y - 3, x + 4, y + 5), 200, 340, fill=color, width=3)
        d.point((x, y - 2), fill=mix(color, "#ffffff", 0.5))
    else:
        ball(d, x, y, 3, 3, color)


def _gourd(d, mature, green, fruit, shape):
    d.line((6, 28, 12, 24, 20, 26, 27, 22), fill=ramp(green)[0], width=1)
    for tx, ty in [(8, 20), (24, 18), (14, 19)] if mature else [(10, 21)]:
        leaf(d, tx, ty + 6, tx, ty - 2, 3.2, green)
    if mature:
        ball(d, 16, 23, 9, 6, fruit)
        if shape == "squash":
            for x in (10, 13, 19, 22):
                d.arc((x - 3, 17, x + 3, 29), 100, 260, fill=mix(fruit, "#000000", 0.28))
            d.rectangle((15, 15, 17, 17), fill="#6a4a2a")
        else:
            for x in (9, 13, 18, 22):
                d.line((x, 18, x + 1, 28), fill=mix(fruit, "#1a3a1a", 0.5))
    else:
        ball(d, 17, 26, 3, 2, fruit)


def _tall(d, mature, green, fruit, shape):
    height = 26 if mature else 17
    stalk(d, 16, 29, 16, 29 - height, green, 2)
    for i, y in enumerate(range(26, 29 - height, -6)):
        side = -1 if i % 2 == 0 else 1
        leaf(d, 16, y, 16 + side * 11, y - 6, 2.2, green)
    if not mature:
        return
    top = 29 - height
    if shape == "ear":
        d.rounded_rectangle((18, 12, 23, 22), radius=2, fill=fruit)
        d.rectangle((19, 12, 20, 21), fill=mix(fruit, "#ffffff", 0.45))
        leaf(d, 20, 24, 24, 13, 2.4, green)
    elif shape == "disc":
        ball(d, 16, top + 4, 7, 7, "#6a4a2a")
        for k in range(10):
            a = k * 36
            import math

            x = 16 + math.cos(math.radians(a)) * 9
            y = top + 4 + math.sin(math.radians(a)) * 9
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=fruit)
        ball(d, 16, top + 4, 4, 4, "#4a3220")
    else:
        for x, y in [(12, top + 2), (17, top), (21, top + 4), (14, top + 6)]:
            d.rectangle((x, y, x + 2, y + 2), fill=fruit)


def _bush(d, mature, green, fruit, shape):
    for tx, ty in (
        [(7, 22), (25, 22), (10, 15), (22, 15), (16, 12)]
        if mature
        else [(9, 22), (23, 22), (16, 17)]
    ):
        leaf(d, 16, 28, tx, ty, 3.4, green)
    if not mature:
        return
    if shape == "berry":
        for x, y in [(10, 24), (20, 25), (15, 20), (24, 21)]:
            d.polygon([(x - 2, y - 2), (x + 2, y - 2), (x + 1, y + 3), (x - 1, y + 3)], fill=fruit)
            d.point((x - 1, y - 1), fill=mix(fruit, "#ffffff", 0.5))
    else:
        for x, y in [(11, 18), (20, 17), (15, 21)]:
            for ox, oy in [(0, 0), (2, 2), (-2, 2), (0, 4), (2, 5), (-2, 5)]:
                d.ellipse((x + ox - 1, y + oy - 1, x + ox + 1, y + oy + 1), fill=fruit)


# ----------------------------------------------------------------- icons


def produce_icon(spec):
    shape, color = spec[11], spec[10]
    return icon_shape(shape, color, spec[9])


EXTRA_SHAPES = {"round_root", "shoot_g", "pearl", "shell", "coral", "sphere_f"}


def icon_shape(shape, color, green="#4f9a3f"):
    if shape in EXTRA_SHAPES:
        return extra_icon(
            shape, (color, mix(color, "#ffffff", 0.4), mix(color, "#101010", 0.4)), green
        )
    im = blank()
    d = ImageDraw.Draw(im)
    if shape == "sphere":
        ball(d, 16, 18, 10, 9, color)
        for dx, dy in [(-4, -8), (0, -9), (4, -8)]:
            leaf(d, 16, 10, 16 + dx, 10 + dy, 1.6, green)
    elif shape == "pods":
        for i, x in enumerate((9, 15, 21)):
            d.arc((x - 6, 6 + i * 2, x + 8, 28), 200, 345, fill=color, width=4)
            d.arc((x - 6, 7 + i * 2, x + 7, 27), 215, 330, fill=mix(color, "#ffffff", 0.4), width=1)
    elif shape == "bunch":
        for dx, dy in [(-9, -6), (9, -6), (-5, -11), (5, -11), (0, -13)]:
            leaf(d, 16, 27, 16 + dx, 27 + dy, 3.2, green)
        d.rectangle((13, 24, 19, 27), fill=mix(green, "#e8d8a0", 0.5))
        if color in ("#f0cf3a",):
            for x, y in [(10, 12), (16, 9), (21, 12)]:
                d.rectangle((x, y, x + 1, y + 1), fill=color)
    elif shape in ("lumpy", "long_root"):
        for dx, dy in [(-6, -5), (6, -5), (0, -8)]:
            leaf(d, 16, 12, 16 + dx, 12 + dy, 1.8, green)
        if shape == "lumpy":
            ball(d, 12, 20, 6, 5, color)
            ball(d, 20, 21, 6, 5, color)
            ball(d, 16, 16, 5, 4, color)
        else:
            d.polygon([(9, 13), (23, 14), (25, 22), (18, 28), (10, 24)], fill=color)
            d.line((11, 15, 20, 23), fill=mix(color, "#ffffff", 0.4), width=2)
    elif shape == "long":
        d.rounded_rectangle((5, 12, 27, 21), radius=4, fill=color)
        d.line((7, 14, 24, 14), fill=mix(color, "#ffffff", 0.4), width=2)
        for x in (10, 15, 20):
            d.point((x, 18), fill=mix(color, "#000000", 0.3))
    elif shape == "drop":
        ball(d, 15, 19, 8, 9, color)
        d.polygon([(10, 11), (20, 11), (18, 7), (12, 7)], fill="#4f8a45")
        d.line((16, 7, 16, 4), fill="#4f8a45", width=2)
    elif shape == "cone":
        d.polygon([(8, 10), (24, 10), (18, 28), (14, 28)], fill=color)
        d.line((11, 12, 16, 25), fill=mix(color, "#ffffff", 0.45), width=2)
        d.rectangle((12, 6, 20, 10), fill="#4f8a45")
    elif shape == "ear":
        d.rounded_rectangle((11, 5, 21, 28), radius=4, fill=color)
        for y in range(8, 27, 4):
            for x in (13, 17):
                d.rectangle((x, y, x + 1, y + 1), fill=mix(color, "#ffffff", 0.5))
        leaf(d, 16, 28, 6, 12, 3.0, green)
        leaf(d, 16, 28, 26, 12, 3.0, green)
    elif shape == "disc":
        ball(d, 16, 15, 7, 7, "#6a4a2a")
        import math

        for k in range(12):
            a = k * 30
            x = 16 + math.cos(math.radians(a)) * 10
            y = 15 + math.sin(math.radians(a)) * 10
            d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=color)
        ball(d, 16, 15, 5, 5, "#4a3220")
        d.line((16, 24, 16, 30), fill=green, width=2)
    elif shape in ("melon", "squash"):
        ball(d, 16, 18, 13, 10, color)
        stripes = "#1f5a2a" if shape == "melon" else mix(color, "#000000", 0.3)
        for x in (9, 13, 19, 23):
            d.arc((x - 4, 8, x + 4, 28), 100, 260, fill=stripes)
        if shape == "squash":
            d.rectangle((15, 6, 17, 9), fill="#6a4a2a")
    elif shape == "grain":
        for dx in (-6, 0, 6):
            d.line((16 + dx, 28, 16 + dx // 2, 8), fill="#a89a58", width=1)
            for y in range(8, 18, 3):
                d.rectangle((15 + dx // 2, y, 17 + dx // 2, y + 1), fill=color)
        d.rectangle((12, 22, 20, 24), fill="#8a6a3a")
    elif shape == "bunch_fruit":
        d.line((16, 4, 16, 9), fill="#6a4a2a", width=2)
        for row, count in enumerate((4, 3, 3, 2, 1)):
            for i in range(count):
                x = 16 + (i - (count - 1) / 2) * 5
                ball(d, int(x), 11 + row * 4, 2, 2, color)
        leaf(d, 16, 8, 6, 5, 2.5, green)
    elif shape == "berry":
        d.polygon([(8, 11), (24, 11), (19, 28), (13, 28)], fill=color)
        for x, y in [(12, 15), (17, 14), (15, 20), (19, 19), (14, 24)]:
            d.point((x, y), fill=mix(color, "#fff0a0", 0.7))
        d.polygon([(10, 11), (16, 7), (22, 11), (16, 12)], fill="#4f9a45")
    return outlined(im)


def packet(spec):
    im = Image.new("RGBA", (32, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((6, 6, 25, 36), fill="#ead9a8")
    d.rectangle((6, 6, 25, 10), fill="#c9a96a")
    d.line((7, 7, 24, 7), fill="#f4e8c0")
    d.polygon([(6, 6), (9, 3), (22, 3), (25, 6)], fill="#d8bd80")
    d.rectangle((8, 13, 23, 31), fill=mix(spec[9], "#ffffff", 0.55))
    d.rectangle((8, 13, 23, 15), fill=spec[9])
    small = produce_icon(spec).resize((16, 16), Image.Resampling.NEAREST)
    im.alpha_composite(small, (8, 15))
    for x in range(8, 24, 3):
        d.point((x, 34), fill="#b89a60")
    return outlined(im, "#4a3a22")


# ----------------------------------------------------------------- fish


def fish_icon(spec):
    shape = spec[10]
    back, belly, fin = spec[11]
    im = blank()
    d = ImageDraw.Draw(im)
    if shape == "shrimp":
        d.arc((6, 8, 26, 28), 200, 20, fill=back, width=6)
        d.arc((8, 10, 24, 26), 200, 20, fill=belly, width=1)
        d.polygon([(24, 18), (30, 14), (29, 22)], fill=fin)
        d.line((8, 12, 3, 6), fill=fin)
        d.line((9, 11, 5, 4), fill=fin)
        d.point((10, 12), fill="#101010")
    elif shape == "crab":
        ball(d, 16, 19, 9, 6, back)
        for side in (-1, 1):
            d.line((16 + side * 9, 20, 16 + side * 13, 26), fill=fin, width=1)
            d.line((16 + side * 8, 17, 16 + side * 14, 12), fill=fin, width=2)
            d.ellipse((16 + side * 14 - 3, 8, 16 + side * 14 + 3, 14), fill=back)
        d.point((13, 15), fill="#101010")
        d.point((19, 15), fill="#101010")
    elif shape == "eel":
        pts = [(4, 22), (9, 16), (15, 22), (21, 15), (27, 20)]
        d.line(pts, fill=back, width=5)
        d.line([(x, y + 1) for x, y in pts], fill=belly, width=1)
        d.point((27, 18), fill="#101010")
    else:
        body = {
            "round": (5, 9, 26, 24),
            "slim": (3, 12, 27, 21),
            "long": (2, 11, 28, 21),
            "flat": (6, 6, 25, 27),
        }[shape]
        x0, y0, x1, y1 = body
        tail_x = x0 - 1
        mid = (y0 + y1) // 2
        d.polygon([(tail_x + 4, mid), (tail_x - 2, mid - 6), (tail_x - 2, mid + 6)], fill=fin)
        top = (x0 + 6, y0 - 1)
        d.polygon(
            [(top[0], top[1] + 2), (top[0] + 8, top[1] + 2), (top[0] + 4, top[1] - 4)], fill=fin
        )
        d.ellipse(body, fill=belly)
        d.pieslice(body, 180, 360, fill=back)
        d.line((x0 + 3, mid, x1 - 3, mid), fill=mix(back, belly, 0.5))
        d.polygon(
            [(x1 - 6, y0 + 2), (x1 - 6, y1 - 2), (x1 - 3, mid)], fill=mix(back, "#000000", 0.12)
        )
        d.point((x1 - 5, mid - 2), fill="#101010")
        d.point((x1 - 6, mid - 3), fill="#ffffff")
        d.line((x0 + 8, y0 + 4, x0 + 8, y1 - 4), fill=mix(belly, back, 0.25))
    return outlined(im)


# ----------------------------------------------------------------- forage


def forage_icon(spec):
    shape = spec[5]
    a, b, c = spec[6]
    if shape in EXTRA_SHAPES:
        return extra_icon(shape, spec[6])
    im = blank()
    d = ImageDraw.Draw(im)
    if shape == "shoot":
        d.polygon([(11, 28), (21, 28), (18, 8), (14, 8)], fill=a)
        for y in (12, 17, 22):
            d.line((12, y, 20, y), fill=c)
        d.polygon([(14, 8), (18, 8), (16, 3)], fill=b)
    elif shape == "sprig":
        stalk(d, 16, 29, 16, 8, "#4f9a3f")
        for i, y in enumerate(range(24, 8, -5)):
            side = -1 if i % 2 == 0 else 1
            leaf(d, 16, y, 16 + side * 9, y - 5, 2.4, a)
    elif shape == "lotus":
        for x in (8, 15, 22):
            ball(d, x, 18, 4, 7, a)
            d.ellipse((x - 1, 15, x + 1, 17), fill=c)
            d.ellipse((x - 1, 20, x + 1, 22), fill=c)
    elif shape == "mushroom":
        d.rectangle((13, 16, 19, 27), fill="#e8dcc0")
        d.pieslice((4, 6, 28, 26), 180, 360, fill=a)
        d.pieslice((6, 8, 24, 22), 190, 300, fill=b)
        for x, y in [(11, 12), (18, 10), (21, 15)]:
            d.point((x, y), fill="#f0e4c8")
    elif shape == "burr":
        ball(d, 16, 17, 10, 9, a)
        for k in range(14):
            import math

            ang = k * 26
            x = 16 + math.cos(math.radians(ang)) * 10
            y = 17 + math.sin(math.radians(ang)) * 9
            d.line((16 + (x - 16) * 0.7, 17 + (y - 17) * 0.7, x, y), fill=c)
        ball(d, 16, 24, 5, 3, "#a86a30")
    elif shape == "berry":
        for x, y in [(11, 18), (20, 17), (15, 23), (16, 12)]:
            ball(d, x, y, 4, 4, a)
            d.point((x - 1, y - 2), fill="#ffffff")
    elif shape == "nut":
        d.polygon([(16, 5), (24, 18), (16, 28), (8, 18)], fill=a)
        d.line((16, 8, 16, 25), fill=c)
    elif shape == "weed":
        for dx, h in [(-7, 14), (-2, 20), (3, 17), (8, 12)]:
            d.line((16 + dx, 28, 16 + dx // 2, 28 - h), fill=a, width=2)
            d.line((16 + dx + 1, 28, 16 + dx // 2 + 1, 28 - h + 2), fill=b, width=1)
    elif shape == "jar":
        d.rectangle((9, 11, 23, 28), fill=mix(a, "#ffffff", 0.35))
        d.rectangle((10, 14, 22, 27), fill=a)
        d.rectangle((10, 14, 22, 17), fill=b)
        d.rectangle((8, 7, 24, 11), fill="#a88a5a")
        d.line((12, 18, 12, 26), fill=mix(b, "#ffffff", 0.4))
    elif shape == "feather":
        d.polygon([(7, 27), (24, 5), (27, 8), (14, 22)], fill=a)
        d.line((7, 27, 26, 6), fill=c, width=1)
        for i in range(6):
            d.line((11 + i * 2, 24 - i * 3, 20 + i, 22 - i * 3), fill=b)
    elif shape == "note":
        d.polygon([(7, 6), (24, 4), (26, 26), (9, 28)], fill=a)
        for y in (11, 15, 19):
            d.line((10, y, 22, y - 1), fill=c)
        d.ellipse((17, 20, 22, 25), fill="#c08a5a")
    elif shape == "coin":
        ball(d, 16, 16, 11, 11, a)
        d.ellipse((12, 12, 20, 20), outline=c)
        d.rectangle((14, 14, 17, 17), fill=c)
    elif shape == "sugar":
        d.line([(6, 20), (10, 10), (16, 16), (22, 8), (27, 14)], fill=a, width=3)
        d.line([(6, 19), (10, 9), (16, 15), (22, 7), (27, 13)], fill=b, width=1)
        d.line((10, 20, 10, 29), fill="#c8a468", width=2)
    return outlined(im)


# ----------------------------------------------------------------- dishes


def dish_icon(spec):
    shape = spec[6]
    a, b = spec[7]
    im = blank()
    d = ImageDraw.Draw(im)
    if shape == "bowl":
        d.ellipse((5, 14, 27, 22), fill=a)
        d.ellipse((7, 15, 25, 21), fill=b)
        d.pieslice((4, 12, 28, 32), 0, 180, fill="#e8e0d0")
        d.pieslice((6, 12, 26, 30), 20, 160, fill="#d4c8b0")
        d.arc((4, 12, 28, 32), 20, 160, fill="#a89a80")
        d.line((8, 20, 24, 20), fill="#f4ecd8")
        for x in (12, 17, 21):
            d.line((x, 10, x - 1, 6), fill="#ffffff80")
    elif shape == "plate":
        d.ellipse((3, 16, 29, 28), fill="#e8e0d0")
        d.ellipse((5, 17, 27, 26), fill="#f4ecd8")
        d.ellipse((9, 18, 23, 25), fill=a)
        d.ellipse((12, 18, 21, 22), fill=b)
        for x, y in [(11, 20), (19, 21), (15, 19)]:
            d.point((x, y), fill="#ffffff")
    elif shape == "skewer":
        d.line((6, 26, 26, 6), fill="#a88a5a", width=2)
        d.rounded_rectangle((9, 8, 22, 22), radius=3, fill=a)
        for y in (11, 15, 19):
            d.line((10, y, 21, y), fill=b)
    elif shape == "bun":
        ball(d, 16, 19, 11, 8, a)
        d.arc((9, 12, 23, 22), 200, 340, fill=b, width=2)
        for x in (12, 16, 20):
            d.line((x, 8, x - 1, 4), fill="#ffffff80")
    elif shape == "cake":
        d.rounded_rectangle((6, 14, 26, 26), radius=3, fill="#d8b070")
        d.rectangle((6, 14, 26, 18), fill=a)
        d.rectangle((7, 19, 25, 21), fill=b)
        ball(d, 16, 12, 3, 3, a)
    elif shape == "cup":
        d.polygon([(8, 10), (24, 10), (21, 28), (11, 28)], fill="#e8e0d0")
        d.polygon([(10, 14), (22, 14), (20, 26), (12, 26)], fill=a)
        d.rectangle((10, 14, 22, 17), fill=b)
        d.arc((20, 12, 29, 22), 270, 90, fill="#a89a80", width=2)
    return outlined(im)


def fishing_rod():
    im = blank()
    d = ImageDraw.Draw(im)
    d.line((5, 28, 25, 5), fill="#6a4a2a", width=3)
    d.line((6, 27, 25, 5), fill="#c79b62", width=1)
    d.line((25, 5, 28, 14), fill="#e8e8e0", width=1)
    d.ellipse((26, 14, 30, 18), fill="#d8402f")
    d.ellipse((9, 21, 14, 26), fill="#4a5a6a")
    d.ellipse((10, 22, 13, 25), fill="#9ab0c0")
    return outlined(im, "#2a2018")


def sword_icon():
    im = blank()
    d = ImageDraw.Draw(im)
    d.polygon([(26, 3), (29, 6), (13, 22), (10, 19)], fill="#c8d4dc")
    d.polygon([(26, 3), (29, 6), (27, 8), (24, 5)], fill="#ffffff")
    d.line((12, 20, 27, 5), fill="#8a98a4", width=1)
    d.polygon([(7, 19), (13, 25), (11, 27), (5, 21)], fill="#a8802a")
    d.line((9, 22, 4, 28), fill="#513e2d", width=3)
    d.ellipse((2, 26, 6, 30), fill="#e8c050")
    return outlined(im, "#2a2018")


# ----------------------------------------------------------------- shapes for the second wave


def extra_icon(shape, colours, green="#4f9a3f"):
    """Minerals, animal goods, misc items and the forage shapes not covered above."""
    a, b, c = colours
    im = blank()
    d = ImageDraw.Draw(im)
    if shape == "ore":
        d.polygon(
            [(4, 24), (6, 14), (13, 8), (23, 9), (28, 18), (25, 26), (10, 28)],
            fill=mix(a, "#505058", 0.45),
        )
        d.polygon(
            [(7, 22), (9, 15), (14, 11), (21, 12), (24, 19), (22, 24), (11, 25)],
            fill=mix(a, "#808088", 0.35),
        )
        for x, y, r in [(11, 17, 2), (18, 15, 2), (20, 21, 2), (14, 22, 1)]:
            d.ellipse((x - r, y - r, x + r, y + r), fill=a)
            d.point((x - 1, y - 1), fill=b)
    elif shape == "gem":
        d.polygon([(16, 4), (26, 12), (22, 27), (10, 27), (6, 12)], fill=c)
        d.polygon([(16, 4), (22, 12), (16, 27), (10, 12)], fill=a)
        d.polygon([(16, 4), (26, 12), (22, 12)], fill=b)
        d.polygon([(6, 12), (16, 4), (10, 12)], fill=mix(a, "#ffffff", 0.5))
        d.line((10, 12, 22, 12), fill=b)
        d.point((13, 9), fill="#ffffff")
    elif shape == "geode":
        ball(d, 16, 17, 11, 10, "#8a8070")
        d.ellipse((9, 11, 23, 23), fill=c)
        d.ellipse((11, 13, 21, 21), fill=mix(c, "#ffffff", 0.35))
        for x, y in [(13, 15), (17, 14), (15, 18), (19, 18)]:
            d.polygon([(x, y), (x + 2, y - 3), (x + 3, y)], fill=mix(c, "#ffffff", 0.6))
    elif shape == "fossil":
        d.rounded_rectangle((4, 6, 28, 27), radius=4, fill=mix(a, "#505040", 0.35))
        d.rounded_rectangle((6, 8, 26, 25), radius=3, fill=a)
        d.arc((10, 11, 22, 23), 0, 300, fill=c, width=2)
        d.arc((13, 14, 19, 20), 0, 300, fill=c, width=1)
        d.line((6, 24, 26, 24), fill=b)
    elif shape == "bar":
        d.polygon([(4, 22), (9, 11), (25, 11), (29, 22)], fill=c)
        d.polygon([(6, 21), (10, 12), (24, 12), (27, 21)], fill=a)
        d.polygon([(8, 14), (11, 12), (23, 12), (23, 15), (9, 16)], fill=b)
        d.rectangle((4, 22, 29, 26), fill=c)
        d.line((6, 23, 27, 23), fill=a)
    elif shape in ("egg", "egg_small"):
        r = 8 if shape == "egg" else 5
        d.ellipse((16 - r, 17 - int(r * 1.2), 16 + r, 17 + int(r * 1.2)), fill=c)
        d.ellipse((16 - r, 17 - int(r * 1.2), 16 + r - 1, 17 + int(r * 1.2) - 2), fill=a)
        d.ellipse((16 - r + 2, 17 - int(r * 1.2) + 2, 16, 14), fill=b)
        if shape == "egg_small":
            for x, y in [(14, 16), (18, 19), (15, 21)]:
                d.point((x, y), fill=c)
    elif shape == "bottle":
        d.rectangle((13, 4, 19, 9), fill="#c8c0b0")
        d.polygon(
            [(13, 9), (19, 9), (24, 15), (24, 28), (8, 28), (8, 15)], fill=mix(a, "#a0b8c0", 0.4)
        )
        d.polygon([(10, 17), (22, 17), (22, 27), (10, 27)], fill=a)
        d.rectangle((10, 17, 22, 19), fill=b)
        d.line((10, 12, 10, 26), fill="#ffffff")
    elif shape == "wool":
        for x, y, r in [(11, 18, 6), (21, 18, 6), (16, 12, 6), (16, 21, 6)]:
            d.ellipse((x - r, y - r, x + r, y + r), fill=a)
        for x, y in [(12, 14), (19, 12), (15, 19)]:
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=b)
        d.arc((8, 15, 24, 27), 20, 160, fill=c)
    elif shape == "cheese":
        d.polygon([(3, 24), (14, 7), (29, 14), (29, 24)], fill=c)
        d.polygon([(3, 24), (14, 7), (29, 14), (26, 17), (5, 24)], fill=a)
        d.polygon([(3, 24), (29, 24), (29, 28), (3, 28)], fill=mix(a, "#000000", 0.18))
        for x, y in [(12, 19), (20, 20), (24, 16)]:
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=c)
    elif shape == "jar":
        d.rectangle((9, 11, 23, 28), fill=mix(a, "#ffffff", 0.35))
        d.rectangle((10, 14, 22, 27), fill=a)
        d.rectangle((10, 14, 22, 17), fill=b)
        d.rectangle((8, 7, 24, 11), fill="#a88a5a")
    elif shape == "cloth":
        d.rectangle((5, 18, 27, 26), fill=c)
        d.rectangle((6, 17, 26, 24), fill=a)
        d.rectangle((7, 11, 25, 17), fill=b)
        d.line((7, 14, 25, 14), fill=a)
        d.line((6, 21, 26, 21), fill=c)
    elif shape == "hay":
        for x in range(7, 26, 3):
            d.line((x, 26, x + (x % 5) - 2, 8), fill=a if x % 2 else b, width=2)
        d.rectangle((6, 16, 26, 19), fill="#8a6a38")
    elif shape == "bait":
        for x, y in [(10, 20), (17, 15), (21, 22), (13, 25)]:
            d.ellipse((x - 3, y - 2, x + 3, y + 2), fill=a)
            d.line((x - 2, y, x + 2, y), fill=c)
        d.arc((8, 8, 24, 18), 200, 340, fill=a, width=2)
    elif shape == "sack":
        d.polygon([(8, 12), (24, 12), (27, 26), (5, 26)], fill=a)
        d.polygon([(8, 12), (24, 12), (22, 16), (10, 16)], fill=b)
        d.rectangle((13, 8, 19, 12), fill=c)
        d.line((9, 20, 23, 20), fill=c)
    elif shape == "pearl":
        ball(d, 16, 16, 9, 9, "#f0ecec")
        d.point((12, 12), fill="#ffffff")
        d.point((13, 12), fill="#ffffff")
    elif shape == "shell":
        d.pieslice((3, 8, 29, 34), 180, 360, fill=a)
        for ang in range(200, 340, 20):
            import math

            x = 16 + math.cos(math.radians(ang)) * 12
            y = 21 + math.sin(math.radians(ang)) * 12
            d.line((16, 21, x, y), fill=c)
        d.rectangle((12, 22, 20, 26), fill=b)
    elif shape == "coral":
        for x, y in [(16, 27), (11, 21), (21, 20)]:
            d.line((16, 28, x, y), fill=a, width=3)
        for x, y in [(8, 12), (14, 8), (22, 10), (26, 15), (11, 17)]:
            d.line((16, 24, x, y), fill=a, width=2)
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=b)
    elif shape == "sphere_f":
        ball(d, 16, 18, 9, 8, a)
        d.polygon([(11, 11), (16, 9), (21, 11), (16, 13)], fill=green)
    elif shape == "round_root":
        for dx, dy in [(-7, -5), (7, -5), (0, -8)]:
            leaf(d, 16, 13, 16 + dx, 13 + dy, 1.8, green)
        ball(d, 16, 20, 9, 8, a)
        d.line((16, 28, 16, 31), fill=mix(a, "#000000", 0.4))
    elif shape == "glass":
        d.polygon([(6, 8), (26, 6), (27, 24), (7, 26)], fill=c)
        d.polygon([(8, 10), (24, 8), (25, 22), (9, 24)], fill=a)
        d.polygon([(8, 10), (14, 9), (9, 18)], fill=b)
        d.line((18, 9, 12, 24), fill=b)
        d.line((6, 8, 26, 6), fill=b)
    elif shape == "rope":
        for i in range(4):
            d.ellipse((6 + i, 8 + i, 26 - i, 26 - i), outline=a if i % 2 else b, width=2)
        d.ellipse((13, 15, 19, 20), fill=c)
        d.line((24, 22, 29, 28), fill=a, width=2)
        d.line((29, 28, 27, 31), fill=b, width=2)
    elif shape == "gel":
        d.polygon([(6, 26), (7, 17), (11, 11), (16, 8), (21, 11), (25, 17), (26, 26)], fill=c)
        d.polygon([(8, 25), (9, 18), (12, 13), (16, 11), (20, 13), (23, 18), (24, 25)], fill=a)
        d.ellipse((11, 13, 15, 17), fill=b)
        d.point((13, 15), fill="#ffffff")
        d.line((9, 25, 23, 25), fill=c)
    elif shape == "wing":
        d.polygon(
            [(4, 12), (10, 8), (16, 14), (22, 8), (28, 12), (24, 24), (18, 20), (14, 24), (8, 20)],
            fill=c,
        )
        d.polygon(
            [
                (7, 13),
                (11, 11),
                (16, 16),
                (21, 11),
                (25, 13),
                (22, 21),
                (18, 18),
                (14, 21),
                (10, 18),
            ],
            fill=a,
        )
        for x in (10, 14, 19, 22):
            d.line((16, 16, x, 21), fill=b)
    elif shape == "heart_stone":
        ball(d, 16, 17, 11, 10, a)
        d.polygon([(16, 24), (8, 15), (10, 11), (16, 14), (22, 11), (24, 15)], fill=c)
        d.polygon([(16, 22), (11, 16), (12, 13), (16, 15), (20, 13), (21, 16)], fill=b)
        d.point((13, 14), fill="#ffffff")
    elif shape == "core":
        d.polygon([(16, 3), (26, 14), (16, 29), (6, 14)], fill=c)
        d.polygon([(16, 3), (21, 14), (16, 29), (11, 14)], fill=a)
        d.polygon([(16, 7), (19, 14), (16, 22), (13, 14)], fill=b)
        d.line((6, 14, 26, 14), fill=b)
        d.line((16, 1, 16, 3), fill=b)
        d.point((14, 10), fill="#ffffff")
    elif shape == "lantern":
        d.rectangle((13, 3, 19, 6), fill=c)
        d.rectangle((8, 6, 24, 9), fill=c)
        d.rectangle((9, 9, 23, 24), fill=a)
        d.rectangle((11, 11, 21, 22), fill=b)
        d.rectangle((8, 24, 24, 27), fill=c)
        d.line((16, 9, 16, 24), fill=a)
        d.line((16, 27, 16, 30), fill=c)
    elif shape == "ring":
        d.ellipse((5, 8, 27, 28), outline=c, width=4)
        d.ellipse((7, 10, 25, 26), outline=a, width=2)
        d.polygon([(16, 2), (21, 7), (16, 11), (11, 7)], fill="#bfe4ea")
        d.polygon([(16, 2), (19, 7), (16, 8), (13, 7)], fill="#ffffff")
        d.line((7, 18, 12, 26), fill=b)
    elif shape == "shoot_g":
        for dx in (-6, 0, 6):
            d.polygon([(16 + dx - 2, 28), (16 + dx + 2, 28), (16 + dx, 6 + abs(dx) // 2)], fill=a)
            d.line((16 + dx, 26, 16 + dx, 10), fill=b)
    return outlined(im)

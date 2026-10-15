"""Layered pixel terrain: clustered grass, worn paths and stepped river banks."""

from PIL import Image, ImageDraw, ImageFilter
import random
from .decor import draw_decor


BIOMES = {
    "meadow": {
        "base": "#72944c",
        "patches": ["#6c8e48", "#789b50", "#7d9e52", "#688b47", "#74954c"],
        "path_edge": "#8b8b50",
        "path": "#c1ad73",
        "flecks": ["#d8c58b", "#b49b66", "#cdb77f"],
        "clod": "#a68d60",
        "bank": "#4f6544",
        "shore": "#b2a978",
        "water": "#76a29a",
        "deep": "#487f83",
        "ripples": ["#639997", "#75aaa1", "#91bdb0", "#3f7379"],
        "glint": "#a5cbbb",
        "pebble": "#717f65",
        "pebble_light": "#d0c69c",
    },
    "beach": {
        "base": "#dcc88f",
        "patches": ["#d4bf86", "#e2d09c", "#cdb77c", "#e6d6a8", "#d8c48c"],
        "path_edge": "#9a7a4a",
        "path": "#b8905a",
        "flecks": ["#d0a870", "#9a7a48", "#c89c64"],
        "clod": "#7a5a34",
        "bank": "#bba870",
        "shore": "#f4f0e0",
        "water": "#4f92b0",
        "deep": "#2f6f95",
        "ripples": ["#6fb0c8", "#8ccadc", "#b0e0ec", "#2a6a8a"],
        "glint": "#d8f0f8",
        "pebble": "#d8c898",
        "pebble_light": "#f4ecd0",
    },
    "cave": {
        "base": "#5a5a64",
        "patches": ["#52525c", "#62626c", "#4a4a54", "#68687a", "#58586a"],
        "path_edge": "#4a4238",
        "path": "#8a7a68",
        "flecks": ["#a29080", "#74665a", "#988878"],
        "clod": "#5a4c40",
        "bank": "#2a3a44",
        "shore": "#5a7a80",
        "water": "#3a6a78",
        "deep": "#1f4452",
        "ripples": ["#4a7a88", "#5a8a98", "#7aa8b4", "#2a5260"],
        "glint": "#9ac8d0",
        "pebble": "#3a4a50",
        "pebble_light": "#8aa8b0",
    },
}


def style_paths(im, paths, style, rng):
    """Replaces the plain dirt fill with cobblestones or boardwalk planks, clipped to the path."""
    w, h = im.size
    layer = im.copy()
    d = ImageDraw.Draw(layer)
    if style == "cobble":
        for row, y in enumerate(range(0, h, 12)):
            offset = 0 if row % 2 == 0 else 8
            for x in range(-offset, w, 16):
                cx, cy = x + 8, y + 6
                if not (0 <= cx < w and 0 <= cy < h and paths.getpixel((cx, cy))):
                    continue
                base = rng.choice(["#a29c8c", "#9a9486", "#aaa494", "#928c7e"])
                d.rectangle((x + 1, y + 1, x + 14, y + 10), fill=base)
                d.line((x + 1, y + 1, x + 14, y + 1), fill="#c4beac")
                d.line((x + 1, y + 10, x + 14, y + 10), fill="#6a665c")
                d.line((x, y, x, y + 11), fill="#6a665c")
    else:
        for row, y in enumerate(range(0, h, 8)):
            x = -rng.randrange(0, 40)
            while x < w:
                length = rng.choice([40, 48, 56])
                cx, cy = x + length // 2, y + 4
                if 0 <= cx < w and 0 <= cy < h and paths.getpixel((cx, cy)):
                    base = rng.choice(["#b8905a", "#a8824e", "#c49c66"])
                    d.rectangle((x, y, x + length - 1, y + 6), fill=base)
                    d.line((x, y, x + length - 1, y), fill="#d8b47c")
                    d.line((x, y + 7, x + length - 1, y + 7), fill="#5a3e24")
                    d.line((x + length - 1, y, x + length - 1, y + 7), fill="#5a3e24")
                    d.point((x + 3, y + 3), fill="#6a4a2a")
                    d.point((x + length - 4, y + 3), fill="#6a4a2a")
                x += length
    im.paste(layer, (0, 0), paths)


def landscape(region):
    w, h = region["width"] * 32, region["height"] * 32
    biome = region.get("biome", "meadow")
    pal = BIOMES[biome]
    rng = random.Random(720 + sum(map(ord, region["id"])))
    im = Image.new("RGB", (w, h), pal["base"])
    d = ImageDraw.Draw(im)
    # Large irregular patches keep the meadow from looking like repeated solid tiles.
    for _ in range(w * h // 1900):
        x = rng.randrange(w)
        y = rng.randrange(h)
        rx = rng.randrange(18, 83)
        ry = rng.randrange(8, 34)
        color = rng.choice(pal["patches"])
        d.polygon(
            [
                (x - rx, y),
                (x - rx + 8, y - ry + 4),
                (x - 10, y - ry),
                (x + rx - 12, y - ry + 5),
                (x + rx, y),
                (x + rx - 8, y + ry),
                (x - 15, y + ry + 3),
                (x - rx + 3, y + ry - 5),
            ],
            fill=color,
        )
    if biome == "meadow":
        grass = ["#97b563", "#a9bd6a", "#587e40", "#628747", "#87a856"]
        for _ in range(w * h // 60):
            x = rng.randrange(1, w - 6)
            y = rng.randrange(6, h - 3)
            c = rng.choice(grass)
            d.line((x, y, x - 1, y - 3), fill=c)
            d.line((x + 2, y, x + 3, y - 4), fill=c)
            if rng.random() < 0.4:
                d.point((x + 1, y + 1), fill="#567a3e")
    elif biome == "beach":
        for _ in range(w * h // 180):
            x = rng.randrange(2, w - 14)
            y = rng.randrange(4, h - 3)
            c = rng.choice(["#c8b27a", "#ecdcae", "#bda46a"])
            d.line((x, y, x + rng.randrange(4, 12), y), fill=c)
        for _ in range(w * h // 2600):
            x = rng.randrange(6, w - 8)
            y = rng.randrange(8, h - 6)
            d.ellipse((x, y, x + 4, y + 2), fill=rng.choice(["#f0d0c0", "#e8b8a0", "#fff0e4"]))
    else:
        for _ in range(w * h // 700):
            x = rng.randrange(4, w - 10)
            y = rng.randrange(6, h - 6)
            r = rng.randrange(2, 6)
            d.ellipse((x, y, x + r * 2, y + r), fill=rng.choice(["#46464e", "#6e6e7c", "#3e3e46"]))
        for _ in range(w * h // 5200):
            x = rng.randrange(6, w - 12)
            y = rng.randrange(8, h - 8)
            d.line((x, y, x + rng.randrange(6, 16), y + rng.randrange(-4, 5)), fill="#3a3a42")
    paths = Image.new("L", (w, h))
    pd = ImageDraw.Draw(paths)
    for x, y, ww, hh in region["paths"]:
        pd.rectangle((x * 32, y * 32, (x + ww) * 32 - 1, (y + hh) * 32 - 1), fill=255)
    # Worn edges have clipped pixels and sporadic grass intrusions.
    small = paths.resize((w // 8, h // 8), Image.Resampling.NEAREST)
    sd = ImageDraw.Draw(small)
    for _ in range(w * h // 250):
        x = rng.randrange(1, small.width - 1)
        y = rng.randrange(1, small.height - 1)
        if small.getpixel((x, y)) and any(
            not small.getpixel((x + a, y + b)) for a, b in [(1, 0), (-1, 0), (0, 1), (0, -1)]
        ):
            if rng.random() < 0.55:
                sd.point((x, y), fill=0)
    paths = small.resize((w, h), Image.Resampling.NEAREST)
    edge = paths.filter(ImageFilter.MaxFilter(9))
    im.paste(pal["path_edge"], (0, 0), edge)
    im.paste(pal["path"], (0, 0), paths)
    path_style = region.get("path_style", "dirt")
    if path_style != "dirt":
        style_paths(im, paths, path_style, rng)
    d = ImageDraw.Draw(im)
    for _ in range(w * h // 80 if path_style == "dirt" else 0):
        x = rng.randrange(w - 8)
        y = rng.randrange(h - 4)
        if paths.getpixel((x, y)):
            d.line(
                (x, y, x + rng.randrange(2, 7), y),
                fill=rng.choice(pal["flecks"]),
            )
            if rng.random() < 0.15:
                d.rectangle((x, y, x + 2, y + 1), fill=pal["clod"])
    water = Image.new("L", (w, h))
    wd = ImageDraw.Draw(water)
    # Use the same occupied cells as collision, so the visible shore matches walkability.
    cellmask = Image.new("1", (region["width"], region["height"]))
    cd = ImageDraw.Draw(cellmask)
    for poly in region["water"]:
        cd.polygon([tuple(p) for p in poly], fill=1)
    for yy in range(region["height"]):
        for xx in range(region["width"]):
            if cellmask.getpixel((xx, yy)):
                wd.rectangle((xx * 32, yy * 32, xx * 32 + 31, yy * 32 + 31), fill=255)
    if water.getbbox():
        bank = water.filter(ImageFilter.MaxFilter(17))
        im.paste(pal["bank"], (0, 0), bank)
        im.paste(pal["shore"], (0, 0), water.filter(ImageFilter.MaxFilter(9)))
        im.paste(pal["water"], (0, 0), water)
        im.paste(pal["deep"], (0, 0), water.filter(ImageFilter.MinFilter(17)))
        d = ImageDraw.Draw(im)
        for _ in range(w * h // 130):
            x = rng.randrange(12, w - 24)
            y = rng.randrange(12, h - 16)
            if not water.getpixel((x, y)):
                continue
            if all(water.getpixel((x + a, y + b)) for a, b in [(10, 0), (-10, 0), (0, 8), (0, -8)]):
                if rng.random() < 0.5:
                    d.line(
                        (x, y, x + rng.randrange(4, 18), y),
                        fill=rng.choice(pal["ripples"]),
                    )
                    if rng.random() < 0.2:
                        d.line((x + 3, y + 2, x + 8, y + 2), fill=pal["glint"])
            else:
                d.ellipse((x - 4, y - 2, x + 5, y + 3), fill=pal["pebble"])
                d.line((x - 2, y - 2, x + 3, y - 2), fill=pal["pebble_light"])
    d = ImageDraw.Draw(im)
    for _ in range(w * h // 2100 if biome == "meadow" else 0):
        x = rng.randrange(6, w - 7)
        y = rng.randrange(8, h - 7)
        if paths.getpixel((x, y)) or water.getpixel((x, y)):
            continue
        d.line((x, y, x - 1, y - 5), fill="#436e3c", width=2)
        c = rng.choice(["#e6d49d", "#d7a9a2", "#a5be83"])
        d.rectangle((x - 3, y - 7, x + 1, y - 5), fill=c)
        d.point((x - 1, y - 6), fill="#f2e7c1")
    if region["id"] == "town":
        for x, y in [(23, 26), (53, 26), (31, 38), (48, 38)]:
            x *= 32
            y *= 32
            d.rectangle((x - 35, y - 10, x + 37, y + 13), fill="#665a3b")
            for i in range(12):
                xx = x - 29 + i * 5
                yy = y + (i % 3) * 3
                d.line((xx, yy + 6, xx, yy - 4), fill="#3b683d")
                d.rectangle(
                    (xx - 2, yy - 6, xx + 2, yy - 3),
                    fill=["#d5a09b", "#e4c788", "#b8c986"][i % 3],
                )
    # Subtle perimeter marks; entrances remain open and clear.
    for x in range(32, w - 32, 32) if biome == "meadow" else []:
        for y in [24, h - 24]:
            if any(
                abs(x - (s["cell"][0] + 0.5) * 32) < 96 and abs(y - (s["cell"][1] + 0.5) * 32) < 96
                for s in region["stations"]
            ):
                continue
            d.rectangle((x, y, x + 26, y + 3), fill="#7e7247")
            d.rectangle((x, y - 5, x + 4, y + 10), fill="#b99d64")
            d.line((x, y - 5, x + 4, y - 5), fill="#d1b77b")
    return draw_decor(im, region)

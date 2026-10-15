"""Layered pixel terrain: clustered grass, worn paths and stepped river banks."""

from PIL import Image, ImageDraw, ImageFilter
import random


def landscape(region):
    w, h = region["width"] * 32, region["height"] * 32
    rng = random.Random(720 + sum(map(ord, region["id"])))
    im = Image.new("RGB", (w, h), "#72944c")
    d = ImageDraw.Draw(im)
    # Large irregular patches keep the meadow from looking like repeated solid tiles.
    for _ in range(w * h // 1900):
        x = rng.randrange(w)
        y = rng.randrange(h)
        rx = rng.randrange(18, 83)
        ry = rng.randrange(8, 34)
        color = rng.choice(["#6c8e48", "#789b50", "#7d9e52", "#688b47", "#74954c"])
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
    grass = ["#97b563", "#a9bd6a", "#587e40", "#628747", "#87a856"]
    for _ in range(w * h // 60):
        x = rng.randrange(1, w - 6)
        y = rng.randrange(6, h - 3)
        c = rng.choice(grass)
        d.line((x, y, x - 1, y - 3), fill=c)
        d.line((x + 2, y, x + 3, y - 4), fill=c)
        if rng.random() < 0.4:
            d.point((x + 1, y + 1), fill="#567a3e")
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
    im.paste("#8b8b50", (0, 0), edge)
    im.paste("#c1ad73", (0, 0), paths)
    d = ImageDraw.Draw(im)
    for _ in range(w * h // 80):
        x = rng.randrange(w - 8)
        y = rng.randrange(h - 4)
        if paths.getpixel((x, y)):
            d.line(
                (x, y, x + rng.randrange(2, 7), y),
                fill=rng.choice(["#d8c58b", "#b49b66", "#cdb77f"]),
            )
            if rng.random() < 0.15:
                d.rectangle((x, y, x + 2, y + 1), fill="#a68d60")
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
        im.paste("#4f6544", (0, 0), bank)
        im.paste("#b2a978", (0, 0), water.filter(ImageFilter.MaxFilter(9)))
        im.paste("#76a29a", (0, 0), water)
        im.paste("#487f83", (0, 0), water.filter(ImageFilter.MinFilter(17)))
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
                        fill=rng.choice(["#639997", "#75aaa1", "#91bdb0", "#3f7379"]),
                    )
                    if rng.random() < 0.2:
                        d.line((x + 3, y + 2, x + 8, y + 2), fill="#a5cbbb")
            else:
                d.ellipse((x - 4, y - 2, x + 5, y + 3), fill="#717f65")
                d.line((x - 2, y - 2, x + 3, y - 2), fill="#d0c69c")
    d = ImageDraw.Draw(im)
    for _ in range(w * h // 2100):
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
    for x in range(32, w - 32, 32):
        for y in [24, h - 24]:
            if any(
                abs(x - (s["cell"][0] + 0.5) * 32) < 96 and abs(y - (s["cell"][1] + 0.5) * 32) < 96
                for s in region["stations"]
            ):
                continue
            d.rectangle((x, y, x + 26, y + 3), fill="#7e7247")
            d.rectangle((x, y - 5, x + 4, y + 10), fill="#b99d64")
            d.line((x, y - 5, x + 4, y - 5), fill="#d1b77b")
    return im

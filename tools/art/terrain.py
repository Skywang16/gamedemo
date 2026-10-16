"""Map backgrounds: the image model's seamless ground tiles laid out per region, with worn path edges and river banks."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter
import random
from .decor import draw_decor

ART = Path(__file__).resolve().parents[2] / "assets/art"

# Which tiles a biome is made of, the colour of the worn rim around paths, and the river banks.
BIOMES = {
    "meadow": {
        "base": "grass_a",
        "patches": ["grass_b", "grass_b", "grass_c"],
        "path": "dirt",
        "path_edge": "#7d7a45",
        "bank": "#4f6544",
        "shore": "#b2a978",
    },
    "beach": {
        "base": "sand",
        "patches": [],
        "path": "dirt",
        "path_edge": "#9a7a4a",
        "bank": "#bba870",
        "shore": "#f4f0e0",
    },
    "cave": {
        "base": "cave",
        "patches": [],
        "path": "dirt",
        "path_edge": "#4a4238",
        "bank": "#2a3a44",
        "shore": "#5a7a80",
    },
}
PATH_TILES = {"dirt": "dirt", "cobble": "cobble", "boardwalk": "plank"}


def tiled(name, w, h, rng, dim=1.0):
    """The seamless tile repeated over a w x h picture, shifted by a random offset."""
    tile = Image.open(ART / f"ground_{name}.png").convert("RGB")
    if dim != 1.0:
        tile = ImageEnhance.Brightness(tile).enhance(dim)
    out = Image.new("RGB", (w, h))
    ox, oy = rng.randrange(tile.width), rng.randrange(tile.height)
    for y in range(-oy, h, tile.height):
        for x in range(-ox, w, tile.width):
            out.paste(tile, (x, y))
    return out


def blob(rng, x, y, rx, ry):
    return [
        (x - rx, y),
        (x - rx + 8, y - ry + 4),
        (x - 10, y - ry),
        (x + rx - 12, y - ry + 5),
        (x + rx, y),
        (x + rx - 8, y + ry),
        (x - 15, y + ry + 3),
        (x - rx + 3, y + ry - 5),
    ]


def landscape(region):
    w, h = region["width"] * 32, region["height"] * 32
    biome = region.get("biome", "meadow")
    pal = BIOMES[biome]
    rng = random.Random(720 + sum(map(ord, region["id"])))
    im = tiled(pal["base"], w, h, rng)
    # Large irregular patches of the other grass tiles keep the meadow from reading as a repeated stamp.
    if pal["patches"]:
        masks = {name: Image.new("L", (w, h)) for name in set(pal["patches"])}
        for _ in range(w * h // 14000):
            x, y = rng.randrange(w), rng.randrange(h)
            ImageDraw.Draw(masks[rng.choice(pal["patches"])]).polygon(
                blob(rng, x, y, rng.randrange(60, 200), rng.randrange(30, 100)), fill=255
            )
        for name, mask in masks.items():
            im.paste(tiled(name, w, h, rng), (0, 0), mask.filter(ImageFilter.GaussianBlur(2)))
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
    path_style = region.get("path_style", "dirt")
    surface = tiled(PATH_TILES[path_style], w, h, rng, 0.72 if biome == "cave" else 1.0)
    if path_style == "dirt":
        im.paste(pal["path_edge"], (0, 0), paths.filter(ImageFilter.MaxFilter(9)))
    im.paste(surface, (0, 0), paths)
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
        surface = tiled("water", w, h, rng)
        im.paste(pal["bank"], (0, 0), water.filter(ImageFilter.MaxFilter(17)))
        im.paste(pal["shore"], (0, 0), water.filter(ImageFilter.MaxFilter(9)))
        im.paste(surface, (0, 0), water)
        # Deeper water in the middle of the channel.
        deep = ImageEnhance.Brightness(surface).enhance(0.78)
        im.paste(
            deep,
            (0, 0),
            water.filter(ImageFilter.MinFilter(17)).filter(ImageFilter.GaussianBlur(3)),
        )
    d = ImageDraw.Draw(im)
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

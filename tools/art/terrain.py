"""Map backgrounds, built like a tile map on the art grid: one grass ground, paths and river banks with
hand-pixelled edges, tufts and flowers. Drawn at 16 art pixels per cell, snapped to the world palette,
then scaled up to game pixels (art/finish.py) so ground, sprites and characters share one pixel size.
"""

from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter
import random

from art import finish
from .decor import draw_decor

ART = Path(__file__).resolve().parents[2] / "assets/art"
CELL = 16  # art pixels per map cell

# Which ground a biome is made of, and the colours of its river bank, foam and plant details.
BIOMES = {
    "meadow": {
        "base": "grass_a",
        "bank": (146, 118, 78),
        "bank_edge": (84, 64, 42),
        "foam": (190, 226, 220),
        "tuft": ((66, 118, 58), (132, 182, 88)),
        "flowers": [(246, 240, 226), (244, 214, 110), (232, 150, 170)],
    },
    "beach": {
        "base": "sand",
        "bank": (214, 196, 142),
        "bank_edge": (150, 126, 84),
        "foam": (250, 248, 238),
        "tuft": ((152, 132, 84), (206, 188, 128)),
        "flowers": [(246, 236, 220)],
    },
    "cave": {
        "base": "cave",
        "bank": (58, 70, 80),
        "bank_edge": (24, 32, 40),
        "foam": (120, 160, 166),
        "tuft": ((40, 52, 60), (84, 98, 108)),
        "flowers": [],
    },
}
PATH_TILES = {"dirt": "dirt", "cobble": "cobble", "boardwalk": "plank"}
# How much each path style rounds its corners (blur radius, art px) and darkens its rim.
PATH_LOOK = {
    "dirt": {"round": 3, "rim": 0.58, "ragged": 60},
    "cobble": {"round": 2, "rim": 0.55, "ragged": 30},
    "boardwalk": {"round": 0, "rim": 0.5, "ragged": 0},
}


def texture(name):
    """A ground texture on the art grid (64 x 64)."""
    return finish.to_art(Image.open(ART / f"ground_{name}.png")).convert("RGB")


def tiled(name, w, h, rng, dim=1.0):
    """The seamless tile repeated over a w x h art picture, shifted by a random offset."""
    tile = texture(name)
    if dim != 1.0:
        tile = ImageEnhance.Brightness(tile).enhance(dim)
    out = Image.new("RGB", (w, h))
    ox, oy = rng.randrange(tile.width), rng.randrange(tile.height)
    for y in range(-oy, h, tile.height):
        for x in range(-ox, w, tile.width):
            out.paste(tile, (x, y))
    return out


def noise(w, h, rng, block=2):
    """Random 0..255 values in block x block squares, so a rough edge has pixel clusters, not static."""
    small = Image.frombytes(
        "L", (w // block + 1, h // block + 1), rng.randbytes((w // block + 1) * (h // block + 1))
    )
    return small.resize((small.width * block, small.height * block), Image.NEAREST).crop(
        (0, 0, w, h)
    )


def shape(mask, radius, ragged, rng):
    """Round the corners of a hard cell mask and roughen its edge by a pixel or two."""
    if not radius:
        return mask
    soft = mask.filter(ImageFilter.GaussianBlur(radius))
    if ragged:
        soft = ImageChops.add(soft, noise(*mask.size, rng).point(lambda v: v * ragged // 255))
        soft = ImageChops.subtract(soft, Image.new("L", mask.size, ragged // 2))
    return soft.point(lambda v: 255 if v > 127 else 0)


def cells_mask(size, rects):
    mask = Image.new("L", size)
    d = ImageDraw.Draw(mask)
    for x, y, w, h in rects:
        d.rectangle((x * CELL, y * CELL, (x + w) * CELL - 1, (y + h) * CELL - 1), fill=255)
    return mask


def paint_path(im, mask, surface, look, grass_dark, rng):
    """Surface inside the mask, a darker one-pixel rim, and grass overhanging the outside edge."""
    inner = mask.filter(ImageFilter.MinFilter(3))
    rim = ImageChops.subtract(mask, inner)
    im.paste(surface, (0, 0), mask)
    dark = ImageEnhance.Brightness(surface).enhance(look["rim"])
    im.paste(dark, (0, 0), rim)
    outer = ImageChops.subtract(mask.filter(ImageFilter.MaxFilter(3)), mask)
    if look["ragged"]:
        tufts = noise(*mask.size, rng).point(lambda v: 255 if v < 110 else 0)
        im.paste(Image.new("RGB", mask.size, grass_dark), (0, 0), ImageChops.multiply(outer, tufts))
    else:
        shadow = ImageChops.offset(mask, 0, 1)
        shadow = ImageChops.subtract(shadow, mask)
        im.paste(Image.new("RGB", mask.size, (40, 48, 40)), (0, 0), shadow.point(lambda v: v // 2))


def paint_water(im, water, pal, rng):
    """River: bank, dark bank edge, water, foam on the shore and darker deep water."""
    edge = water.filter(ImageFilter.MaxFilter(9))
    bank = water.filter(ImageFilter.MaxFilter(7))
    surface = tiled("water", *im.size, rng)
    im.paste(Image.new("RGB", im.size, pal["bank_edge"]), (0, 0), edge)
    im.paste(Image.new("RGB", im.size, pal["bank"]), (0, 0), bank)
    waves = surface.copy()
    d = ImageDraw.Draw(waves)
    light, dark = (
        ImageEnhance.Brightness(surface).enhance(1.28),
        ImageEnhance.Brightness(surface).enhance(0.82),
    )
    for _ in range(im.width * im.height // 230):
        x, y, n = rng.randrange(im.width), rng.randrange(im.height), rng.randrange(3, 7)
        d.line((x, y, x + n, y), fill=light.getpixel((x, y)))
        d.line((x + 1, y + 1, x + n - 1, y + 1), fill=dark.getpixel((x, y)))
    im.paste(waves, (0, 0), water)
    foam = ImageChops.subtract(water, water.filter(ImageFilter.MinFilter(3)))
    im.paste(Image.new("RGB", im.size, pal["foam"]), (0, 0), foam)
    deep = water.filter(ImageFilter.MinFilter(9))
    im.paste(ImageEnhance.Brightness(waves).enhance(0.84), (0, 0), deep)


def scatter(im, region, pal, rng, blocked):
    """Grass tufts and tiny flowers on open ground, a few per cell, never on paths or water."""
    d = ImageDraw.Draw(im)
    dark, light = pal["tuft"]
    for cy in range(region["height"]):
        for cx in range(region["width"]):
            if (cx, cy) in blocked:
                continue
            x, y = cx * CELL + rng.randrange(2, 12), cy * CELL + rng.randrange(3, 13)
            roll = rng.random()
            if roll < 0.16:
                d.point([(x, y + 1), (x + 1, y), (x + 1, y + 1), (x + 2, y + 1)], fill=dark)
                d.point([(x + 1, y - 1)], fill=light)
            elif roll < 0.2 and pal["flowers"]:
                d.point([(x, y), (x + 1, y)], fill=rng.choice(pal["flowers"]))
                d.point([(x, y + 1)], fill=dark)


def blocked_cells(region):
    cells = set()
    for x, y, w, h in region["paths"]:
        cells.update((xx, yy) for yy in range(y, y + h) for xx in range(x, x + w))
    for poly in region["water"]:
        xs = [p[0] for p in poly]
        ys = [p[1] for p in poly]
        cells.update(
            (xx, yy)
            for yy in range(min(ys) - 1, max(ys) + 2)
            for xx in range(min(xs) - 1, max(xs) + 2)
        )
    return cells


def garden_beds(d):
    """The town's flower beds: a packed-earth bed with a row of flowers."""
    for x, y in [(23, 26), (53, 26), (31, 38), (48, 38)]:
        x *= CELL
        y *= CELL
        d.rectangle((x - 17, y - 5, x + 18, y + 6), fill=(102, 90, 59))
        for i in range(6):
            xx = x - 14 + i * 5
            yy = y + (i % 3) * 2
            d.line((xx, yy + 3, xx, yy - 2), fill=(59, 104, 61))
            d.rectangle(
                (xx - 1, yy - 3, xx + 1, yy - 2),
                fill=[(213, 160, 155), (228, 199, 136), (184, 201, 134)][i % 3],
            )


def fence_marks(d, region):
    """Subtle perimeter posts; entrances stay open and clear."""
    w, h = region["width"] * CELL, region["height"] * CELL
    for x in range(CELL, w - CELL, CELL):
        for y in [12, h - 12]:
            if any(
                abs(x - (s["cell"][0] + 0.5) * CELL) < 48
                and abs(y - (s["cell"][1] + 0.5) * CELL) < 48
                for s in region["stations"]
            ):
                continue
            d.rectangle((x, y, x + 13, y + 1), fill=(126, 114, 71))
            d.rectangle((x, y - 3, x + 2, y + 5), fill=(185, 157, 100))
            d.line((x, y - 3, x + 2, y - 3), fill=(209, 183, 123))


def landscape(region):
    w, h = region["width"] * CELL, region["height"] * CELL
    biome = region.get("biome", "meadow")
    pal = BIOMES[biome]
    rng = random.Random(720 + sum(map(ord, region["id"])))
    im = tiled(pal["base"], w, h, rng)
    paths = cells_mask((w, h), region["paths"])
    style = region.get("path_style", "dirt")
    look = PATH_LOOK[style]
    # The occupied cells are the collision cells, so the visible shore matches walkability.
    occupied = Image.new("1", (region["width"], region["height"]))
    for poly in region["water"]:
        ImageDraw.Draw(occupied).polygon([tuple(p) for p in poly], fill=1)
    water = cells_mask(
        (w, h),
        [
            (x, y, 1, 1)
            for y in range(region["height"])
            for x in range(region["width"])
            if occupied.getpixel((x, y))
        ],
    )
    if water.getbbox():
        paint_water(im, shape(water, 4, 60, rng), pal, rng)
    if paths.getbbox():
        surface = tiled(PATH_TILES[style], w, h, rng, 0.72 if biome == "cave" else 1.0)
        grass_dark = pal["tuft"][0]
        paint_path(
            im, shape(paths, look["round"], look["ragged"], rng), surface, look, grass_dark, rng
        )
    scatter(im, region, pal, rng, blocked_cells(region))
    d = ImageDraw.Draw(im)
    if region["id"] == "town":
        garden_beds(d)
    if biome == "meadow":
        fence_marks(d, region)
    ground = finish.from_art(finish.snap(im).convert("RGB"))
    return draw_decor(ground, region)

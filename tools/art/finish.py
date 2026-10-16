"""The one look every drawn asset shares: a single pixel grain, a single palette, a single ground shadow.

Stardew-style maps work because everything lives on one grid with one pixel size. Here the art grid is
GRAIN game pixels per art pixel (2), so a 32 px map cell is 16 art pixels. Every sprite and ground
texture is reduced to the art grid, snapped to the one world palette and scaled back up with nearest
neighbour; sprites that stand on the ground get a hard-edged contact shadow under them.

    python tools/art/finish.py palette     # rebuild assets/reference/world_palette.json
"""

from functools import lru_cache
import json
from pathlib import Path
import random
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
PALETTE_FILE = ROOT / "assets/reference/world_palette.json"
GRAIN = 2
COLORS = 160
SHADOW = (24, 36, 46)


@lru_cache(maxsize=1)
def palette_image() -> Image.Image:
    colors = json.loads(PALETTE_FILE.read_text())
    flat = [c for rgb in colors for c in rgb]
    flat += flat[:3] * ((768 - len(flat)) // 3)
    image = Image.new("P", (1, 1))
    image.putpalette(flat)
    return image


def snap(rgb: Image.Image) -> Image.Image:
    """Nearest colour of the world palette for every pixel, no dithering."""
    return rgb.convert("RGB").quantize(palette=palette_image(), dither=Image.Dither.NONE)


def lock_art(art: Image.Image) -> Image.Image:
    """An RGBA picture at art-grid size: world palette and hard 0/255 alpha."""
    art = art.convert("RGBA")
    alpha = art.getchannel("A").point(lambda a: 255 if a > 127 else 0)
    out = snap(art).convert("RGBA")
    out.putalpha(alpha)
    return out


def grain(im: Image.Image) -> Image.Image:
    """Game-size RGBA (even dimensions) -> art grid -> palette -> back at game size."""
    if im.width % GRAIN or im.height % GRAIN:
        raise ValueError(f"size {im.size} is not a multiple of the art grid")
    art = im.convert("RGBA").resize((im.width // GRAIN, im.height // GRAIN), Image.BOX)
    return lock_art(art).resize(im.size, Image.NEAREST)


def to_art(im: Image.Image) -> Image.Image:
    """A picture already on the grain, read back at art-grid size."""
    return im.convert("RGBA").resize((im.width // GRAIN, im.height // GRAIN), Image.NEAREST)


def from_art(art: Image.Image) -> Image.Image:
    return art.resize((art.width * GRAIN, art.height * GRAIN), Image.NEAREST)


def wrapped(tile: Image.Image, fn) -> Image.Image:
    """Apply a filter to a seamless tile without creating a seam: filter the 3 x 3 mosaic, keep the middle."""
    w, h = tile.size
    mosaic = Image.new(tile.mode, (w * 3, h * 3))
    for y in range(3):
        for x in range(3):
            mosaic.paste(tile, (x * w, y * h))
    return fn(mosaic).crop((w, h, 2 * w, 2 * h))


def ramp(tile: Image.Image, colors: int, flatten: float = 0.0) -> Image.Image:
    """A seamless ground tile on the art grid reduced to a few tones of the world palette.

    `flatten` (0..1) removes the model's broad light and dark patches and softens the rest, so a
    meadow is a calm even green with small details instead of static. The tones are the tile's own
    colours moved to their nearest world-palette entries."""
    tile = tile.convert("RGB")
    if flatten:
        low = wrapped(tile, lambda im: im.filter(ImageFilter.GaussianBlur(10)))
        mean = tile.resize((1, 1), Image.BOX).getpixel((0, 0))
        detail = ImageChops.subtract(tile, low, 1.0, 128)
        detail = detail.point(lambda v: 128 + round((v - 128) * (1 - flatten)))
        tile = ImageChops.add(Image.new("RGB", tile.size, mean), detail, 1.0, -128)
    tile = wrapped(tile, lambda im: im.filter(ImageFilter.MedianFilter(3)))
    reduced = tile.quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.Dither.NONE)
    centroids = reduced.getpalette()[: colors * 3]
    world = json.loads(PALETTE_FILE.read_text())
    flat: list[int] = []
    for i in range(0, len(centroids), 3):
        near = min(world, key=lambda c: sum((a - b) ** 2 for a, b in zip(c, centroids[i : i + 3])))
        flat += near
    reduced.putpalette(flat + flat[:3] * ((768 - len(flat)) // 3))
    return reduced.convert("RGB")


def shadow(im: Image.Image, shape: str = "ellipse") -> Image.Image:
    """Hard-edged contact shadow under a sprite standing on the ground, light from the upper left.

    `im` is a game-size RGBA canvas on the grain. The shadow sits under the lowest opaque rows,
    stretches a little to the right and is only drawn where the sprite itself is empty."""
    art = to_art(im)
    alpha = art.getchannel("A")
    box = alpha.point(lambda a: 255 if a > 0 else 0).getbbox()
    if box is None:
        return im
    bottom = box[3] - 1
    cols = [x for x in range(art.width) if alpha.crop((x, bottom - 2, x + 1, bottom + 1)).getbbox()]
    left, right = cols[0], cols[-1]
    layer = Image.new("RGBA", art.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    colour = SHADOW + (92,)
    if shape == "band":
        d.rectangle((left - 1, bottom - 1, right + 3, bottom + 1), fill=colour)
        for x, y in ((left - 1, bottom + 1), (right + 3, bottom + 1), (right + 3, bottom - 1)):
            d.point((x, y), fill=(0, 0, 0, 0))
    else:
        half = max((right - left) // 2 + 2, art.width // 4)
        mid = (left + right) // 2 + 2
        d.ellipse((mid - half, bottom - 2, mid + half, bottom + 2), fill=colour)
    layer.alpha_composite(art)
    return from_art(layer)


def build_palette() -> None:
    """The world palette: median cut over an equal sample of every drawn asset."""
    art = ROOT / "assets/art"
    library = ROOT / "assets/library/interiors/v2"
    names = [p for p in sorted(art.glob("*.png")) if is_world_art(p.stem)]
    names += sorted(library.glob("*.png"))
    rng = random.Random(7)
    pixels: list[tuple[int, int, int]] = []
    for path in names:
        im = Image.open(path).convert("RGBA")
        raw = im.tobytes()
        solid = [tuple(raw[i : i + 3]) for i in range(0, len(raw), 4) if raw[i + 3] > 127]
        pixels += rng.sample(solid, min(len(solid), 2500))
    side = int(len(pixels) ** 0.5) + 1
    mosaic = Image.new("RGB", (side, side))
    mosaic.putdata(pixels + [pixels[0]] * (side * side - len(pixels)))
    reduced = mosaic.quantize(colors=COLORS, method=Image.MEDIANCUT, dither=Image.Dither.NONE)
    flat = reduced.getpalette()[: COLORS * 3]
    colors = [flat[i : i + 3] for i in range(0, len(flat), 3)]
    PALETTE_FILE.write_text(json.dumps(colors) + "\n")
    print(f"world palette: {len(colors)} colours from {len(names)} images")


def is_world_art(stem: str) -> bool:
    """Image-model art that shares the palette: buildings, nature, decor, ground, furniture."""
    from art.ai_assets import ASSETS
    from art.ai_nature import names as nature
    from art.ai_decor import names as decor

    return (
        stem in ASSETS
        or stem in nature()
        or stem in decor()
        or stem.startswith("ground_")
        or stem.startswith("soil_")
        or stem.startswith("room_")
    )


if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    if sys.argv[1:] == ["palette"]:
        build_palette()
    else:
        raise SystemExit(__doc__)

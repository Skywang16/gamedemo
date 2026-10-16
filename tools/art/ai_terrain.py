"""Ground textures drawn by the image model: seamless tiles for grass, paths, sand, cave floor, water, soil.

Every request carries the shared style board (imagegen.style_board).

    python tools/art/ai_terrain.py [name ...] [--force]

Each tile is a flat top-down render (1K, no transparency needed), made seamless with a cross-fade and
reduced to 256 px (8 x 8 game cells); soil tiles are single 32 px cells. Output: assets/art/ground_<name>.png (soil_dry.png and soil_wet.png for the plots).
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import sys
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g

OUT = Path(__file__).resolve().parents[2] / "assets/art"

GROUND_STYLE = (
    "Original hand-made 16-bit pixel art ground texture for a cozy riverside European-village farming game, in exactly the same "
    "style as the buildings and trees of the reference style board. "
    "VIEW: straight top-down, the camera looks directly down at the ground, orthographic, no horizon, no perspective, "
    "no vignette, no lighting gradient, no cast shadows. "
    "SEAMLESS TILE: even density everywhere, no large focal object, no single big feature, only small evenly scattered details. "
    "HARD-EDGED PIXEL ART: every stone, plank, blade of grass and pebble is built from clearly visible square pixels with crisp "
    "edges; flat cel colours with only two or three tones per material; dark warm-brown 1-pixel outlines around stones, planks and "
    "larger details; absolutely NO smooth gradients, NO blur, NO painterly brush strokes, NO anti-aliasing, NO photographic texture, "
    "NO noise. Soft storybook palette, gentle contrast so sprites on top stay readable. "
    "No text, no border, no frame, no watermark."
)

# name -> (size in px, subject)
TEXTURES = {
    "grass_a": (
        256,
        "SUBJECT: short meadow grass, a calm mid-green base with small darker green blade clusters and rare "
        "lighter yellow-green tufts.",
    ),
    "grass_b": (
        256,
        "SUBJECT: lush darker green grass with a few tiny three-leaf clover patches and very small white and "
        "pale yellow wildflowers scattered sparsely.",
    ),
    "grass_c": (
        256,
        "SUBJECT: sun-dried yellow-green grass with tiny dry stalks and a few small bare earth specks.",
    ),
    "dirt": (
        256,
        "SUBJECT: packed village dirt path, warm tan-brown earth with fine speckles, a few small pebbles and "
        "faint darker cracks.",
    ),
    "cobble": (
        256,
        "SUBJECT: village cobblestone paving, LARGE rounded grey-beige stones, each stone about one sixth of the tile width, laid in offset rows, dark mortar joints, "
        "slight colour variation between stones, a little moss in a few joints.",
    ),
    "plank": (
        256,
        "SUBJECT: a wooden boardwalk, long horizontal weathered brown planks, each plank about one eighth of the tile height, with dark gaps, "
        "small nail heads and wood grain.",
    ),
    "sand": (
        256,
        "SUBJECT: pale beach sand with stepped pixel ripple lines, a few tiny shell fragments and darker wet grains.",
    ),
    "cave": (
        256,
        "SUBJECT: dark blue-grey rocky cavern floor, flat stone slabs with fine cracks, small scattered pebbles, "
        "a few faint lighter mineral flecks.",
    ),
    "water": (
        256,
        "SUBJECT: calm river water seen from above, teal-green with stepped pixel wave streaks in darker "
        "and lighter teal, a few tiny white sparkles, no foam, no shore.",
    ),
    "soil_dry": (
        32,
        "SUBJECT: freshly tilled farm soil, dry medium brown earth with parallel shallow furrows and small clods.",
    ),
    "soil_wet": (
        32,
        "SUBJECT: freshly tilled farm soil that has just been watered, dark chocolate-brown earth with parallel "
        "shallow furrows, small clods and a slight damp sheen.",
    ),
}


ART_GRID = 170  # the model draws about 6 px per art pixel on a 1024 px render


def edge_cost(a: list, b: list) -> int:
    return sum(abs(p[0] - q[0]) + abs(p[1] - q[1]) + abs(p[2] - q[2]) for p, q in zip(a, b))


def seamless(im: Image.Image) -> Image.Image:
    """Reduce to the art grid, then crop the window whose last column/row best continues into its first one.
    Nothing is blended, so the pixel edges stay hard."""
    small = im.resize((ART_GRID, ART_GRID), Image.BOX)
    px = small.load()
    n = ART_GRID

    def col(x):
        return [px[x, y] for y in range(n)]

    def row(y):
        return [px[x, y] for x in range(n)]

    best_x = min(
        (
            (edge_cost(col(x1 - 1), col(x0)), x0, x1)
            for x0 in range(0, 24)
            for x1 in range(n - 24, n + 1)
        ),
        key=lambda t: t[0] + 0 * t[1],
    )
    best_y = min(
        (
            (edge_cost(row(y1 - 1), row(y0)), y0, y1)
            for y0 in range(0, 24)
            for y1 in range(n - 24, n + 1)
        ),
        key=lambda t: t[0],
    )
    return small.crop((best_x[1], best_y[1], best_x[2], best_y[2]))


def lock(tile: Image.Image) -> Image.Image:
    """A small flat palette, no dithering."""
    return tile.quantize(colors=28, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")


def output_name(name: str) -> str:
    return name if name.startswith("soil") else "ground_" + name


def make(name: str, force: bool = False) -> str:
    size, subject = TEXTURES[name]
    cache = g.RAW / ("ground_" + name + ".png")
    if force or not cache.exists():
        g.generate(
            GROUND_STYLE + " " + subject,
            quality="standard",
            transparent=False,
            keep_background=True,
        ).convert("RGB").save(cache)
    tile = Image.open(cache).convert("RGB")
    tile = lock(tile.resize((size, size), Image.BOX) if size <= 32 else seamless(tile))
    tile.save(OUT / (output_name(name) + ".png"))
    return name


def main(argv: list[str]) -> None:
    force = "--force" in argv
    names = [a for a in argv if not a.startswith("--")] or list(TEXTURES)
    g.RAW.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as pool:
        for done in pool.map(lambda n: make(n, force), names):
            print("done", done, flush=True)
    print("balance", g.balance())


if __name__ == "__main__":
    main(sys.argv[1:])

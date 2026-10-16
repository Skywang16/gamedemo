"""Street furniture drawn by the image model: lamps, signs, barrels, crates, beds, hedges, fences, carts.

    python tools/art/ai_decor.py [sheet ...] [--force]

Three requests, each a row of different objects on a flat magenta background; every row is split on
its empty columns and each sprite is fitted to its footprint. Output: assets/art/decor_<kind>.png,
pasted onto the map backgrounds by decor.py (bottom-centre of the cell).
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import sys
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g
from art.ai_nature import split_sheet

OUT = Path(__file__).resolve().parents[2] / "assets/art"

# kind -> (max width, max height) in game pixels
SIZES = {
    "lamp": (30, 78),
    "signpost": (32, 46),
    "barrel": (30, 34),
    "crates": (32, 34),
    "hay": (32, 32),
    "flowerbed": (32, 32),
    "planter": (28, 36),
    "hedge": (32, 32),
    "rocks": (32, 28),
    "trough": (64, 32),
    "cart": (64, 48),
    "fence_h": (32, 32),
    "fence_v": (24, 40),
}
SHEETS = {
    "a": (
        ["lamp", "signpost", "barrel", "crates", "hay"],
        "SUBJECT: a row of FIVE different small village street objects, each fully separate, evenly spaced with wide empty gaps "
        "between them, all drawn at the same scale and standing on the same baseline, left to right: (1) a tall black iron street "
        "lamp post with a glass lantern glowing warm yellow on top, (2) a wooden signpost with one blank arrow-shaped board, "
        "(3) a single oak barrel with iron hoops, (4) a stack of three wooden crates, (5) one round golden hay bale tied with twine.",
    ),
    "b": (
        ["flowerbed", "planter", "hedge", "rocks"],
        "SUBJECT: a row of FOUR different garden objects, each fully separate, evenly spaced with wide empty gaps between them, "
        "all at the same scale, left to right: (1) a small square raised flower bed with a wooden frame full of mixed pink, "
        "yellow and white flowers, (2) a terracotta flower pot with red flowers, (3) a short block of neatly trimmed green box "
        "hedge, (4) a cluster of two grey field stones with moss.",
    ),
    "c": (
        ["trough", "cart", "fence_h", "fence_v"],
        "SUBJECT: a row of FOUR different farm objects, each fully separate, evenly spaced with wide empty gaps between them, "
        "all at the same scale, left to right: (1) a long wooden animal water trough filled with water, (2) a small two-wheeled "
        "wooden hand cart with a few sacks, (3) one short section of a wooden post-and-rail fence seen from the front with "
        "two rails and one post in the middle, (4) a single wooden fence post with a tiny rail stub on each side.",
    ),
}


def make(sheet: str, force: bool = False) -> str:
    kinds, subject = SHEETS[sheet]
    cache = g.RAW / f"decor_{sheet}_cut.png"
    if force or not cache.exists():
        raw = g.generate(
            g.STYLE + " " + subject, quality="standard", transparent=False, size="1536x768"
        )
        g.cut_out(raw, key_magenta=True).save(cache)
    parts = split_sheet(Image.open(cache), len(kinds))
    for kind, part in zip(kinds, parts):
        max_w, max_h = SIZES[kind]
        g.to_game(part, max_w, max_h, (max_w, max_h), 0).save(OUT / f"decor_{kind}.png")
    return sheet


def names() -> list[str]:
    return [f"decor_{k}" for k in SIZES]


def main(argv: list[str]) -> None:
    force = "--force" in argv
    todo = [a for a in argv if not a.startswith("--")] or list(SHEETS)
    g.RAW.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=3) as pool:
        for done in pool.map(lambda sheet: make(sheet, force), todo):
            print("done", done, flush=True)
    print("balance", g.balance())


if __name__ == "__main__":
    main(sys.argv[1:])

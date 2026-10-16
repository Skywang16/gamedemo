"""Trees, stump, weeds, branches and rocks drawn by the image model.

    python tools/art/ai_nature.py [name ...] [--force]

Singles are one sprite per request; "sheets" ask for three variants side by side on one request and are
split on the empty columns between them (an explicit error if the model did not draw exactly three).
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import sys
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g

OUT = Path(__file__).resolve().parents[2] / "assets/art"

SINGLES = {
    "tree_0": (
        94,
        124,
        (96, 128),
        "SUBJECT: a broad round-crowned oak tree: thick brown trunk with visible roots at the "
        "bottom, a full rounded crown of layered mid-green leaf clusters with lighter highlights on the upper left.",
    ),
    "tree_1": (
        94,
        124,
        (96, 128),
        "SUBJECT: a tall maple tree with a slightly oval crown of green leaves with a few "
        "yellow-orange leaves, a straight dark-brown trunk with a small fork, visible roots.",
    ),
    "tree_2": (
        94,
        124,
        (96, 128),
        "SUBJECT: a slender silver birch tree with a white trunk marked by dark horizontal "
        "dashes, a light airy crown of small bright yellow-green leaves.",
    ),
    "tree_3": (
        94,
        124,
        (96, 128),
        "SUBJECT: a tall conical spruce tree, dark blue-green layered branches getting wider "
        "towards the bottom, a short brown trunk at the foot.",
    ),
    "tree_stump": (
        30,
        28,
        (32, 32),
        "SUBJECT: a freshly cut tree stump, light wood top with visible growth rings, "
        "bark sides, a couple of roots, a small mushroom on one side.",
    ),
}
SHEETS = {
    "weeds": (
        30,
        36,
        (32, 40),
        "SUBJECT: three DIFFERENT clumps of wild field weeds in a row, evenly spaced with clear empty "
        "gaps between them: (1) tall spiky green grass tufts, (2) broad-leafed dock weeds with a seed stalk, "
        "(3) thistle-like weeds with tiny purple flowers. Each clump about the same size.",
    ),
    "branch": (
        30,
        36,
        (32, 40),
        "SUBJECT: three DIFFERENT fallen tree branches in a row, evenly spaced with clear empty "
        "gaps between them: (1) a long forked brown branch with a few dry leaves, (2) a short thick mossy branch piece, "
        "(3) a pair of crossed thin twigs. Each about the same size.",
    ),
    "rock": (
        30,
        36,
        (32, 40),
        "SUBJECT: three DIFFERENT field stones in a row, evenly spaced with clear empty gaps between "
        "them: (1) a rounded grey boulder with moss on top, (2) an angular pale-grey rock with cracks, "
        "(3) a pair of small stones leaning on each other. Each about the same size.",
    ),
}


def split_sheet(im: Image.Image, count: int) -> list[Image.Image]:
    alpha = im.getchannel("A").point(lambda a: 255 if a > 24 else 0)
    cols = [alpha.crop((x, 0, x + 1, im.height)).getbbox() is not None for x in range(im.width)]
    groups, start = [], None
    for x, on in enumerate(cols + [False]):
        if on and start is None:
            start = x
        elif not on and start is not None:
            groups.append((start, x))
            start = None
    groups = sorted(
        sorted(groups, key=lambda s: s[0] - s[1])[:count]
    )  # the widest runs, left to right
    if len(groups) != count:
        raise RuntimeError(f"expected {count} separate sprites, found {len(groups)}")
    return [g.cut_out(im.crop((a, 0, b, im.height))) for a, b in groups]


def fetch(name: str, subject: str, force: bool) -> Image.Image:
    cache = g.RAW / (name + "_cut.png")
    if force or not cache.exists():
        raw = g.generate(g.STYLE + " " + subject, quality="standard", transparent=False)
        g.cut_out(raw, key_magenta=True).save(cache)
    return Image.open(cache)


def make(name: str, force: bool = False) -> str:
    if name in SINGLES:
        max_w, max_h, canvas, subject = SINGLES[name]
        sprite = g.to_game(fetch(name, subject, force), max_w, max_h, canvas, 4, "ellipse")
        sprite.save(OUT / (name + ".png"))
        if name.startswith("tree_") and name != "tree_stump":
            # The felled-tree animation turns this sprite, so it is the same picture.
            sprite.save(OUT / ("tree_moving_" + name[-1] + ".png"))
    else:
        max_w, max_h, canvas, subject = SHEETS[name]
        for i, part in enumerate(split_sheet(fetch(name, subject, force), 3)):
            shape = None if name == "weeds" else "ellipse"
            g.to_game(part, max_w, max_h, canvas, 4, shape).save(OUT / f"{name}_{i}.png")
    return name


def names() -> list[str]:
    out = (
        list(SINGLES)
        + [f"{n}_{i}" for n in SHEETS for i in range(3)]
        + [f"tree_moving_{i}" for i in range(4)]
    )
    return out


def main(argv: list[str]) -> None:
    force = "--force" in argv
    todo = [a for a in argv if not a.startswith("--")] or list(SINGLES) + list(SHEETS)
    g.RAW.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as pool:
        for done in pool.map(lambda n: make(n, force), todo):
            print("done", done, flush=True)
    print("balance", g.balance())


if __name__ == "__main__":
    main(sys.argv[1:])

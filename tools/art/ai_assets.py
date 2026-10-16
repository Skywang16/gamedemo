"""Buildings drawn by the image model: prompts, target sizes, batch runner.

    python tools/art/ai_assets.py [name ...] [--force]

Every sprite is requested on a flat magenta background (cheap 1K render), keyed out, trimmed and fitted to
the footprint the map generator expects. Full-size cut-outs are cached in build/art-raw so a rerun only
asks for what is missing. The finished PNGs in assets/art are the authoritative art (build_art.py leaves
the names listed in ASSETS alone).
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import sys
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g

OUT = Path(__file__).resolve().parents[2] / "assets/art"

# name -> (max width, max height, canvas, subject). Building doors sit on the bottom edge of the canvas.
HOUSE = (240, 212, (256, 224))
SHOP = (248, 214, (256, 224))
ASSETS = {
    "house": (
        *HOUSE,
        "SUBJECT: the player's own farmhouse. A snug one-storey farmhouse with a wide low roof of weathered "
        "terracotta tiles, cream plaster walls with oak timber framing, a small brick chimney with a thin curl of smoke, "
        "a covered wooden porch with two steps and a rocking chair, a green front door, two windows with flower boxes. "
        "About 7 tiles wide.",
    ),
    "inn": (
        *SHOP,
        "SUBJECT: a village tavern called the inn. A two-storey building: lower floor of grey fieldstone, "
        "upper floor of dark timber and ochre plaster, a wide plum-purple shingle roof, two dormer windows, a warm lit "
        "window glowing orange, a double wooden door in the centre, a blank wooden sign shaped like a beer mug hanging from an iron "
        "bracket, two lanterns beside the door, stacked barrels at the left. About 8 tiles wide.",
    ),
    "workshop": (
        *SHOP,
        "SUBJECT: a carpenter's workshop. A long low timber-plank building with dark slate roof, "
        "large double barn doors in the centre standing half open, a big round saw blade and tools hanging on the front wall, "
        "stacks of cut lumber and a log pile against the left side, a small brick chimney. About 8 tiles wide.",
    ),
    "shop_store": (
        *SHOP,
        "SUBJECT: a village general store. A cheerful one-storey shop with a green and cream striped canvas "
        "awning over a wide display window, wooden crates of vegetables and sacks in front, a hanging blank wooden sign, "
        "pale yellow plaster walls, a flat-pitched brown tile roof with a small hip. About 8 tiles wide.",
    ),
    "shop_smith": (
        *SHOP,
        "SUBJECT: a blacksmith's forge. A sturdy building of dark grey stone with a charcoal slate roof, "
        "a huge stone chimney with smoke, an open front with glowing orange fire inside, an anvil and a barrel of water "
        "outside, horseshoes and tools on the wall, an iron blank sign bracket. About 8 tiles wide.",
    ),
    "shop_clinic": (
        *SHOP,
        "SUBJECT: a village herbalist clinic. A tidy white plaster building with a pale blue-green tiled roof, "
        "bundles of drying herbs hanging under the eaves, flower boxes full of green herbs, two large leaf-shaped lamps "
        "beside a light wooden door, a round window, a small bench. About 8 tiles wide.",
    ),
    "shop_tea": (
        *SHOP,
        "SUBJECT: a little tea house. A charming pink-cream plaster building with a teal glazed-tile roof "
        "with curved eaves, round arched windows, paper lanterns hanging along the front, a small porch with a round "
        "table and two chairs set with teacups, a teapot-shaped blank hanging sign. About 8 tiles wide.",
    ),
    "shop_tackle": (
        *SHOP,
        "SUBJECT: a seaside fishing tackle shop. A weathered blue-grey plank hut with a white-washed trim and a "
        "shingled roof, fishing nets drying on the wall, rods leaning by the door, a rowing boat tipped on its side "
        "against the left wall, crates and a barrel, a blank hanging sign shaped like a fish. About 8 tiles wide.",
    ),
    "barn": (
        *SHOP,
        "SUBJECT: a classic red wooden barn. Red board walls with white trim, large double doors with white X braces, "
        "a hayloft door above with a little hay sticking out, a grey shingle roof, a small weathervane. About 8 tiles wide.",
    ),
    "greenhouse": (
        248,
        170,
        (256, 176),
        "SUBJECT: a greenhouse. A white-painted iron frame with glass panels, a low brick base, "
        "a glass gabled roof with a small vent, lush green plants and tomatoes visible through the glass, a glass door "
        "in the centre. About 8 tiles wide, low and wide.",
    ),
    "coop": (
        150,
        112,
        (160, 120),
        "SUBJECT: a small chicken coop. A tiny wooden henhouse with a slanted red-brown plank roof, "
        "a little round door with a ramp, a straw-filled nesting box on the side, a wire-fence run section, "
        "one white hen standing in front. About 4 tiles wide.",
    ),
    "lighthouse": (
        60,
        150,
        (64, 152),
        "SUBJECT: a seaside lighthouse. A tall round stone tower painted white with a red band, "
        "a small dark door at the base, a lantern room with a glowing yellow lamp and a red conical cap on top, "
        "a rocky base. Tall and narrow.",
    ),
    "mine_gate": (
        190,
        148,
        (192, 152),
        "SUBJECT: an old mine entrance cut into a rocky hillside. A dark tunnel mouth braced "
        "with thick timber beams and a lintel, a pair of rusted rails going in, a hanging lantern, a few rocks and "
        "a wooden mine cart tipped beside it, mossy grey stones around. About 6 tiles wide.",
    ),
}
HOMES = {
    "home_01": "pale blue painted clapboard siding, white trim, a grey slate roof with two dormers, a small front porch",
    "home_02": "ochre-yellow plaster with dark timber framing, a brown shingle roof, a bay window on the left, a green door",
    "home_03": "red brick walls with ivy climbing one side, a dark grey slate roof, a white door with a brass knocker, a tall chimney",
    "home_04": "pale golden stucco, terracotta roof, an arched wooden door, a small balcony with flower pots above it",
    "home_05": "green-painted wooden siding, a thatched roof with a rounded eave, a stable door in two halves, a rain barrel",
    "home_06": "grey fieldstone cottage, a moss-covered roof, a round-topped oak door, a stone chimney, a woodpile at the left",
    "home_07": "white plaster walls with blue shutters, a blue-grey tiled roof, a trellis with climbing roses by the door",
    "home_08": "warm brown log cabin, a green mossy shingle roof, a stone chimney, a covered porch with firewood stacked",
    "home_09": "lakeside cottage in soft teal plank siding, a white-trimmed gable roof, a small wooden jetty-like deck at the front",
    "home_10": "weathered whitewashed seaside cottage with navy shutters, a slate roof, a ship's lantern by the door, a lifebuoy on the wall",
    "home_11": "brown timber farmhouse with a red tile roof, a hay-bale at the side, a milk churn by the door",
    "home_12": "cream plaster townhouse with a mansard-style tiled roof, a bakery-like striped awning over a window, a brass lamp",
    "home_13": "dusty pink plaster cottage with a green tiled roof, lace-curtained windows, a tidy flower garden fence-less front",
}
for _n, _d in HOMES.items():
    ASSETS[_n] = (
        *HOUSE,
        "SUBJECT: a village family home. One-storey cottage (or low one-and-a-half storey) with a wide roof whose "
        "ridge runs left to right: "
        + _d
        + ". A single front door in the centre-left, two windows. About 7 tiles wide.",
    )


def make(name: str, force: bool = False) -> str:
    max_w, max_h, canvas, subject = ASSETS[name]
    cache = g.RAW / (name + "_cut.png")
    if force or not cache.exists():
        raw = g.generate(g.STYLE + " " + subject, quality="standard", transparent=False)
        g.cut_out(raw, key_magenta=True).save(cache)
    sprite = g.to_game(Image.open(cache), max_w, max_h, canvas)
    sprite.save(OUT / (name + ".png"))
    return name


def main(argv: list[str]) -> None:
    force = "--force" in argv
    names = [a for a in argv if not a.startswith("--")] or list(ASSETS)
    g.RAW.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as pool:
        for done in pool.map(lambda n: make(n, force), names):
            print("done", done, flush=True)
    print("balance", g.balance())


if __name__ == "__main__":
    main(sys.argv[1:])

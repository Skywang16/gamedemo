"""Room backgrounds drawn by the image model (960 x 608, 30 x 19 cells of 32 px).

    python tools/art/ai_interiors.py [name ...] [--force]

The prompts place the furniture where the map generator puts the collision rectangles
(tools/world/build_maps.py and shop_layouts.py), so what is drawn is what blocks the player.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g

OUT = Path(__file__).resolve().parents[2] / "assets/art"
SIZE = (960, 608)

ROOM_STYLE = (
    "Original hand-painted 16-bit pixel art interior for a cozy riverside European-village farming game. "
    "VIEW: a cut-away room seen in the classic 2D RPG top-down 3/4 view, camera tilted about 45 degrees: the back wall is "
    "seen face-on as a vertical wall in the top fifth of the picture, the wooden floor fills the middle, furniture is seen "
    "from the front and slightly above. The room fills the WHOLE picture edge to edge: thick side walls on the left and right "
    "(each about 13 percent of the width), a lower wall at the bottom with an open wooden doorway exactly in the middle of the "
    "bottom edge, no black void, no outside view except through windows. The large central floor area in front of the back wall "
    "must stay mostly EMPTY and walkable, with furniture only where listed. "
    "LIGHT AND COLOUR: bright, cheerful, evenly lit like a sunny daytime cartoon, flat cel shading with one light tone and one "
    "shadow tone per material; NOT dark, NOT moody, NOT cinematic, no light shafts, no sun rays, no glow, no vignette, no dark "
    "corners, no gradients, no realistic texture noise. "
    "RENDERING: big chunky pixels and simple shapes like a 16-bit console RPG, every object built from a few large pixel clusters, "
    "thick dark warm-brown outlines around every piece of furniture, floor drawn as simple flat planks with thin dark seams, "
    "soft storybook colours (terracotta, cream, moss, river teal, oak) with gentle saturation, the same pixel size and the same "
    "outline weight as the reference image. Match the reference image's art style exactly. "
    "No characters, no people, no text, no letters, no watermark, no UI."
)

ROOMS = {
    "cottage": "SUBJECT: the player's snug farmhouse room, one open room with plank floor and cream plaster walls with timber "
    "beams. Furniture: a single bed with a patchwork quilt against the back wall in the upper left (about 20 to 30 percent "
    "of the width); a small writing desk with a letter on it against the back wall at the upper right (about 63 to 73 "
    "percent); a round dining table with two stools in the centre (about 40 to 53 percent across, 47 to 58 percent down); "
    "a wooden storage chest at the left (about 20 to 27 percent across, 58 percent down); a kitchen counter with a stove "
    "and hanging pots at the right (about 67 to 77 percent across, 47 to 58 percent down); a window on the back wall in "
    "the middle, a woven rug in the middle of the floor, a few plants.",
    "inn": "SUBJECT: a village tavern hall called the inn, warm and cosy, dark timber beams, stone fireplace, plank floor. "
    "Furniture: two big dining tables with benches, one at about 23 to 37 percent across and 30 to 42 percent down, the "
    "other at about 60 to 73 percent across and 30 to 42 percent down; a bar counter with beer kegs and shelves of mugs "
    "along the back wall's upper right; a big kitchen range with a hanging kettle at the right (about 67 percent across, "
    "40 percent down); lanterns on the walls, a staircase going up in the back-left corner, a stone fireplace on the back "
    "wall in the middle. The centre of the floor is empty.",
    "workshop": "SUBJECT: a carpenter's workshop, plank floor with wood shavings, tools hanging on the back wall. "
    "Furniture: two long workbenches with vices and planes, one at about 23 to 37 percent across and 30 to 42 percent down, "
    "the other at about 60 to 73 percent across and 30 to 42 percent down; racks of lumber boards and a saw on the back wall; "
    "a large blueprint table (a drafting table with rolled blueprints) in the middle of the back wall around 33 to 66 percent "
    "across; a stack of logs in the back-left corner; a stool, sawdust. The centre of the floor is empty.",
    "general_store": "SUBJECT: a village general store. A long wooden shop counter across the back, about 30 to 70 percent of the "
    "width, at 26 to 37 percent down, with a brass scale and a cash drawer on it; shelves of jars, tins and packets on the "
    "back wall behind it. Furniture: stacked sacks of flour at the upper left (about 13 to 20 percent across, 21 to 32 "
    "percent down); barrels at the upper right (about 77 to 83 percent across, 21 to 32 percent down); a low display table "
    "of vegetables at the left (about 13 to 23 percent across, 53 to 63 percent down); another display table of produce at "
    "the right (about 73 to 83 percent across, 47 to 58 percent down); stacked wooden crates (about 77 to 83 percent across, "
    "68 to 79 percent down).",
    "blacksmith": "SUBJECT: a blacksmith's forge shop with stone floor, soot-dark walls, a big brick forge with glowing coals "
    "in the back wall's centre. A long wooden counter across the back, about 30 to 70 percent of the width, 26 to 37 percent down. "
    "Furniture: an iron anvil on a stump at the left (about 20 to 27 percent across, 47 to 58 percent down); a round "
    "grindstone wheel (about 13 to 20 percent across, 68 to 79 percent down); a water barrel at the upper right "
    "(about 77 to 83 percent across, 21 to 32 percent down); neat stacks of metal ingots at the right (about 73 to 83 "
    "percent across, 47 to 58 percent down); a worktable with tongs and hammers (about 63 to 73 percent across, "
    "53 to 58 percent down); tools and horseshoes on the walls.",
    "clinic": "SUBJECT: a village herbalist clinic, clean and bright, pale plaster walls, pale wooden floor, herb bundles drying "
    "from the ceiling beams. A wooden consultation counter with bottles and a mortar across the back, about 30 to 70 percent "
    "of the width, 26 to 37 percent down, shelves of medicine jars behind it. Furniture: a bed with white linen at the left "
    "(about 13 to 23 percent across, 53 to 63 percent down), a second identical bed at the right (about 70 to 80 percent "
    "across, 53 to 63 percent down); tall potted ferns at the upper left and the upper right corners; a long waiting bench "
    "at the left bottom (about 13 to 23 percent across, 74 to 79 percent down).",
    "tea_house": "SUBJECT: a little tea house, warm pink-cream walls, pale wooden floor, paper lanterns hanging from the "
    "ceiling, a copper kettle. A tea counter with cups and a samovar across the back, about 30 to 70 percent of the width, "
    "26 to 37 percent down, shelves of tea tins behind it. Furniture: a round table with teacups and two chairs at the left "
    "(about 20 to 30 percent across, 53 to 63 percent down); a second round table at the right (about 60 to 70 percent "
    "across, 53 to 63 percent down); a small iron stove with a kettle at the upper left (about 13 to 20 percent across, "
    "21 to 32 percent down); a cushioned sofa at the upper right (about 77 to 83 percent across, 26 to 42 percent down); "
    "a potted fern at the lower right (about 77 to 83 percent across, 68 to 79 percent down).",
    "tackle_shop": "SUBJECT: a seaside fishing tackle shop with weathered blue-grey plank walls, nets and rods on the walls, "
    "a ship's lantern. A wooden counter with a tackle box and reels across the back, about 30 to 70 percent of the width, "
    "26 to 37 percent down. Furniture: crates of bait at the upper left (about 13 to 20 percent across, 21 to 32 percent "
    "down); barrels of bait at the left lower (about 13 to 20 percent across, 63 to 74 percent down); a lure display "
    "table at the left (about 20 to 30 percent across, 53 to 58 percent down); a big glass fish tank with fish at the "
    "right (about 73 to 83 percent across, 42 to 58 percent down); a pile of coiled rope (about 77 to 83 percent across, "
    "68 to 79 percent down).",
}


def make(name: str, force: bool = False) -> str:
    cache = g.RAW / (name + "_room.png")
    if force or not cache.exists():
        raw = g.generate(
            ROOM_STYLE + " " + ROOMS[name],
            quality="standard",
            transparent=False,
            keep_background=True,
            size="1536x960",
        )
        raw.convert("RGB").save(cache)
    room = g.pixel_lock(Image.open(cache).convert("RGB").resize(SIZE, Image.BOX), 64).convert("RGB")
    # The corners outside the room walls come out as the style board's green; paint them as dark void.
    for corner in [(0, 0), (SIZE[0] - 1, 0), (0, SIZE[1] - 1), (SIZE[0] - 1, SIZE[1] - 1)]:
        r, gr, b = room.getpixel(corner)
        if gr > r + 20 and gr > b + 20:
            ImageDraw.floodfill(room, corner, (23, 42, 36), thresh=60)
    room.save(OUT / (name + "_background.png"))
    return name


def main(argv: list[str]) -> None:
    force = "--force" in argv
    names = [a for a in argv if not a.startswith("--")] or list(ROOMS)
    g.RAW.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as pool:
        for done in pool.map(lambda n: make(n, force), names):
            print("done", done, flush=True)
    print("balance", g.balance())


if __name__ == "__main__":
    main(sys.argv[1:])

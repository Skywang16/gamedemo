"""Farm tile-kit sources drawn by the image model: ground textures and object sheets.

    python tools/art/ai_farm_kit.py [name ...] [--force]

Every request carries the approved farm concept (assets/library/maps/farm/scene.png) as its only
style reference, so textures, trees and decorations share its pixel clusters, palette and light.
Sources are committed under assets/library/maps/farm/kit/ together with their prompts; an existing
source is never replaced without --force. tools/art/farm_tiles.py turns them into the tile atlas
and the object sprites without any network access.
"""

from concurrent.futures import ThreadPoolExecutor
import base64
import io
from pathlib import Path
import sys

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "assets/library/maps/farm"
KIT = LIBRARY / "kit"

STYLE = (
    "Original 16-bit pixel art for a cozy top-down farming life-sim game map. Match the attached "
    "reference map EXACTLY in style: the same crisp compact pixel clusters, the same pixel density, "
    "the same palette (warm honey earth, muted leafy yellow-greens, deep teal-green shadows, "
    "blue-green pond water), the same soft daylight from the upper left and the same flat "
    "orthographic top-down three-quarter camera. Do not copy the layout of the reference. "
    "No text, no letters, no watermark, no UI, no grid lines, no border, no frame."
)
REFERENCE_NOTE = " Image 1 is the approved map of this very farm: it is the style reference only."
TEXTURE = (
    " SUBJECT: one SEAMLESS, TILEABLE ground texture swatch that fills the entire square image "
    "edge to edge, seen from straight above, for repeating as a game floor. Uniform density, "
    "uniform brightness and uniform scale everywhere: no vignette, no lighting gradient, no "
    "perspective, no objects, no edges, no shadows of trees or buildings. Low, calm contrast. "
)
SHEET = (
    " SUBJECT: a sprite sheet of separate game objects on a perfectly flat solid pure magenta "
    "(#FF00FF) background. Every object is complete, isolated, drawn at the same scale as the "
    "reference map, with wide empty magenta gaps between objects and around the image edge; no "
    "object touches another. No ground, no grass, no cast shadow under the objects, and no "
    "magenta inside any object. "
)

SOURCES = {
    "grass": TEXTURE
    + "Short natural spring meadow grass like the open clearing of the reference: small readable "
    "clusters of grass blades in four close yellow-greens and olive greens with a few slightly "
    "lighter blade tips. No flowers, no stones, no bare earth.",
    "dirt": TEXTURE
    + "Packed warm honey-coloured earth of a well-trodden farm footpath, like the lanes of the "
    "reference: fine soil grain in four close warm tans, a few tiny scattered pebbles and faint "
    "footworn specks. No grass, no puddles, no wheel tracks.",
    "forest": TEXTURE
    + "Shady woodland floor under a dense deciduous canopy: dark mossy green ground with soft "
    "patches of dark brown leaf litter, tiny moss tufts and a few small fern sprigs, everything "
    "deep teal-green and dim. No trunks, no roots, no stones, no light spots.",
    "water": TEXTURE
    + "EVERY pixel of the image is open pond water: the camera floats above the middle of a "
    "large calm pond and looks straight down, so there is NO land, NO grass, NO bank and NO "
    "shore anywhere in the picture. Muted turquoise blue-green water like the ponds of the "
    "reference, gentle slightly darker and lighter water tones and a few small soft horizontal "
    "ripple highlights. No plants, no lily pads, no reflections of objects, no fish.",
    "trees": SHEET
    + "SIX different leafy deciduous trees of the farm's surrounding woodland, arranged in a "
    "3 by 2 grid, each tree fully visible: a big rounded canopy made of clustered leaf clumps "
    "seen from slightly above, the trunk base and a few roots visible under the canopy, trunk "
    "centred at the bottom. Each tree is about 1.3 times as tall as it is wide. Left to right, "
    "top row: (1) broad round oak with bright yellow-green highlights, (2) broad oak with deeper "
    "green leaves, (3) tall oval tree with teal-green shadows; bottom row: (4) wide two-lobed "
    "tree, (5) smaller young tree, (6) dark bushy tree.",
    "flora": SHEET
    + "TWELVE small ground decorations of the meadow in a 4 by 3 grid. Draw each one LARGE so it "
    "fills most of its grid cell, in its natural daylight colours exactly like the small "
    "details of the reference (no pink, no purple, no magenta tint): (1) white daisy clump with "
    "green leaves, (2) yellow buttercup clump, (3) blue forget-me-not clump, (4) red poppy "
    "clump, (5) dandelions with leaves, (6) short green grass tuft, (7) taller green grass tuft, "
    "(8) wide low grass tuft with seed heads, (9) small grey pebbles, (10) brown mushrooms "
    "cluster, (11) small green fern sprig, (12) green clover leaves patch.",
    "waterside": SHEET
    + "TWELVE pond-side and woodland-edge objects in a 4 by 3 grid: (1) tall reed clump with "
    "cattails, (2) small reed clump, (3) wide sedge and reed clump, (4) round lily pads group, "
    "(5) lily pads with one pink water lily flower, (6) small grey boulder, (7) large mossy "
    "boulder, (8) cluster of two mossy rocks, (9) old tree stump with roots, (10) fallen mossy "
    "log lying horizontally, (11) round leafy green shrub, (12) round shrub with small white "
    "blossoms.",
    "walls": SHEET
    + "EIGHT pieces of an old low mossy dry-stone field wall made of stacked grey-beige stones "
    "with moss and a few tiny flowers on top, seen in the reference camera so the top of the "
    "wall and its south-facing front face are visible: (1) to (4) straight horizontal wall "
    "segments of different lengths, about two, three, four and five ground tiles long, each "
    "with roughly finished ends; (5) a short crumbled wall end; (6) a single loose stone "
    "pile; (7) a short vertical segment running north to south; (8) a longer vertical segment "
    "running north to south.",
    "yard": SHEET
    + "TEN cottage-yard objects in a 5 by 2 grid: (1) wooden barrel, (2) stack of split "
    "firewood logs, (3) terracotta pot with red geraniums, (4) terracotta pot with white "
    "flowers, (5) small wooden bench, (6) wooden mailbox on a post, (7) wooden flower planter "
    "box with mixed flowers, (8) three flat round stepping stones, (9) small hay bale, "
    "(10) wooden water bucket.",
}


def reference() -> str:
    concept = Image.open(LIBRARY / "scene.png").convert("RGB")
    concept.thumbnail((1536, 1152), Image.Resampling.LANCZOS)
    buffer = io.BytesIO()
    concept.save(buffer, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buffer.getvalue()).decode()


def make(name: str, force: bool, ref: str) -> str:
    target = KIT / (name + ".png")
    if target.exists() and not force:
        raise SystemExit(f"{target} exists; pass --force to request a new picture")
    prompt = STYLE + SOURCES[name]
    im = g.generate(
        prompt,
        quality="standard",
        transparent=False,
        keep_background=True,
        size="1:1",
        references=[ref],
        reference_note=REFERENCE_NOTE,
    )
    KIT.mkdir(parents=True, exist_ok=True)
    im.save(target)
    (KIT / (name + ".prompt.txt")).write_text(prompt + REFERENCE_NOTE + "\n")
    return name


def main(argv: list[str]) -> None:
    force = "--force" in argv
    todo = [a for a in argv if not a.startswith("--")] or list(SOURCES)
    unknown = [n for n in todo if n not in SOURCES]
    if unknown:
        raise SystemExit("unknown source: " + ", ".join(unknown))
    ref = reference()
    with ThreadPoolExecutor(max_workers=5) as pool:
        for done in pool.map(lambda name: make(name, force, ref), todo):
            print("done", done, flush=True)
    print("balance", g.balance())


if __name__ == "__main__":
    main(sys.argv[1:])

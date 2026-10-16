"""Whole-scene farm art. Network calls are explicit; normal builds install committed art only.

    python tools/art/ai_farm_scene.py guide
    python tools/art/ai_farm_scene.py generate

Credentials use the shared imagegen client, never prompt files or source code.
"""

import base64
import io
from pathlib import Path
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "assets/library/maps/farm"
WORK = ROOT / "build/farm-scene"

PROMPT = """Use case: stylized-concept.
Asset type: an entire playable 2D farming RPG farm map, original production environment art.
Draw ONE cohesive, beautifully art-directed private countryside farm. A lovingly designed game
location, with the density, readable pixel clusters and spatial clarity of a classic 16-bit life sim.
This is a flat orthographic top-down three-quarter GAME MAP, viewed straight north: ground has no
perspective convergence, all vertical walls face south, NO isometric rotation, NO horizon, NO sky,
NO miniature floating diorama and NO diagram. Fill the entire image with the map.

Image 1 is a strict spatial guide, NOT a style reference. Preserve the composition and footprint of
its features, but replace every schematic shape with accomplished pixel artwork. Remove ALL labels,
outlines and diagram marks. The intended game uses 96 by 72 square cells. Output 4:3 landscape.
Buildings and tall vegetation have vertical sprite height above their ground footprint.

Composition: ONE modest cream plaster cottage with terracotta roof in the north-central clearing,
its south-facing front door precisely at 42% of image width, 22% of image height. Cottage including
roof fits between x=36..47%, y=10..22%. A worn stone doorstep merges naturally into an irregular
warm-earth courtyard. A small stone well at 35%,21%, and a small wooden shipping chest at 48%,24%.
No shop, stall, other people's houses, greenhouse, barn or coop: this is the player's private farm.
A narrow winding earth lane leads from the courtyard to the EAST edge at y=25%, and a second lane
continues south to the BOTTOM edge at x=51%. Keep those two exits open and visually unmistakable.
The lanes have bends, worn grassy shoulders and occasional stones, not straight ruler rectangles.

Keep the central agricultural clearing at x=28..58%, y=29..60% broad, unobstructed and quiet:
short natural olive grass with occasional bare earth, NOT pre-tilled soil, NO crops, NO furrows,
NO fences crossing this area. The player will cultivate it. A small flattened patch by the yard is
enough to suggest the first planting spot. The eastern expansion clearing x=61..80%, y=30..52%
is also EMPTY short grass, with no structures or large objects, reserved for player construction.
An irregular pond lies within x=7..26%, y=35..59%, with reeds, subtly undercut muddy banks, reflective
muted turquoise water and a readable shore. A smaller pond lies x=83..97%, y=60..88%.

Tall leafy woodland, mossy rocks, shrub masses, small flower patches and old low stone walls frame
the north, west and south edges in asymmetrical groups. Use large readable tree shapes and rich
overlap at the perimeter; small quiet clearings between groups. No fence enclosing the whole image.
Interior playable clearings must remain open: NO scattered mature trees, fallen logs, large rocks,
tools, buckets, crops or other collectible objects there; these will be separate game objects.
Concentrate detail at transitions: roots into grass, grass into packed earth, stones into banks,
ivy against cottage base. The image must feel painted as a single place, never pasted stock sprites.

Art direction: crisp deliberate PIXEL ART, compact clusters, clean silhouettes, no blur, no
antialiasing, no photographic texture or noisy stippling. Warm cream and honey earth, muted leafy
greens, blue-green pond shadows, restrained terracotta accents. Light from upper left. Ground low
contrast; cottage and banks more defined. Cheerful spring daylight. Keep the SAME pixel density and
object scale everywhere. No people, UI, labels, letters, grid lines, watermarks or map symbols.
"""


def guide() -> Path:
    WORK.mkdir(parents=True, exist_ok=True)
    im = Image.new("RGB", (1536, 1152), "#6e9250")
    d = ImageDraw.Draw(im)
    # This is only a composition control image, never a shipped game background.
    d.polygon(
        [
            (0, 0),
            (1536, 0),
            (1536, 135),
            (1150, 160),
            (880, 110),
            (770, 140),
            (480, 125),
            (290, 260),
            (0, 310),
        ],
        fill="#365b3e",
    )
    d.polygon(
        [
            (0, 240),
            (95, 250),
            (115, 810),
            (240, 1000),
            (500, 1050),
            (710, 1030),
            (740, 1152),
            (0, 1152),
        ],
        fill="#365b3e",
    )
    d.polygon(
        [
            (880, 1152),
            (900, 1040),
            (1100, 970),
            (1190, 1000),
            (1310, 1100),
            (1536, 1090),
            (1536, 1152),
        ],
        fill="#365b3e",
    )
    d.polygon(
        [
            (128, 496),
            (160, 432),
            (272, 400),
            (368, 448),
            (400, 560),
            (336, 656),
            (192, 672),
            (112, 592),
        ],
        fill="#528c8e",
    )
    d.polygon(
        [(1280, 736), (1376, 688), (1472, 752), (1488, 928), (1392, 992), (1296, 928)],
        fill="#528c8e",
    )
    d.rounded_rectangle((440, 335, 890, 700), 70, fill="#93a767")
    d.rounded_rectangle((965, 355, 1240, 655), 55, fill="#93a767")
    d.line(
        [(640, 255), (640, 310), (690, 350), (900, 320), (1080, 290), (1310, 300), (1536, 290)],
        fill="#b9a076",
        width=36,
    )
    d.line(
        [(640, 300), (650, 570), (660, 760), (720, 890), (785, 990), (785, 1152)],
        fill="#b9a076",
        width=32,
    )
    d.ellipse((540, 225, 800, 330), fill="#c5ab7d")
    d.rectangle((557, 187, 722, 245), fill="#e3ca9d")
    d.polygon([(548, 187), (565, 130), (710, 130), (732, 187)], fill="#af6650")
    d.rectangle((632, 216, 650, 251), fill="#514238")
    d.ellipse((532, 228, 553, 248), fill="#7f8376")
    d.rectangle((731, 267, 747, 283), fill="#805d3d")
    path = WORK / "layout-guide.png"
    im.save(path)
    (WORK / "farm-scene.prompt.txt").write_text(PROMPT, encoding="utf-8")
    return path


def main() -> None:
    command = sys.argv[1] if len(sys.argv) > 1 else "guide"
    if command == "tree":
        destination = LIBRARY / "tree.png"
        if destination.exists():
            raise SystemExit("tree.png already exists")
        prompt = (
            "Create ONE isolated leafy oak tree sprite for the attached farming game map. "
            "Match its painted pixel clusters, warm yellow-green highlights, deep teal leaf shadows, "
            "brown trunk and top-down three-quarter camera EXACTLY. A full broad oval canopy, "
            "visible forked trunk and roots below; height about 1.3 times width. "
            "This will be a chop-able medium orchard tree inside the same farm, so it must look "
            "like it belongs to that painted woodland. Do not copy the map or include any landscape. "
            "Center the entire tree with a small clear margin on every side. Fully transparent "
            "background, no grass tile or ground plane, no cast shadow, no other objects, no text."
        )
        reference_image = Image.open(LIBRARY / "scene.png").convert("RGB")
        reference_image.thumbnail((1536, 1152))
        buffer = io.BytesIO()
        reference_image.save(buffer, format="JPEG", quality=92)
        reference = "data:image/jpeg;base64," + base64.b64encode(buffer.getvalue()).decode()
        tree = g.generate(
            prompt,
            quality="hd",
            transparent=True,
            references=[reference],
            attempts=1,
            reference_note="",
        )
        tree.save(destination)
        (LIBRARY / "tree.prompt.txt").write_text(prompt, encoding="utf-8")
        print("Matching farm tree saved:", destination, flush=True)
        return
    layout = guide()
    if command == "guide":
        print(layout)
        return
    if command not in ("generate", "resume"):
        raise SystemExit("Use guide, generate or resume TASK_ID")
    LIBRARY.mkdir(parents=True, exist_ok=True)
    destination = LIBRARY / "scene.png"
    if destination.exists():
        raise SystemExit("scene.png already exists; preserve it before requesting another image")
    if command == "resume":
        if len(sys.argv) != 3 or not sys.argv[2].startswith("j_"):
            raise SystemExit("Use resume TASK_ID from the submitted request")
        result = g.call("GET", "/v1/tasks/" + sys.argv[2])["data"]
        if result["status"] != "done":
            raise SystemExit("Task status: " + result["status"])
        url = result["result"]["images"][0]["url"]
        image = Image.open(io.BytesIO(g.fetch(url[0] if isinstance(url, list) else url))).convert(
            "RGBA"
        )
    else:
        reference = "data:image/png;base64," + base64.b64encode(layout.read_bytes()).decode()
        image = g.generate(
            PROMPT,
            quality="uhd",
            size="4:3",
            transparent=False,
            keep_background=True,
            references=[reference],
            attempts=1,
            reference_note="",
        )
    image.save(destination)
    (LIBRARY / "scene.prompt.txt").write_text(PROMPT, encoding="utf-8")
    print("Farm scene saved:", destination, image.size, flush=True)


if __name__ == "__main__":
    main()

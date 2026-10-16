"""Create an original 4K art direction image from credited, external layout references."""

from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g

REFERENCES = [
    "https://stardewvalleywiki.com/mediawiki/images/9/90/Saloon_Interior.png",
    "https://stardewvalleywiki.com/mediawiki/images/3/3d/Pierre%27s_General_Store_Interior.png",
]
PROMPT = """Use case: stylized-concept. Original art direction for Sprout Valley, a riverside farming RPG.
Images 1 and 2 are Stardew Valley interior screenshots, references ONLY for pixel scale,
space efficiency, wall height and overhead RPG camera. Invent our own room shapes, furniture,
ornaments and palette. Do not duplicate their room layouts or recognizable objects.
Draw one beautiful coherent cutaway cottage: compact 12 by 9 tile living-kitchen with a connected
7 by 6 tile bedroom alcove. A 2-tile-wide passage, deep rear walls with muted sage wallpaper,
dark walnut wainscoting, thick wood framing and cutaway front edge. Small daylight windows sit
inside the wall faces. Oak floorboards, terracotta quilt, river-blue ceramics, cream linen,
warm amber lamps. Dense inhabited corners: books, jars, hanging herbs, shoes, sewing basket,
coat hooks and a family painting. Kitchen fitted against rear wall; a writing nook and chest;
small two-person table. Keep clear continuous walking paths. No empty oversized halls.
Furniture is ordinary human scale: single bed 1x2 tiles, chair 1x1, table 2x2, cabinets 2x1.
Keep an even orthographic top-down three-quarter view, no perspective convergence, no side-on
isometric room. Genuine chunky pixel clusters at an apparent 320x320 resolution enlarged to
4K, crisp dark brown outlines, 3 shades per material, no soft painting or tiny photo detail.
Charcoal background outside cutaway, no people, logos, lettering, UI, captions or grid lines.
"""


def main():
    out = Path(__file__).resolve().parents[2] / "assets/reference/interior_style_v2.png"
    if out.exists():
        print("Reference already exists:", out)
        return
    image = g.generate(
        PROMPT,
        quality="uhd",
        size="16:9",
        transparent=False,
        keep_background=True,
        references=REFERENCES,
        attempts=2,
    )
    if max(image.size) < 3840:
        raise RuntimeError(f"Expected a 4K reference, received {image.size}")
    image.save(out)
    print("Saved original reference:", image.size, out, flush=True)


if __name__ == "__main__":
    main()

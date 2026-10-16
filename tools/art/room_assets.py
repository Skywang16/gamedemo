"""Furniture and wall hangings for the interiors, from the committed library to the game art grid.

Each library piece is put on the art grain and the world palette. Pieces that stand on the floor get a
strip of SHADOW_PAD pixels under them holding the contact shadow, so their canvas is that much taller.
"""

from pathlib import Path
import sys
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import finish
from art.interior_asset_catalog import CANVAS_PX, FURNITURE, HANGING, PASSAGES, SHADOW_PAD

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "assets/library/interiors"


def names():
    return ["room_" + kind for kind in FURNITURE]


def standing(kind: str) -> bool:
    return kind not in HANGING and kind not in PASSAGES


def canvas(kind: str) -> tuple[int, int]:
    """Size of the installed sprite in game pixels; its bottom edge is the ground line."""
    width, _depth, height, _ = FURNITURE[kind]
    w, h = CANVAS_PX.get(kind, (width * 32, height * 32))
    return (w, h + SHADOW_PAD) if standing(kind) else (w, h)


def install():
    for kind in FURNITURE:
        source = finish.grain(Image.open(LIBRARY / f"room_{kind}.png"))
        sprite = Image.new("RGBA", canvas(kind), (0, 0, 0, 0))
        sprite.alpha_composite(source, (0, 0))
        if standing(kind):
            sprite = finish.shadow(sprite, "band")
        sprite.save(ROOT / "assets/art" / f"room_{kind}.png")
    print(f"Installed {len(FURNITURE)} interior pieces")


if __name__ == "__main__":
    install()

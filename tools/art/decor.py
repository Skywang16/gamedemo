"""Street furniture baked into the map backgrounds: sprites drawn by the image model (ai_decor.py).

Everything sits on the 32 px cell grid, bottom-centred on its cell; the contact shadow is baked into
each sprite. The map scripts add the matching collision rectangles for the solid pieces.
"""

from pathlib import Path
from PIL import Image

CELL = 32
SHADOW_PAD = 4  # the sprites carry their contact shadow in their last four rows (ai_decor.py)
ART = Path(__file__).resolve().parents[2] / "assets/art"
# Drawn once across the whole w x h footprint; every other kind is repeated per cell.
WHOLE = {"trough", "cart"}


def sprite(kind):
    return Image.open(ART / f"decor_{kind}.png").convert("RGBA")


def put(objects, im, cx, bottom):
    """Paste im with its picture's bottom edge on `bottom` (its shadow hangs below), centred on cx."""
    objects.alpha_composite(im, (round(cx - im.width / 2), bottom - im.height + SHADOW_PAD))


def draw_decor(im, region):
    """Draws region["fences"] and region["decor"] onto the terrain image."""
    fences = region.get("fences", [])
    decor = region.get("decor", [])
    if not fences and not decor:
        return im
    base = im.convert("RGBA")
    objects = Image.new("RGBA", im.size, (0, 0, 0, 0))
    items = []  # (bottom row in px, drawing function), drawn back to front
    for x0, y0, x1, y1, *_style in fences:
        horizontal = y0 == y1
        kind = "fence_h" if horizontal else "fence_v"
        for i in range(x0, x1 + 1) if horizontal else range(y0, y1 + 1):
            cx, row = (i, y0) if horizontal else (x0, i)
            items.append(
                (
                    (row + 1) * CELL,
                    lambda cx=cx, row=row, kind=kind: put(
                        objects, sprite(kind), cx * CELL + CELL // 2, (row + 1) * CELL - 2
                    ),
                )
            )
    for e in decor:
        x, y, w, h = e["cell"][0], e["cell"][1], e.get("w", 1), e.get("h", 1)
        kind = e["kind"]
        if kind in WHOLE:
            items.append(
                (
                    (y + h) * CELL,
                    lambda x=x, y=y, w=w, h=h, kind=kind: put(
                        objects,
                        sprite(kind),
                        (x * CELL) + w * CELL // 2,
                        (y + h) * CELL - 2,
                    ),
                )
            )
            continue
        for row in range(y, y + h):
            for col in range(x, x + w):
                items.append(
                    (
                        (row + 1) * CELL,
                        lambda col=col, row=row, kind=kind: put(
                            objects,
                            sprite(kind),
                            col * CELL + CELL // 2,
                            (row + 1) * CELL - 2,
                        ),
                    )
                )
    for _bottom, draw in sorted(items, key=lambda item: item[0]):
        draw()
    base.alpha_composite(objects)
    return base.convert("RGB")

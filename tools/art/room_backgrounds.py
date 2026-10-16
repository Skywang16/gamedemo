"""Offline assembly of a room's floor, walls, rugs and wall hangings from the playable floor plan.

The picture is built like a tile map on the art grid (room_kit.py): continuous floor boards, a two-cell
north wall face wherever the floor has no floor to its north, wall tops for every other wall, and shaded
floor along the walls. Furniture is never baked in: it stays a separate y-sorted sprite in the game.
"""

from pathlib import Path
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import finish
from art import room_kit as kit

ART = Path(__file__).resolve().parents[2] / "assets/art"
CELL = kit.CELL


def classify(floors: dict, width: int, height: int) -> dict:
    """Cell -> "face_up" | "face_low" | "cap" for every non-floor cell that shows a wall."""

    def inside(c):
        return 0 <= c[0] < width and 0 <= c[1] < height

    low = set()
    for y in range(height):
        for x in range(width):
            if (x, y) in floors:
                continue
            # A cell with floor on both sides is the top of a partition, not a wall face.
            if (x - 1, y) in floors and (x + 1, y) in floors:
                continue
            below = (x, y + 1)
            partition_top = (
                below not in floors
                and (x - 1, y + 1) in floors
                and (x + 1, y + 1) in floors
                and (x - 1, y) not in floors
                and (x + 1, y) not in floors
            )
            if below in floors or partition_top:
                low.add((x, y))
    up = {(x, y - 1) for x, y in low}
    if any(c in floors or not inside(c) for c in up):
        raise ValueError("a north wall face overlaps floor or leaves the map")
    kinds = {c: "face_low" for c in low} | {c: "face_up" for c in up}
    shown = set(floors) | set(kinds)
    for y in range(height):
        for x in range(width):
            cell = (x, y)
            if cell in shown:
                continue
            near = ((x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if any(n in shown for n in near):
                kinds[cell] = "cap"
    return kinds


def floor_cells(region: dict) -> dict:
    cells = {}
    for room in region["floors"]:
        x, y, w, h = room["rect"]
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                cells[(xx, yy)] = room["material"]
    return cells


def wall_material(cell: tuple, floors: dict) -> str:
    """The material of the nearest floor, looking below first: stone rooms get stone walls."""
    x, y = cell
    for dy in (1, 2, 3, 0, -1, -2, -3):
        for dx in (0, -1, 1, -2, 2):
            if (x + dx, y + dy) in floors:
                return floors[(x + dx, y + dy)]
    raise ValueError(f"wall at {cell} has no floor near it")


def structure(region: dict) -> Image.Image:
    """The room without rugs and hangings, at art-grid size."""
    w, h = region["width"], region["height"]
    floors = floor_cells(region)
    kinds = classify(floors, w, h)
    art = kit.blank(w, h)
    px = art.load()

    def kind(c):
        if c in floors:
            return "floor"
        return kinds.get(c, "void")

    for (cx, cy), material in floors.items():
        n, s = kind((cx, cy - 1)), kind((cx, cy + 1))
        west, east = kind((cx - 1, cy)), kind((cx + 1, cy))
        for py in range(CELL):
            for pxx in range(CELL):
                x, y = cx * CELL + pxx, cy * CELL + py
                colour = kit.floor_pixel(material, x, y)
                strength = 0
                if n in ("face_low", "face_up"):
                    strength = max(strength, (55, 35, 18)[py] if py < 3 else 0)
                elif n == "cap" and py < 2:
                    strength = max(strength, (40, 20)[py])
                if west != "floor" and west != "void" and pxx < 3:
                    strength = max(strength, (50, 30, 15)[pxx])
                if east == "cap" and pxx >= CELL - 2:
                    strength = max(strength, (22, 10)[pxx - (CELL - 2)])
                if s == "cap" and py >= CELL - 2:
                    strength = max(strength, 10)
                px[x, y] = kit.shade(colour, strength) if strength else colour
    for (cx, cy), what in kinds.items():
        if what == "cap":
            n, s = kind((cx, cy - 1)), kind((cx, cy + 1))
            west, east = kind((cx - 1, cy)), kind((cx + 1, cy))
            material = wall_material((cx, cy), floors)
            for py in range(CELL):
                for pxx in range(CELL):
                    px[cx * CELL + pxx, cy * CELL + py] = kit.cap_pixel(
                        material, pxx, py, n == "void", s == "void", west == "void", east == "void"
                    )
            continue
        material = wall_material((cx, cy), floors)
        base = 0 if what == "face_up" else CELL
        for py in range(CELL):
            for pxx in range(CELL):
                x = cx * CELL + pxx
                colour = kit.face_pixel(material, x, base + py)
                if kind((cx - 1, cy)) == "floor" and pxx < 2:
                    colour = (
                        kit.WALLS[material]["crown"] if pxx == 0 else kit.CAP[material]["light"]
                    )
                if kind((cx + 1, cy)) == "floor" and pxx >= CELL - 2:
                    colour = (
                        kit.CAP[material]["light"]
                        if pxx == CELL - 2
                        else kit.WALLS[material]["crown"]
                    )
                px[x, cy * CELL + py] = colour
    return art


def rug(width: int, height: int, seed: int) -> Image.Image:
    """A woven rug of w x h art pixels: outline, orange and green borders, cream field, diamond."""
    palettes = [
        ((110, 50, 34), (200, 112, 60), (110, 130, 84), (240, 222, 178)),
        ((60, 52, 92), (86, 124, 150), (214, 176, 98), (236, 226, 198)),
        ((92, 40, 44), (176, 72, 62), (222, 188, 120), (238, 218, 184)),
    ]
    dark, edge, band, field = palettes[seed % len(palettes)]
    im = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 1, width - 1, height - 2), fill=dark)
    d.rectangle((1, 2, width - 2, height - 3), fill=edge)
    d.rectangle((3, 4, width - 4, height - 5), fill=band)
    d.rectangle((6, 7, width - 7, height - 8), fill=dark)
    d.rectangle((7, 8, width - 8, height - 9), fill=field)
    for x in range(5, width - 5, 4):
        d.point((x, 5), fill=field)
        d.point((x, height - 6), fill=field)
    for y in range(6, height - 6, 4):
        d.point((4, y), fill=field)
        d.point((width - 5, y), fill=field)
    cx, cy = width // 2, height // 2
    reach = min(cx - 9, cy - 9)
    for i in range(-reach, reach + 1):
        d.point((cx + i, cy - (reach - abs(i))), fill=edge)
        d.point((cx + i, cy + (reach - abs(i))), fill=edge)
    d.rectangle((cx - 1, cy - 1, cx + 1, cy + 1), fill=dark)
    for y in range(3, height - 3, 2):
        d.point((0, y), fill=dark)
        d.point((width - 1, y), fill=dark)
    return im


def background(region: dict) -> Image.Image:
    art = finish.snap(structure(region)).convert("RGBA")
    for i, (x, y, rw, rh) in enumerate(region.get("rugs", [])):
        piece = finish.lock_art(rug(rw * CELL, rh * CELL, i + x))
        art.alpha_composite(piece, (x * CELL, y * CELL))
    image = finish.from_art(art).convert("RGB")
    for hanging in region.get("wall_art", []):
        sprite = Image.open(ART / ("room_" + hanging["kind"] + ".png")).convert("RGBA")
        x, y = hanging["cell"]
        image.paste(sprite, (x * 32, (y + 1) * 32 - sprite.height), sprite)
    for station in region["stations"]:
        if station["kind"] != "exit":
            continue
        is_entry = station["cell"] == region["entry"]
        kind = region.get("entry_style", "door") if is_entry else "stairs"
        sprite = Image.open(ART / ("room_" + kind + ".png")).convert("RGBA")
        x, y = station["cell"]
        bottom = (y + 2 if is_entry and kind == "door" else y + 1) * 32
        image.paste(sprite, (x * 32 + 16 - sprite.width // 2, bottom - sprite.height), sprite)
    return image


def preview(region: dict, collisions: bool = False) -> Image.Image:
    image = background(region).convert("RGBA")
    for prop in sorted(region["props"], key=lambda p: p["ground"][1]):
        sprite = Image.open(ART / (prop["texture"] + ".png")).convert("RGBA")
        x, y = [round(a + b) for a, b in zip(prop["ground"], prop["offset"])]
        image.alpha_composite(sprite, (x, y))
    if collisions:
        layer = Image.new("RGBA", image.size)
        d = ImageDraw.Draw(layer)
        for x, y, w, h in region["obstacles"]:
            d.rectangle(
                (x * 32, y * 32, (x + w) * 32 - 1, (y + h) * 32 - 1),
                fill=(255, 70, 70, 35),
                outline=(255, 70, 70, 190),
            )
        for station in region["stations"]:
            x, y = station["cell"]
            d.ellipse((x * 32 + 10, y * 32 + 10, x * 32 + 22, y * 32 + 22), fill="cyan")
        image = Image.alpha_composite(image, layer)
    return image


def main() -> None:
    import json

    root = ART.parents[1]
    folder = root / "build/interior-previews"
    folder.mkdir(parents=True, exist_ok=True)
    for name in json.loads((root / "data/maps/index.json").read_text())["maps"]:
        region = json.loads((root / "data/maps" / (name + ".json")).read_text())
        if region["environment"] != "interior":
            continue
        background(region).save(ART / (region["background"] + ".png"))
        preview(region).save(folder / (name + ".png"))
        if "--collisions" in sys.argv:
            preview(region, True).save(folder / (name + "-collision.png"))
    print("Interior backgrounds and previews:", folder)


if __name__ == "__main__":
    main()

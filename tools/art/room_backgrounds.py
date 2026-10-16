"""Offline assembly of model-drawn walls and floors, from the playable floor plan.

Furniture remains separate y-sorted sprites in the game. The preview command composites it
only for inspection; it is never baked into the collision-free floor image.
"""

from pathlib import Path
from PIL import Image, ImageDraw

ART = Path(__file__).resolve().parents[2] / "assets/art"


def background(region):
    w, h = region["width"], region["height"]
    image = Image.new("RGB", (w * 32, h * 32), "#182a2a")
    floors = set()
    floor_mask = Image.new("L", image.size)
    mask_draw = ImageDraw.Draw(floor_mask)
    for room in region["floors"]:
        x, y, rw, rh = room["rect"]
        tile = Image.open(ART / ("room_floor_" + room["material"] + ".png")).convert("RGB")
        # Global phase and native material scale keep adjacent floor patches seamless.
        for yy in range(y * 32, (y + rh) * 32):
            for xx in range(x * 32, (x + rw) * 32):
                image.putpixel((xx, yy), tile.getpixel((xx % tile.width, yy % tile.height)))
        mask_draw.rectangle((x * 32, y * 32, (x + rw) * 32 - 1, (y + rh) * 32 - 1), fill=255)
        floors.update((xx, yy) for yy in range(y, y + rh) for xx in range(x, x + rw))
    # North walls show the full elevation; side and south walls are cut away.
    # Never stamp a horizontal wall texture into a vertical corridor.
    wall = Image.open(ART / "room_wall.png").convert("RGB")
    walls = image.copy()
    d = ImageDraw.Draw(walls)
    for x, y in sorted(floors, key=lambda cell: (cell[1], cell[0])):
        if (x, y - 1) not in floors:
            strip = wall.crop(((x * 32) % wall.width, 0, (x * 32) % wall.width + 32, 64))
            walls.paste(strip, (x * 32, y * 32 - 64))
        if (x - 1, y) not in floors:
            d.rectangle((x * 32 - 10, y * 32, x * 32 - 1, y * 32 + 31), fill="#493b2f")
            d.line((x * 32 - 3, y * 32, x * 32 - 3, y * 32 + 31), fill="#ba8c53", width=3)
        if (x + 1, y) not in floors:
            d.rectangle(((x + 1) * 32, y * 32, (x + 1) * 32 + 9, y * 32 + 31), fill="#493b2f")
            d.line(
                ((x + 1) * 32 + 2, y * 32, (x + 1) * 32 + 2, y * 32 + 31), fill="#ba8c53", width=3
            )
        if (x, y + 1) not in floors:
            d.rectangle((x * 32, (y + 1) * 32, x * 32 + 31, (y + 1) * 32 + 7), fill="#493b2f")
            d.line(
                (x * 32, (y + 1) * 32 + 2, x * 32 + 31, (y + 1) * 32 + 2), fill="#ba8c53", width=2
            )
    # Preserve every walkable pixel; elevations extend only into solid wall space.
    walls.paste(image, (0, 0), floor_mask)
    image = walls
    rug = Image.open(ART / "room_rug.png").convert("RGBA")
    for x, y, rw, rh in region.get("rugs", []):
        # A rug's weave has a fixed scale. Crop a repeat instead of stretching the motif.
        patch = Image.new("RGBA", (rw * 32, rh * 32))
        scale = min(patch.width / rug.width, patch.height / rug.height, 1.0)
        size = (round(rug.width * scale), round(rug.height * scale))
        scaled = rug.resize(size, Image.Resampling.NEAREST)
        patch.alpha_composite(scaled, ((patch.width - size[0]) // 2, (patch.height - size[1]) // 2))
        image.paste(patch, (x * 32, y * 32), patch)
    for art in region.get("wall_art", []):
        sprite = Image.open(ART / ("room_" + art["kind"] + ".png")).convert("RGBA")
        x, y = art["cell"]
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


def preview(region, collisions=False):
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


def main():
    import json
    import sys

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

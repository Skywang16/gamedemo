"""Reusable farm tiles, built from approved AI swatches and explicit pixel transition rules.

This builds an atlas, never a map layout. The authoritative map is the editable TMX file.
16-pixel artwork is exported at exactly 2x; shore/path variants are reusable in any arrangement.
"""

from pathlib import Path
import json
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "assets/library/maps/farm"
ART = ROOT / "assets/art"
MAPS = ROOT / "tools/world/maps"
NEIGHBORS = [(0, -1), (1, 0), (0, 1), (-1, 0), (1, -1), (1, 1), (-1, 1), (-1, -1)]
COLUMNS = 16
TILE_COUNT = 528
WATER = 8
SHORE = 16
PATH = 272


def connected(mask):
    im = Image.new("L", (48, 48))
    d = ImageDraw.Draw(im)
    d.rectangle((16, 16, 31, 31), fill=255)
    for i, (x, y) in enumerate(NEIGHBORS):
        if mask & (1 << i):
            d.rectangle(((x + 1) * 16, (y + 1) * 16, (x + 2) * 16 - 1, (y + 2) * 16 - 1), fill=255)
    # Pixel erosion gives banks/road shoulders thickness; smoothing rounds concave corners.
    return (
        im.filter(ImageFilter.MinFilter(5))
        .filter(ImageFilter.GaussianBlur(1.1))
        .point(lambda a: 255 if a >= 112 else 0)
        .crop((16, 16, 32, 32))
    )


def swatch(scene, rect, palette, mean):
    im = scene.crop(rect).resize((16, 16), Image.Resampling.BOX).convert("RGB")
    average = ImageStat.Stat(im).mean
    channels = im.split()
    im = Image.merge(
        "RGB",
        [
            c.point(lambda v, i=i: round((v - average[i]) * 0.62 + mean[i]))
            for i, c in enumerate(channels)
        ],
    )
    pal = Image.new("P", (1, 1))
    colors = [v for rgb in palette for v in rgb]
    pal.putpalette(colors + colors[:3] * ((768 - len(colors)) // 3))
    return im.quantize(palette=pal, dither=Image.Dither.NONE).convert("RGBA")


def build_atlas():
    scene = Image.open(LIBRARY / "scene.png").resize((1536, 1152)).convert("RGB")
    green = [(110, 148, 70), (119, 157, 77), (129, 166, 84), (139, 175, 91), (149, 181, 101)]
    earth = [(165, 133, 84), (178, 144, 91), (192, 158, 103), (202, 169, 116), (213, 183, 131)]
    grasses = [
        swatch(scene, r, green, (129, 166, 84))
        for r in [
            (1050, 450, 1114, 514),
            (1110, 500, 1174, 564),
            (1100, 560, 1164, 624),
            (1050, 760, 1114, 824),
        ]
    ]
    dirt = swatch(scene, (1210, 270, 1250, 300), earth, (192, 158, 103))
    atlas = Image.new("RGBA", (256, 528))

    def put(index, tile):
        atlas.alpha_composite(tile, ((index % 16) * 16, (index // 16) * 16))

    for i, tile in enumerate(grasses):
        put(i, tile)
        dark = tile.point(lambda v: int(v * 0.84))
        dark.putalpha(255)
        put(12 + i, dark)
    for i in range(4):
        put(
            4 + i,
            dirt.transpose(
                [
                    Image.Transpose.FLIP_LEFT_RIGHT,
                    Image.Transpose.FLIP_TOP_BOTTOM,
                    Image.Transpose.ROTATE_180,
                    Image.Transpose.ROTATE_90,
                ][i]
            ),
        )
    # Four deliberate looping frames. Water is animated by TileSetAtlasSource, not a shader on a map image.
    for frame in range(4):
        water = Image.new("RGBA", (16, 16), "#4d9399")
        d = ImageDraw.Draw(water)
        for row, start, length in [(3, 2, 5), (10, 9, 4)]:
            shift = (start + frame * 2) % 16
            yy = row + (1 if frame in (1, 2) else 0)
            for k in range(length):
                d.point(((shift + k) % 16, yy), fill="#76b1ac" if frame != 3 else "#609fa3")
            d.point(((shift + length) % 16, yy + 1), fill="#3f858e")
        put(WATER + frame, water)
    for mask in range(256):
        shape = connected(mask)
        land = ImageChops.invert(shape)
        # Transparent water centre; a light soil lip and dark submerged bank remain stationary.
        shore = Image.new("RGBA", (16, 16))
        expanded = land.filter(ImageFilter.MaxFilter(5))
        shore.paste("#356d70", (0, 0, 16, 16), expanded)
        shore.paste("#a78350", (0, 0, 16, 16), land.filter(ImageFilter.MaxFilter(3)))
        shore.paste(grasses[0], (0, 0), land)
        put(SHORE + mask, shore)
        path = grasses[0].copy()
        path.paste("#8b8048", (0, 0, 16, 16), shape.filter(ImageFilter.MaxFilter(3)))
        path.paste(dirt, (0, 0), shape)
        put(PATH + mask, path)
    atlas.resize((512, 1056), Image.Resampling.NEAREST).save(ART / "farm_tiles.png")
    MAPS.mkdir(parents=True, exist_ok=True)
    tileset = ET.Element(
        "tileset",
        version="1.10",
        tiledversion="1.11.2",
        name="Farm terrain",
        tilewidth="32",
        tileheight="32",
        tilecount=str(TILE_COUNT),
        columns="16",
    )
    ET.SubElement(
        tileset, "image", source="../../../assets/art/farm_tiles.png", width="512", height="1056"
    )
    tile = ET.SubElement(tileset, "tile", id=str(WATER))
    animation = ET.SubElement(tile, "animation")
    for frame in range(4):
        ET.SubElement(animation, "frame", tileid=str(WATER + frame), duration="280")
    ET.indent(tileset)
    ET.ElementTree(tileset).write(MAPS / "farm_tiles.tsx", encoding="UTF-8", xml_declaration=True)


def install_objects():
    """Extract reusable objects once, at character-compatible scale, never with a ground rectangle."""
    concept = Image.open(LIBRARY / "scene.png").convert("RGBA")
    annotations = json.loads((LIBRARY / "cutouts.json").read_text())
    sizes = {
        "house": (256, 224),
        "well": (64, 80),
        "shipping": (48, 64),
        "bush_east": (96, 64),
        "bush_field": (64, 64),
    }
    for entry in annotations:
        key = entry["texture"].removeprefix("farm_scene_")
        mask = Image.new("L", concept.size)
        points = [
            (round(x * concept.width / 1536), round(y * concept.height / 1152))
            for x, y in entry["polygon"]
        ]
        ImageDraw.Draw(mask).polygon(points, fill=255)
        sprite = concept.copy()
        sprite.putalpha(mask)
        sprite = sprite.crop(mask.getbbox())
        w, h = sizes[key]
        sprite.thumbnail((w // 2 - 2, h // 2 - 4), Image.Resampling.LANCZOS)
        alpha = sprite.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
        sprite = sprite.convert("RGB").quantize(colors=96, dither=Image.Dither.NONE).convert("RGBA")
        sprite.putalpha(alpha)
        canvas = Image.new("RGBA", (w // 2, h // 2))
        canvas.alpha_composite(sprite, ((w // 2 - sprite.width) // 2, h // 2 - 2 - sprite.height))
        canvas.resize((w, h), Image.Resampling.NEAREST).save(ART / (entry["texture"] + ".png"))
    raw = Image.open(LIBRARY / "tree.png").convert("RGBA")
    raw = raw.crop(raw.getchannel("A").getbbox())
    for name, w, h in [("tree", 144, 192), ("woodland", 208, 272)]:
        tree = raw.copy()
        tree.thumbnail((w // 2 - 2, h // 2 - 4), Image.Resampling.LANCZOS)
        alpha = tree.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
        tree = tree.convert("RGB").quantize(colors=64, dither=Image.Dither.NONE).convert("RGBA")
        tree.putalpha(alpha)
        canvas = Image.new("RGBA", (w // 2, h // 2))
        canvas.alpha_composite(tree, ((w // 2 - tree.width) // 2, h // 2 - 2 - tree.height))
        canvas.resize((w, h), Image.Resampling.NEAREST).save(ART / ("farm_scene_" + name + ".png"))


def preview(region):
    atlas = Image.open(ART / "farm_tiles.png").convert("RGBA")
    im = Image.new("RGBA", (region["width"] * 32, region["height"] * 32))
    for layer in region["tile_layers"]:
        for i, gid in enumerate(layer["cells"]):
            if not gid:
                continue
            index = gid - 1
            x, y = (index % 16) * 32, (index // 16) * 32
            im.alpha_composite(
                atlas.crop((x, y, x + 32, y + 32)),
                ((i % region["width"]) * 32, (i // region["width"]) * 32),
            )
    im.save(ART / "home_farm_background.png")  # Overview thumbnail only, never the game's ground.


def install():
    build_atlas()
    install_objects()
    preview(json.loads((ROOT / "data/maps/home_farm.json").read_text()))


if __name__ == "__main__":
    install()

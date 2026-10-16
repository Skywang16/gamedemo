"""Generate 4K four-object sheets against the original v2 reference; export game-size sprites.

Run with optional asset names, --force to request fresh sheets, --process-only for offline export.
Sheet caches are versioned. Raw 4K images remain in build/art-raw; game imports are pixel locked.
"""

from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
import hashlib
import io
import json
from pathlib import Path
import sys
from PIL import Image, ImageChops, ImageDraw, ImageOps

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g
from art.interior_asset_catalog import CANVAS_PX, FURNITURE, SURFACES

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/library/interiors/v2"
STYLE = (
    "Use case: stylized-concept. Original production sprites for Sprout Valley. "
    "The attached original cottage is the immutable art direction. Match its chunky pixel clusters, "
    "warm walnut outlines, muted sage/cream walls, terracotta cloth, river blue ceramics and warm oak. "
    "Flat orthographic top-down three-quarter RPG view, fronts face straight down the screen. "
    "Same apparent pixel scale as a 16-bit farming RPG, no vanishing points, no side-view isometric projection. "
    "No photorealism, microdetail, text, letters, logo, characters or UI. "
)
SPRITES = list(FURNITURE) + ["rug"]
GROUPS = [SPRITES[i : i + 4] for i in range(0, len(SPRITES), 4)]
GROUPS += [[name for name in SURFACES if name != "rug"]]


@lru_cache(maxsize=1)
def reference():
    import base64

    path = ROOT / "assets/reference/interior_style_v2.png"
    image = Image.open(path).convert("RGB")
    image.thumbnail((1280, 720), Image.Resampling.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=90)
    return "data:image/jpeg;base64," + base64.b64encode(buffer.getvalue()).decode()


@lru_cache(maxsize=1)
def palette():
    """One immutable palette for the entire library, rather than one palette per object."""
    source = Image.open(ROOT / "assets/reference/interior_style_v2.png").convert("RGB")
    base = source.resize((480, 270), Image.Resampling.BOX).quantize(colors=96)
    colors = base.getpalette()[: 96 * 3]
    # The cottage reference contains almost no grey stone. Preserve its material ramp
    # rather than mapping limestone into green wallpaper colors.
    stone = g.RAW / "interior_v2_4k_sheet_10.png"
    if stone.exists():
        material = Image.open(stone).convert("RGB")
        material = material.crop((material.width // 2, 0, material.width, material.height // 2))
        material = material.resize((128, 128), Image.Resampling.BOX).quantize(colors=16)
        colors += material.getpalette()[: 16 * 3]
    colors += colors[:3] * ((768 - len(colors)) // 3)
    base.putpalette(colors)
    return base


def lock_palette(sprite):
    alpha = sprite.convert("RGBA").getchannel("A").point(lambda a: 255 if a > 127 else 0)
    result = (
        sprite.convert("RGB").quantize(palette=palette(), dither=Image.Dither.NONE).convert("RGBA")
    )
    result.putalpha(alpha)
    return result


def names():
    return ["room_" + key for key in FURNITURE | SURFACES]


def extract_cutout(raw, checkerboard=False):
    """Remove the pilot sheets' baked checkerboard without erasing neutral furniture."""
    image = raw.convert("RGBA")
    if checkerboard:
        r, green, b = image.convert("RGB").split()
        low = ImageChops.darker(ImageChops.darker(r, green), b)
        high = ImageChops.lighter(ImageChops.lighter(r, green), b)
        neutral = ImageChops.subtract(high, low).point(lambda v: 255 if v < 30 else 0)
        bright = low.point(lambda v: 255 if v > 85 else 0)
        background = ImageChops.multiply(neutral, bright)
        ImageDraw.floodfill(background, (0, 0), 128)
        image.putalpha(background.point(lambda v: 0 if v == 128 else 255))
    return g.cut_out(image, key_magenta=True)


def export(name, raw, checkerboard=False):
    cutouts = g.RAW / "interior_v2_cutouts"
    cutouts.mkdir(exist_ok=True)
    if name in FURNITURE or name == "rug":
        if name == "rug":
            w, h = 128, 80
        else:
            width, _depth, height, _ = FURNITURE[name]
            w, h = CANVAS_PX.get(name, (width * 32, height * 32))
        cutout = extract_cutout(raw, checkerboard)
        cutout.save(cutouts / (name + ".png"))
        sprite = g.to_game(cutout, w, h, (w, h), 0)
    else:
        size = (128, 64) if name == "wall" else (128, 128)
        if name.startswith("floor"):
            quarter = raw.resize((64, 64), Image.Resampling.BOX)
            sprite = Image.new("RGBA", size)
            sprite.paste(quarter, (0, 0))
            sprite.paste(ImageOps.mirror(quarter), (64, 0))
            sprite.paste(ImageOps.flip(quarter), (0, 64))
            sprite.paste(ImageOps.flip(ImageOps.mirror(quarter)), (64, 64))
        else:
            sprite = raw.resize(size, Image.Resampling.BOX)
            # Mirror a half-strip to close the horizontal wallpaper seam.
            left = sprite.crop((0, 0, 64, 64))
            sprite.paste(ImageOps.mirror(left), (64, 0))
        raw.save(cutouts / (name + ".png"))
    sprite = lock_palette(sprite)
    if name in SURFACES and name != "rug":
        sprite = sprite.convert("RGB")
    sprite.save(OUT / ("room_" + name + ".png"))


def make_group(index, force=False, process_only=False):
    group = GROUPS[index]
    surface = "floor_wood" in group
    cache = g.RAW / f"interior_v2_4k_sheet_{index:02d}.png"
    if force or not cache.exists():
        if process_only:
            raise FileNotFoundError(cache)
        prompt = (
            STYLE
            + "Produce a strict 2 by 2 sheet, four equally sized quadrants with boundaries exactly at 50% width and 50% height. "
        )
        for corner, name in zip(("TOP LEFT", "TOP RIGHT", "BOTTOM LEFT", "BOTTOM RIGHT"), group):
            subject = FURNITURE[name][3] if name in FURNITURE else SURFACES[name]
            prompt += f"{corner}: {subject}. "
        if surface:
            prompt += "Each quadrant is one FLAT rectangular texture filling its entire quadrant edge to edge. No furniture. Fourth quadrant repeats the bottom left wall texture. No margins or gutters."
        else:
            prompt += "Exactly one object centered in each quadrant. Keep all object pixels at least 12% away from quadrant edges. No dividing lines or frame. Perfectly flat pure magenta #FF00FF background; NO checkerboard, NO transparency pattern. No floor, cast shadow or scene. Furniture proportions must be compact, not oversized."
            if len(group) < 4:
                prompt += " Unspecified quadrants MUST remain completely empty."
        cache.with_suffix(".prompt.txt").write_text(prompt, encoding="utf-8")
        raw = g.generate(
            prompt,
            quality="uhd",
            size="16:9",
            transparent=False,
            keep_background=surface,
            references=[reference()],
            attempts=2,
        )
        raw.save(cache)
    raw = Image.open(cache).convert("RGBA")
    if max(raw.size) < 3840:
        raise RuntimeError(f"Expected 4K sheet, received {raw.size}; retained at {cache}")
    w, h = raw.width // 2, raw.height // 2
    for i, name in enumerate(group):
        x, y = i % 2 * w, i // 2 * h
        part = raw.crop((x, y, x + w, y + h))
        checkerboard = "Transparent empty" in cache.with_suffix(".prompt.txt").read_text()
        export(name, part, checkerboard=checkerboard)
    print("Generated 4K sheet", index, group, raw.size, flush=True)


def write_manifest():
    hanging = {"window", "painting", "herbs", "coat"}
    entries = {}
    for index, group in enumerate(GROUPS):
        source = g.RAW / f"interior_v2_4k_sheet_{index:02d}.png"
        if not source.exists():
            continue
        source_size = Image.open(source).size
        source_sha = hashlib.sha256(source.read_bytes()).hexdigest()
        for quadrant, name in enumerate(group):
            path = OUT / ("room_" + name + ".png")
            if not path.exists():
                continue
            im = Image.open(path)
            entry = {
                "file": path.name,
                "canvas_px": list(im.size),
                "source_sheet": str(source.relative_to(ROOT)),
                "source_sheet_px": list(source_size),
                "source_sha256": source_sha,
                "source_prompt": str(source.with_suffix(".prompt.txt").relative_to(ROOT)),
                "source_quadrant": quadrant,
                "source_cutout": f"build/art-raw/interior_v2_cutouts/{name}.png",
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            }
            if name in FURNITURE:
                width, depth, _, _ = FURNITURE[name]
                entry.update(
                    {
                        "category": "wall_decoration"
                        if name in hanging
                        else "portal"
                        if name in {"door", "stairs"}
                        else "furniture",
                        "anchor_px": [im.width // 2, im.height],
                        "placement_tiles": [width, depth],
                        "placement_box_px": [-width * 16, -depth * 32, width * 32, depth * 32],
                        "collision": "none" if name in hanging else "author_at_map_integration",
                    }
                )
            else:
                entry.update(
                    {
                        "category": "floor_decoration" if name == "rug" else "texture",
                        "anchor_px": [0, 0],
                        "collision": "none",
                        "tile_axes": []
                        if name == "rug"
                        else ["x"]
                        if name == "wall"
                        else ["x", "y"],
                    }
                )
            entries[name] = entry
    swatches = palette().getpalette()[: 112 * 3]
    (OUT / "palette.json").write_text(
        json.dumps([swatches[i : i + 3] for i in range(0, len(swatches), 3)]) + "\n"
    )
    manifest = {
        "version": 2,
        "status": "asset_library_not_map_integration",
        "tile_size_px": 32,
        "player_frame_px": [32, 48],
        "player_world_scale": 1.25,
        "filter": "nearest",
        "mipmaps": False,
        "palette": "palette.json",
        "palette_source": "96 colors from original reference + 16 limestone colors from sheet 10",
        "provider": g.BASE,
        "model": g.MODEL,
        "requested_quality": "uhd",
        "reference": "assets/reference/interior_style_v2.png",
        "reference_sha256": hashlib.sha256(
            (ROOT / "assets/reference/interior_style_v2.png").read_bytes()
        ).hexdigest(),
        "generation_script": "tools/art/ai_interior_library.py",
        "assets": entries,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")


def main():
    requested = [a for a in sys.argv[1:] if not a.startswith("--")]
    unknown = set(requested) - set(FURNITURE | SURFACES)
    if unknown:
        raise SystemExit("Unknown assets: " + ", ".join(sorted(unknown)))
    chosen = [i for i, group in enumerate(GROUPS) if not requested or set(group) & set(requested)]
    g.RAW.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    previous = OUT / "manifest.json"
    if previous.exists():
        recorded = json.loads(previous.read_text())
        current = hashlib.sha256(
            (ROOT / "assets/reference/interior_style_v2.png").read_bytes()
        ).hexdigest()
        if recorded["reference_sha256"] != current:
            raise SystemExit(
                "Reference changed: create a new library version instead of mixing styles."
            )
    with ThreadPoolExecutor(max_workers=2) as pool:
        list(
            pool.map(
                lambda i: make_group(i, "--force" in sys.argv, "--process-only" in sys.argv), chosen
            )
        )
    write_manifest()


if __name__ == "__main__":
    main()

"""Furniture drawn by the image model: 4K four-object sheets against the interior style reference.

    python tools/art/ai_interior_library.py [name ...] [--force] [--process-only]

Each sheet holds four pieces on a flat magenta background. The cut-out pieces are fitted to their
catalogue canvas and saved to assets/library/interiors/ (the committed source art); room_assets.py
then puts them on the art grid and the world palette, with their contact shadow. Raw 4K sheets stay
in build/art-raw. --process-only re-exports from cached sheets and never calls the model.
"""

from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache
import base64
import io
from pathlib import Path
import sys
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import imagegen as g
from art.interior_asset_catalog import CANVAS_PX, FURNITURE

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/library/interiors"
STYLE = (
    "Use case: stylized-concept. Original production sprites for Sprout Valley. "
    "The attached original cottage is the immutable art direction. Match its chunky pixel clusters, "
    "warm walnut outlines, muted sage/cream walls, terracotta cloth, river blue ceramics and warm oak. "
    "Flat orthographic top-down three-quarter RPG view, fronts face straight down the screen. "
    "Same apparent pixel scale as a 16-bit farming RPG, no vanishing points, no side-view isometric projection. "
    "No photorealism, microdetail, text, letters, logo, characters or UI. "
)
SPRITES = list(FURNITURE)
GROUPS = [SPRITES[i : i + 4] for i in range(0, len(SPRITES), 4)]


@lru_cache(maxsize=1)
def reference() -> str:
    image = Image.open(ROOT / "assets/reference/interior_style_v2.png").convert("RGB")
    image.thumbnail((1280, 720), Image.Resampling.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=90)
    return "data:image/jpeg;base64," + base64.b64encode(buffer.getvalue()).decode()


def export(name: str, raw: Image.Image) -> None:
    width, _depth, height, _ = FURNITURE[name]
    w, h = CANVAS_PX.get(name, (width * 32, height * 32))
    cutout = g.cut_out(raw, key_magenta=True)
    cutout.save(g.RAW / "interior_cutouts" / (name + ".png"))
    scale = min(w / cutout.width, h / cutout.height)
    size = (max(1, round(cutout.width * scale)), max(1, round(cutout.height * scale)))
    sprite = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sprite.alpha_composite(cutout.resize(size, Image.BOX), ((w - size[0]) // 2, h - size[1]))
    alpha = sprite.getchannel("A").point(lambda a: 255 if a > 127 else 0)
    sprite.putalpha(alpha)
    sprite.save(OUT / ("room_" + name + ".png"))


def make_group(index: int, force: bool = False, process_only: bool = False) -> None:
    group = GROUPS[index]
    cache = g.RAW / f"interior_v2_4k_sheet_{index:02d}.png"
    if force or not cache.exists():
        if process_only:
            raise FileNotFoundError(cache)
        prompt = (
            STYLE
            + "Produce a strict 2 by 2 sheet, four equally sized quadrants with boundaries exactly at 50% width and 50% height. "
        )
        for corner, name in zip(("TOP LEFT", "TOP RIGHT", "BOTTOM LEFT", "BOTTOM RIGHT"), group):
            prompt += f"{corner}: {FURNITURE[name][3]}. "
        prompt += (
            "Exactly one object centered in each quadrant. Keep all object pixels at least 12% away from quadrant edges. "
            "No dividing lines or frame. Perfectly flat pure magenta #FF00FF background; NO checkerboard, NO transparency pattern. "
            "No floor, cast shadow or scene. Furniture proportions must be compact, not oversized."
        )
        if len(group) < 4:
            prompt += " Unspecified quadrants MUST remain completely empty."
        cache.with_suffix(".prompt.txt").write_text(prompt, encoding="utf-8")
        raw = g.generate(
            prompt,
            quality="uhd",
            size="16:9",
            transparent=False,
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
        export(name, raw.crop((x, y, x + w, y + h)))
    print("Generated 4K sheet", index, group, raw.size, flush=True)


def main() -> None:
    requested = [a for a in sys.argv[1:] if not a.startswith("--")]
    unknown = set(requested) - set(FURNITURE)
    if unknown:
        raise SystemExit("Unknown assets: " + ", ".join(sorted(unknown)))
    chosen = [i for i, group in enumerate(GROUPS) if not requested or set(group) & set(requested)]
    (g.RAW / "interior_cutouts").mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=2) as pool:
        list(
            pool.map(
                lambda i: make_group(i, "--force" in sys.argv, "--process-only" in sys.argv), chosen
            )
        )


if __name__ == "__main__":
    main()

"""Offline checks and scale previews for the reusable interior library. No game window."""

import json
import hashlib
from pathlib import Path
import sys
import zipfile

from PIL import Image, ImageChops, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art.ai_interior_library import OUT, ROOT
from art.interior_asset_catalog import FURNITURE, SURFACES


def font(size):
    return ImageFont.truetype(str(ROOT / "assets/fonts/NotoSansSC.ttf"), size)


def validate(manifest):
    entries = manifest["assets"]
    expected = set(FURNITURE) | set(SURFACES)
    assert set(entries) == expected, f"Missing assets: {expected - set(entries)}"
    palette = {tuple(color) for color in json.loads((OUT / manifest["palette"]).read_text())}
    for name, item in entries.items():
        im = Image.open(OUT / item["file"]).convert("RGBA")
        assert hashlib.sha256((OUT / item["file"]).read_bytes()).hexdigest() == item["sha256"], (
            f"Manifest out of date: {name}"
        )
        assert list(im.size) == item["canvas_px"], name
        alpha = im.getchannel("A")
        visible_colors = {pixel[:3] for _, pixel in im.getcolors(im.width * im.height) if pixel[3]}
        assert visible_colors <= palette, f"Palette mismatch: {name}"
        assert alpha.getbbox(), f"Empty asset: {name}"
        alpha_values = {value for _, value in alpha.getcolors(256)}
        assert alpha_values <= {0, 255}, f"Soft alpha: {name}"
        if name in FURNITURE or name == "rug":
            assert 0 in alpha_values, f"Opaque background: {name}"
            cutout = Image.open(ROOT / item["source_cutout"]).convert("RGBA")
            assert cutout.getchannel("A").getextrema()[0] == 0, (
                f"Cutout has no transparency: {name}"
            )
        assert max(item["source_sheet_px"]) >= 3840, f"Not 4K: {name}"
        rgb = im.convert("RGB")
        if "x" in item.get("tile_axes", []):
            assert not ImageChops.difference(
                rgb.crop((0, 0, 1, im.height)), rgb.crop((im.width - 1, 0, im.width, im.height))
            ).getbbox(), f"X seam: {name}"
        if "y" in item.get("tile_axes", []):
            assert not ImageChops.difference(
                rgb.crop((0, 0, im.width, 1)), rgb.crop((0, im.height - 1, im.width, im.height))
            ).getbbox(), f"Y seam: {name}"
    return len(entries)


def preview(manifest):
    entries = list(manifest["assets"].items())
    width, height = 320, 280
    rows = (len(entries) + 4) // 5
    page = Image.new("RGB", (5 * width, rows * height + 100), "#18242a")
    draw = ImageDraw.Draw(page)
    draw.text((24, 18), "SPROUT VALLEY / REUSABLE INTERIOR KIT", font=font(30), fill="#f5e6c9")
    draw.text(
        (24, 58),
        "32 px tiles | 2x nearest preview | current character shown at the same scale",
        font=font(19),
        fill="#b1beb4",
    )
    player = Image.open(ROOT / "assets/art/avatar_0_0_0_0.png").convert("RGBA").crop((0, 0, 32, 48))
    for i, (name, item) in enumerate(entries):
        x, y = i % 5 * width, 100 + i // 5 * height
        draw.rounded_rectangle((x + 7, y + 5, x + width - 7, y + height - 5), 8, fill="#26363b")
        draw.text((x + 16, y + 15), name, font=font(20), fill="#f5e6c9")
        im = Image.open(OUT / item["file"]).convert("RGBA")
        texture = item["category"] == "texture"
        if texture:
            im = im.crop((0, 0, min(112, im.width), min(80, im.height)))
        scaled = im.resize((im.width * 2, im.height * 2), Image.Resampling.NEAREST)
        baseline = y + 232
        # Checkerboard makes opaque backgrounds and stray pixels visible.
        for gy in range(y + 45, baseline, 16):
            for gx in range(x + 16, x + width - 16, 16):
                color = "#314448" if (gx // 16 + gy // 16) % 2 else "#293b40"
                draw.rectangle(
                    (gx, gy, min(gx + 15, x + width - 16), min(gy + 15, baseline)), fill=color
                )
        page.paste(scaled, (x + 18, baseline - scaled.height), scaled)
        if not texture and scaled.width <= 224:
            scale = 2 * manifest["player_world_scale"]
            actor = player.resize(
                (round(player.width * scale), round(player.height * scale)),
                Image.Resampling.NEAREST,
            )
            page.paste(actor, (x + width - actor.width - 10, baseline - actor.height), actor)
        draw.text(
            (x + 16, y + 246),
            f"{item['canvas_px'][0]} x {item['canvas_px'][1]} px  /  {item['category']}",
            font=font(15),
            fill="#bac9bd",
        )
    page.save(OUT / "preview.png")


def package(manifest):
    destination = ROOT / "build/art-delivery/sprout-valley-interiors-v2.zip"
    destination.parent.mkdir(parents=True, exist_ok=True)
    paths = set(OUT.glob("*.png")) | {
        OUT / "manifest.json",
        OUT / "README.md",
        OUT / "QA.md",
        OUT / "palette.json",
        ROOT / manifest["reference"],
    }
    for item in manifest["assets"].values():
        paths.update(ROOT / item[key] for key in ("source_sheet", "source_cutout", "source_prompt"))
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(paths):
            archive.write(path, str(path.relative_to(ROOT)))
    print("Packaged:", destination)


def main():
    manifest = json.loads((OUT / "manifest.json").read_text())
    count = validate(manifest)
    preview(manifest)
    print(f"PASS: {count} assets; dimensions, alpha, 4K sources and declared tiling seams checked.")
    if "--package" in sys.argv:
        package(manifest)


if __name__ == "__main__":
    main()

"""Build a locally signed macOS app in build/macos using a Godot executable.

Usage: python3 tools/package_macos.py /absolute/path/to/Godot
Shipping releases require export templates, a developer signature and notarization.
"""

import argparse
import configparser
from pathlib import Path
import plistlib
import shutil
import subprocess

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]


def build(engine: Path) -> Path:
    config = configparser.ConfigParser(interpolation=None)
    config.read(ROOT / "export_presets.cfg", encoding="utf-8")
    options = config["preset.0.options"]
    bundle_id = options["application/bundle_identifier"].strip('"')
    version = options["application/short_version"].strip('"')
    build_version = options["application/version"].strip('"')

    output = ROOT / "build"
    output.mkdir(exist_ok=True)
    (output / ".gdignore").touch()
    subprocess.run(
        [str(engine), "--headless", "--editor", "--path", str(ROOT), "--import"], check=True
    )
    app = output / "macos/Sprout Valley.app"
    if app.exists():
        shutil.rmtree(app)
    mac = app / "Contents/MacOS"
    resources = app / "Contents/Resources"
    mac.mkdir(parents=True)
    resources.mkdir(parents=True)
    subprocess.run(
        [
            str(engine),
            "--headless",
            "--path",
            str(ROOT),
            "--export-pack",
            "macOS",
            str(resources / "game.pck"),
        ],
        check=True,
    )
    shutil.copy2(engine, mac / "Godot")
    launcher = mac / "SproutValley"
    launcher.write_text(
        """#!/bin/sh
set -eu
bundle_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$bundle_dir/MacOS/Godot" --main-pack "$bundle_dir/Resources/game.pck" "$@"
""",
        encoding="utf-8",
    )
    launcher.chmod(0o755)
    with (app / "Contents/Info.plist").open("wb") as stream:
        plistlib.dump(
            {
                "CFBundleName": "芽田农场",
                "CFBundleDisplayName": "芽田农场",
                "CFBundleIdentifier": bundle_id,
                "CFBundleExecutable": "SproutValley",
                "CFBundlePackageType": "APPL",
                "CFBundleShortVersionString": version,
                "CFBundleVersion": build_version,
                "CFBundleInfoDictionaryVersion": "6.0",
                "CFBundleIconFile": "Farm.icns",
                "LSApplicationCategoryType": "public.app-category.games",
                "NSHighResolutionCapable": True,
                "NSPrincipalClass": "NSApplication",
                "LSMinimumSystemVersionByArchitecture": {"arm64": "13.0", "x86_64": "11.0"},
            },
            stream,
        )
    icon = Image.new("RGBA", (1024, 1024))
    draw = ImageDraw.Draw(icon)
    draw.rounded_rectangle((40, 40, 984, 984), radius=200, fill="#244b37")
    sprite = Image.open(ROOT / "assets/art/turnip_item.png").resize(
        (768, 768), Image.Resampling.NEAREST
    )
    icon.alpha_composite(sprite, (128, 100))
    icon.save(resources / "Farm.icns", format="ICNS")
    shutil.copytree(ROOT / "licenses", resources / "licenses")
    shutil.copy2(ROOT / "assets/fonts/OFL.txt", resources / "NotoSansSC-OFL.txt")
    subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(app)], check=True)
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    return app


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("engine", type=Path, help="Path to the Godot executable")
    args = parser.parse_args()
    engine = args.engine.expanduser().resolve()
    if not engine.is_file():
        parser.error(f"Godot executable does not exist: {engine}")
    print(build(engine))


if __name__ == "__main__":
    main()

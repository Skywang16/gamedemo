"""Create a portable development .app using a supplied Godot editor executable.

Usage: python3 tools/package_macos.py /absolute/path/to/Godot
For shipping releases, install official export templates and use the macOS preset.
"""

from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
engine = Path(sys.argv[1]).resolve()
app = root.parent / "Sprout Valley.app"
mac = app / "Contents/MacOS"
resources = app / "Contents/Resources"
mac.mkdir(parents=True, exist_ok=True)
resources.mkdir(parents=True, exist_ok=True)
subprocess.run(
    [
        str(engine),
        "--headless",
        "--path",
        str(root),
        "--export-pack",
        "macOS",
        str(resources / "game.pck"),
    ],
    check=True,
)
shutil.copy2(engine, mac / "Godot")
launcher = mac / "SproutValley"
launcher.write_text("""#!/bin/sh
set -eu
bundle_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec "$bundle_dir/MacOS/Godot" --main-pack "$bundle_dir/Resources/game.pck" "$@"
""")
launcher.chmod(0o755)
with (app / "Contents/Info.plist").open("wb") as f:
    plistlib.dump(
        {
            "CFBundleName": "芽田农场",
            "CFBundleDisplayName": "芽田农场",
            "CFBundleIdentifier": "dev.sproutvalley.demo",
            "CFBundleExecutable": "SproutValley",
            "CFBundlePackageType": "APPL",
            "CFBundleShortVersionString": "0.3.0",
            "CFBundleVersion": "3",
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleIconFile": "Farm.icns",
            "LSApplicationCategoryType": "public.app-category.games",
            "NSHighResolutionCapable": True,
            "NSPrincipalClass": "NSApplication",
            "LSMinimumSystemVersionByArchitecture": {"arm64": "13.0", "x86_64": "11.0"},
        },
        f,
    )
icon = Image.new("RGBA", (1024, 1024))
d = ImageDraw.Draw(icon)
d.rounded_rectangle((40, 40, 984, 984), radius=200, fill="#244b37")
sprite = Image.open(root / "assets/art/turnip_item.png").resize(
    (768, 768), Image.Resampling.NEAREST
)
icon.alpha_composite(sprite, (128, 100))
icon.save(resources / "Farm.icns", format="ICNS")
license_dir = root / "licenses"
if license_dir.exists():
    shutil.copytree(license_dir, resources / "licenses", dirs_exist_ok=True)
shutil.copy2(root / "assets/fonts/OFL.txt", resources / "NotoSansSC-OFL.txt")
subprocess.run(["codesign", "--force", "--deep", "--sign", "-", str(app)], check=True)
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
print(app)

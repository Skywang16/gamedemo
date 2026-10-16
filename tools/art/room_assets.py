"""Install the approved v2 library without resizing; the manifest owns asset dimensions."""

import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "assets/library/interiors/v2"


def names():
    manifest = json.loads((LIBRARY / "manifest.json").read_text())
    return [Path(item["file"]).stem for item in manifest["assets"].values()]


def install():
    manifest = json.loads((LIBRARY / "manifest.json").read_text())
    for item in manifest["assets"].values():
        source = LIBRARY / item["file"]
        if hashlib.sha256(source.read_bytes()).hexdigest() != item["sha256"]:
            raise ValueError(f"Asset differs from approved library: {source.name}")
        shutil.copyfile(source, ROOT / "assets/art" / source.name)
    print(f"Installed {len(manifest['assets'])} v2 interior assets")


if __name__ == "__main__":
    install()

"""Rebuild the code-drawn pixel assets. No network: image-model sprites are listed in art/ai_assets.py and kept as they are."""

from pathlib import Path
import json
import time
from art.crops import crop, watering_can
from art.props import carrot, stall, crate, tool, build_misc
from art.environment import utility, well
from art.ai_assets import ASSETS as AI_ASSETS
from art.ai_terrain import TEXTURES as AI_TERRAIN, output_name
from art.ai_nature import names as nature_names
from art.ai_interiors import ROOMS as AI_ROOMS
from art.ai_decor import names as decor_names
from art.characters import build_characters, build_villagers
from art.actions import build_actions
from art.terrain import landscape
from art.interface import build_interface
from art.produce_build import build_produce
from art.buildings import build_buildings
from art.enemies import build_enemies
from content.story_data import GUEST_LOOKS, LOOKS

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/art"


KEPT = (
    set(AI_ASSETS)
    | {output_name(n) for n in AI_TERRAIN}
    | set(nature_names())
    | set(decor_names())
    | {n + "_background" for n in AI_ROOMS}
)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    started = time.time()

    def save(name, im):
        im.save(OUTPUT / (name + ".png"))

    for name, im in {
        "watering_can": watering_can(),
        "hoe": tool("hoe"),
        "seed_bag": tool("seed"),
        "shop": stall(),
        "shipping": crate(),
        "well": well(),
    }.items():
        save(name, im)
    for name in ["scythe", "axe", "pickaxe", "fiber"]:
        save(name, utility(name))
    for name, fn in [("turnip", crop), ("carrot", carrot)]:
        for stage in ["seeds", "sprout", "young", "mature"]:
            save(name + "_" + stage, fn(stage))
        save(name + "_item", fn("harvest"))
    build_misc(OUTPUT)
    build_characters(OUTPUT)
    build_villagers(OUTPUT, {**LOOKS, **GUEST_LOOKS})
    build_enemies(OUTPUT)
    build_actions(OUTPUT)
    build_interface(OUTPUT)
    build_produce(OUTPUT)
    build_buildings(OUTPUT)
    index = json.loads((ROOT / "data/maps/index.json").read_text())
    for name in index["maps"]:
        region = json.loads((ROOT / "data/maps" / f"{name}.json").read_text())
        if region["width"] <= 30:
            continue
        save(region["background"], landscape(region))
        print("Rendered", name, region["width"] * 32, region["height"] * 32, flush=True)
    # The generator is authoritative: anything it did not write this run is removed.
    # The sprites drawn by the image model (tools/art/ai_assets.py) are committed art, not generated here.
    for stale in OUTPUT.glob("*.png"):
        if stale.stem in KEPT:
            continue
        if stale.stat().st_mtime < started:
            stale.unlink()
            Path(str(stale) + ".import").unlink(missing_ok=True)
            print("Removed stale", stale.name)


if __name__ == "__main__":
    main()

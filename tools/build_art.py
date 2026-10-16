"""Rebuild original pixel assets. No network, image model or external source artwork."""

from pathlib import Path
import json
import time
from art.crops import crop, soil, watering_can
from art.props import carrot, stall, crate, tool, build_misc
from art.environment import house, tree, debris, utility, well
from art.characters import build_characters, build_villagers
from art.actions import build_actions
from art.terrain import landscape
from art.interiors import build_interiors
from art.interface import build_interface
from art.produce_build import build_produce
from art.buildings import build_buildings
from art.interiors2 import build_shop_interiors
from art.enemies import build_enemies
from content.story_data import GUEST_LOOKS, LOOKS

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/art"


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    started = time.time()

    def save(name, im):
        im.save(OUTPUT / (name + ".png"))

    for name, im in {
        "soil_dry": soil(),
        "soil_wet": soil(True),
        "watering_can": watering_can(),
        "hoe": tool("hoe"),
        "seed_bag": tool("seed"),
        "house": house(),
        "inn": house("plum"),
        "workshop": house("slate"),
        "shop": stall(),
        "shipping": crate(),
        "well": well(),
    }.items():
        save(name, im)
    for name in ["scythe", "axe", "pickaxe", "fiber"]:
        save(name, utility(name))
    for i in range(4):
        save("tree_" + str(i), tree(i))
    for name in ["weeds", "branch", "rock"]:
        for i in range(3):
            save(name + "_" + str(i), debris(name, i))
    for name, fn in [("turnip", crop), ("carrot", carrot)]:
        for stage in ["seeds", "sprout", "young", "mature"]:
            save(name + "_" + stage, fn(stage))
        save(name + "_item", fn("harvest"))
    build_misc(OUTPUT)
    build_characters(OUTPUT)
    build_villagers(OUTPUT, {**LOOKS, **GUEST_LOOKS})
    build_enemies(OUTPUT)
    build_actions(OUTPUT)
    build_interiors(OUTPUT)
    build_interface(OUTPUT)
    build_produce(OUTPUT)
    build_buildings(OUTPUT)
    build_shop_interiors(OUTPUT)
    index = json.loads((ROOT / "data/maps/index.json").read_text())
    for name in index["maps"]:
        region = json.loads((ROOT / "data/maps" / f"{name}.json").read_text())
        if region["width"] <= 30:
            continue
        save(region["background"], landscape(region))
        print("Rendered", name, region["width"] * 32, region["height"] * 32, flush=True)
    # The generator is authoritative: anything it did not write this run is removed.
    for stale in OUTPUT.glob("*.png"):
        if stale.stat().st_mtime < started:
            stale.unlink()
            Path(str(stale) + ".import").unlink(missing_ok=True)
            print("Removed stale", stale.name)


if __name__ == "__main__":
    main()

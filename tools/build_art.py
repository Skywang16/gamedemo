"""Rebuild original pixel assets. No network, image model or external source artwork."""

from pathlib import Path
import json
from art.crops import crop, soil, watering_can
from art.props import carrot, stall, crate, tool, build_misc
from art.environment import house, tree, debris, utility, well
from art.characters import build_characters
from art.terrain import landscape
from art.interiors import build_interiors, build_title

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/art"


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)

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
    build_interiors(OUTPUT)
    build_title(OUTPUT)
    for name in ["home_farm", "town", "forest", "lake"]:
        region = json.loads((ROOT / "data/maps" / f"{name}.json").read_text())
        save(region["background"], landscape(region))
        print("Rendered", name, region["width"] * 32, region["height"] * 32, flush=True)


if __name__ == "__main__":
    main()

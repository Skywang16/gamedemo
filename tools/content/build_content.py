"""Authoring command: writes data/items.json, crops.json, fish.json and recipes.json.

Everything is generated from tools/content/specs.py and dishes.py; nothing is read back from
earlier output.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from content import economy, specs  # noqa: E402
from content.dishes import all_dishes  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
SEASON_NAMES = {"spring": "春", "summer": "夏", "autumn": "秋", "winter": "冬"}
SPOT_NAMES = {
    "pond": "池塘",
    "stream": "溪流",
    "river": "河道",
    "lake": "湖泊",
    "sea": "海边",
    "cave": "洞窟",
}
# Which water type each map offers for fishing.
SPOT_OF_MAP = {
    "home_farm": "pond",
    "ranch": "pond",
    "town": "river",
    "forest": "stream",
    "lake": "lake",
    "seaside": "sea",
    "far_shore": "lake",
    "mine_1": "cave",
    "mine_2": "cave",
    "mine_3": "cave",
}


def season_text(seasons):
    if len(seasons) == len(SEASON_NAMES):
        return "四"
    return "、".join(SEASON_NAMES[s] for s in seasons)


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf8")


def item(name, kind, buy, sell, icon, description, energy):
    return {
        "name": name,
        "kind": kind,
        "buy_price": buy,
        "sell_price": sell,
        "icon": icon,
        "description": description,
        "energy": energy,
    }


def build():
    items = {}
    crops = {}
    for spec in specs.BASE_CROPS + specs.CROPS:
        ident, name, seasons, days, regrow, seed_price, sell, energy = spec[:8]
        if regrow >= days:
            raise SystemExit("crop %s: regrow days must be fewer than growth days" % ident)
        note = "，收获后每 %d 天再结一次果" % regrow if regrow else ""
        items[ident + "_seed"] = item(
            name + "种子",
            "seed",
            seed_price,
            0,
            ident + "_packet",
            "%s季种子。每天浇水，%d 天成熟%s。" % (season_text(seasons), days, note),
            0,
        )
        items[ident] = item(name, "produce", 0, sell, ident + "_item", spec[12], energy)
        crops[ident] = {
            "name": name,
            "seed_item": ident + "_seed",
            "harvest_item": ident,
            "seasons": seasons,
            "growth_days": days,
            "regrow": regrow,
            "yield": 1,
            "stages": [ident + "_seeds", ident + "_sprout", ident + "_young", ident + "_mature"],
        }
    for ident, name, kind, sell, energy, text in specs.BASE_MATERIALS:
        items[ident] = item(name, kind, 0, sell, ident, text, energy)
    fish_entries = []
    for spec in specs.FISH:
        ident, name, spots, seasons, weather, hours, rarity, difficulty, price, energy = spec[:10]
        where = "、".join(SPOT_NAMES[s] for s in spots)
        items[ident] = item(
            name,
            "fish",
            0,
            price,
            "fish_" + ident,
            "%s（%s · %s）" % (spec[12], where, season_text(seasons)),
            energy,
        )
        fish_entries.append(
            {
                "id": ident,
                "spots": spots,
                "seasons": seasons,
                "weather": weather if isinstance(weather, list) else ["any"],
                "hours": list(hours),
                "weight": rarity,
                "difficulty": difficulty,
            }
        )
    for ident, name, kind, price, energy, _shape, _colours, text in specs.FORAGE:
        items[ident] = item(name, kind, 0, price, "forage_" + ident, text, energy)
    for ident, name, price, _shape, _colours, text in specs.MINERALS:
        items[ident] = item(name, "mineral", 0, price, "mineral_" + ident, text, 0)
    for ident, name, kind, price, energy, _shape, _colours, text in specs.ANIMAL_GOODS:
        items[ident] = item(
            name, kind, 8 if ident == "hay" else 0, price, "goods_" + ident, text, energy
        )
    for ident, name, kind, buy, sell, energy, _shape, _colours, text in specs.MISC:
        items[ident] = item(name, kind, buy, sell, "misc_" + ident, text, energy)
    recipes = []
    for ident, name, needs, energy, price, level, _shape, _colours, text in all_dishes():
        items[ident] = item(
            name, "dish", 0, price, "dish_" + ident, "%s 恢复 %d 体力。" % (text, energy), energy
        )
        recipes.append({"id": ident, "needs": needs, "level": level})
    write(DATA / "items.json", items)
    write(DATA / "crops.json", crops)
    write(DATA / "fish.json", {"spots": SPOT_OF_MAP, "fish": fish_entries})
    write(DATA / "recipes.json", recipes)
    write(
        DATA / "shops.json",
        {
            "shops": economy.SHOPS,
            "rods": economy.RODS,
            "tool_tiers": economy.TOOL_TIERS,
            "smelting": economy.SMELTING,
        },
    )
    write(DATA / "animals.json", economy.ANIMALS)
    write(DATA / "buildings.json", economy.BUILDINGS)
    write(
        DATA / "enemies.json",
        {"enemies": economy.ENEMIES, "spawns": economy.SPAWNS, "weapon": economy.WEAPON},
    )
    write(DATA / "spouses.json", economy.SPOUSES)
    write(DATA / "gather_tables.json", economy.GATHER_TABLES)
    write(DATA / "events.json", economy.EVENTS)
    print(
        "items", len(items), "crops", len(crops), "fish", len(fish_entries), "recipes", len(recipes)
    )
    return items


if __name__ == "__main__":
    build()

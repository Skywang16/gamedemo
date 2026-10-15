"""Writes every generated crop stage, item icon and packet into assets/art/."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from content import specs  # noqa: E402
from content.dishes import all_dishes  # noqa: E402
from .produce import (  # noqa: E402
    dish_icon,
    extra_icon,
    fish_icon,
    fishing_rod,
    forage_icon,
    packet,
    plant,
    produce_icon,
)


def build_produce(output):
    def save(name, im):
        im.save(output / (name + ".png"))

    for spec in specs.CROPS:
        ident = spec[0]
        for stage in ("seeds", "sprout", "young", "mature"):
            save("%s_%s" % (ident, stage), plant(spec, stage))
        save(ident + "_item", produce_icon(spec))
        save(ident + "_packet", packet(spec))
    for spec in specs.FISH:
        save("fish_" + spec[0], fish_icon(spec))
    for spec in specs.FORAGE:
        save("forage_" + spec[0], forage_icon(spec))
    for ident, _name, _price, shape, colours, _text in specs.MINERALS:
        save("mineral_" + ident, extra_icon(shape, colours))
    for ident, _name, _kind, _price, _energy, shape, colours, _text in specs.ANIMAL_GOODS:
        save("goods_" + ident, extra_icon(shape, colours))
    for ident, _name, _kind, _buy, _sell, _energy, shape, colours, _text in specs.MISC:
        save("misc_" + ident, extra_icon(shape, colours))
    for spec in all_dishes():
        save("dish_" + spec[0], dish_icon(spec))
    save("fishing_rod", fishing_rod())

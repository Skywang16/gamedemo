"""Template dishes: every edible ingredient gets two or three recipes.

The hand-written dishes in specs.py keep their own names; these fill out the cookbook so
that nearly everything the player grows, catches or forages can be turned into a meal.
Names, shapes and colours follow the ingredient.
"""

from .specs import CROPS, DISHES, FISH, FORAGE

# (name template, icon shape, value factor, description)
LEAFY = [
    ("蒜香煎{n}", "plate", 1.0, "蒜香煎得刚好，保留脆嫩。"),
    ("{n}浓汤", "bowl", 1.05, "绵密顺滑的一碗浓汤。"),
    ("{n}沙拉", "plate", 0.9, "淋上橄榄油和柠檬汁。"),
]
ROOT = [
    ("炖{n}", "bowl", 1.15, "炖到软烂入味。"),
    ("烤{n}", "bun", 1.1, "外焦里嫩，带着炭火气。"),
    ("{n}泥", "plate", 1.0, "细细压成泥，加了黄油。"),
]
VINE = [
    ("香煎{n}", "plate", 1.0, "下饭的家常煎菜。"),
    ("{n}酱", "jar", 1.2, "熬成酱，抹面包很香。"),
    ("腌{n}", "plate", 0.95, "腌了一夜，酸脆爽口。"),
]
FRUIT = [
    ("{n}汁", "cup", 1.0, "冰凉清甜的果汁。"),
    ("{n}果酱", "jar", 1.25, "熬得浓稠的果酱。"),
    ("{n}派", "cake", 1.35, "酥皮包着满满的果肉。"),
]
GRAIN = [
    ("{n}烤饼", "bun", 1.05, "烤得金黄的饼。"),
    ("{n}粥", "bowl", 1.0, "熬得软糯的热粥。"),
]
FISH_DISHES = [
    ("香煎{n}", "plate", 1.15, "煎到两面金黄，挤一点柠檬。"),
    ("{n}浓汤", "bowl", 1.1, "奶味浓郁的鱼汤。"),
    ("烤{n}", "skewer", 1.2, "撒了盐和香草，烤得外酥里嫩。"),
]
SHELL = [
    ("黄油{n}", "plate", 1.2, "黄油和蒜末一起焖熟。"),
    ("{n}炖锅", "bowl", 1.15, "炖出一锅鲜汁。"),
]
MUSHROOM = [
    ("煎{n}", "plate", 1.1, "山野的鲜味。"),
    ("{n}浓汤", "bowl", 1.15, "香气扑鼻的浓汤。"),
]
FORAGE_DISHES = [
    ("{n}浓汤", "bowl", 1.1, "熬得温润的浓汤。"),
    ("{n}沙拉", "plate", 0.95, "拌上一点橄榄油。"),
]

SLUGS = {
    "蒜香煎{n}": "garlic_saute",
    "{n}浓汤": "soup",
    "{n}沙拉": "salad",
    "炖{n}": "stew",
    "烤{n}": "roast",
    "{n}泥": "mash",
    "香煎{n}": "pan_fried",
    "{n}酱": "sauce",
    "腌{n}": "pickle",
    "{n}汁": "juice",
    "{n}果酱": "jam",
    "{n}派": "pie",
    "{n}烤饼": "scone",
    "{n}粥": "porridge",
    "黄油{n}": "buttered",
    "{n}炖锅": "pot",
    "煎{n}": "fry",
}
SHELL_SHAPES = {"flat", "crab", "shrimp"}
FRUITY = {"bunch_fruit", "melon", "squash", "berry", "sphere"}
NOT_COOKED_FISH = {"starfish", "frog", "snail", "kelp", "seaweed"}
NOT_COOKED_FORAGE = {
    "feather",
    "lamp_note",
    "old_coin",
    "firefly",
    "pearl",
    "seashell",
    "conch",
    "coral",
    "driftwood",
    "sandrose",
    "candy_apple",
    "acorn",
    "honey",
    "snowdrop",
    "holly_berry",
    "primrose",
    "elderflower",
}


def crop_templates(crop):
    family, shape = crop[8], crop[11]
    if family == "leafy":
        return LEAFY
    if family == "root":
        return ROOT
    if family == "tall":
        return GRAIN if shape in ("grain", "ear") else VINE
    if family == "bush" or shape in FRUITY:
        return FRUIT
    return VINE


def cooking_level(price):
    for limit, level in ((30, 0), (60, 1), (100, 2), (160, 3), (260, 4)):
        if price < limit:
            return level
    return 5


def make(ingredient, name, sell, energy, colours, templates, taken):
    amount = 1 if sell >= 36 else 2
    out = []
    for template, shape, factor, text in templates:
        dish_id = "%s_%s" % (SLUGS[template], ingredient)
        if dish_id in taken:
            continue
        price = max(10, int(sell * amount * 2.1 * factor))
        gain = min(120, int(20 + energy * amount * 2.6 * factor + sell * 0.15))
        out.append(
            (
                dish_id,
                template.format(n=name),
                {ingredient: amount},
                gain,
                price,
                cooking_level(price),
                shape,
                colours,
                text,
            )
        )
    return out


def all_dishes():
    dishes = list(DISHES)
    taken = {d[0] for d in dishes}

    def add(rows):
        for row in rows:
            dishes.append(row)
            taken.add(row[0])

    for c in CROPS:
        add(make(c[0], c[1], c[6], c[7], (c[10], c[9]), crop_templates(c), taken))
    for f in FISH:
        if f[0] in NOT_COOKED_FISH:
            continue
        templates = SHELL if f[10] in SHELL_SHAPES else FISH_DISHES
        add(make(f[0], f[1], f[8], f[9], (f[11][1], f[11][0]), templates, taken))
    for fo in FORAGE:
        if fo[0] in NOT_COOKED_FORAGE:
            continue
        templates = MUSHROOM if fo[5] == "mushroom" else FORAGE_DISHES
        add(make(fo[0], fo[1], fo[3], fo[4], (fo[6][1], fo[6][0]), templates, taken))
    return dishes

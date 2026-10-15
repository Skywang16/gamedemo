"""Authoring command: rebuild deterministic outdoor layouts in data/maps/."""

from pathlib import Path
import json
import random
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
MAPS = DATA / "maps"
MAPS.mkdir(exist_ok=True)


def save(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def pos(x, y):
    return [x * 32 + 16, y * 32 + 16]


def prop(texture, x, y, offset=(-128, -216)):
    return {"texture": texture, "ground": pos(x, y), "offset": list(offset)}


def point(id, name, kind, x, y, **extra):
    return dict(id=id, name=name, kind=kind, cell=[x, y], **extra)


def inside(x, y, r):
    return r[0] <= x < r[0] + r[2] and r[1] <= y < r[1] + r[3]


def area(id, name, w, h, spawn, paths, water, obstacles, props, stations):
    mask = Image.new("1", (w, h))
    d = ImageDraw.Draw(mask)
    for poly in water:
        d.polygon(poly, fill=1)
    water_rects = []
    for y in range(h):
        x = 0
        while x < w:
            if not mask.getpixel((x, y)):
                x += 1
                continue
            start = x
            while x < w and mask.getpixel((x, y)):
                x += 1
            water_rects.append([start, y, x - start, 1])
    return dict(
        id=id,
        name=name,
        width=w,
        height=h,
        tile_size=32,
        spawn=pos(*spawn),
        background=id + "_background",
        paths=paths,
        water=water,
        obstacles=obstacles + water_rects,
        props=props,
        stations=stations,
        trees=[],
        gather=[],
        debris=[],
        no_plant=paths,
    )


def available(m, x, y, margin=1):
    if any(inside(x, y, r) for r in m["obstacles"] + m["paths"]):
        return False
    if any(
        abs(x - s["cell"][0]) <= margin and abs(y - s["cell"][1]) <= margin for s in m["stations"]
    ):
        return False
    return True


def scatter_trees(m, count, seed, zones=None):
    rng = random.Random(seed)
    used = set()
    for _ in range(count * 10):
        if len(used) >= count:
            break
        if zones:
            x0, y0, x1, y1 = rng.choice(zones)
            x = rng.randrange(x0, x1)
            y = rng.randrange(y0, y1)
        else:
            x = rng.randrange(2, m["width"] - 2)
            y = rng.randrange(3, m["height"] - 2)
        if not available(m, x, y, 3) or any(abs(x - a) < 2 and abs(y - b) < 2 for a, b in used):
            continue
        used.add((x, y))
    m["trees"] = [list(p) for p in sorted(used)]


farm = area(
    "home_farm",
    "芽田农场",
    96,
    72,
    (40, 16),
    [[38, 15, 17, 4], [39, 18, 3, 45], [39, 61, 11, 3], [47, 61, 3, 9]],
    [
        [(8, 31), (10, 27), (17, 25), (23, 28), (25, 35), (21, 41), (12, 42), (7, 37)],
        [(80, 46), (86, 43), (92, 47), (93, 58), (87, 62), (81, 58)],
    ],
    [[37, 12, 7, 3], [51, 14, 4, 3], [45, 16, 2, 1]],
    [
        prop("house", 40, 15),
        prop("shop", 53, 17, (-64, -96)),
        prop("shipping", 46, 17, (-32, -48)),
        prop("well", 34, 15, (-32, -64)),
    ],
    [
        point(
            "bed",
            "进入农舍",
            "exit",
            40,
            15,
            destination="cottage",
            arrival=pos(14, 14),
        ),
        point("shop", "阿禾的种子摊", "shop", 53, 18),
        point("shipping", "出售农产品", "shipping", 46, 18),
        point(
            "to_town",
            "南行 · 青苇镇",
            "exit",
            48,
            69,
            destination="town",
            arrival=pos(3, 30),
        ),
    ],
)
farm.update(
    plantable=[4, 18, 88, 49],
    starting_gold=40,
    starting_inventory={"turnip_seed": 8, "carrot_seed": 4},
    tutorial_plot=[34, 20],
)
scatter_trees(farm, 210, 71, [(3, 4, 28, 24), (62, 5, 92, 38), (4, 45, 31, 67), (57, 42, 78, 66)])
# The farm starts wild: no tilled soil and no planted crops.
rng = random.Random(177)
for y in range(18, 66):
    for x in range(5, 91):
        if not available(farm, x, y, 2) or [x, y] in farm["trees"]:
            continue
        density = 0.72 if (26 <= x <= 38 and 19 <= y <= 35) else 0.25
        if rng.random() < density:
            kind = rng.choices(["weeds", "branch", "rock"], [0.73, 0.17, 0.10])[0]
            farm["debris"].append(
                dict(id=f"d_{x}_{y}", kind=kind, cell=[x, y], variant=rng.randrange(3))
            )
for x in range(34, 39):
    farm["debris"] = [n for n in farm["debris"] if n["cell"] != [x, 20]]
    farm["debris"].append(dict(id=f"d_{x}_20", kind="weeds", cell=[x, 20], variant=x % 3))
# Keep explicit examples of each tool near the starting clearing.
for x, y, kind in [(35, 22, "branch"), (37, 23, "rock")]:
    farm["debris"] = [n for n in farm["debris"] if n["cell"] != [x, y]]
    farm["debris"].append(dict(id=f"d_{x}_{y}", kind=kind, cell=[x, y], variant=0))
town = area(
    "town",
    "青苇镇",
    80,
    56,
    (3, 30),
    [[1, 28, 74, 5], [38, 2, 5, 49], [22, 20, 5, 11], [52, 20, 5, 11], [22, 40, 37, 4]],
    [[(75, 1), (78, 1), (78, 27), (75, 27)], [(75, 33), (78, 33), (78, 54), (75, 54)]],
    [[21, 18, 7, 3], [51, 18, 7, 3], [38, 33, 3, 2]],
    [
        prop("inn", 24, 21),
        prop("workshop", 54, 21),
        prop("fountain", 40, 34, (-48, -64)),
        prop("bench", 30, 37, (-48, -32)),
        prop("bench", 49, 37, (-48, -32)),
    ],
    [
        point(
            "farm",
            "西行 · 芽田农场",
            "exit",
            2,
            30,
            destination="home_farm",
            arrival=pos(48, 68),
        ),
        point(
            "forest",
            "北行 · 松风林地",
            "exit",
            40,
            2,
            destination="forest",
            arrival=pos(38, 59),
        ),
        point("bridge", "旧木桥 · 萤汀湖畔", "bridge", 74, 30),
        point("board", "青苇镇路牌", "board", 35, 30),
        point(
            "inn",
            "进入米朵的小馆",
            "exit",
            24,
            21,
            destination="inn",
            arrival=pos(14, 14),
        ),
        point(
            "workshop",
            "进入沈砚工坊",
            "exit",
            54,
            21,
            destination="workshop",
            arrival=pos(14, 14),
        ),
    ],
)
town["bridge_rect"] = [75, 28, 4, 5]
scatter_trees(town, 90, 99, [(3, 3, 19, 25), (60, 3, 72, 25), (3, 37, 20, 51), (60, 38, 72, 51)])
forest = area(
    "forest",
    "松风林地",
    80,
    64,
    (38, 59),
    [[37, 9, 4, 52], [18, 20, 44, 3], [18, 39, 46, 3], [56, 21, 3, 21]],
    [[(4, 26), (9, 22), (15, 24), (18, 32), (15, 39), (8, 42), (3, 36)]],
    [],
    [prop("stump", 60, 40, (-32, -40)), prop("camp", 46, 30, (-48, -48))],
    [
        point(
            "town",
            "南行 · 青苇镇",
            "exit",
            38,
            61,
            destination="town",
            arrival=pos(40, 3),
        )
    ],
)
scatter_trees(
    forest,
    270,
    15,
    [
        (2, 3, 34, 19),
        (44, 4, 76, 19),
        (20, 26, 34, 37),
        (62, 25, 77, 60),
        (2, 47, 32, 60),
        (44, 47, 61, 60),
    ],
)
for item, coords in [
    ("wood", [(34, 24), (43, 23), (52, 37), (26, 38)]),
    ("stone", [(31, 35), (43, 43), (55, 28)]),
    ("berry", [(34, 45), (45, 33), (49, 20)]),
]:
    for i, (x, y) in enumerate(coords):
        forest["gather"].append(dict(id=item + str(i), item=item, cell=[x, y]))
lake = area(
    "lake",
    "萤汀湖畔",
    88,
    60,
    (4, 29),
    [[2, 27, 38, 4], [35, 27, 4, 21], [15, 45, 51, 4]],
    [
        [
            (17, 4),
            (76, 3),
            (84, 11),
            (85, 37),
            (71, 42),
            (53, 38),
            (47, 30),
            (43, 22),
            (20, 23),
            (13, 15),
        ]
    ],
    [],
    [
        prop("lantern_stand", 37, 29, (-32, -64)),
        prop("bench", 26, 46, (-48, -32)),
        prop("bench", 48, 46, (-48, -32)),
    ],
    [
        point(
            "town",
            "西行 · 青苇镇",
            "exit",
            2,
            29,
            destination="town",
            arrival=pos(73, 30),
        ),
        point("lantern", "河灯台", "lantern", 37, 31),
    ],
)
lake["lantern_area"] = [24 * 32, 7 * 32, 52 * 32, 14 * 32]
scatter_trees(lake, 110, 45, [(3, 3, 11, 23), (4, 35, 13, 55), (15, 51, 78, 58), (63, 46, 83, 52)])
farm["trees"].extend([[32, 14], [47, 12], [49, 22], [30, 18]])
farm["debris"] = [n for n in farm["debris"] if n["cell"] not in farm["trees"]]
for m, points in [
    (farm, [(43, 19), (51, 19)]),
    (town, [(54, 24), (61, 30), (24, 24), (33, 31)]),
    (lake, [(24, 28), (31, 44)]),
]:
    m["debris"] = [
        n
        for n in m["debris"]
        if all(abs(n["cell"][0] - x) > 1 or abs(n["cell"][1] - y) > 1 for x, y in points)
    ]
    m["trees"] = [
        p for p in m["trees"] if all(abs(p[0] - x) > 1 or abs(p[1] - y) > 1 for x, y in points)
    ]
forest["trees"] = [
    p
    for p in forest["trees"]
    if all(abs(p[0] - n["cell"][0]) > 1 or abs(p[1] - n["cell"][1]) > 1 for n in forest["gather"])
]
# Existing interiors are small rooms; only outdoor worlds need extensive camera travel.
interiors = {
    id: json.loads((MAPS / (id + ".json")).read_text()) for id in ["cottage", "inn", "workshop"]
}
for id in ["cottage", "inn", "workshop"]:
    m = interiors[id]
    m["debris"] = []
    m["paths"] = []
    m["water"] = []
    for s in m["stations"]:
        if s["kind"] == "exit":
            s["arrival"] = pos(*({"cottage": (40, 16), "inn": (24, 22), "workshop": (54, 22)}[id]))
    save(MAPS / (id + ".json"), m)
for m in [farm, town, forest, lake]:
    save(MAPS / (m["id"] + ".json"), m)
save(
    MAPS / "index.json",
    {"maps": ["home_farm", "town", "forest", "lake", "cottage", "inn", "workshop"]},
)
story = json.loads((DATA / "story.json").read_text())
for id, positions in {
    "ahe": [[43, 19], [51, 19]],
    "shen": [[54, 24], [61, 30]],
    "mido": [[24, 24], [33, 31]],
    "lin": [[24, 28], [31, 44]],
}.items():
    story["npcs"][id]["positions"] = positions
story["scenes"]["welcome"] = [
    [
        "ahe",
        "你就是 {name} 吧？我是阿禾。祖母说你会来。\n\n农场好久没人住了，杂草长得比我的种子还积极。",
    ],
    [
        "ahe",
        "先按 5 用镰刀清草，枯枝用 6 斧头，碎石用 7 镐。清出空地后按 1 翻土，再播种、浇水。",
    ],
    [
        "ahe",
        "试着亲手收获两份萝卜，给镇上的米朵做汤。南边的路通小镇，按住 Shift 可以跑步，迷路就按 M 看地图。",
    ],
]
story["quests"][0]["hint"] = "阿禾就在屋前。按 E 交谈，再从杂草中开出第一块田。"
story["quests"][1]["hint"] = "5 清草、6 伐枝、7 碎石；清地后种萝卜，浇水 3 天。带 2 份收成给米朵。"
story["npcs"]["ahe"]["talk"][1] = "祖母说，荒地不是空白。它只是等你决定，哪里留条路，哪里种点东西。"
save(DATA / "story.json", story)
items = json.loads((DATA / "items.json").read_text())
items["fiber"] = {
    "name": "纤维",
    "kind": "material",
    "buy_price": 0,
    "sell_price": 0,
    "icon": "fiber",
}
save(DATA / "items.json", items)
print(
    "Large worlds:",
    [
        (m["id"], m["width"], m["height"], len(m["trees"]), len(m["debris"]))
        for m in [farm, town, forest, lake]
    ],
)

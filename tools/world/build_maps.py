"""Authoring command: defines every map and writes data/maps/*.json from scratch.

Connectivity (every arrow is a real road with an exit on both ends):
    farm <-> town <-> forest <-> mine 1 <-> mine 2 <-> mine 3
    farm <-> ranch <-> market <-> town
    town <-> lake (over the bridge)
    market <-> seaside
    shop and house interiors hang off their street through one door each.
"""

from pathlib import Path
import json
import random
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from places import PLACES, parse  # noqa: E402
from world.interior_layouts import build_interiors  # noqa: E402
from world.residences import HOMES  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
MAPS = ROOT / "data" / "maps"
SOLID = {
    "lamp",
    "hedge",
    "crates",
    "barrel",
    "signpost",
    "hay",
    "trough",
    "stall",
    "rocks",
    "cart",
    "planter",
    "flowerbed",
}


# (map a, exit cell, arrival cell when coming from b, label, map b, exit cell, arrival cell, label)
LINKS = [
    (
        "home_farm",
        (48, 69),
        (48, 68),
        "南行 · 芦苇渡镇",
        "town",
        (2, 30),
        (3, 30),
        "西行 · 芽田农场",
    ),
    (
        "home_farm",
        (94, 17),
        (93, 17),
        "东行 · 草溪牧场",
        "ranch",
        (1, 8),
        (2, 8),
        "西北 · 芽田农场",
    ),
    ("home_farm", (40, 15), (40, 16), "进入农舍", "cottage", (14, 15), (14, 14), "走出农舍"),
    ("town", (40, 2), (40, 3), "北行 · 松木林", "forest", (38, 61), (38, 60), "南行 · 芦苇渡镇"),
    ("town", (40, 53), (40, 52), "南行 · 集市街", "market", (47, 2), (47, 3), "北行 · 芦苇渡镇"),
    ("town", (24, 21), (24, 22), "进入玛戈的小酒馆", "inn", (14, 15), (14, 14), "回到镇上"),
    ("town", (54, 21), (54, 22), "进入卡弗木工坊", "workshop", (14, 15), (14, 14), "回到镇上"),
    ("forest", (38, 9), (38, 10), "进入旧采石矿", "mine_1", (32, 46), (32, 45), "回到松木林"),
    ("mine_1", (32, 3), (32, 4), "向下 · 第 2 层", "mine_2", (32, 46), (32, 45), "向上 · 第 1 层"),
    ("mine_2", (32, 3), (32, 4), "向下 · 第 3 层", "mine_3", (32, 46), (32, 45), "向上 · 第 2 层"),
    ("market", (94, 31), (93, 31), "东行 · 草溪牧场", "ranch", (1, 25), (2, 25), "西行 · 集市街"),
    ("market", (47, 62), (47, 61), "南行 · 海鸥湾", "seaside", (47, 2), (47, 3), "北行 · 集市街"),
    (
        "market",
        (16, 26),  # shop_store.png door is at x=183, two cells east of its anchor.
        (16, 27),
        "进入霍克杂货店",
        "general_store",
        (14, 15),
        (14, 14),
        "回到集市街",
    ),
    (
        "market",
        (28, 26),
        (28, 27),
        "进入布兰尼根铁匠铺",
        "blacksmith",
        (14, 15),
        (14, 14),
        "回到集市街",
    ),
    ("market", (66, 26), (66, 27), "进入芦苇渡诊所", "clinic", (14, 15), (14, 14), "回到集市街"),
    ("market", (80, 26), (80, 27), "进入铜壶茶室", "tea_house", (14, 15), (14, 14), "回到集市街"),
    (
        "seaside",
        (20, 11),
        (20, 12),
        "进入托比渔具店",
        "tackle_shop",
        (14, 15),
        (14, 14),
        "回到海鸥湾",
    ),
]
# The lake is entered over the town's bridge; only the way back is a normal exit.
BRIDGE_CELL = (74, 30)
LAKE_EXIT = ((2, 29), (73, 30))
# The ferry boards at the lake shore (cell, arrival cell when coming back from the far shore).
FERRY = ((49, 35), (48, 35))

# Cells that must stay open on each map: exits, the cells people arrive on, and the bridge.
RESERVED = {}
for _a, _ac, _ai, _an, _b, _bc, _bi, _bn in LINKS:
    RESERVED.setdefault(_a, []).extend([_ac, _ai])
    RESERVED.setdefault(_b, []).extend([_bc, _bi])
RESERVED["town"].extend([BRIDGE_CELL, LAKE_EXIT[1], (35, 30)])
RESERVED["lake"] = [LAKE_EXIT[0], (4, 29), FERRY[0], FERRY[1]]
RESERVED["far_shore"] = [(4, 44), (5, 44), (6, 44), (29, 16)]
RESERVED["home_farm"].extend([(53, 18), (46, 18)])
for _name, _outside, _door, _residents in HOMES.values():
    RESERVED.setdefault(_outside, []).extend([_door, (_door[0], _door[1] + 1)])
for _key, _entry in PLACES.items():
    _map_id, _name = _key.split("/")
    RESERVED.setdefault(_map_id, []).append(parse(_entry)[:2])


def pos(x, y):
    return [x * 32 + 16, y * 32 + 16]


def prop(texture, x, y, offset):
    return {"texture": texture, "ground": pos(x, y), "offset": list(offset)}


def point(id, name, kind, x, y, **extra):
    return dict(id=id, name=name, kind=kind, cell=[x, y], **extra)


def inside(x, y, r):
    return r[0] <= x < r[0] + r[2] and r[1] <= y < r[1] + r[3]


def area(
    id,
    name,
    w,
    h,
    spawn,
    paths,
    water,
    obstacles,
    props,
    stations,
    biome="meadow",
    path_style="dirt",
):
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
        biome=biome,
        path_style=path_style,
        paths=paths,
        water=water,
        water_rects=water_rects,
        obstacles=obstacles + water_rects,
        props=props,
        stations=stations,
        trees=[],
        gather=[],
        debris=[],
        no_plant=paths,
        decor=[],
        fences=[],
    )


def on_path(m, x, y):
    return any(inside(x, y, r) for r in m["paths"])


def blocked_cell(m, x, y):
    if x <= 1 or y <= 1 or x >= m["width"] - 2 or y >= m["height"] - 2:
        return True
    if any(inside(x, y, r) for r in m["obstacles"]):
        return True
    return [x, y] in m["trees"]


def near_station(m, x, y, margin):
    cells = [tuple(s["cell"]) for s in m["stations"]] + RESERVED.get(m["id"], [])
    return any(abs(x - cx) <= margin and abs(y - cy) <= margin for cx, cy in cells)


def clear_rect(m, x, y, w, h):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if blocked_cell(m, xx, yy) or on_path(m, xx, yy) or near_station(m, xx, yy, 1):
                return False
    return True


def decor(m, kind, x, y, w=1, h=1, force=False):
    """Places a piece of street furniture; solid pieces also get a collision rectangle."""
    if not force and not clear_rect(m, x, y, w, h):
        return False
    m["decor"].append({"kind": kind, "cell": [x, y], "w": w, "h": h})
    if kind in SOLID:
        m["obstacles"].append([x, y, w, h])
    return True


def fence(m, x0, y0, x1, y1, gaps=()):
    """A fence along one row or column; cells in `gaps` (gates) and on roads stay open."""
    horizontal = y0 == y1
    cells = (
        [(x, y0) for x in range(x0, x1 + 1)] if horizontal else [(x0, y) for y in range(y0, y1 + 1)]
    )
    run = []
    for c in cells + [None]:
        if c is None or c in gaps or blocked_cell(m, *c) or on_path(m, *c):
            if run:
                a, b = run[0], run[-1]
                m["fences"].append([a[0], a[1], b[0], b[1]])
                m["obstacles"] += [[cx, cy, 1, 1] for cx, cy in run]
                run = []
        else:
            run.append(c)


def fence_rect(m, x0, y0, x1, y1, gaps=()):
    fence(m, x0, y0, x1, y0, gaps)
    fence(m, x0, y1, x1, y1, gaps)
    fence(m, x0, y0 + 1, x0, y1 - 1, gaps)
    fence(m, x1, y0 + 1, x1, y1 - 1, gaps)


def scatter_trees(m, count, seed, zones):
    rng = random.Random(seed)
    used = set()
    for _ in range(count * 14):
        if len(used) >= count:
            break
        x0, y0, x1, y1 = rng.choice(zones)
        x, y = rng.randrange(x0, x1), rng.randrange(y0, y1)
        if blocked_cell(m, x, y) or on_path(m, x, y) or near_station(m, x, y, 3):
            continue
        if any(abs(x - a) < 2 and abs(y - b) < 2 for a, b in used):
            continue
        if any(
            inside(x, y, [d["cell"][0] - 1, d["cell"][1] - 1, d["w"] + 2, d["h"] + 2])
            for d in m["decor"]
        ):
            continue
        used.add((x, y))
    m["trees"] = sorted(m["trees"] + [list(p) for p in used])


def scatter_nodes(m, count, seed, table, prefix, zones):
    """Gather nodes whose item is rolled from data/gather_tables.json each day."""
    rng = random.Random(seed)
    placed = []
    for _ in range(count * 60):
        if len(placed) >= count:
            break
        x0, y0, x1, y1 = rng.choice(zones)
        x, y = rng.randrange(x0, x1), rng.randrange(y0, y1)
        if blocked_cell(m, x, y) or on_path(m, x, y) or near_station(m, x, y, 2):
            continue
        if any(abs(x - a) < 3 and abs(y - b) < 3 for a, b in placed):
            continue
        placed.append((x, y))
    for i, (x, y) in enumerate(placed):
        m["gather"].append({"id": "%s%d" % (prefix, i), "table": table, "cell": [x, y]})


def building(m, texture, door, size=(7, 3)):
    """A building whose door cell is on its ground row; returns nothing, the caller links the door."""
    dx, dy = door
    m["obstacles"].append([dx - size[0] // 2, dy - size[1], size[0], size[1]])
    m["props"].append(prop(texture, dx, dy, (-128, -216)))
    m["paths"].append([dx - 1, dy, 3, 1])


def home_yard(m, texture, dx, dy):
    """A residence with a fenced yard and a clear path to its linked front door."""
    building(m, texture, (dx, dy))
    fence_rect(
        m,
        dx - 5,
        dy + 1,
        dx + 5,
        dy + 5,
        gaps=[(dx + offset, row) for row in (dy + 1, dy + 5) for offset in (-1, 0, 1)],
    )
    decor(m, "flowerbed", dx - 4, dy + 2, 3, 1)
    decor(m, "flowerbed", dx + 2, dy + 2, 3, 1)
    decor(m, "planter", dx + 4, dy)
    decor(m, "planter", dx - 4, dy)


def link(maps, a, a_cell, a_in, a_name, b, b_cell, b_in, b_name):
    """Exit stations on both ends; each arrives on the cell just inside the other map."""
    maps[a]["stations"].append(
        point("to_" + b, a_name, "exit", a_cell[0], a_cell[1], destination=b, arrival=pos(*b_in))
    )
    maps[b]["stations"].append(
        point("to_" + a, b_name, "exit", b_cell[0], b_cell[1], destination=a, arrival=pos(*a_in))
    )


# ---------------------------------------------------------------------------- outdoor maps


def build_farm():
    farm = area(
        "home_farm",
        "芽田农场",
        96,
        72,
        (40, 16),
        [
            [38, 15, 3, 1],
            [38, 16, 17, 3],
            [40, 19, 2, 44],
            [40, 61, 10, 2],
            [48, 61, 2, 9],
            [55, 17, 40, 2],
        ],
        [
            [(8, 31), (10, 27), (17, 25), (23, 28), (25, 35), (21, 41), (12, 42), (7, 37)],
            [(80, 46), (86, 43), (92, 47), (93, 58), (87, 62), (81, 58)],
        ],
        [
            [37, 12, 7, 3],
            [51, 14, 4, 3],
            [45, 16, 2, 1],
            [60, 22, 5, 2],
            [68, 22, 7, 3],
            [62, 30, 7, 4],
        ],
        [
            prop("house", 40, 15, (-128, -216)),
            prop("shop", 53, 17, (-64, -96)),
            prop("shipping", 46, 17, (-32, -48)),
            prop("well", 34, 15, (-32, -64)),
        ],
        [
            point("shop", "黑兹尔的种子摊", "shop", 53, 18, shop_id="seeds"),
            point("shipping", "出售农产品", "shipping", 46, 18),
        ],
    )
    building(farm, "home_07", (30, 17))
    farm["paths"].append([29, 17, 10, 2])
    farm.update(
        plantable=[4, 18, 88, 49],
        starting_gold=40,
        starting_inventory={"turnip_seed": 8, "carrot_seed": 4},
        tutorial_plot=[34, 20],
        building_sites={
            "coop": {
                "rect": [60, 22, 5, 2],
                "door": [62, 24],
                "texture": "coop",
                "offset": [-80, -120],
            },
            "barn": {
                "rect": [68, 22, 7, 3],
                "door": [71, 25],
                "texture": "barn",
                "offset": [-128, -216],
            },
            "greenhouse": {
                "rect": [62, 30, 7, 4],
                "door": [65, 34],
                "texture": "greenhouse",
                "offset": [-128, -176],
            },
        },
    )
    decor(farm, "flowerbed", 36, 17, 2, 1)
    decor(farm, "planter", 38, 19)
    decor(farm, "planter", 42, 19)
    for y in range(24, 64, 8):
        decor(farm, "lamp", 37, y)
    decor(farm, "signpost", 41, 66)
    decor(farm, "barrel", 56, 19)
    decor(farm, "crates", 57, 19, 2, 1)
    for x in range(62, 94, 8):
        decor(farm, "lamp", x, 15)
    fence(farm, 55, 20, 94, 20, gaps=[(56, 20)])
    scatter_trees(
        farm, 210, 71, [(3, 4, 28, 24), (62, 5, 92, 14), (4, 45, 31, 67), (57, 42, 78, 66)]
    )
    farm["trees"] += [[47, 12], [49, 22]]
    rng = random.Random(177)
    for y in range(18, 66):
        for x in range(5, 91):
            if blocked_cell(farm, x, y) or on_path(farm, x, y) or near_station(farm, x, y, 2):
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
    for x, y, kind in [(35, 22, "branch"), (37, 23, "rock")]:
        farm["debris"] = [n for n in farm["debris"] if n["cell"] != [x, y]]
        farm["debris"].append(dict(id=f"d_{x}_{y}", kind=kind, cell=[x, y], variant=0))
    return farm


def build_town():
    town = area(
        "town",
        "芦苇渡镇",
        80,
        56,
        (3, 30),
        [
            [1, 29, 74, 3],
            [39, 2, 3, 49],
            [24, 21, 2, 9],
            [54, 21, 2, 9],
            [22, 41, 37, 3],
            [39, 50, 3, 5],
        ],
        [[(75, 1), (78, 1), (78, 27), (75, 27)], [(75, 33), (78, 33), (78, 54), (75, 54)]],
        [[21, 18, 7, 3], [51, 18, 7, 3], [38, 33, 3, 2]],
        [
            prop("inn", 24, 21, (-128, -216)),
            prop("workshop", 54, 21, (-128, -216)),
            prop("fountain", 40, 34, (-48, -64)),
            prop("bench", 30, 37, (-48, -32)),
            prop("bench", 49, 37, (-48, -32)),
        ],
        [
            point("bridge", "旧木桥 · 萤火湖畔", "bridge", 74, 30),
            point("board", "告示栏", "board", 35, 30),
        ],
        path_style="cobble",
    )
    town["bridge_rect"] = [75, 28, 4, 5]
    building(town, "home_12", (12, 23))
    town["paths"].append([12, 23, 2, 7])
    building(town, "home_13", (30, 14))
    town["paths"].append([30, 14, 2, 16])
    for x in range(6, 74, 8):
        decor(town, "lamp", x, 27)
        # Keep the festival crowd area south of the fountain free of street furniture.
        if not 36 <= x + 4 <= 44:
            decor(town, "lamp", x + 4, 33)
    for fx, fy in [(35, 36), (43, 36)]:
        decor(town, "flowerbed", fx, fy, 2, 1)
    decor(town, "signpost", 37, 29)
    decor(town, "crates", 55, 23, 2, 1)
    decor(town, "barrel", 59, 23)
    decor(town, "planter", 23, 22)
    decor(town, "planter", 26, 22)
    decor(town, "hedge", 4, 26, 7, 1)
    decor(town, "hedge", 14, 26, 6, 1)
    decor(town, "hedge", 60, 26, 14, 1)
    fence_rect(town, 6, 45, 20, 52, gaps=[(13, 45)])
    fence_rect(town, 60, 45, 74, 52, gaps=[(67, 45)])
    decor(town, "hay", 10, 48)
    decor(town, "hay", 16, 48)
    decor(town, "flowerbed", 63, 48, 4, 2)
    scatter_trees(
        town, 90, 99, [(3, 3, 19, 25), (60, 3, 72, 25), (3, 36, 21, 54), (59, 36, 74, 54)]
    )
    return town


def build_forest():
    forest = area(
        "forest",
        "松木林",
        80,
        64,
        (38, 59),
        [[38, 3, 2, 58], [18, 21, 44, 2], [18, 40, 46, 2], [57, 21, 2, 21]],
        [[(4, 26), (9, 22), (15, 24), (18, 32), (15, 39), (8, 42), (3, 36)]],
        [[35, 6, 7, 3]],
        [
            prop("stump", 60, 40, (-32, -40)),
            prop("camp", 46, 30, (-48, -48)),
            prop("mine_gate", 38, 9, (-96, -152)),
        ],
        [],
    )
    building(forest, "home_08", (46, 50))
    forest["paths"].append([40, 50, 7, 1])
    for item, coords in [
        ("wood", [(34, 24), (43, 23), (52, 37), (26, 38)]),
        ("stone", [(31, 35), (43, 43), (55, 28)]),
    ]:
        for i, (x, y) in enumerate(coords):
            forest["gather"].append(dict(id=item + str(i), item=item, cell=[x, y]))
    for i, (x, y) in enumerate([(34, 45), (45, 33), (49, 20)]):
        forest["gather"].append(
            dict(
                id="berry%d" % i,
                item="berry",
                cell=[x, y],
            )
        )
    for y in range(12, 58, 10):
        decor(forest, "lamp", 36, y)
        decor(forest, "lamp", 41, y + 5)
    decor(forest, "rocks", 30, 30, 2, 1)
    decor(forest, "rocks", 50, 44, 2, 1)
    decor(forest, "hay", 44, 31)
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
    scatter_nodes(forest, 16, 4242, "forest", "forage", [(8, 12, 72, 58)])
    return forest


def build_lake():
    lake = area(
        "lake",
        "萤火湖畔",
        88,
        60,
        (4, 29),
        [[2, 28, 37, 2], [36, 28, 2, 20], [15, 46, 51, 2]],
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
        [point("lantern", "灯台", "lantern", 37, 31)],
    )
    lake["lantern_area"] = [24 * 32, 7 * 32, 52 * 32, 14 * 32]
    building(lake, "home_09", (10, 36))
    lake["paths"].append([10, 30, 2, 6])
    for x in range(8, 70, 9):
        decor(lake, "lamp", x, 44)
    decor(lake, "signpost", 5, 27)
    decor(lake, "flowerbed", 32, 33, 2, 1)
    decor(lake, "flowerbed", 40, 33, 2, 1)
    scatter_trees(
        lake, 110, 45, [(3, 3, 11, 23), (4, 35, 13, 55), (15, 51, 78, 58), (63, 46, 83, 52)]
    )
    scatter_nodes(lake, 10, 5151, "lake", "shore", [(4, 24, 40, 56), (46, 40, 84, 56)])
    return lake


def build_market():
    market = area(
        "market",
        "集市街",
        96,
        64,
        (47, 5),
        [
            [1, 30, 94, 3],
            [46, 1, 3, 62],
            [41, 26, 14, 12],
            [6, 20, 86, 2],
            [21, 20, 2, 10],
            [39, 20, 2, 10],
            [90, 20, 2, 10],
        ],
        [],
        [],
        [],
        [],
        path_style="cobble",
    )
    for texture, dx in [
        ("shop_store", 14),
        ("shop_smith", 28),
        ("shop_clinic", 66),
        ("shop_tea", 80),
    ]:
        building(market, texture, (dx, 26))
        market["paths"].append([16 if texture == "shop_store" else dx, 26, 2, 4])
    for dx, texture in [
        (10, "home_01"),
        (24, "home_02"),
        (36, "home_03"),
        (60, "home_04"),
        (72, "home_05"),
        (84, "home_06"),
    ]:
        home_yard(market, texture, dx, 17)
    for fx, fy in [(42, 27), (52, 27), (42, 35), (52, 35)]:
        decor(market, "flowerbed", fx, fy, 2, 2, force=True)
    decor(market, "signpost", 44, 29, force=True)
    market["props"] += [
        prop("fountain", 48, 33, (-48, -64)),
        prop("bench", 40, 39, (-48, -32)),
        prop("bench", 56, 39, (-48, -32)),
    ]
    market["obstacles"].append([46, 32, 3, 2])
    for x in range(6, 92, 6):
        if not 40 <= x <= 56:
            decor(market, "lamp", x, 29)
            decor(market, "lamp", x + 3, 34)
    for x in (8, 16, 24, 32, 62, 70, 78, 86):
        decor(market, "stall", x, 37, 3, 2)
        decor(market, "crates", x + 3, 38)
        decor(market, "barrel", x - 1, 38)
    for x in (12, 30, 66, 82):
        decor(market, "hedge", x, 41, 4, 1)
    fence(market, 4, 44, 40, 44, gaps=[(20, 44)])
    fence(market, 56, 44, 92, 44, gaps=[(72, 44)])
    for x in (12, 20, 28, 66, 74, 82):
        decor(market, "flowerbed", x, 46, 3, 1)
    scatter_trees(
        market, 60, 811, [(2, 3, 40, 14), (56, 3, 94, 14), (2, 46, 44, 61), (52, 46, 94, 61)]
    )
    return market


def build_ranch():
    ranch = area(
        "ranch",
        "草溪牧场",
        80,
        56,
        (4, 25),
        [
            [1, 24, 46, 3],
            [1, 7, 24, 3],
            [22, 7, 3, 20],
            [36, 15, 3, 10],
            [46, 24, 30, 3],
            [70, 4, 3, 22],
            [45, 22, 4, 2],
            [45, 28, 4, 2],
        ],
        [[(8, 36), (14, 34), (24, 35), (28, 40), (22, 46), (12, 47), (6, 42)]],
        [[35, 12, 7, 3], [11, 14, 7, 3]],
        [prop("barn", 38, 15, (-128, -216)), prop("home_11", 14, 17, (-128, -216))],
        [point("ranch_shop", "罗西的牧场", "shop", 38, 16, shop_id="ranch")],
    )
    fence_rect(ranch, 44, 6, 68, 21, gaps=[(46, 21), (47, 21)])
    fence_rect(ranch, 44, 30, 68, 45, gaps=[(46, 30), (47, 30)])
    for x, y in [(50, 10), (58, 12), (62, 18), (52, 34), (60, 36), (64, 42)]:
        decor(ranch, "hay", x, y)
    for x, y in [(47, 8), (47, 33), (65, 8)]:
        decor(ranch, "trough", x, y, 2, 1)
    decor(ranch, "cart", 32, 22, 2, 1)
    decor(ranch, "barrel", 42, 18)
    decor(ranch, "crates", 43, 18, 2, 1)
    decor(ranch, "signpost", 3, 22)
    decor(ranch, "planter", 13, 21)
    decor(ranch, "planter", 17, 21)
    decor(ranch, "flowerbed", 11, 22, 2, 1)
    decor(ranch, "flowerbed", 16, 22, 2, 1)
    for x in range(6, 70, 8):
        decor(ranch, "lamp", x, 23)
    scatter_trees(
        ranch,
        80,
        903,
        [(2, 2, 26, 6), (2, 12, 10, 24), (26, 30, 42, 52), (70, 6, 78, 52), (12, 48, 70, 54)],
    )
    return ranch


def build_seaside():
    sea_left = [(0, 38), (12, 36), (26, 38), (43, 40), (43, 54), (0, 54)]
    sea_right = [(52, 40), (66, 37), (80, 39), (95, 36), (95, 54), (52, 54)]
    sea_bottom = [(0, 54), (95, 54), (95, 63), (0, 63)]
    seaside = area(
        "seaside",
        "海鸥湾",
        96,
        64,
        (47, 5),
        [[1, 12, 92, 3], [46, 1, 3, 11], [44, 15, 8, 39], [8, 15, 3, 14], [84, 15, 3, 12]],
        [sea_left, sea_right, sea_bottom],
        [[84, 26, 2, 2]],
        [
            prop("lighthouse", 85, 28, (-32, -144)),
            prop("boat", 30, 42, (-64, -48)),
            prop("boat", 70, 44, (-64, -48)),
        ],
        [],
        biome="beach",
        path_style="boardwalk",
    )
    building(seaside, "shop_tackle", (20, 11))
    building(seaside, "home_10", (70, 11))
    for x in range(8, 92, 8):
        if not 44 <= x <= 52:
            decor(seaside, "lamp", x, 11)
    for x, y in [(10, 17), (60, 18), (76, 18)]:
        decor(seaside, "crates", x, y, 2, 1)
        decor(seaside, "barrel", x + 2, y)
    decor(seaside, "signpost", 44, 13)
    decor(seaside, "rocks", 18, 33, 3, 1)
    decor(seaside, "rocks", 60, 34, 3, 1)
    decor(seaside, "rocks", 88, 33, 2, 1)
    fence_rect(seaside, 56, 17, 64, 24, gaps=[(60, 17), (60, 24)])
    decor(seaside, "flowerbed", 58, 19, 5, 2)
    scatter_trees(seaside, 24, 77, [(2, 16, 16, 30), (68, 16, 92, 26)])
    scatter_nodes(seaside, 22, 7001, "beach", "shell", [(3, 22, 92, 36)])
    return seaside


def build_mine(level):
    mid = "mine_%d" % level
    rng = random.Random(900 + level)
    side_paths = [[10, 24, 54, 3]] if level == 3 else [[30, 24, 20, 3]]
    walls = []
    for _ in range(26):
        ww, hh = rng.randrange(3, 8), rng.randrange(2, 5)
        x, y = rng.randrange(3, 62 - ww), rng.randrange(6, 42 - hh)
        if x + ww > 27 and x < 37:
            continue
        if any(
            x < p[0] + p[2] + 1 and p[0] < x + ww + 1 and y < p[1] + p[3] + 1 and p[1] < y + hh + 1
            for p in side_paths
        ):
            continue
        walls.append([x, y, ww, hh])
    pool = (
        [(46, 14), (55, 16), (56, 26), (48, 29), (43, 22)]
        if level != 2
        else [(6, 14), (14, 15), (15, 25), (7, 28), (3, 20)]
    )
    mine = area(
        mid,
        "旧采石矿 · 第 %d 层" % level,
        64,
        48,
        (32, 44),
        [[30, 2, 4, 45]] + side_paths,
        [pool],
        walls,
        [prop("mine_cart", 28, 40, (-32, -40))] if level == 1 else [],
        [],
        biome="cave",
    )
    if level == 1:
        mine["obstacles"].append([28, 40, 2, 1])
    for y in range(8, 44, 8):
        decor(mine, "lamp", 29, y)
        decor(mine, "lamp", 34, y + 4)
    decor(mine, "crates", 36, 42, 2, 1)
    decor(mine, "barrel", 38, 42)
    decor(mine, "rocks", 26, 36, 2, 1)
    scatter_nodes(mine, 24, 6000 + level, mid, "ore", [(3, 5, 61, 44)])
    return mine


def build_far_shore():
    shore = area(
        "far_shore",
        "对岸 · 野渡",
        80,
        56,
        (6, 44),
        [[2, 42, 26, 4], [26, 17, 4, 28], [20, 12, 18, 6], [38, 14, 14, 3]],
        [[(54, 6), (72, 5), (77, 14), (67, 22), (54, 18)]],
        [],
        [prop("lantern_stand", 29, 14, (-32, -64)), prop("boat", 3, 47, (-64, -48))],
        [
            point(
                "shrine",
                "旧灯龛",
                "story",
                29,
                16,
                event="ferryman",
                idle="一座很旧的石灯龛，龛里空着，只有风吹过的声音。",
            )
        ],
    )
    for x in range(4, 26, 6):
        decor(shore, "lamp", x, 41)
    decor(shore, "signpost", 3, 41)
    decor(shore, "flowerbed", 24, 14, 3, 1)
    decor(shore, "flowerbed", 31, 14, 3, 1)
    decor(shore, "rocks", 44, 30, 2, 1)
    decor(shore, "rocks", 60, 36, 3, 1)
    scatter_trees(
        shore, 80, 3131, [(3, 3, 20, 38), (40, 22, 77, 52), (4, 48, 38, 53), (54, 24, 77, 34)]
    )
    scatter_nodes(shore, 12, 8808, "lake", "reed", [(40, 4, 78, 26), (44, 24, 77, 52)])
    scatter_nodes(shore, 8, 8809, "beach", "pebble", [(3, 36, 30, 53)])
    return shore


# ---------------------------------------------------------------------------- assembly


def build_all():
    maps = {
        "home_farm": build_farm(),
        "town": build_town(),
        "forest": build_forest(),
        "lake": build_lake(),
        "market": build_market(),
        "ranch": build_ranch(),
        "seaside": build_seaside(),
        "far_shore": build_far_shore(),
        "mine_1": build_mine(1),
        "mine_2": build_mine(2),
        "mine_3": build_mine(3),
    }
    interiors, _places = build_interiors()
    maps.update(interiors)

    for a, a_cell, a_in, a_name, b, b_cell, b_in, b_name in LINKS:
        if b in interiors:
            b_cell = maps[b]["entry"]
            b_in = (b_cell[0], b_cell[1] - 1)
        link(maps, a, a_cell, a_in, a_name, b, b_cell, b_in, b_name)
    for ident, (name, outside, door, _residents) in HOMES.items():
        if outside in interiors:
            door = maps[outside]["stairs_entry"]
            maps[ident]["entry_style"] = "stairs"
        inside = maps[ident]["entry"]
        link(
            maps,
            outside,
            door,
            (door[0], door[1] + 1),
            "进入" + name,
            ident,
            inside,
            (inside[0], inside[1] - 1),
            "离开" + name,
        )
    for ident, door in [("school", (12, 23)), ("town_hall", (30, 14))]:
        inside = maps[ident]["entry"]
        link(
            maps,
            "town",
            door,
            (door[0], door[1] + 1),
            "进入" + maps[ident]["name"],
            ident,
            inside,
            (inside[0], inside[1] - 1),
            "回到镇上",
        )
    for region in maps.values():
        region.setdefault("environment", "cave" if region.get("biome") == "cave" else "exterior")
    maps["lake"]["stations"].append(
        point(
            "to_town",
            "西行 · 芦苇渡镇",
            "exit",
            LAKE_EXIT[0][0],
            LAKE_EXIT[0][1],
            destination="town",
            arrival=pos(*LAKE_EXIT[1]),
        )
    )
    maps["lake"]["stations"].append(
        point(
            "ferry",
            "摆渡 · 对岸野渡",
            "ferry",
            FERRY[0][0],
            FERRY[0][1],
            destination="far_shore",
            arrival=pos(5, 44),
        )
    )
    maps["far_shore"]["stations"].append(
        point(
            "to_lake",
            "摆渡 · 萤火湖畔",
            "exit",
            4,
            44,
            destination="lake",
            arrival=pos(*FERRY[1]),
        )
    )
    maps["lake"]["props"].append(prop("boat", 50, 36, (-64, -48)))
    return maps


def keep_places_clear(maps):
    """Villagers stand on open ground: remove trees, debris and nodes around every place."""
    for key, entry in PLACES.items():
        map_id, _name = key.split("/")
        x, y, _hidden = parse(entry)
        m = maps[map_id]
        m["trees"] = [t for t in m["trees"] if abs(t[0] - x) > 1 or abs(t[1] - y) > 1]
        m["debris"] = [
            n for n in m["debris"] if abs(n["cell"][0] - x) > 1 or abs(n["cell"][1] - y) > 1
        ]
        m["gather"] = [
            g for g in m["gather"] if abs(g["cell"][0] - x) > 1 or abs(g["cell"][1] - y) > 1
        ]


def verify(maps):
    problems = []
    for key, entry in PLACES.items():
        map_id, _name = key.split("/")
        x, y, _hidden = parse(entry)
        if map_id not in maps:
            problems.append("%s: unknown map" % key)
        elif blocked_cell(maps[map_id], x, y):
            problems.append("place %s (%d, %d) is on a blocked cell" % (key, x, y))
    plaza = json.loads((ROOT / "data/calendar.json").read_text())["plaza"]
    for x, y in plaza["cells"]:
        if blocked_cell(maps[plaza["map"]], x, y):
            problems.append(f"festival stand ({x}, {y}) is blocked")
    for m in maps.values():
        for s in m["stations"]:
            x, y = s["cell"]
            if s["kind"] == "exit" and any(inside(x, y, r) for r in m["obstacles"]):
                problems.append("exit %s in %s is inside an obstacle" % (s["id"], m["id"]))
            if s["kind"] == "exit":
                target = maps[s["destination"]]
                ax, ay = s["arrival"][0] // 32, s["arrival"][1] // 32
                if blocked_cell(target, ax, ay):
                    problems.append(
                        "arrival of %s in %s lands on a blocked cell %s"
                        % (s["id"], m["id"], (ax, ay))
                    )
    if problems:
        raise SystemExit("Map problems:\n  " + "\n  ".join(problems))


def main():
    maps = build_all()
    keep_places_clear(maps)
    verify(maps)
    MAPS.mkdir(exist_ok=True)
    for stale in MAPS.glob("*.json"):
        stale.unlink()
    order = [
        "home_farm",
        "town",
        "forest",
        "lake",
        "cottage",
        "inn",
        "workshop",
        "market",
        "ranch",
        "seaside",
        "far_shore",
        "mine_1",
        "mine_2",
        "mine_3",
        "general_store",
        "blacksmith",
        "clinic",
        "tea_house",
        "tackle_shop",
    ]
    order += [ident for ident in maps if ident not in order]
    for map_id in order:
        (MAPS / (map_id + ".json")).write_text(
            json.dumps(maps[map_id], ensure_ascii=False, indent=2) + "\n", encoding="utf8"
        )
    places = {
        key: [parse(entry)[0], parse(entry)[1], parse(entry)[2]] for key, entry in PLACES.items()
    }
    (ROOT / "data" / "places.json").write_text(
        json.dumps(places, ensure_ascii=False, indent=1) + "\n", encoding="utf8"
    )
    (MAPS / "index.json").write_text(json.dumps({"maps": order}, indent=2) + "\n", encoding="utf8")
    print("maps written:", len(order))


if __name__ == "__main__":
    main()

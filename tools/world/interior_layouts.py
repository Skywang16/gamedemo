"""Compact furnished homes and public interiors, authored against the approved v2 asset kit."""

from content.story_data import NPCS
from world.interior_plan import Interior
from world.residences import HOMES, DETAILS
from world.public_interiors import public_room, PUBLIC


def bedroom(room, npc, x, y, width=7, depth=6):
    room.floor(x, y, width, depth, NPCS[npc]["name"] + "的卧室")
    room.furnishing("bed", x, y + 1)
    room.furnishing("lamp", x + 1, y + 1)
    room.furnishing("wardrobe", x + width - 2, y)
    kind, title, detail = DETAILS[npc]
    room.furnishing(kind, x + 3, y + 3, "detail_" + npc, (title, detail))
    room.place("bed_" + npc, x + 1, y + 3)
    room.map["rugs"].append([x + 1, y + 3, 2, 2])
    room.wall_art("window", x + 2, y - 1)


def living(room, x, y, width, depth):
    room.floor(x, y, width, depth, "餐厨与起居室")
    room.furnishing("kitchen", x + width - 2, y)
    room.furnishing("cabinet", x + width - 5, y)
    room.furnishing("sofa", x, y)
    room.furnishing("tea_table", x, y + 2)
    room.furnishing("table", x + width - 5, y + 3)
    room.furnishing("chair", x + width - 6, y + 3)
    room.furnishing("chair", x + width - 3, y + 3)
    room.furnishing("plant", x, y + depth - 1)
    room.map["rugs"].append([x, y + 1, 3, 2])
    room.place("living", x + 3, y + 3)


def residence(ident, name, residents):
    count = len(residents)
    if count == 1:
        # Bedroom and workroom share a short hall opening into the living room.
        w, h = (18, 21) if ident in ("hazel_home", "theo_home") else (18, 20)
        r = Interior(ident, name, w, h)
        bedroom(r, residents[0], 2, 3)
        r.floor(10, 3, 5, 6, "书房与收藏")
        r.furnishing("bookshelf", 10, 3)
        r.furnishing("desk", 13, 5)
        r.furnishing("stool", 13, 7)
        r.wall_art("painting", 13, 2)
        r.doorway(4, 9, 2, 2)
        r.doorway(11, 9, 2, 2)
        r.floor(2, 11, 13, 2, "过厅")
        living(r, 2, 13, 13, h - 15)
    elif count == 2:
        w, h = 20, 22
        r = Interior(ident, name, w, h)
        bedroom(r, residents[0], 2, 3)
        bedroom(r, residents[1], 10, 3)
        r.doorway(4, 9, 2, 2)
        r.doorway(12, 9, 2, 2)
        r.floor(2, 11, 15, 2, "共享走廊")
        living(r, 2, 13, 15, h - 15)
    else:
        w, h = 22, 27
        r = Interior(ident, name, w, h)
        r.floor(10, 3, 2, 22, "住客走廊" if ident == "inn_lodging" else "家庭走廊")
        for i, npc in enumerate(residents):
            x, y = (2 if i % 2 == 0 else 13), 3 + i // 2 * 8
            bedroom(r, npc, x, y)
            r.doorway(9 if i % 2 == 0 else 12, y + 4, 1, 2)
        if count == 3:
            r.floor(13, 11, 7, 6, "家庭书房")
            r.furnishing("bookshelf", 13, 11)
            r.furnishing("desk", 17, 12)
            r.furnishing("sofa", 14, 15)
            r.doorway(12, 15, 1, 2)
        living(r, 2, 19, 18, 6)
    r.map["residents"] = residents
    r.entry(7 if count == 1 else w // 2, h - 3)
    return r.finish()


def cottage():
    r = Interior("cottage", "农舍", 20, 20)
    r.floor(2, 3, 7, 6, "卧室")
    r.floor(10, 3, 7, 6, "厨房与书房")
    r.doorway(4, 9, 2, 2)
    r.doorway(12, 9, 2, 2)
    r.floor(2, 11, 15, 2, "过厅")
    r.floor(2, 13, 15, 5, "起居室")
    r.furnishing("bed", 2, 4)
    r.furnishing("lamp", 3, 4)
    r.furnishing("wardrobe", 7, 3)
    r.furnishing("desk", 10, 4)
    r.furnishing("kitchen", 15, 4)
    r.furnishing("bookshelf", 15, 7)
    r.furnishing("sofa", 2, 13)
    r.furnishing("tea_table", 2, 15)
    r.furnishing("table", 12, 14)
    r.furnishing("chair", 11, 14)
    r.furnishing("chair", 14, 14)
    r.furnishing("chest", 16, 15)
    r.furnishing("plant", 16, 13)
    r.furnishing("fireplace", 6, 13)
    r.map["rugs"] += [[2, 14, 3, 2], [8, 15, 3, 2]]
    r.wall_art("window", 4, 2)
    r.wall_art("herbs", 15, 2)
    r.wall_art("painting", 12, 2)
    for ident, label, kind, x, y in [
        ("sleep", "床 / 休息", "bed", 3, 6),
        ("letter", "祖母的信", "letter", 11, 5),
        ("kitchen", "厨房 / 烹饪", "kitchen", 16, 5),
        ("chest", "储物箱", "storage", 16, 16),
    ]:
        r.station(ident, label, kind, x, y)
    for name, x, y in [
        ("bed_side", 3, 6),
        ("table", 13, 16),
        ("kitchen_side", 14, 5),
        ("window", 7, 7),
    ]:
        r.place(name, x, y)
    r.entry(10, 17)
    return r.finish()


def build_interiors():
    result = [cottage()] + [public_room(i) for i in PUBLIC]
    result += [residence(i, row[0], row[3]) for i, row in HOMES.items()]
    return {m["id"]: m for m, _ in result}, {k: v for _, p in result for k, v in p.items()}

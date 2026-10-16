"""Public rooms: distinct business areas, furnished back rooms and live service approaches."""

from world.interior_plan import Interior

# name, width, height, shop, front room, back room
PUBLIC = {
    "inn": ("玛戈的小酒馆", 28, 21, None, "酒馆与餐桌", "厨房与住客楼梯"),
    "workshop": ("卡弗木工坊", 26, 20, "builder", "木工营业间", "织造间与楼梯"),
    "general_store": ("霍克杂货店", 24, 18, "general", "柜台与货架", "种子仓房"),
    "blacksmith": ("布兰尼根铁匠铺", 24, 20, "smith", "接待与打铁间", "锻炉与后宅入口"),
    "clinic": ("芦苇渡诊所", 24, 20, "clinic", "挂号与候诊", "诊疗室"),
    "tea_house": ("铜壶茶室", 22, 18, "tea", "品茶间", "茶具与备餐间"),
    "tackle_shop": ("托比渔具店", 20, 17, "tackle", "渔具营业间", "修网间"),
    "school": ("芦苇渡小学", 26, 19, None, "教室", "阅读与手工室"),
    "town_hall": ("芦苇渡议事厅", 26, 21, None, "议事与接待", "档案室"),
}


def dining(r, x, y, tea=False):
    r.furnishing("tea_table" if tea else "table", x, y)
    r.furnishing("chair", x - 1, y)
    r.furnishing("chair", x + 2, y)


def public_room(ident):
    name, w, h, shop, front, back = PUBLIC[ident]
    r = Interior(ident, name, w, h)
    split = w - 10
    bx = split + 1
    material = "stone" if ident in ("clinic", "blacksmith") else "wood"
    r.floor(2, 3, split - 2, h - 5, front, material)
    r.floor(bx, 3, 7, h - 5, back, material)
    r.doorway(split - 1, 9, 3, 2)
    r.furnishing("counter", 4, 6)
    if shop:
        r.station(
            "builder" if shop == "builder" else "counter",
            "建造台" if shop == "builder" else "柜台",
            "shop",
            6,
            7,
            shop_id=shop,
        )
    r.furnishing("bookshelf", 2, 3)
    r.wall_art("window", 6, 2)
    r.wall_art("window", bx + 3, 2)
    r.furnishing("plant", 2, h - 4)
    r.wall_art("coat", bx, 2)
    for place, x, y in [
        ("behind", 5, 5),
        ("behind_r", 7, 5),
        ("behind_l", 4, 5),
        ("front", 6, 8),
        ("shelf", 3, 8),
        ("table", 6, h - 4),
    ]:
        r.place(place, x, y)
    if ident == "inn":
        r.furnishing("bar_shelf", 10, 3)
        r.furnishing("fireplace", 13, 4)
        dining(r, 4, 11)
        dining(r, 11, 11)
        dining(r, 11, 16)
        r.furnishing("stool", 4, 8)
        r.furnishing("stool", 8, 8)
        r.furnishing("kitchen", bx + 4, 4)
        r.furnishing("cabinet", bx, 4)
        r.furnishing("table", bx + 2, 10)
        r.furnishing("bread", bx + 5, 10)
        r.station("kitchen", "灶台 / 烹饪", "kitchen", bx + 5, 5)
        for n, x, y in [
            ("counter", 6, 5),
            ("table_a", 5, 13),
            ("table_b", 12, 13),
            ("window", 3, 15),
        ]:
            r.place(n, x, y)
    elif ident == "workshop":
        r.furnishing(
            "workbench",
            4,
            11,
            "woodwork",
            ("木工作品", "木鸟与修桥用的榫头放在一起，工作台上的墨线还很清晰。"),
        )
        r.furnishing("cabinet", 11, 3)
        r.furnishing("chest", 11, 12)
        r.furnishing("loom", bx + 3, 5)
        r.furnishing("dressrack", bx, 3)
        r.furnishing("wardrobe", bx + 4, 11)
        for n, x, y in [("bench", 7, 12), ("loom", bx + 2, 7), ("table", 8, 15)]:
            r.place(n, x, y)
    elif ident == "blacksmith":
        r.furnishing("anvil", 4, 11)
        r.furnishing("workbench", 8, 12)
        r.furnishing(
            "forge",
            bx + 3,
            4,
            "forge_notes",
            ("锻炉", "炉边的铁件按火候分开，墙上挂着修旧矿车的草图。"),
        )
        r.furnishing("cabinet", bx, 3)
        r.furnishing("chest", bx + 4, 10)
        r.place("forge", bx + 2, 6)
    elif ident == "clinic":
        r.furnishing("sofa", 3, 11)
        r.furnishing("sofa", 8, 11)
        r.furnishing("tea_table", 5, 14)
        r.furnishing("medical", bx + 3, 4)
        r.furnishing("medical", bx + 3, 9)
        r.furnishing("cabinet", bx, 3)
        r.wall_art("herbs", bx + 3, 2)
        r.place("bed", bx + 2, 6)
    elif ident == "tea_house":
        dining(r, 4, 11, True)
        dining(r, 9, 11, True)
        r.furnishing("kitchen", bx + 4, 4)
        r.furnishing("cabinet", bx, 3)
        r.furnishing(
            "tea_table",
            bx + 3,
            10,
            "tea_notes",
            ("冲泡手记", "每一罐茶都贴着采摘月份，最旧的配方记着牧场雨后的草香。"),
        )
        r.place("table_a", 5, 12)
        r.place("table_b", 9, 12)
    elif ident == "general_store":
        r.furnishing("cabinet", 3, 10)
        r.furnishing("seedbench", 8, 11)
        r.furnishing("seedbench", bx + 4, 4)
        r.furnishing("cabinet", bx, 3)
        r.furnishing("chest", bx + 4, 11)
        r.furnishing(
            "bread",
            bx + 1,
            11,
            "delivery",
            ("今日到货", "送货单按住户分好，空篮子留给明早的新鲜面包。"),
        )
    elif ident == "tackle_shop":
        r.furnishing("fishrack", 3, 10)
        r.furnishing("fishrack", bx + 4, 4)
        r.furnishing(
            "workbench",
            bx + 2,
            10,
            "nets",
            ("修网台", "补好的渔网用蓝线系着，破掉的浮标被留下当作教学样本。"),
        )
        r.furnishing("chest", bx, 3)
    elif ident == "school":
        for x, y in [(4, 11), (9, 11), (4, 15), (9, 15)]:
            r.furnishing("desk", x, y)
            r.furnishing("stool", x, y + 1)
        r.furnishing("bookshelf", bx, 3)
        r.furnishing("toys", bx + 4, 5)
        dining(r, bx + 2, 11)
        r.station(
            "schoolwork",
            "孩子们的作业",
            "inspect",
            6,
            11,
            description="河流、鸟和桥画满了纸页。西奥用不同颜色的小星星批注。",
        )
        r.place("teacher", 6, 5)
    elif ident == "town_hall":
        dining(r, 4, 11)
        dining(r, 10, 11)
        r.furnishing("sofa", 3, 16)
        r.furnishing("bookshelf", bx, 3)
        r.furnishing("mapdesk", bx + 4, 5)
        r.furnishing("cabinet", bx + 4, 11)
        r.station(
            "minutes",
            "议事记录",
            "inspect",
            bx + 5,
            6,
            description="会议记录按年份排好。桥、水渠和渡口的改造图分别收在三个档案夹里。",
        )
        r.place("records", bx + 3, 6)
    if ident in ("inn", "workshop", "clinic", "blacksmith"):
        r.map["stairs_entry"] = [bx + 2, h - 4]
    r.map["rugs"].append([split // 2 - 1, h - 5, 2, 2])
    r.entry(split // 2, h - 3)
    return r.finish()

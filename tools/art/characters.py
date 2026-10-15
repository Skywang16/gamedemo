"""Four-direction pixel actors with stepped silhouettes and a consistent light source."""

from PIL import Image, ImageDraw

SKINS = [
    ["#a36c4d", "#d89d70", "#f0c595"],
    ["#80513b", "#b77c53", "#dca16e"],
    ["#563d33", "#86583f", "#b27b53"],
]
HAIRS = [
    ["#322f2a", "#594035", "#866044"],
    ["#523a2d", "#975f36", "#c18c50"],
    ["#626b65", "#9da79a", "#d1d1b7"],
]
SHIRTS = [
    ["#354c59", "#577a89", "#87a6ad"],
    ["#713d39", "#a25c4c", "#d38a6c"],
    ["#3c543b", "#628047", "#93a561"],
    ["#513f61", "#83618f", "#b58cae"],
]


def actor(skin, hair, outfit, hat, row, frame, arms=True, ramps=None):
    im = Image.new("RGBA", (32, 48))
    d = ImageDraw.Draw(im)
    sk, ha, cl = ramps if ramps else (SKINS[skin], HAIRS[hair], SHIRTS[outfit])
    bob = frame % 2
    step = [0, 2, 0, -2][frame]
    d.ellipse((7, 41, 26, 46), fill="#29473465")
    # Legs, hems, toe caps and swinging arms.
    for x, stride in [(11, step), (19, -step)]:
        d.polygon(
            [
                (x, 33),
                (x + 5, 33),
                (x + 4, 41 + stride // 2),
                (x + 5, 44 + stride // 2),
                (x - 2, 44 + stride // 2),
                (x - 2, 41),
                (x, 40),
            ],
            fill="#353f40",
        )
        d.rectangle((x + 1, 35, x + 3, 41 + stride // 2), fill="#62747b")
        d.line((x - 1, 42 + stride // 2, x + 3, 42 + stride // 2), fill="#9b7854")
    d.polygon(
        [
            (11, 25 + bob),
            (22, 25 + bob),
            (25, 29 + bob),
            (23, 37 + bob),
            (9, 37 + bob),
            (7, 29 + bob),
        ],
        fill=cl[0],
    )
    d.polygon(
        [
            (11, 26 + bob),
            (21, 26 + bob),
            (23, 30 + bob),
            (21, 35 + bob),
            (11, 35 + bob),
            (9, 30 + bob),
        ],
        fill=cl[1],
    )
    d.line((11, 27 + bob, 14, 27 + bob), fill=cl[2], width=2)
    if row != 1:
        d.polygon([(13, 26 + bob), (16, 29 + bob), (20, 26 + bob)], fill="#edddb1")
        for x in [12, 20]:
            d.line((x, 27 + bob, x, 35 + bob), fill="#b9aa7c")
            d.point((x, 30 + bob), fill="#e7cf91")
        d.rectangle((15, 31 + bob, 18, 34 + bob), fill=cl[0])
        d.line((15, 31 + bob, 18, 31 + bob), fill=cl[2])
    else:
        d.line((12, 28 + bob, 21, 28 + bob), fill=cl[2])
        d.line((11, 34 + bob, 21, 34 + bob), fill=cl[0])
    for x, dy in [(7, step // 2), (23, -step // 2)] if arms else []:
        d.polygon(
            [
                (x, 28 + bob),
                (x + 3, 28 + bob),
                (x + 4, 32 + bob + dy),
                (x + 3, 37 + bob + dy),
                (x, 37 + bob + dy),
                (x - 1, 33 + bob),
            ],
            fill=cl[0],
        )
        d.rectangle((x, 29 + bob, x + 2, 32 + bob + dy), fill="#d7cba2")
        d.rectangle((x, 34 + bob + dy, x + 2, 36 + bob + dy), fill=sk[1])
        d.point((x, 34 + bob + dy), fill=sk[2])
    # Rounded face with ears, cheek light, nose and brows.
    y = 12 + bob
    d.polygon(
        [
            (12, y),
            (21, y),
            (24, y + 3),
            (24, y + 10),
            (21, y + 14),
            (13, y + 14),
            (9, y + 10),
            (9, y + 4),
        ],
        fill=ha[0],
    )
    if row != 1:
        d.rectangle((10, y + 6, 24, y + 10), fill=sk[0])
        d.polygon(
            [
                (12, y + 3),
                (21, y + 3),
                (23, y + 6),
                (22, y + 11),
                (20, y + 13),
                (14, y + 13),
                (11, y + 10),
                (11, y + 5),
            ],
            fill=sk[1],
        )
        d.polygon(
            [(12, y + 5), (20, y + 4), (21, y + 9), (18, y + 11), (13, y + 10)],
            fill=sk[2],
        )
        for x in [13, 20] if row == 0 else [12 if row == 2 else 21]:
            d.line((x, y + 6, x + 1, y + 6), fill=ha[1])
            d.point((x + 1, y + 8), fill="#293b37")
            d.point((x + 1, y + 7), fill="#3a3b2e")
        d.point((17 if row == 0 else (10 if row == 2 else 23), y + 10), fill=sk[0])
        d.line((16, y + 12, 18, y + 12), fill="#ac7153")
    else:
        d.polygon(
            [
                (11, y + 3),
                (22, y + 2),
                (23, y + 10),
                (20, y + 13),
                (13, y + 12),
                (10, y + 9),
            ],
            fill=ha[1],
        )
        d.line((13, y + 4, 12, y + 9), fill=ha[2])
        d.line((19, y + 3, 20, y + 10), fill=ha[0])
    # Uneven bangs and strands avoid a solid rectangular hair block.
    d.polygon(
        [
            (9, y + 4),
            (10, y),
            (13, y - 2),
            (20, y - 2),
            (23, y),
            (24, y + 5),
            (21, y + 4),
            (20, y + 1),
            (18, y + 4),
            (15, y + 2),
            (13, y + 5),
            (12, y + 3),
            (10, y + 7),
        ],
        fill=ha[1],
    )
    d.line([(11, y + 1), (14, y - 1), (19, y - 1), (21, y + 1)], fill=ha[2])
    d.line((11, y + 2, 11, y + 5), fill=ha[2])
    d.line((22, y + 2, 23, y + 6), fill=ha[0])
    if hat:
        d.polygon(
            [
                (7, y + 2),
                (9, y - 1),
                (9, y - 6),
                (12, y - 8),
                (21, y - 8),
                (24, y - 5),
                (24, y),
                (28, y + 2),
                (27, y + 5),
                (6, y + 5),
                (4, y + 3),
            ],
            fill="#79532f",
        )
        d.polygon(
            [(10, y - 5), (12, y - 7), (20, y - 7), (23, y - 4), (23, y), (9, y)],
            fill="#cea05a",
        )
        d.line((12, y - 6, 20, y - 6), fill="#f0cd83", width=2)
        for x in range(11, 23, 3):
            d.point((x, y - 3), fill="#e2b56b")
        d.rectangle((9, y - 1, 24, y + 1), fill="#8b5437")
        d.polygon([(6, y + 2), (27, y + 2), (25, y + 4), (8, y + 4)], fill="#dfb973")
        d.line((8, y + 2, 25, y + 2), fill="#f3d598")
    return im


def build_characters(output):
    for skin in range(3):
        for hair in range(3):
            for outfit in range(4):
                for hat in range(2):
                    sheet = Image.new("RGBA", (128, 192))
                    for row in range(4):
                        for frame in range(4):
                            sheet.alpha_composite(
                                actor(skin, hair, outfit, hat, row, frame),
                                (frame * 32, row * 48),
                            )
                    sheet.save(output / f"avatar_{skin}_{hair}_{outfit}_{hat}.png")


# --------------------------------------------------------------------------- villagers

SKIN_TONES = [
    ["#a36c4d", "#d89d70", "#f0c595"],
    ["#80513b", "#b77c53", "#dca16e"],
    ["#563d33", "#86583f", "#b27b53"],
    ["#b98a6c", "#e8b894", "#f8d8b8"],
    ["#8a5a3a", "#c48a5c", "#e8b080"],
]
HAIR_COLORS = {
    "black": "#2a2a2e",
    "brown": "#5a3c2c",
    "chestnut": "#8a5a36",
    "blond": "#c8a258",
    "red": "#a8482e",
    "grey": "#9a9e98",
    "white": "#d8d8d0",
    "navy": "#2f3a58",
}


def ramp3(base):
    def mixc(a, b, t):
        ca = tuple(int(a[i : i + 2], 16) for i in (1, 3, 5))
        cb = tuple(int(b[i : i + 2], 16) for i in (1, 3, 5))
        return "#%02x%02x%02x" % tuple(int(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))

    return [mixc(base, "#101418", 0.42), base, mixc(base, "#ffffff", 0.32)]


def accessory(im, name, color, hair):
    d = ImageDraw.Draw(im)
    hc = hair[1]
    if name == "glasses":
        for x in (12, 18):
            d.rectangle((x, 18, x + 3, 20), outline="#2a2a30")
        d.line((16, 19, 17, 19), fill="#2a2a30")
    elif name == "beard":
        d.polygon([(12, 23), (21, 23), (21, 26), (18, 29), (15, 29), (12, 26)], fill=hc)
        d.line((14, 24, 19, 24), fill=hair[2])
    elif name == "apron":
        d.polygon([(12, 28), (21, 28), (22, 40), (11, 40)], fill=color)
        d.line((12, 28, 12, 27), fill=color)
        d.rectangle((14, 33, 19, 36), fill=ramp3(color)[0])
    elif name == "scarf":
        d.rectangle((11, 25, 22, 28), fill=color)
        d.rectangle((19, 28, 22, 33), fill=ramp3(color)[0])
    elif name == "headband":
        d.rectangle((10, 14, 23, 15), fill=color)
    elif name == "bun":
        d.ellipse((13, 5, 20, 11), fill=hc)
        d.point((15, 6), fill=hair[2])
    elif name == "long":
        d.polygon([(8, 15), (11, 14), (11, 31), (8, 33)], fill=hc)
        d.polygon([(22, 14), (25, 15), (25, 33), (22, 31)], fill=hc)
    elif name == "pigtails":
        for x in (7, 24):
            d.rectangle((x, 17, x + 2, 27), fill=hc)
            d.rectangle((x, 17, x + 2, 18), fill=color)
    elif name == "cap":
        d.polygon([(9, 15), (10, 9), (14, 7), (21, 7), (24, 10), (24, 15)], fill=color)
        d.rectangle((9, 15, 25, 16), fill=ramp3(color)[0])
    elif name == "headscarf":
        d.polygon(
            [(9, 15), (10, 9), (14, 7), (21, 7), (24, 10), (24, 16), (22, 14), (11, 14)], fill=color
        )
        d.rectangle((22, 14, 25, 18), fill=ramp3(color)[0])
    elif name == "bald":
        d.polygon([(11, 9), (14, 7), (20, 7), (23, 10), (23, 14), (11, 14)], fill=color)
    elif name == "cane":
        d.line((26, 27, 28, 42), fill="#6a4a2a", width=2)
        d.line((25, 27, 28, 26), fill="#6a4a2a", width=2)
    elif name == "pack":
        d.rectangle((7, 27, 10, 38), fill=color)
        d.rectangle((22, 27, 25, 38), fill=color)
        d.line((11, 27, 11, 34), fill=ramp3(color)[0])
        d.line((21, 27, 21, 34), fill=ramp3(color)[0])
    elif name == "coat":
        d.polygon([(10, 36), (22, 36), (24, 44), (8, 44)], fill=color)
        d.line((16, 36, 16, 44), fill=ramp3(color)[0])
    elif name == "cross":
        d.rectangle((14, 31, 18, 32), fill="#c83a3a")
        d.rectangle((15, 30, 17, 34), fill="#c83a3a")
    elif name == "lamp":
        d.rectangle((14, 12, 18, 14), fill="#f4d878")
        d.point((16, 12), fill="#ffffff")
    elif name == "bowtie":
        d.polygon([(14, 27), (16, 29), (14, 31)], fill=color)
        d.polygon([(19, 27), (17, 29), (19, 31)], fill=color)
    elif name == "satchel":
        d.line((10, 27, 22, 38), fill=color, width=2)
        d.rectangle((19, 35, 24, 40), fill=ramp3(color)[0])
    elif name == "bandage":
        d.rectangle((9, 31, 12, 33), fill="#f4f0e4")
    elif name == "flower":
        d.ellipse((21, 12, 24, 15), fill=color)
        d.point((22, 13), fill="#fff4b0")
    elif name == "braid":
        d.polygon([(21, 14), (25, 15), (26, 30), (23, 31)], fill=hc)
        d.line((24, 18, 24, 29), fill=hair[2])


FRONT_ONLY = {"glasses", "beard", "bowtie", "cross", "lamp", "apron", "bandage"}


def npc_sprite(cfg, row=0, frame=0):
    sk = SKIN_TONES[cfg.get("skin", 0)]
    ha = ramp3(HAIR_COLORS[cfg.get("hair", "brown")])
    cl = ramp3(cfg["outfit"])
    im = actor(0, 0, 0, bool(cfg.get("hat", False)), row, frame, True, (sk, ha, cl))
    extras = Image.new("RGBA", im.size)
    for entry in cfg.get("acc", []):
        name, _, color = entry.partition(":")
        if row != 0 and name in FRONT_ONLY:
            continue
        accessory(extras, name, color or "#e8e0c8", ha)
    # The upper body bobs one pixel on odd frames; accessories bob with it.
    im.alpha_composite(extras, (0, frame % 2))
    if cfg.get("child"):
        small = im.resize((25, 37), Image.Resampling.NEAREST)
        out = Image.new("RGBA", (32, 48))
        out.alpha_composite(small, (3, 11))
        im = out
    return im


def build_villagers(output, villagers):
    """Writes a 4 direction x 4 frame walking sheet and a portrait for each villager."""
    for ident, cfg in villagers.items():
        sheet = Image.new("RGBA", (128, 192))
        for row in range(4):
            for frame in range(4):
                sheet.alpha_composite(npc_sprite(cfg, row, frame), (frame * 32, row * 48))
        sheet.save(output / f"npc_{ident}.png")
        im = npc_sprite(cfg, 0, 0)
        portrait = Image.new("RGBA", (96, 112), "#29483b")
        d = ImageDraw.Draw(portrait)
        d.ellipse((7, 3, 88, 86), fill="#365b49")
        d.ellipse((11, 57, 84, 133), fill=ramp3(cfg["outfit"])[1])
        head = im.crop((4, 3, 29, 37)).resize((75, 102), Image.Resampling.NEAREST)
        portrait.alpha_composite(head, (10, 5))
        d.rectangle((0, 0, 95, 111), outline="#b49c65", width=2)
        portrait.save(output / f"portrait_{ident}.png")

"""Original pixel UI skins, icons and title scenery, drawn on an integer grid."""

from PIL import Image, ImageDraw
from pathlib import Path
import random
from .crops import crop


def frame(kind):
    im = Image.new("RGBA", (48, 48))
    d = ImageDraw.Draw(im)
    palettes = {
        "paper": ("#683b24", "#b07336", "#e7b96a", "#f4dfaa"),
        "wood": ("#4f2c1e", "#915024", "#dcaa58", "#aa7139"),
        "button": ("#57301d", "#9c5727", "#e0ad58", "#c08a42"),
        "hover": ("#59311e", "#b96d2e", "#f8d479", "#dca553"),
        "pressed": ("#57301d", "#825026", "#bc883d", "#aa7134"),
        "disabled": ("#65523a", "#928064", "#b9a583", "#b5a17e"),
        "slot": ("#623e29", "#947047", "#d8b57c", "#c5a578"),
        "selected": ("#7d481e", "#d4882f", "#ffe697", "#eed08b"),
        "inset": ("#8d673f", "#b28c57", "#e6c68b", "#dfc48f"),
    }
    edge, rim, light, fill = palettes[kind]
    d.polygon(
        [
            (4, 1),
            (43, 1),
            (43, 4),
            (47, 4),
            (47, 43),
            (44, 43),
            (44, 47),
            (4, 47),
            (4, 44),
            (1, 44),
            (1, 4),
            (4, 4),
        ],
        fill="#34271dcc",
    )
    d.polygon(
        [
            (4, 0),
            (43, 0),
            (43, 3),
            (46, 3),
            (46, 42),
            (43, 42),
            (43, 45),
            (4, 45),
            (4, 42),
            (0, 42),
            (0, 3),
            (4, 3),
        ],
        fill=edge,
    )
    d.rectangle((3, 4, 43, 41), fill=rim)
    d.rectangle((5, 2, 41, 43), fill=rim)
    d.line([(5, 4), (41, 4), (41, 6)], fill=light, width=2)
    d.line((4, 7, 4, 38), fill=light, width=2)
    d.rectangle((7, 8, 39, 38), fill=edge)
    d.rectangle((9, 10, 37, 36), fill=fill)
    d.line((9, 10, 37, 10), fill=light)
    d.line((8, 37, 39, 37), fill=rim)
    if kind not in ("slot", "selected", "inset"):
        for x, y in [(4, 4), (39, 4), (4, 37), (39, 37)]:
            d.rectangle((x, y, x + 3, y + 3), fill=edge)
            d.rectangle((x, y, x + 2, y + 1), fill=light)
        for x in [13, 27, 33]:
            d.line((x, 6, x + 3, 6), fill=edge)
    return im


def glyph(name):
    im = Image.new("RGBA", (24, 24))
    d = ImageDraw.Draw(im)
    dark = "#5f3c26"
    light = "#f8d98b"
    gold = "#dca542"
    if name == "sun":
        for a, b in [
            ((12, 1), (12, 4)),
            ((12, 20), (12, 23)),
            ((1, 12), (4, 12)),
            ((20, 12), (23, 12)),
            ((3, 3), (5, 5)),
            ((19, 19), (21, 21)),
            ((3, 21), (5, 19)),
            ((19, 5), (21, 3)),
        ]:
            d.line((*a, *b), fill=gold, width=2)
        d.ellipse((6, 6, 18, 18), fill=dark)
        d.ellipse((7, 6, 18, 17), fill=gold)
        d.arc((8, 7, 17, 16), 190, 280, fill=light, width=2)
    elif name == "coin":
        d.ellipse((4, 3, 20, 21), fill="#75461e")
        d.ellipse((3, 2, 19, 20), fill=gold)
        d.ellipse((5, 4, 17, 18), outline=light, width=2)
        d.line((11, 6, 11, 16), fill="#a46a27", width=2)
        d.line((9, 7, 13, 7), fill=light)
    elif name == "bag":
        d.arc((7, 1, 18, 13), 180, 360, fill=dark, width=3)
        d.rounded_rectangle((4, 7, 21, 22), radius=3, fill=dark)
        d.rectangle((6, 8, 19, 20), fill="#b87b42")
        d.rectangle((7, 8, 18, 13), fill="#d8aa65")
        d.rectangle((9, 14, 17, 19), fill="#835430")
        d.line((7, 10, 18, 10), fill=light)
        d.rectangle((12, 12, 14, 15), fill=gold)
    elif name == "book":
        d.polygon([(3, 3), (12, 5), (21, 3), (21, 21), (12, 23), (3, 21)], fill=dark)
        d.polygon([(5, 4), (11, 6), (11, 20), (5, 18)], fill="#f1d89d")
        d.polygon([(13, 6), (19, 4), (19, 18), (13, 20)], fill="#e0c084")
        d.line((12, 5, 12, 21), fill="#b38a4b")
        d.rectangle((16, 3, 18, 10), fill="#a64f37")
    elif name == "map":
        d.polygon(
            [(2, 5), (8, 2), (15, 5), (21, 2), (23, 20), (16, 23), (9, 20), (3, 23)], fill=dark
        )
        d.polygon(
            [(4, 6), (8, 4), (15, 7), (19, 5), (21, 18), (16, 21), (9, 18), (5, 20)], fill="#ebd39c"
        )
        d.line([(6, 14), (10, 10), (14, 14), (18, 10)], fill="#71916a", width=2)
        d.line((8, 4, 9, 18), fill="#b49463")
        d.line((15, 7, 16, 20), fill="#b49463")
        d.rectangle((15, 8, 18, 11), fill="#b56142")
    elif name == "menu":
        for y in [5, 11, 17]:
            d.rectangle((4, y, 20, y + 3), fill=dark)
            d.line((5, y, 19, y), fill=light)
    elif name == "letter":
        d.rectangle((2, 5, 22, 20), fill=dark)
        d.rectangle((4, 6, 20, 18), fill="#eed7a1")
        d.line([(4, 7), (12, 13), (20, 7)], fill="#ab854e", width=2)
        d.rectangle((10, 12, 14, 16), fill="#a14e38")
        d.point((11, 13), fill="#e7a66e")
    elif name == "leaf":
        d.polygon([(3, 18), (5, 9), (14, 3), (22, 2), (21, 12), (14, 19), (5, 21)], fill=dark)
        d.polygon([(5, 17), (7, 10), (15, 5), (20, 4), (19, 12), (13, 17)], fill="#81a15b")
        d.line((5, 20, 18, 7), fill="#c9d789", width=2)
    elif name in ("heart", "heart_empty"):
        d.polygon(
            [
                (2, 6),
                (5, 3),
                (9, 3),
                (12, 6),
                (15, 3),
                (19, 3),
                (22, 6),
                (22, 12),
                (12, 22),
                (2, 12),
            ],
            fill=dark,
        )
        d.polygon(
            [
                (4, 7),
                (6, 5),
                (9, 5),
                (12, 8),
                (15, 5),
                (18, 5),
                (20, 7),
                (20, 11),
                (12, 19),
                (4, 11),
            ],
            fill="#c76a55" if name == "heart" else "#bca27a",
        )
        d.line((6, 6, 9, 6), fill="#f4b18b" if name == "heart" else "#d4bd91", width=2)
    return im


def control(name):
    """Slider and switch parts for the settings page."""
    edge = "#57301d"
    if name in ("track", "fill"):
        im = Image.new("RGBA", (24, 12))
        d = ImageDraw.Draw(im)
        if name == "track":
            d.rectangle((0, 2, 23, 9), fill=edge)
            d.rectangle((1, 3, 22, 8), fill="#3d2417")
            d.line((1, 8, 22, 8), fill="#8d673f")
            d.line((1, 3, 22, 3), fill="#2b190f")
        else:
            d.rectangle((0, 2, 23, 9), fill="#7d481e")
            d.rectangle((1, 3, 22, 8), fill="#dca553")
            d.line((1, 3, 22, 3), fill="#f8d479")
            d.line((1, 7, 22, 7), fill="#b97d36")
        return im
    if name == "knob":
        im = Image.new("RGBA", (20, 26))
        d = ImageDraw.Draw(im)
        d.ellipse((1, 4, 19, 24), fill="#34271d99")
        d.rounded_rectangle((2, 1, 17, 20), radius=4, fill=edge)
        d.rounded_rectangle((3, 2, 16, 19), radius=3, fill="#dca553")
        d.rounded_rectangle((4, 3, 13, 12), radius=2, fill="#f8d479")
        d.line((5, 16, 14, 16), fill="#b97d36")
        d.line((6, 5, 9, 5), fill="#fff0c3")
        return im
    on = name == "toggle_on"
    im = Image.new("RGBA", (52, 28))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((0, 2, 51, 25), radius=7, fill=edge)
    d.rounded_rectangle((2, 4, 49, 23), radius=5, fill="#c98a3a" if on else "#3d2417")
    if on:
        d.line((5, 6, 46, 6), fill="#f8d479")
    else:
        d.line((5, 21, 46, 21), fill="#8d673f")
    kx = 29 if on else 4
    d.rounded_rectangle((kx, 5, kx + 18, 22), radius=4, fill=edge)
    d.rounded_rectangle((kx + 1, 6, kx + 17, 21), radius=3, fill="#f4dfaa" if on else "#b9a583")
    d.line((kx + 3, 8, kx + 10, 8), fill="#fff8db" if on else "#d8c9a6")
    return im


def title_scene():
    rng = random.Random(762)
    im = Image.new("RGB", (640, 400))
    d = ImageDraw.Draw(im)
    for y in range(400):
        t = min(1, y / 230)
        d.line((0, y, 639, y), fill=(int(105 + 75 * t), int(166 + 41 * t), int(194 - 20 * t)))
    d.ellipse((485, 36, 525, 76), fill="#ffe9af")
    d.polygon(
        [
            (0, 208),
            (66, 112),
            (119, 181),
            (188, 98),
            (270, 187),
            (338, 122),
            (409, 174),
            (485, 91),
            (558, 171),
            (612, 121),
            (640, 169),
            (640, 300),
            (0, 300),
        ],
        fill="#7d9e97",
    )
    d.polygon([(66, 112), (86, 143), (71, 138), (62, 150), (51, 137)], fill="#c6d3b3")
    d.polygon(
        [(188, 98), (213, 130), (195, 124), (186, 139), (175, 128), (164, 131)], fill="#cbd9bf"
    )
    d.polygon(
        [
            (0, 221),
            (83, 180),
            (162, 219),
            (248, 171),
            (355, 213),
            (436, 169),
            (542, 202),
            (640, 178),
            (640, 310),
            (0, 310),
        ],
        fill="#527e6a",
    )
    d.polygon(
        [
            (0, 277),
            (82, 221),
            (197, 236),
            (301, 207),
            (424, 232),
            (530, 205),
            (640, 230),
            (640, 400),
            (0, 400),
        ],
        fill="#63874d",
    )
    for _ in range(2800):
        x = rng.randrange(640)
        y = rng.randrange(258, 400)
        d.line((x, y, x + 2, y - 2), fill=rng.choice(["#87a25c", "#77974f", "#a5b769", "#4f7645"]))
    d.polygon(
        [
            (416, 259),
            (477, 236),
            (550, 249),
            (640, 280),
            (640, 400),
            (563, 375),
            (498, 330),
            (425, 317),
            (387, 288),
        ],
        fill="#548d94",
    )
    for _ in range(170):
        x = rng.randrange(430, 640)
        y = rng.randrange(262, 390)
        if im.getpixel((x, y)) == (84, 141, 148):
            d.line((x, y, x + rng.randrange(3, 11), y), fill="#9ac3b7")
    d.polygon(
        [
            (167, 291),
            (184, 289),
            (235, 330),
            (299, 350),
            (303, 400),
            (272, 400),
            (271, 367),
            (220, 346),
        ],
        fill="#cfb47b",
    )
    farmhouse = Image.open(Path(__file__).resolve().parents[2] / "assets/art/house.png").resize(
        (154, 134), Image.Resampling.NEAREST
    )
    im.paste(farmhouse, (80, 184), farmhouse)
    for x, y, v, scale in [
        (-23, 245, 0, 1.5),
        (30, 224, 1, 1),
        (500, 250, 1, 1.4),
        (570, 245, 3, 1.4),
        (15, 322, 2, 1.2),
        (348, 318, 0, 0.9),
        (589, 340, 0, 1.2),
    ]:
        t = Image.open(Path(__file__).resolve().parents[2] / f"assets/art/tree_{v}.png").convert(
            "RGBA"
        )
        t = t.resize((int(t.width * scale), int(t.height * scale)), Image.Resampling.NEAREST)
        im.paste(t, (x, y), t)
    return im.resize((1280, 800), Image.Resampling.NEAREST)


def title_clouds():
    im = Image.new("RGBA", (640, 400))
    d = ImageDraw.Draw(im)
    for x, y, w in [(35, 49, 75), (166, 30, 58), (370, 64, 94), (556, 25, 73)]:
        for xx, yy, rr in [
            (x, y, 14),
            (x + 19, y - 6, 18),
            (x + 40, y, 15),
            (x + w - 10, y + 5, 12),
        ]:
            d.ellipse((xx - rr, yy - rr, xx + rr, yy + rr), fill="#e8e7cb")
        d.rectangle((x - 12, y + 2, x + w, y + 15), fill="#e8e7cb")
    return im.resize((1280, 800), Image.Resampling.NEAREST)


def seed_packet(kind):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    d.polygon([(7, 3), (24, 3), (26, 7), (26, 28), (5, 28), (5, 7)], fill="#5f402c")
    d.rectangle((7, 7, 24, 26), fill="#d9be82")
    d.rectangle((8, 9, 22, 24), fill="#f5dfa4")
    d.rectangle((8, 4, 23, 8), fill="#64814b" if kind == "turnip" else "#ad6338")
    d.line((9, 5, 22, 5), fill="#a9ba6d" if kind == "turnip" else "#e8ae66")
    d.line((6, 9, 6, 26), fill="#ab8754")
    d.line((8, 27, 24, 27), fill="#997549")
    root = crop("harvest").resize((16, 16), Image.Resampling.NEAREST)
    if kind == "carrot":
        px = root.load()
        for y in range(10, 16):
            for x in range(16):
                r, g, b, a = px[x, y]
                if a and r > g * 0.95 and r > b * 1.12:
                    px[x, y] = (min(240, r + 15), int(g * 0.65), int(b * 0.36), a)
    im.alpha_composite(root, (8, 9))
    return im


def build_interface(output):
    ui = output.parent / "ui"
    ui.mkdir(exist_ok=True)
    for kind in [
        "paper",
        "wood",
        "button",
        "hover",
        "pressed",
        "disabled",
        "slot",
        "selected",
        "inset",
    ]:
        frame(kind).save(ui / (kind + ".png"))
    for name in [
        "sun",
        "coin",
        "bag",
        "book",
        "map",
        "menu",
        "letter",
        "leaf",
        "heart",
        "heart_empty",
    ]:
        glyph(name).save(ui / (name + ".png"))
    for name in ["track", "fill", "knob", "toggle_on", "toggle_off"]:
        control(name).save(ui / (name + ".png"))
    title_scene().save(output / "title_landscape.png")
    title_clouds().save(output / "title_clouds.png")
    for kind in ("turnip", "carrot"):
        seed_packet(kind).save(output / (kind + "_packet.png"))

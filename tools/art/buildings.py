"""Shop fronts, farm buildings, mine gate, dock and other props for the new districts."""

from PIL import Image, ImageDraw
from .environment import house


def sign(im, kind):
    """A hanging board above the door with a small emblem for the shop type."""
    d = ImageDraw.Draw(im)
    d.rectangle((92, 124, 164, 152), fill="#4a3220")
    d.rectangle((95, 127, 161, 149), fill="#d8b878")
    d.line((97, 129, 159, 129), fill="#f0d898", width=2)
    for x in (98, 156):
        d.line((x, 118, x, 126), fill="#4a3220", width=2)
    if kind == "store":
        d.ellipse((116, 130, 140, 148), fill="#7a5028")
        d.rectangle((120, 128, 136, 134), fill="#7a5028")
        d.ellipse((119, 133, 137, 147), fill="#c8923a")
        d.line((128, 135, 128, 145), fill="#7a5028", width=2)
    elif kind == "smith":
        d.polygon(
            [
                (106, 134),
                (150, 134),
                (150, 140),
                (140, 142),
                (136, 148),
                (120, 148),
                (116, 142),
                (106, 140),
            ],
            fill="#3a3a44",
        )
        d.line((108, 135, 148, 135), fill="#7a7a88", width=2)
    elif kind == "clinic":
        d.rectangle((105, 130, 151, 148), fill="#f4f0e4")
        d.rectangle((124, 132, 132, 146), fill="#c83a3a")
        d.rectangle((117, 137, 139, 141), fill="#c83a3a")
    elif kind == "tea":
        d.polygon([(110, 148), (146, 148), (142, 138), (114, 138)], fill="#f4f0e4")
        d.ellipse((112, 131, 144, 142), fill="#e8e0d0")
        d.ellipse((116, 133, 140, 140), fill="#7a5028")
        d.arc((140, 134, 152, 144), 270, 90, fill="#f4f0e4", width=2)
        d.line((124, 130, 122, 126), fill="#ffffff", width=1)
        d.line((132, 130, 134, 125), fill="#ffffff", width=1)
    elif kind == "tackle":
        d.ellipse((108, 133, 142, 146), fill="#4a7a9a")
        d.polygon([(140, 139), (152, 132), (152, 147)], fill="#4a7a9a")
        d.ellipse((114, 137, 118, 141), fill="#f4f4f4")
    return im


def shopfront(kind):
    roof = {
        "store": "green",
        "smith": "slate",
        "clinic": "white",
        "tackle": "blue",
        "tea": "brown",
    }[kind]
    im = house(roof)
    return sign(im, kind)


def barn():
    im = Image.new("RGBA", (256, 224))
    d = ImageDraw.Draw(im)
    d.ellipse((12, 196, 244, 222), fill="#263b2860")
    d.rectangle((26, 96, 230, 206), fill="#5a2a22")
    d.rectangle((30, 100, 226, 202), fill="#a8483a")
    for x in range(34, 226, 12):
        d.line((x, 101, x, 201), fill="#8a3a2e", width=2)
    d.polygon([(10, 100), (128, 22), (246, 100), (238, 112), (18, 112)], fill="#4a2a20")
    d.polygon([(22, 100), (128, 32), (234, 100), (226, 108), (30, 108)], fill="#7a5a48")
    for y in range(40, 104, 8):
        d.line((60 + (y - 40) // 2, y, 196 - (y - 40) // 2, y), fill="#98745a")
    d.rectangle((86, 130, 170, 206), fill="#f0e8d4")
    d.rectangle((90, 134, 166, 202), fill="#d8452e")
    d.line((90, 134, 166, 202), fill="#f0e8d4", width=5)
    d.line((166, 134, 90, 202), fill="#f0e8d4", width=5)
    d.rectangle((108, 60, 148, 88), fill="#4a3a2a")
    d.rectangle((112, 64, 144, 84), fill="#2a2018")
    d.rectangle((116, 112, 140, 124), fill="#f0e8d4")
    return im


def coop():
    im = Image.new("RGBA", (160, 128))
    d = ImageDraw.Draw(im)
    d.ellipse((6, 108, 154, 126), fill="#263b2860")
    d.rectangle((20, 52, 140, 112), fill="#6a4a30")
    d.rectangle((24, 56, 136, 108), fill="#c8964e")
    for x in range(26, 136, 10):
        d.line((x, 57, x, 107), fill="#a8763a", width=2)
    d.polygon([(8, 56), (80, 12), (152, 56), (144, 64), (16, 64)], fill="#5a3a2a")
    d.polygon([(18, 56), (80, 20), (142, 56), (136, 60), (24, 60)], fill="#a8603a")
    d.rectangle((62, 76, 98, 112), fill="#4a3220")
    d.rectangle((66, 80, 94, 112), fill="#2a1e14")
    d.rectangle((34, 72, 52, 88), fill="#e8dcb0")
    d.rectangle((36, 74, 50, 86), fill="#f8ecc0")
    d.rectangle((108, 90, 130, 112), fill="#e8d098")
    return im


def lot_sign():
    im = Image.new("RGBA", (64, 64))
    d = ImageDraw.Draw(im)
    d.ellipse((6, 52, 58, 62), fill="#263b2860")
    d.rectangle((29, 22, 35, 56), fill="#5a3a22")
    d.rectangle((10, 8, 54, 30), fill="#4a3220")
    d.rectangle((12, 10, 52, 28), fill="#d8b878")
    d.line((14, 13, 50, 13), fill="#f0d898", width=2)
    d.rectangle((24, 17, 40, 24), fill="#a88848")
    return im


def mine_gate():
    im = Image.new("RGBA", (192, 160))
    d = ImageDraw.Draw(im)
    d.ellipse((8, 140, 184, 158), fill="#263b2860")
    d.polygon(
        [(6, 150), (14, 52), (50, 18), (96, 8), (142, 18), (178, 52), (186, 150)], fill="#4a4a54"
    )
    d.polygon(
        [(16, 148), (22, 56), (54, 26), (96, 16), (138, 26), (170, 56), (176, 148)], fill="#6a6a76"
    )
    for x, y, r in [(40, 60, 12), (140, 50, 14), (98, 34, 10), (28, 110, 10), (160, 100, 12)]:
        d.ellipse((x - r, y - r, x + r, y + r), fill="#7a7a86")
        d.ellipse((x - r + 2, y - r + 2, x + r - 6, y + r - 6), fill="#8e8e9a")
    d.polygon(
        [(56, 150), (56, 78), (74, 56), (96, 50), (118, 56), (136, 78), (136, 150)], fill="#16161c"
    )
    d.rectangle((50, 70, 58, 150), fill="#6a4a30")
    d.rectangle((134, 70, 142, 150), fill="#6a4a30")
    d.rectangle((46, 62, 146, 72), fill="#8a6038")
    d.line((50, 64, 142, 64), fill="#b08850", width=2)
    d.rectangle((88, 82, 104, 92), fill="#e8c860")
    d.line((96, 72, 96, 82), fill="#4a3220", width=2)
    return im


def ore_node():
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    d.ellipse((3, 22, 29, 30), fill="#16161c50")
    d.polygon([(4, 24), (6, 14), (13, 8), (23, 9), (28, 17), (26, 25), (10, 27)], fill="#3a3a44")
    d.polygon([(7, 23), (9, 15), (14, 11), (22, 12), (25, 18), (23, 23), (11, 24)], fill="#6a6a76")
    for x, y in [(12, 16), (19, 14), (21, 20), (14, 21)]:
        d.rectangle((x, y, x + 2, y + 2), fill="#e8d878")
        d.point((x, y), fill="#fffbd0")
    d.line((9, 14, 16, 11), fill="#9a9aa6", width=2)
    return im


def dock():
    im = Image.new("RGBA", (192, 64))
    d = ImageDraw.Draw(im)
    for i in range(6):
        x = 8 + i * 30
        d.rectangle((x, 16, x + 26, 52), fill="#7a5a38")
        d.rectangle((x + 1, 17, x + 25, 28), fill="#b0884e")
        d.line((x + 2, 18, x + 24, 18), fill="#d0a866", width=2)
        d.line((x + 2, 40, x + 24, 40), fill="#5a4028")
    for x in (4, 100, 184):
        d.rectangle((x, 8, x + 5, 60), fill="#4a3220")
        d.rectangle((x, 8, x + 5, 12), fill="#8a6a40")
    return im


def boat():
    im = Image.new("RGBA", (128, 64))
    d = ImageDraw.Draw(im)
    d.ellipse((6, 44, 122, 62), fill="#16405a50")
    d.polygon([(6, 28), (122, 28), (108, 54), (22, 54)], fill="#4a3220")
    d.polygon([(10, 30), (118, 30), (106, 50), (24, 50)], fill="#9a6a3a")
    d.line((12, 33, 116, 33), fill="#d0a060", width=2)
    d.line((64, 28, 64, 4), fill="#4a3220", width=3)
    d.polygon([(66, 6), (66, 26), (100, 26)], fill="#f0e8d4")
    d.line((14, 40, 114, 40), fill="#7a4a28")
    return im


def lighthouse():
    im = Image.new("RGBA", (64, 160))
    d = ImageDraw.Draw(im)
    d.ellipse((4, 148, 60, 158), fill="#263b2860")
    d.polygon([(14, 150), (22, 40), (42, 40), (50, 150)], fill="#e8e0d0")
    for y in range(52, 140, 26):
        d.polygon(
            [
                (22 - (y - 40) // 14, y),
                (42 + (y - 40) // 14, y),
                (42 + (y - 26) // 14, y + 14),
                (22 - (y - 26) // 14, y + 14),
            ],
            fill="#c83a3a",
        )
    d.rectangle((18, 28, 46, 40), fill="#4a4a54")
    d.rectangle((22, 14, 42, 28), fill="#f8e898")
    d.rectangle((26, 16, 38, 26), fill="#fffbd0")
    d.polygon([(18, 14), (32, 2), (46, 14)], fill="#c83a3a")
    d.rectangle((28, 120, 36, 150), fill="#4a3220")
    return im


def mine_cart():
    im = Image.new("RGBA", (64, 48))
    d = ImageDraw.Draw(im)
    d.ellipse((6, 40, 58, 47), fill="#16161c50")
    d.polygon([(6, 12), (58, 12), (52, 34), (12, 34)], fill="#5a3a22")
    d.polygon([(9, 14), (55, 14), (50, 31), (14, 31)], fill="#8a5a32")
    for x, y in [(16, 12), (26, 8), (36, 10), (44, 7)]:
        d.polygon([(x, y + 6), (x + 6, y), (x + 12, y + 6)], fill="#6a6a76")
    d.ellipse((12, 32, 24, 44), fill="#2a2a30")
    d.ellipse((40, 32, 52, 44), fill="#2a2a30")
    d.ellipse((16, 36, 20, 40), fill="#8a8a98")
    d.ellipse((44, 36, 48, 40), fill="#8a8a98")
    return im


def build_buildings(output):
    for kind in ("store", "smith", "clinic", "tackle", "tea"):
        shopfront(kind).save(output / ("shop_" + kind + ".png"))
    for roof in ("green", "blue", "brown", "gold"):
        house(roof).save(output / ("home_" + roof + ".png"))
    barn().save(output / "barn.png")
    coop().save(output / "coop.png")
    lot_sign().save(output / "lot_sign.png")
    mine_gate().save(output / "mine_gate.png")
    ore_node().save(output / "ore_node.png")
    dock().save(output / "dock.png")
    boat().save(output / "boat.png")
    lighthouse().save(output / "lighthouse.png")
    mine_cart().save(output / "mine_cart.png")

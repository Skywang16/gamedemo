"""Small props for the districts; the buildings themselves are drawn by the image model (ai_assets.py)."""

from PIL import Image, ImageDraw


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
    lot_sign().save(output / "lot_sign.png")
    ore_node().save(output / "ore_node.png")
    dock().save(output / "dock.png")
    boat().save(output / "boat.png")
    mine_cart().save(output / "mine_cart.png")

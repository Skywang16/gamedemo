from PIL import Image, ImageDraw
from .crops import crop, foliage


def carrot(stage):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    if stage in ("seeds", "sprout"):
        return crop(stage)
    foliage(d, mature=True)
    if stage in ("mature", "harvest"):
        d.polygon(
            [
                (12, 19),
                (19, 19),
                (22, 22),
                (20, 26),
                (17, 30),
                (15, 31),
                (13, 27),
                (11, 23),
            ],
            fill="#814b2b",
        )
        d.polygon([(13, 20), (18, 20), (20, 22), (18, 27), (16, 29), (13, 24)], fill="#dd873d")
        d.line([(14, 21), (14, 24), (16, 26)], fill="#f4b65c", width=1)
        d.line([(17, 23), (19, 23)], fill="#b86032")
        d.point((16, 27), fill="#b86032")
    return im


def stall():
    im = Image.new("RGBA", (128, 96))
    d = ImageDraw.Draw(im)
    d.ellipse((4, 80, 122, 95), fill="#314d3566")
    for x in (10, 110):
        d.rectangle((x, 20, x + 7, 83), fill="#695133")
        d.line((x + 2, 23, x + 2, 80), fill="#c1985e", width=2)
    d.rectangle((14, 53, 112, 84), fill="#86623c")
    for x in range(17, 112, 13):
        d.rectangle((x, 57, x + 10, 81), fill="#b68b52")
        d.line((x + 2, 59, x + 2, 77), fill="#d1aa6b")
    d.rectangle((8, 50, 118, 57), fill="#d6b576")
    d.line((8, 57, 118, 57), fill="#624d32", width=2)
    d.polygon([(16, 7), (111, 7), (125, 34), (3, 34)], fill="#365c48")
    for i in range(6):
        x = 8 + i * 19
        d.polygon(
            [(x + 8, 9), (x + 22, 9), (x + 20, 33), (x + 1, 33)],
            fill="#b5be80" if i % 2 else "#638a62",
        )
        d.rectangle((x + 1, 33, x + 18, 40), fill="#a5b378" if i % 2 else "#527b57")
    for x, c in [(29, "#e4dbaf"), (54, "#d99b4d"), (80, "#b6c57c")]:
        d.rectangle((x, 42, x + 14, 50), fill="#6b5437")
        d.rectangle((x + 2, 40, x + 12, 48), fill=c)
    return im


def crate():
    im = Image.new("RGBA", (64, 48))
    d = ImageDraw.Draw(im)
    d.ellipse((2, 34, 62, 47), fill="#314d3566")
    d.rectangle((4, 10, 59, 40), fill="#644a32")
    d.rectangle((7, 13, 56, 37), fill="#b98c50")
    for y in (17, 27, 36):
        d.line((7, y, 56, y), fill="#7e5b35", width=2)
    d.rectangle((3, 7, 60, 14), fill="#d0a464")
    d.line((4, 7, 59, 7), fill="#e2bd79", width=2)
    for x in (10, 49):
        d.rectangle((x, 10, x + 4, 38), fill="#8f693d")
    d.rectangle((25, 18, 39, 30), fill="#ded2a1")
    d.line((28, 24, 36, 24), fill="#537945", width=2)
    d.line((32, 20, 32, 27), fill="#537945", width=2)
    return im


def tool(kind):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    if kind == "hoe":
        d.line((8, 27, 23, 6), fill="#513e2d", width=5)
        d.line((9, 26, 23, 7), fill="#c79b62", width=2)
        d.polygon([(17, 4), (21, 2), (30, 8), (28, 13), (24, 12), (24, 9)], fill="#405653")
        d.line((19, 4, 28, 9), fill="#afc2ad", width=2)
    else:
        d.rectangle((9, 11, 23, 28), fill="#735339")
        d.rectangle((11, 12, 21, 26), fill="#d8b578")
        d.polygon(
            [(11, 11), (9, 5), (13, 4), (16, 8), (19, 3), (23, 5), (21, 12)],
            fill="#60884a",
        )
        d.ellipse((13, 17, 19, 23), fill="#edf0c9")
    return im


# Building rendering lives with the environmental palette.


def build_misc(output):
    def rect(d, b, c):
        d.rectangle(b, fill=c)

    def save(name, im):
        im.save(output / (name + ".png"))

    for id, name in [
        ("wood", "wood"),
        ("stone", "stone"),
        ("berry", "berry"),
        ("stump", "stump"),
        ("bench", "bench"),
        ("lantern_stand", "lantern_stand"),
        ("fountain", "fountain"),
    ]:
        size = {
            "wood": (32, 32),
            "stone": (32, 32),
            "berry": (32, 32),
            "stump": (64, 48),
            "bench": (96, 40),
            "lantern_stand": (64, 72),
            "fountain": (96, 72),
        }[id]
        im = Image.new("RGBA", size)
        d = ImageDraw.Draw(im)
        if id == "wood":
            for y in (12, 20):
                rect(d, (4, y, 25, y + 7), "#694631")
                rect(d, (5, y, 24, y + 3), "#b98b50")
                d.ellipse((21, y, 29, y + 8), fill="#d5b27a")
                d.ellipse((23, y + 2, 27, y + 6), outline="#805b36")
        elif id == "stone":
            d.polygon(
                [(3, 24), (5, 14), (13, 8), (24, 10), (29, 23), (22, 28), (9, 28)],
                fill="#596f6b",
            )
            d.polygon([(6, 22), (8, 14), (14, 10), (23, 12), (25, 22)], fill="#a2aaa0")
            d.line((9, 14, 18, 12), fill="#d2d0b8", width=2)
        elif id == "berry":
            d.ellipse((3, 8, 28, 29), fill="#426d3e")
            d.ellipse((8, 5, 26, 23), fill="#7c9d50")
            for x, y in [(9, 18), (18, 14), (22, 23), (13, 24)]:
                d.ellipse((x - 3, y - 3, x + 3, y + 3), fill="#a84d63")
                d.point((x - 1, y - 2), fill="#e4a0a0")
        elif id == "stump":
            rect(d, (16, 15, 48, 39), "#684b33")
            d.ellipse((10, 31, 54, 46), fill="#5e4c32")
            d.ellipse((12, 4, 52, 24), fill="#c79d62")
            d.ellipse((19, 8, 44, 19), outline="#88613e", width=2)
        elif id == "bench":
            for y in [4, 12, 22]:
                rect(d, (4, y, 90, y + 5), "#c29357")
                d.line((6, y, 88, y), fill="#edd298")
            for x in [16, 76]:
                rect(d, (x, 25, x + 5, 39), "#654e34")
        elif id == "lantern_stand":
            for x in [8, 52]:
                rect(d, (x, 9, x + 4, 65), "#6d5338")
            rect(d, (3, 8, 60, 13), "#b89559")
            rect(d, (5, 60, 60, 68), "#87683f")
            for x in [20, 40]:
                d.line((x, 12, x, 27), fill="#d9b77b")
                d.ellipse((x - 7, 27, x + 7, 43), fill="#efcc7b")
                rect(d, (x - 5, 30, x + 5, 40), "#d8834d")
        else:
            d.ellipse((2, 24, 93, 69), fill="#677b75")
            d.ellipse((6, 22, 89, 62), fill="#b7b79a")
            d.ellipse((12, 27, 84, 54), fill="#528d91")
            rect(d, (43, 9, 53, 40), "#c6c6a4")
            d.ellipse((33, 6, 62, 20), fill="#95b8ac")
            d.line((49, 3, 49, 15), fill="#d2ecce", width=3)
        save(id, im)
    im = Image.new("RGBA", (96, 64))
    d = ImageDraw.Draw(im)
    d.ellipse((14, 45, 83, 60), fill="#34472f70")
    d.polygon([(7, 50), (39, 5), (83, 46), (77, 54)], fill="#66583b")
    d.polygon([(11, 48), (39, 9), (60, 48)], fill="#c2ae73")
    d.polygon([(39, 11), (78, 45), (59, 47)], fill="#9d8a5e")
    d.polygon([(30, 49), (39, 25), (49, 49)], fill="#38483a")
    d.line((39, 9, 60, 47), fill="#e0ce93", width=2)
    save("camp", im)

"""Hand-composed pixel clusters, woodwork, roof tiles and reclaimable vegetation."""

from PIL import Image, ImageDraw


def utility(kind):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    if kind == "fiber":
        for i in range(8):
            d.line(
                (7 + i * 2, 27, 5 + i * 3, 5 + i % 3),
                fill=["#7b8a45", "#b0ad59", "#d3c17a"][i % 3],
                width=2,
            )
        d.line((8, 18, 26, 18), fill="#795537", width=3)
    else:
        d.line((7, 28, 23, 7), fill="#4c3d2c", width=5)
        d.line((8, 27, 23, 7), fill="#c9a06b", width=2)
        if kind == "scythe":
            d.arc((8, 1, 31, 23), 190, 340, fill="#405b57", width=5)
            d.arc((8, 1, 30, 22), 195, 325, fill="#bcd0ba", width=2)
        elif kind == "axe":
            d.polygon([(20, 4), (28, 8), (27, 19), (21, 17), (18, 12)], fill="#45615e")
            d.line((27, 9, 26, 17), fill="#d2ddc5", width=3)
        elif kind == "pickaxe":
            d.line([(13, 4), (21, 5), (29, 13)], fill="#415b57", width=5)
            d.line([(13, 3), (21, 4), (29, 12)], fill="#b8c7af", width=2)
    return im


def well():
    im = Image.new("RGBA", (64, 72))
    d = ImageDraw.Draw(im)
    d.ellipse((4, 44, 59, 68), fill="#444e43")
    d.ellipse((6, 40, 57, 61), fill="#a4a18b")
    d.ellipse((14, 44, 50, 56), fill="#304f57")
    for x in [12, 49]:
        d.rectangle((x, 16, x + 4, 52), fill="#715539")
        d.line((x + 1, 17, x + 1, 48), fill="#bb975e")
    d.polygon([(3, 25), (31, 3), (61, 25), (58, 30), (5, 30)], fill="#6c4633")
    d.polygon([(7, 24), (31, 6), (56, 24)], fill="#b67543")
    for y in [14, 20, 25]:
        d.line((17 - (y - 14), y, 45 + (y - 14), y), fill="#855031")
    d.line((32, 25, 32, 48), fill="#c3b181")
    d.rectangle((27, 45, 38, 57), fill="#96764b")
    return im

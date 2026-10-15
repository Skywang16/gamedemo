"""Hand-composed pixel clusters, woodwork, roof tiles and reclaimable vegetation."""

from PIL import Image, ImageDraw
import random


def tree(variant=0):
    rng = random.Random(410 + variant)
    image = Image.new("RGBA", (96, 128))
    d = ImageDraw.Draw(image)
    d.ellipse((19, 111, 85, 125), fill="#243c2768")
    d.polygon(
        [
            (40, 56),
            (56, 52),
            (58, 107),
            (71, 117),
            (58, 118),
            (49, 111),
            (36, 120),
            (26, 117),
            (39, 108),
        ],
        fill="#473b2a",
    )
    d.polygon(
        [(43, 57), (51, 55), (52, 109), (60, 114), (48, 110), (35, 117), (44, 106)],
        fill="#92623c",
    )
    for i in range(14):
        y = 62 + i * 3
        x = 44 + (i * 3) % 7
        d.line((x, y, x - 1, y + 8), fill=["#c19758", "#b78248", "#674b30"][i % 3])
    d.ellipse((45, 83, 52, 94), outline="#593f2c", width=2)
    palettes = [
        ["#254b34", "#34643b", "#477b3f", "#619348", "#80ac51", "#a3c66a"],
        ["#284b38", "#346944", "#478749", "#63a052", "#82b956", "#b2cf74"],
        ["#344f34", "#4c6d3b", "#688a43", "#8ba34b", "#abb95a", "#c9ce7c"],
        ["#273f35", "#355b3d", "#467542", "#668e49", "#87ab5a", "#b2c87c"],
    ]
    p = palettes[variant % 4]
    centers = [
        (46, 24, 24),
        (27, 45, 25),
        (66, 44, 26),
        (18, 67, 19),
        (78, 69, 18),
        (43, 66, 29),
        (57, 83, 25),
        (30, 85, 18),
    ]
    mask = Image.new("1", image.size)
    md = ImageDraw.Draw(mask)
    for cx, cy, r in centers:
        md.ellipse((cx - r, cy - r * 0.8, cx + r, cy + r * 0.8), fill=1)
        d.ellipse((cx - r, cy - r * 0.8, cx + r, cy + r * 0.8), fill=p[0])
        d.ellipse((cx - r + 2, cy - r * 0.8 + 1, cx + r - 2, cy + r * 0.8 - 5), fill=p[1])
    # Interlocking stepped leaf clusters; upper-left light is consistent across assets.
    clusters = []
    for i in range(390):
        x = rng.randrange(3, 92)
        y = rng.randrange(4, 104)
        if not mask.getpixel((x, y)):
            continue
        shade = min(5, max(1, 4 - int(y / 32) + rng.choice([-1, 0, 0, 1])))
        clusters.append((y, x, shade, rng.randrange(3, 9), rng.randrange(2, 6)))
    for i, (y, x, shade, w, h) in enumerate(sorted(clusters)):
        if not all(
            mask.getpixel((min(95, x + dx), min(127, y + dy)))
            for dx, dy in [(w, 0), (0, h), (w, h)]
        ):
            continue
        d.polygon(
            [
                (x, y + 2),
                (x + 2, y),
                (x + w - 2, y),
                (x + w, y + 2),
                (x + w - 1, y + h),
                (x + 2, y + h + 1),
            ],
            fill=p[shade],
        )
        if shade >= 3:
            d.line((x + 2, y, x + w - 3, y), fill=p[min(5, shade + 1)])
        if i % 3 == 0:
            d.point((x + 1, y + h), fill=p[1])
    if variant == 2:
        for x, y in [(20, 54), (58, 34), (68, 78), (40, 88), (33, 39)]:
            d.ellipse((x, y, x + 5, y + 6), fill="#a54b32")
            d.point((x + 1, y + 1), fill="#edba6b")
    return image


def house(roof="red"):
    rng = random.Random(21)
    image = Image.new("RGBA", (256, 224))
    d = ImageDraw.Draw(image)
    d.ellipse((15, 191, 247, 222), fill="#263b2860")
    # Stone foundation and timber facade.
    d.rectangle((34, 104, 227, 202), fill="#5d4531")
    d.rectangle((39, 109, 222, 191), fill="#b7854d")
    for y in range(111, 190, 10):
        d.line((39, y, 222, y), fill="#715137", width=2)
        d.line((42, y + 2, 220, y + 2), fill="#dab77b")
        for x in range(43 + (y % 20) * 4, 218, 65):
            d.line((x, y, x, y + 9), fill="#836039")
        for _ in range(12):
            x = rng.randrange(40, 215)
            d.line((x, y + 5, x + rng.randrange(2, 8), y + 5), fill="#9f733f")
    for y in [191, 200]:
        for x in range(34 + (y % 2) * 9, 225, 19):
            d.rounded_rectangle(
                (x, y, x + 17, y + 8),
                radius=2,
                fill=rng.choice(["#777462", "#92917a", "#a5a18a"]),
                outline="#595a4b",
            )
    # Deep eaves and individual clipped roof shingles.
    outline = [(13, 109), (113, 13), (246, 107), (239, 121), (18, 121)]
    d.polygon(outline, fill="#4c3b2c")
    roof_mask = Image.new("L", image.size)
    rm = ImageDraw.Draw(roof_mask)
    rm.polygon([(19, 107), (114, 19), (239, 107), (233, 114), (22, 114)], fill=255)
    layer = Image.new("RGBA", image.size)
    ld = ImageDraw.Draw(layer)
    palette = {
        "red": ["#8a4936", "#a35c3d", "#b56d43", "#c47b4a", "#d28c55"],
        "plum": ["#624751", "#79515b", "#926367", "#a87570", "#bd8b80"],
        "slate": ["#3c5660", "#4b6870", "#5a7d80", "#6b9090", "#83a29a"],
    }[roof]
    for y in range(15, 116, 9):
        for x in range(-10 + (y // 9 % 2) * 8, 260, 16):
            color = rng.choice(palette[1:4])
            ld.rectangle((x, y, x + 15, y + 8), fill=color)
            ld.line((x, y + 7, x + 14, y + 7), fill=palette[0], width=2)
            ld.line((x + 2, y + 1, x + 12, y + 1), fill=palette[4])
            ld.line((x + 14, y, x + 15, y + 6), fill=palette[0])
            if rng.random() < 0.18:
                ld.line((x + 4, y + 3, x + 7, y + 6), fill=palette[1])
    image.paste(layer, (0, 0), roof_mask)
    d = ImageDraw.Draw(image)
    d.line([(17, 108), (114, 17), (241, 108)], fill="#dfad6d", width=3)
    d.line((114, 22, 234, 110), fill=palette[4], width=2)
    d.line((21, 117, 235, 117), fill="#71442f", width=3)
    # Chimney, attic window, braces.
    d.rectangle((186, 30, 207, 73), fill="#666b5b")
    for y in range(31, 72, 9):
        for x in range(186 + (y // 9 % 2) * 8, 207, 12):
            d.rectangle((x, y, min(x + 10, 207), y + 7), fill="#a5a28a", outline="#747761")
    d.rectangle((182, 25, 211, 32), fill="#c3b495")
    d.rectangle((186, 23, 208, 27), fill="#474d45")
    d.rectangle((103, 77, 131, 108), fill="#4d4834")
    d.rectangle((107, 81, 127, 104), fill="#426d78")
    d.rectangle((109, 83, 124, 89), fill="#a4d4c2")
    d.line((117, 82, 117, 104), fill="#e2c184", width=2)
    d.line((107, 94, 127, 94), fill="#e2c184", width=2)
    for x in [43, 214]:
        d.rectangle((x, 119, x + 5, 188), fill="#6a4a32")
        d.line((x + 1, 120, x + 1, 186), fill="#d0a064")
    # Windows, shutters and planted boxes.
    for x in [57, 167]:
        d.rectangle((x - 6, 129, x + 39, 166), fill="#6d4e35")
        for xx in [x - 5, x + 32]:
            d.rectangle((xx, 132, xx + 6, 162), fill="#78915e")
            for y in range(135, 161, 5):
                d.line((xx, y, xx + 6, y), fill="#4e6749")
        d.rectangle((x + 2, 131, x + 30, 162), fill="#dac08a")
        d.rectangle((x + 5, 134, x + 27, 159), fill="#376674")
        d.polygon([(x + 5, 134), (x + 27, 134), (x + 5, 155)], fill="#94c4bc")
        d.line((x + 16, 133, x + 16, 161), fill="#d8bc7e", width=2)
        d.line((x + 4, 147, x + 28, 147), fill="#d8bc7e", width=2)
        d.rectangle((x - 2, 166, x + 34, 173), fill="#765137")
        d.line((x - 2, 166, x + 34, 166), fill="#d8a66b", width=2)
        for j in range(7):
            xx = x + j * 5
            d.line((xx, 166, xx - 2, 161), fill="#406a3d", width=2)
            d.rectangle(
                (xx - 2, 158, xx + 2, 161),
                fill=["#ebc087", "#d99fa1", "#e8d6ae"][j % 3],
            )
    d.rectangle((107, 127, 148, 201), fill="#4f3b2b")
    d.rectangle((111, 131, 144, 199), fill="#936a3d")
    d.rectangle((116, 135, 139, 156), fill="#3d6870")
    d.polygon([(118, 137), (136, 137), (118, 152)], fill="#b1cab0")
    for y in [162, 179]:
        d.rectangle((116, y, 139, y + 13), outline="#c69d61", width=2)
    d.ellipse((136, 165, 140, 170), fill="#efd094")
    for i in range(3):
        y = 201 + i * 6
        d.rectangle(
            (100 - i * 6, y, 155 + i * 6, y + 5),
            fill=["#b6a384", "#9d8a6c", "#89795e"][i],
        )
        d.line((101 - i * 6, y, 155 + i * 6, y), fill="#dbca9f")
    # Hanging porch light.
    d.line((154, 125, 162, 125), fill="#4f4632", width=2)
    d.line((161, 125, 161, 137), fill="#4f4632")
    d.rectangle((156, 135, 166, 150), fill="#65543c")
    d.rectangle((158, 138, 164, 147), fill="#f0ce81")
    return image


def debris(kind, variant=0):
    rng = random.Random(100 + variant)
    im = Image.new("RGBA", (32, 40))
    d = ImageDraw.Draw(im)
    d.ellipse((2, 29, 31, 38), fill="#324c3055")
    if kind == "weeds":
        for i in range(18):
            x = rng.randrange(4, 29)
            y = rng.randrange(10, 25)
            bend = rng.randrange(-6, 7)
            d.polygon(
                [
                    (x, 35),
                    (x - 3, 28),
                    (x + bend - 1, y),
                    (x + bend + 1, y + 3),
                    (x + 2, 29),
                    (x + 2, 35),
                ],
                fill=rng.choice(["#345a35", "#46703a", "#5e8c40", "#7ba449"]),
            )
            if i % 3 == 0:
                d.line((x + 1, 33, x + bend, y + 5), fill="#a1bf5a")
        for x, y in [(11, 14), (22, 18)]:
            d.line((x, 29, x, y), fill="#8ca54b")
            d.line((x - 2, y, x + 2, y), fill="#c1be6e", width=2)
    elif kind == "branch":
        d.line([(3, 31), (13, 24), (27, 25)], fill="#4b3d2b", width=8)
        d.line([(4, 29), (13, 22), (27, 23)], fill="#9f7846", width=5)
        d.line([(4, 28), (13, 22), (26, 22)], fill="#d0a16a", width=1)
        d.line((14, 24, 18, 13), fill="#735536", width=4)
        d.line((18, 14, 24, 12), fill="#b18a53", width=2)
        d.ellipse((24, 21, 30, 28), fill="#dab37c")
        d.ellipse((26, 23, 28, 26), outline="#8d653d")
    else:
        d.polygon(
            [(2, 29), (7, 18), (18, 13), (27, 19), (31, 31), (24, 37), (9, 36)],
            fill="#46544b",
        )
        d.polygon(
            [(4, 28), (9, 19), (18, 15), (26, 20), (26, 29), (19, 34), (9, 33)],
            fill="#8e9887",
        )
        d.polygon([(9, 19), (18, 15), (23, 20), (16, 24), (5, 28)], fill="#c1c2a7")
        d.polygon([(16, 24), (23, 20), (26, 29), (19, 34)], fill="#6b7b6c")
        d.line((17, 17, 11, 21), fill="#e1d8b7", width=2)
        d.line((15, 26, 18, 28), fill="#5b6b5b")
        d.rectangle((4, 30, 8, 32), fill="#779254")
    return im


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

from PIL import Image, ImageDraw

P = {
    "outline": "#30432c",
    "leaf_shadow": "#365f31",
    "leaf_dark": "#477d38",
    "leaf": "#68a343",
    "leaf_light": "#9ac455",
    "leaf_glint": "#c4d777",
    "root_outline": "#827650",
    "root_shadow": "#b6b995",
    "root": "#e7e2bc",
    "root_light": "#fff2cf",
    "earth_dark": "#69472d",
    "earth": "#8e6239",
    "earth_light": "#b08247",
    "earth_glint": "#c29a58",
}


def blank():
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))


def poly(d, points, color):
    d.polygon(points, fill=P.get(color, color))


def blade(d, pts, light, vein):
    poly(d, pts, "outline")
    poly(d, light, "leaf")
    d.line(vein, fill=P["leaf_light"], width=1)


def foliage(d, mature=False):
    # Stepped silhouettes, filled directly on the native pixel grid.
    blade(
        d,
        [
            (15, 22),
            (10, 20),
            (7, 17),
            (5, 12),
            (6, 9),
            (9, 10),
            (11, 13),
            (13, 16),
            (16, 19),
        ],
        [(14, 20), (10, 18), (8, 15), (7, 11), (9, 12), (11, 15)],
        [(8, 12), (10, 16), (15, 21)],
    )
    blade(
        d,
        [
            (16, 22),
            (18, 17),
            (22, 13),
            (25, 12),
            (27, 14),
            (26, 18),
            (22, 21),
            (18, 23),
        ],
        [(18, 21), (21, 17), (25, 14), (25, 17), (22, 20)],
        [(19, 21), (23, 18), (25, 15)],
    )
    blade(
        d,
        [(15, 21), (12, 16), (11, 11), (12, 7), (14, 6), (17, 10), (18, 15), (17, 20)],
        [(15, 19), (13, 15), (13, 9), (15, 10), (16, 14)],
        [(14, 9), (15, 14), (16, 20)],
    )
    blade(
        d,
        [(17, 21), (16, 15), (17, 10), (20, 6), (22, 7), (23, 11), (21, 15), (19, 19)],
        [(18, 19), (18, 13), (20, 9), (21, 8), (21, 12)],
        [(20, 9), (19, 14), (18, 20)],
    )
    if mature:
        blade(
            d,
            [
                (15, 16),
                (13, 10),
                (13, 5),
                (15, 2),
                (17, 3),
                (19, 7),
                (18, 12),
                (17, 17),
            ],
            [(15, 13), (14, 8), (15, 4), (16, 4), (17, 8)],
            [(15, 5), (16, 10), (16, 16)],
        )
        d.point((15, 4), fill=P["leaf_glint"])
    d.line([(16, 18), (16, 25)], fill=P["leaf_dark"], width=2)
    d.line([(16, 19), (16, 24)], fill=P["leaf_light"], width=1)


def crop(stage):
    im = blank()
    d = ImageDraw.Draw(im)
    if stage == "seeds":
        for x, y in [(11, 25), (17, 23), (21, 26)]:
            poly(
                d,
                [(x, y), (x + 2, y - 1), (x + 3, y), (x + 2, y + 2), (x, y + 2)],
                "#644128",
            )
            d.line([(x + 1, y), (x + 2, y)], fill="#d8b166")
    elif stage == "sprout":
        d.line([(16, 21), (16, 27)], fill=P["outline"], width=2)
        d.line([(16, 22), (16, 26)], fill=P["leaf_light"])
        blade(
            d,
            [(16, 23), (12, 23), (9, 20), (8, 17), (11, 17), (15, 19)],
            [(14, 22), (11, 20), (10, 18), (12, 19)],
            [(11, 19), (14, 21)],
        )
        blade(
            d,
            [(16, 23), (17, 19), (21, 16), (24, 16), (23, 20), (20, 23)],
            [(18, 21), (19, 19), (22, 17), (22, 19), (20, 21)],
            [(19, 21), (22, 18)],
        )
    elif stage == "young":
        foliage(d)
        d.line([(16, 23), (16, 27)], fill=P["leaf_dark"], width=2)
        d.point((16, 25), fill=P["leaf_light"])
    elif stage in ("mature", "harvest"):
        foliage(d, mature=True)
        poly(
            d,
            [
                (12, 21),
                (18, 20),
                (21, 22),
                (23, 25),
                (22, 28),
                (19, 30),
                (17, 30),
                (16, 31),
                (15, 30),
                (12, 29),
                (10, 27),
                (10, 24),
            ],
            "root_outline",
        )
        poly(
            d,
            [
                (12, 23),
                (15, 22),
                (19, 22),
                (21, 24),
                (21, 27),
                (18, 29),
                (15, 29),
                (12, 27),
                (11, 25),
            ],
            "root_shadow",
        )
        poly(
            d,
            [
                (12, 23),
                (15, 22),
                (18, 22),
                (20, 24),
                (19, 27),
                (16, 28),
                (13, 27),
                (12, 26),
            ],
            "root",
        )
        d.line([(13, 23), (16, 23)], fill=P["root_light"], width=1)
        d.line([(12, 24), (12, 25)], fill=P["root_light"], width=1)
        d.point((14, 27), fill=P["root_light"])
        d.line([(16, 20), (16, 23)], fill=P["leaf_dark"], width=2)
        d.point((16, 21), fill=P["leaf_light"])
        if stage == "mature":
            # Shared baseline; bulb settles into the soil, without a baked soil background.
            shifted = blank()
            shifted.alpha_composite(im, (0, -2))
            im = shifted
    return im


def watering_can():
    im = blank()
    d = ImageDraw.Draw(im)
    d.arc((17, 9, 29, 24), -100, 100, fill="#354a49", width=3)
    d.arc((18, 10, 28, 23), -100, 100, fill="#91a6a0", width=1)
    poly(d, [(10, 17), (4, 11), (2, 12), (3, 16), (9, 24), (12, 24)], "#354a49")
    poly(d, [(10, 19), (5, 14), (5, 16), (10, 22)], "#9bb2ad")
    poly(
        d,
        [(10, 12), (20, 12), (23, 16), (23, 26), (20, 28), (11, 28), (8, 25), (8, 17)],
        "#354a49",
    )
    poly(
        d,
        [
            (11, 15),
            (19, 14),
            (21, 17),
            (21, 25),
            (18, 26),
            (11, 26),
            (10, 24),
            (10, 17),
        ],
        "#668a86",
    )
    poly(d, [(11, 16), (14, 15), (14, 25), (11, 24)], "#a6bbb1")
    d.line([(16, 16), (19, 16)], fill="#c4cdb7")
    d.ellipse((9, 11, 22, 16), fill="#354a49")
    d.ellipse((11, 12, 20, 14), fill="#8ba49a")
    d.line([(13, 13), (18, 13)], fill="#354a49")
    return im

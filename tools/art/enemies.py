"""Mine monsters: a two-frame sheet each (idle, move), drawn pixel by pixel."""

from PIL import Image, ImageDraw

OUTLINE = "#241a22"


def outlined(im, color=OUTLINE):
    """A one-pixel outline around every opaque pixel."""
    out = Image.new("RGBA", im.size)
    src = im.load()
    dst = out.load()
    for y in range(im.height):
        for x in range(im.width):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < im.width and 0 <= ny < im.height and src[nx, ny][3] > 0:
                    dst[x, y] = tuple(int(color[i : i + 2], 16) for i in (1, 3, 5)) + (255,)
                    break
    out.alpha_composite(im)
    return out


def slime(frame):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    squash = 3 if frame else 0
    top = 10 + squash
    d.ellipse((4 - squash, top, 28 + squash, 28), fill="#3f9a58")
    d.ellipse((6 - squash, top + 1, 26 + squash, 27), fill="#6ad08a")
    d.ellipse((9, top + 3, 17, top + 9), fill="#c8f4c8")
    d.rectangle((10, top + 8, 12, top + 12), fill="#1c2a22")
    d.rectangle((19, top + 8, 21, top + 12), fill="#1c2a22")
    d.point((10, top + 8), fill="#ffffff")
    d.point((19, top + 8), fill="#ffffff")
    d.line((13, top + 15, 18, top + 15), fill="#2a6a3e")
    d.ellipse((24, 22, 28, 26), fill="#a8f0b8")
    return outlined(im)


def bat(frame):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    up = frame == 0
    wing_y = 8 if up else 18
    d.polygon([(16, 16), (3, wing_y), (6, wing_y + 8), (11, wing_y + 5), (16, 20)], fill="#5a4a6a")
    d.polygon(
        [(16, 16), (29, wing_y), (26, wing_y + 8), (21, wing_y + 5), (16, 20)], fill="#5a4a6a"
    )
    d.polygon([(16, 16), (6, wing_y + 2), (9, wing_y + 6), (14, 19)], fill="#8a78a0")
    d.polygon([(16, 16), (26, wing_y + 2), (23, wing_y + 6), (18, 19)], fill="#8a78a0")
    d.ellipse((11, 13, 21, 24), fill="#3a2e48")
    d.polygon([(11, 14), (9, 9), (14, 12)], fill="#3a2e48")
    d.polygon([(21, 14), (23, 9), (18, 12)], fill="#3a2e48")
    d.rectangle((13, 17, 14, 18), fill="#ff6a5a")
    d.rectangle((18, 17, 19, 18), fill="#ff6a5a")
    d.point((15, 21), fill="#ffffff")
    d.point((17, 21), fill="#ffffff")
    return outlined(im)


def golem(frame):
    im = Image.new("RGBA", (32, 32))
    d = ImageDraw.Draw(im)
    step = 1 if frame else 0
    d.rectangle((9, 24 - step, 14, 30), fill="#5a5660")
    d.rectangle((18, 24 + step - 1, 23, 30), fill="#5a5660")
    d.rectangle((7, 10, 25, 25), fill="#7a7684")
    d.rectangle((9, 12, 23, 24), fill="#9a96a4")
    d.rectangle((9, 12, 23, 14), fill="#b8b4c4")
    d.rectangle((3, 12 + step, 8, 22), fill="#7a7684")
    d.rectangle((24, 12 - step + 1, 29, 22), fill="#7a7684")
    d.rectangle((11, 3, 21, 11), fill="#8a8694")
    d.rectangle((13, 6, 15, 8), fill="#ffb04a")
    d.rectangle((17, 6, 19, 8), fill="#ffb04a")
    d.ellipse((13, 16, 19, 22), fill="#e8a04a")
    d.ellipse((14, 17, 18, 21), fill="#fff0a8")
    return outlined(im)


def statue(frame):
    im = Image.new("RGBA", (64, 64))
    d = ImageDraw.Draw(im)
    step = 2 if frame else 0
    d.rectangle((16, 48 - step, 28, 62), fill="#4a4652")
    d.rectangle((36, 48 + step - 2, 48, 62), fill="#4a4652")
    d.rectangle((10, 20, 54, 50), fill="#6a6674")
    d.rectangle((14, 24, 50, 48), fill="#8a869a")
    d.rectangle((14, 24, 50, 28), fill="#aaa6ba")
    d.rectangle((2, 24 + step, 12, 46), fill="#6a6674")
    d.rectangle((52, 24 - step + 2, 62, 46), fill="#6a6674")
    d.rectangle((4, 26 + step, 10, 44), fill="#8a869a")
    d.rectangle((54, 26 - step + 2, 60, 44), fill="#8a869a")
    d.rectangle((20, 4, 44, 22), fill="#7a768a")
    d.rectangle((22, 6, 42, 20), fill="#9a96aa")
    d.polygon([(32, 0), (38, 6), (26, 6)], fill="#c8a04a")
    d.rectangle((25, 11, 29, 15), fill="#ffd060")
    d.rectangle((35, 11, 39, 15), fill="#ffd060")
    d.ellipse((24, 30, 40, 46), fill="#a8602a")
    d.ellipse((26, 32, 38, 44), fill="#f0c060")
    d.ellipse((29, 35, 35, 41), fill="#fff2b8")
    for x in (18, 30, 44):
        d.line((x, 26, x + 3, 36), fill="#5a5666")
    return outlined(im)


MAKERS = {"slime": slime, "bat": bat, "golem": golem, "statue": statue}


def build_enemies(output):
    for kind, make in MAKERS.items():
        first = make(0)
        sheet = Image.new("RGBA", (first.width * 2, first.height))
        sheet.alpha_composite(first, (0, 0))
        sheet.alpha_composite(make(1), (first.width, 0))
        sheet.save(output / ("enemy_%s.png" % kind))

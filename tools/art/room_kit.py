"""Interior construction kit on the art grid: floors, wall faces, wall tops and the shading between them.

Rooms are built like a tile map, not painted: floor tiles run continuously under every room, each
north-facing wall is a two-cell face (crown moulding, wallpaper, chair rail, wainscot, skirting),
every other wall is seen from above as a wall top, and the floor next to a wall is shaded. All
pieces are drawn at 16 x 16 art pixels per map cell with fixed colours; room_backgrounds.py snaps
the finished picture to the world palette, so the kit shares colours with every other asset.
"""

import random
from PIL import Image

CELL = 16  # art pixels per map cell
VOID = (24, 40, 42)
SHADOW = (30, 24, 28)

FLOORS = {
    "wood": {
        "planks": [(228, 186, 132), (222, 180, 126), (232, 192, 138), (218, 176, 122)],
        "gap": (188, 138, 92),
        "light": (236, 198, 146),
    },
    "stone": {
        "planks": [(206, 200, 186), (196, 190, 176), (214, 208, 194), (200, 194, 180)],
        "gap": (150, 144, 132),
        "light": (226, 220, 206),
    },
}
# Wall face colours: crown, light crown, wallpaper, wallpaper pattern, rail, wainscot boards, gaps, skirting.
WALLS = {
    "wood": {
        "crown": (92, 60, 38),
        "crown_light": (200, 142, 88),
        "paper": (150, 166, 122),
        "paper_dark": (128, 144, 102),
        "pattern": (166, 182, 138),
        "rail": (208, 152, 94),
        "rail_dark": (142, 94, 58),
        "boards": [(168, 108, 64), (158, 98, 58)],
        "board_gap": (118, 76, 46),
        "skirt": (200, 140, 86),
        "skirt_dark": (96, 62, 38),
    },
    "stone": {
        "crown": (84, 76, 70),
        "crown_light": (190, 182, 168),
        "paper": (216, 208, 192),
        "paper_dark": (192, 184, 168),
        "pattern": (206, 198, 182),
        "rail": (196, 188, 172),
        "rail_dark": (132, 124, 112),
        "boards": [(168, 162, 150), (156, 150, 138)],
        "board_gap": (112, 106, 96),
        "skirt": (190, 182, 168),
        "skirt_dark": (84, 76, 70),
    },
}
CAP = {
    "wood": {
        "base": (186, 122, 72),
        "light": (222, 162, 104),
        "dark": (98, 62, 38),
        "mid": (156, 98, 58),
    },
    "stone": {
        "base": (168, 160, 148),
        "light": (206, 198, 184),
        "dark": (84, 76, 70),
        "mid": (140, 132, 122),
    },
}


def floor_pixel(material: str, x: int, y: int) -> tuple[int, int, int]:
    """One floor pixel at global art coordinates, so neighbouring rooms continue the same boards."""
    spec = FLOORS[material]
    if material == "wood":
        # Vertical boards 8 px wide with butt joints every 24..48 px and a faint grain.
        board, along = x // 8, y
        seed = random.Random(board * 7919)
        offset = seed.randrange(48)
        length = 24 + seed.randrange(3) * 12
        segment = (along + offset) // length
        tone = random.Random(board * 131 + segment * 17).randrange(4)
        if x % 8 == 0:
            return spec["gap"]
        if (along + offset) % length == 0:
            return spec["gap"]
        if (along + offset) % length == 1:
            return spec["light"]
        grain = random.Random(x * 31 + y * 57 + board).randrange(90)
        colour = spec["planks"][tone]
        if grain == 0 and x % 8 > 2:
            return spec["gap"]
        if x % 8 == 1:
            return spec["light"] if tone % 2 else colour
        return colour
    # Stone: 16 x 8 slabs laid in offset courses.
    course = y // 8
    shift = 8 if course % 2 else 0
    column = (x + shift) // 16
    tone = random.Random(course * 101 + column * 13).randrange(4)
    if y % 8 == 0 or (x + shift) % 16 == 0:
        return spec["gap"]
    if y % 8 == 1:
        return spec["light"]
    return spec["planks"][tone]


def face_pixel(material: str, x: int, row: int) -> tuple[int, int, int]:
    """One pixel of a north wall face; row 0..31 counts down from the top of the two-cell face."""
    w = WALLS[material]
    if row == 0:
        return w["crown"]
    if row == 1:
        return w["crown_light"]
    if row == 2:
        return w["crown"]
    if row <= 5:
        return w["paper_dark"]
    if row <= 19:
        if (x % 8 == 3 and row % 8 == 4) or (x % 8 == 7 and row % 8 == 0):
            return w["pattern"]
        return w["paper"]
    if row == 20:
        return w["rail"]
    if row == 21:
        return w["rail_dark"]
    if row <= 29:
        if x % 4 == 0:
            return w["board_gap"]
        return w["boards"][(x // 4) % 2]
    if row == 30:
        return w["skirt"]
    return w["skirt_dark"]


def cap_pixel(
    material: str, x: int, y: int, open_n: bool, open_s: bool, open_w: bool, open_e: bool
):
    """One pixel of a wall top. `open_*` say which sides border the dark void."""
    c = CAP[material]
    if open_n and y == 0:
        return c["dark"]
    if open_n and y == 1:
        return c["light"]
    if open_s and y == CELL - 1:
        return c["dark"]
    if open_s and y == CELL - 2:
        return c["mid"]
    if open_w and x == 0:
        return c["dark"]
    if open_w and x == 1:
        return c["light"]
    if open_e and x == CELL - 1:
        return c["dark"]
    if open_e and x == CELL - 2:
        return c["mid"]
    # Sparse specks instead of a repeating diagonal, so long walls do not read as hatching.
    return c["mid"] if random.Random(x * 73 + y * 151).randrange(9) == 0 else c["base"]


def shade(under: tuple[int, int, int], strength: int) -> tuple[int, int, int]:
    """Darken a colour towards the wall shadow tint; strength 0..100."""
    return tuple(round(u + (s - u) * strength / 100) for u, s in zip(under, SHADOW))


def blank(width: int, height: int) -> Image.Image:
    return Image.new("RGB", (width * CELL, height * CELL), VOID)

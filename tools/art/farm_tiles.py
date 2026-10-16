"""Farm tile kit: terrain atlas, decoration atlas, object sprites and their Tiled tilesets.

    python tools/art/farm_tiles.py

Sources are committed and need no network: the image-model textures and sheets in
assets/library/maps/farm/kit/ (tools/art/ai_farm_kit.py) and the cottage, well and shipping chest
cut from the approved concept (scene.png with the polygons in cutouts.json).

Ground textures are reduced to the art grid, made seamless along a minimum-error seam (no blending)
and reduced to the world palette. Each terrain layer is one continuous field: the four corner cells
of a tile blend with smoothstep weights and a periodic noise moves the boundary, and both sides of
every tile border evaluate the same field, so transitions are organic and never show a seam.
"""

from math import ceil, hypot
from pathlib import Path
import json
import random
import sys
import xml.etree.ElementTree as ET

from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from art import finish  # noqa: E402
from art import imagegen as g  # noqa: E402
from world import farm_atlas as atlas  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "assets/library/maps/farm"
KIT = LIBRARY / "kit"
ART = ROOT / "assets/art"
MAPS = ROOT / "tools/world/maps"
T = atlas.TILE
PERIOD = atlas.BLOCK * T
SOURCE = 160  # every kit texture is read at the same art-grid scale
OVERLAP = 16
LIGHT = (0.45, 0.89)  # direction the light travels: from the upper left, mostly downwards

# sheet -> (grid rows, source pixels per art pixel, sprite names in reading order)
SHEETS = {
    "trees": (2, 4.2, [f"tree_{i}" for i in range(6)]),
    "waterside": (
        3,
        7.0,
        [
            "reeds_tall",
            "reeds_small",
            "reeds_wide",
            "lilypads",
            "lily_flower",
            "rock_small",
            "rock_large",
            "rocks_pair",
            "stump",
            "log",
            "shrub",
            "shrub_blossom",
        ],
    ),
    "walls": (
        3,
        6.0,
        [
            "wall_2",
            "wall_3",
            "wall_4",
            "wall_5",
            "wall_end",
            "stone_pile",
            "wall_v_short",
            "wall_v_long",
        ],
    ),
    "yard": (
        2,
        7.5,
        [
            "barrel",
            "firewood",
            "pot_red",
            "pot_white",
            "bench",
            "mailbox",
            "planter",
            "stepping_stones",
            "hay",
            "bucket",
        ],
    ),
    "flora": (
        3,
        16.0,
        [
            "daisy",
            "buttercup",
            "forgetmenot",
            "poppy",
            "dandelion",
            "tuft_short",
            "tuft_tall",
            "tuft_seed",
            "pebbles",
            "mushrooms",
            "fern",
            "clover",
        ],
    ),
}
SCALE = {"bucket": 0.65, "pot_red": 0.85, "pot_white": 0.85, "bench": 1.25}
DECALS = SHEETS["flora"][2] + ["stepping_stones"]
OPEN = {"reeds_tall", "reeds_small", "reeds_wide", "lilypads", "lily_flower"}  # no footprint
BAND = {"wall_2", "wall_3", "wall_4", "wall_5", "wall_end", "wall_v_short", "wall_v_long", "log"}
PALETTE = 128
MIRRORED = {"tree_0", "tree_1", "tree_2", "tree_3", "tree_4", "tree_5", "shrub", "shrub_blossom"}
CHOPPABLE = "tree_1"
CONCEPT = {"house": (256, 224), "well": (64, 80), "shipping": (48, 64)}
CONCEPT_BLOCK = {"house": (-3, -2, 7, 2), "well": (-1, -1, 2, 2), "shipping": (0, 0, 1, 1)}
DEBRIS = [("weeds", 3), ("branch", 3), ("rock", 3)]
MARKERS = [
    ("forest", "#2f5236", "#4f7a45"),
    ("path", "#c09a62", "#e0c48e"),
    ("water", "#3d8590", "#7cc0bb"),
]


# ------------------------------------------------------------------------------------- textures


def seamless(name: str, colors: int, keep: float) -> list[list[tuple]]:
    """A kit texture as a PERIOD x PERIOD seamless art-grid tile, rows of RGB tuples."""
    src = Image.open(KIT / f"{name}.png").convert("RGB").resize((SOURCE, SOURCE), Image.BOX)
    size = PERIOD + OVERLAP
    offsets = [
        (x, y) for x in range(0, SOURCE - size + 1, 2) for y in range(0, SOURCE - size + 1, 2)
    ]
    x, y = min(offsets, key=lambda o: wrap_cost(src.crop((*o, o[0] + size, o[1] + size))))
    tile = reduce(quilt(flatten(src.crop((x, y, x + size, y + size)), keep)), colors)
    px = tile.load()
    return [[px[x, y] for x in range(PERIOD)] for y in range(PERIOD)]


def wrap_cost(im: Image.Image) -> float:
    w = h = PERIOD
    a = ImageChops.difference(
        im.crop((0, 0, OVERLAP, im.height)), im.crop((w, 0, w + OVERLAP, im.height))
    )
    b = ImageChops.difference(
        im.crop((0, 0, im.width, OVERLAP)), im.crop((0, h, im.width, h + OVERLAP))
    )
    return sum(
        sum(c)
        for c in (
            a.resize((1, 1), Image.BOX).getpixel((0, 0)),
            b.resize((1, 1), Image.BOX).getpixel((0, 0)),
        )
    )


def flatten(im: Image.Image, keep: float) -> Image.Image:
    """Remove most of the broad light and dark patches; small detail stays untouched."""
    low = im.filter(ImageFilter.GaussianBlur(14))
    mean = im.resize((1, 1), Image.BOX).getpixel((0, 0))
    offset = ImageChops.subtract(Image.new("RGB", im.size, mean), low, 1.0, 128)
    offset = offset.point(lambda v: 128 + round((v - 128) * (1 - keep)))
    return ImageChops.add(im, offset, 1.0, -128)


def seam(cost: list[list[float]]) -> list[int]:
    """Minimum-cost path through `cost` rows, one column per row, moving at most one column."""
    acc = [row[:] for row in cost]
    back = [[0] * len(cost[0]) for _ in cost]
    for y in range(1, len(cost)):
        for x in range(len(cost[0])):
            best, at = min((acc[y - 1][k], k) for k in (x - 1, x, x + 1) if 0 <= k < len(cost[0]))
            acc[y][x] += best
            back[y][x] = at
    x = min(range(len(cost[0])), key=lambda k: acc[-1][k])
    path = [0] * len(cost)
    for y in range(len(cost) - 1, -1, -1):
        path[y] = x
        x = back[y][x]
    return path


def quilt(im: Image.Image) -> Image.Image:
    """(PERIOD + OVERLAP)^2 -> PERIOD^2 that wraps: the first columns and rows switch from the
    continuation of the far edge to the original picture along the seam where both agree best."""
    px = im.load()

    def diff(a, b):
        return sum((p - q) ** 2 for p, q in zip(a, b))

    cut = seam(
        [[diff(px[x, y], px[x + PERIOD, y]) for x in range(OVERLAP)] for y in range(im.height)]
    )
    wide = im.crop((0, 0, PERIOD, im.height))
    wp = wide.load()
    for y in range(im.height):
        for x in range(cut[y]):
            wp[x, y] = px[x + PERIOD, y]
    cut = seam([[diff(wp[x, y], wp[x, y + PERIOD]) for y in range(OVERLAP)] for x in range(PERIOD)])
    out = wide.crop((0, 0, PERIOD, PERIOD))
    op = out.load()
    for x in range(PERIOD):
        for y in range(cut[x]):
            op[x, y] = wp[x, y + PERIOD]
    return out


def reduce(tile: Image.Image, colors: int) -> Image.Image:
    """The tile's own few tones (median cut), no dithering."""
    reduced = tile.quantize(
        colors=colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE
    )
    return reduced.convert("RGB")


class Field:
    """Periodic value noise on the PERIOD x PERIOD art-pixel torus, centred on zero, with its
    gradient; evaluated at pixel centres, so every tile reads the same values at its borders."""

    def __init__(self, seed: int, octaves: list[tuple[int, float]]):
        rng = random.Random(seed)
        self.v = [[0.0] * PERIOD for _ in range(PERIOD)]
        for cell, weight in octaves:
            n = PERIOD // cell
            grid = [[rng.random() * 2 - 1 for _ in range(n)] for _ in range(n)]
            for y in range(PERIOD):
                gy = (y + 0.5) / cell
                iy, fy = int(gy), gy - int(gy)
                sy = fy * fy * (3 - 2 * fy)
                for x in range(PERIOD):
                    gx = (x + 0.5) / cell
                    ix, fx = int(gx), gx - int(gx)
                    sx = fx * fx * (3 - 2 * fx)
                    a, b = grid[iy % n][ix % n], grid[iy % n][(ix + 1) % n]
                    c, d = grid[(iy + 1) % n][ix % n], grid[(iy + 1) % n][(ix + 1) % n]
                    self.v[y][x] += weight * (
                        a + (b - a) * sx + (c - a) * sy + (a - b - c + d) * sx * sy
                    )
        v = self.v
        self.gx = [
            [(v[y][(x + 1) % PERIOD] - v[y][x - 1]) / 2 for x in range(PERIOD)]
            for y in range(PERIOD)
        ]
        self.gy = [
            [(v[(y + 1) % PERIOD][x] - v[y - 1][x]) / 2 for x in range(PERIOD)]
            for y in range(PERIOD)
        ]


def scatter(seed: int) -> list[list[float]]:
    rng = random.Random(seed)
    return [[rng.random() for _ in range(PERIOD)] for _ in range(PERIOD)]


def shade(rgb: tuple, k: float, warm: tuple = (1.0, 1.0, 1.0)) -> tuple:
    return tuple(min(255, round(c * k * w)) for c, w in zip(rgb, warm))


def smooth(t: float) -> float:
    return t * t * (3 - 2 * t)


def corner_field(mask: int, px: int, py: int) -> tuple[float, float, float]:
    """Smoothstep blend of the four corner cells and its gradient per art pixel. On a tile border
    it depends only on that border's two corners and its normal derivative is zero."""
    tl, tr, bl, br = atlas.corners(mask)
    u, v = (px + 0.5) / T, (py + 0.5) / T
    su, sv = smooth(u), smooth(v)
    top, bottom = tl + (tr - tl) * su, bl + (br - bl) * su
    du = 6 * u * (1 - u) * ((tr - tl) * (1 - sv) + (br - bl) * sv) / T
    dv = 6 * v * (1 - v) * (bottom - top) / T
    return top + (bottom - top) * sv, du, dv


class Kit:
    """Textures, noise fields and scatter tables shared by every terrain tile."""

    def __init__(self):
        self.grass = seamless("grass", 9, 0.35)
        self.forest = seamless("forest", 9, 0.45)
        self.dirt = seamless("dirt", 8, 0.3)
        self.water = seamless("water", 7, 0.25)
        octaves = [(64, 0.34), (32, 0.32), (16, 0.2), (8, 0.1), (4, 0.04)]
        self.edges = {
            name: Field(seed, octaves) for name, seed in (("ground", 3), ("paths", 5), ("shore", 7))
        }
        self.amount = {"ground": 0.46, "paths": 0.3, "shore": 0.34}
        self.grain = [scatter(seed) for seed in (11, 13, 17)]
        rng = random.Random(19)
        self.sparkles = []
        for _ in range(64):
            length = rng.choice((2, 3, 3, 4))
            tx, ty = rng.randrange(atlas.BLOCK), rng.randrange(atlas.BLOCK)
            x, y = rng.randrange(1, T - length - 2), rng.randrange(1, T - 1)
            self.sparkles.append((tx * T + x, ty * T + y, length, rng.randrange(atlas.FRAMES)))

    def field(self, layer: str, mask: int, X: int, Y: int, px: int, py: int):
        """Signed distance in art pixels from the layer's boundary (positive inside) and the unit normal."""
        f, du, dv = corner_field(mask, px, py)
        noise, k = self.edges[layer], self.amount[layer]
        value = f + k * noise.v[Y][X]
        gx, gy = du + k * noise.gx[Y][X], dv + k * noise.gy[Y][X]
        length = max(hypot(gx, gy), 0.02)
        return (value - 0.5) / length, gx / length, gy / length

    def tile(self, painter, mask: int, bx: int, by: int) -> Image.Image:
        pixels = []
        for py in range(T):
            for px in range(T):
                X, Y = bx * T + px, by * T + py
                pixels.append(painter(mask, X, Y, px, py))
        im = Image.new("RGBA", (T, T))
        im.putdata(pixels)
        return im

    def ground(self, mask, X, Y, px, py):
        dist, _, _ = self.field("ground", mask, X, Y, px, py)
        if dist > 0:
            return self.forest[Y][X] + (255,)
        rough = self.grain[0][Y][X]
        # The woodland's shade spills onto the meadow in two ragged steps.
        if dist > -1.2 - rough:
            return shade(self.grass[Y][X], 0.72) + (255,)
        if dist > -3.4 - 2 * rough:
            return shade(self.grass[Y][X], 0.86) + (255,)
        return self.grass[Y][X] + (255,)

    def paths(self, mask, X, Y, px, py):
        dist, nx, ny = self.field("paths", mask, X, Y, px, py)
        if dist > 0:
            lit = max(0.0, nx * LIGHT[0] + ny * LIGHT[1])
            if dist < 2.2 and self.grain[1][Y][X] > 0.74 + dist * 0.08:
                return shade(self.grass[Y][X], 0.9) + (255,)  # blades leaning over the earth
            if dist < 0.9:
                return shade(self.dirt[Y][X], 0.8) + (255,)
            if dist < 0.9 + 2.4 * lit:
                return shade(self.dirt[Y][X], 0.88) + (255,)  # the meadow's lip shades the lane
            return self.dirt[Y][X] + (255,)
        if dist > -0.8:
            return shade(self.grass[Y][X], 0.7) + (255,)
        if dist > -1.7:
            return shade(self.grass[Y][X], 0.83) + (255,)
        return (0, 0, 0, 0)

    def shore(self, mask, X, Y, px, py):
        dist, _, ny = self.field("shore", mask, X, Y, px, py)
        face = 1.0 + 3.2 * max(0.0, ny)  # the far bank shows its earth face, the near one barely
        rough = self.grain[2][Y][X]
        if dist < -2.6:
            return (0, 0, 0, 0)
        if dist <= 0:
            if dist < -1.5 and rough > 0.42:
                return shade(self.grass[Y][X], 0.78) + (255,)
            return shade(self.dirt[Y][X], 0.9, (1.0, 0.88, 0.74)) + (255,)
        if dist <= face:
            k = 0.42 if dist > face - 1 else (0.55 if self.grain[1][0][X] > 0.7 else 0.63)
            return shade(self.dirt[Y][X], k, (1.0, 0.86, 0.72)) + (255,)
        if dist <= face + 1.4:
            return shade(self.water[Y][X], 0.74) + (255,)
        if dist <= face + 3.0:
            return shade(self.water[Y][X], 0.87) + (255,)
        return self.water[Y][X] + (255,)

    def water_frame(self, frame: int, bx: int, by: int) -> Image.Image:
        im = Image.new("RGBA", (T, T))
        im.putdata(
            [self.water[by * T + y][bx * T + x] + (255,) for y in range(T) for x in range(T)]
        )
        d = ImageDraw.Draw(im)
        for sx, sy, length, phase in self.sparkles:
            if sx // T != bx or sy // T != by:
                continue
            step = (frame + phase) % atlas.FRAMES
            if step == 0:
                continue
            x, y = sx - bx * T, sy - by * T
            if step == 2:
                d.line((x, y, x + length - 1, y), fill=(198, 232, 222, 255))
            else:
                light = shade(self.water[sy][sx], 1.28) + (255,)
                start = x + (1 if step == 3 else 0)
                d.line((start, y, start + length - 2, y), fill=light)
        return im


def build_atlas(kit: Kit) -> Image.Image:
    """Every terrain tile at art scale, before the farm palette."""
    im = Image.new("RGBA", (atlas.COLUMNS * T, atlas.ROWS * T))

    def put(index, tile):
        im.paste(tile, ((index % atlas.COLUMNS) * T, (index // atlas.COLUMNS) * T))

    sections = [
        ("ground", kit.ground, range(16)),
        ("paths", kit.paths, range(1, 16)),
        ("shore", kit.shore, range(1, 15)),
    ]
    for section, painter, masks in sections:
        for mask in masks:
            for by in range(atlas.BLOCK):
                for bx in range(atlas.BLOCK):
                    put(atlas.index(section, mask, bx, by), kit.tile(painter, mask, bx, by))
    for frame in range(atlas.FRAMES):
        for by in range(atlas.BLOCK):
            for bx in range(atlas.BLOCK):
                put(atlas.water(bx, by) + frame * atlas.BLOCK, kit.water_frame(frame, bx, by))
    return im


# -------------------------------------------------------------------------------------- sprites


def components(im: Image.Image, rows: int, count: int) -> list[Image.Image]:
    """Separate sprites of a keyed sheet in reading order (row bands split at the widest gaps)."""
    step = 4
    mask = im.getchannel("A").point(lambda a: 255 if a > 24 else 0)
    small = mask.resize((im.width // step, im.height // step), Image.BOX).point(
        lambda a: 255 if a else 0
    )
    small = small.filter(ImageFilter.MaxFilter(5))
    w, h = small.size
    px = small.load()
    seen: set = set()
    boxes = []
    for y in range(h):
        for x in range(w):
            if not px[x, y] or (x, y) in seen:
                continue
            stack, box, area = [(x, y)], [x, y, x, y], 0
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                area += 1
                box = [min(box[0], cx), min(box[1], cy), max(box[2], cx), max(box[3], cy)]
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if area >= 40:
                boxes.append(
                    [box[0] * step, box[1] * step, (box[2] + 1) * step, (box[3] + 1) * step]
                )
    if len(boxes) != count:
        raise RuntimeError(f"expected {count} sprites, found {len(boxes)}")
    boxes.sort(key=lambda b: b[1] + b[3])
    centres = [(b[1] + b[3]) / 2 for b in boxes]
    gaps = (
        sorted(range(1, count), key=lambda i: centres[i] - centres[i - 1])[-(rows - 1) :]
        if rows > 1
        else []
    )
    ordered, start = [], 0
    for end in sorted(gaps) + [count]:
        ordered += sorted(boxes[start:end], key=lambda b: b[0])
        start = end
    return [im.crop(b).crop(im.crop(b).getchannel("A").getbbox()) for b in ordered]


def art_sprite(part: Image.Image, ratio: float) -> Image.Image:
    size = (max(2, round(part.width / ratio)), max(2, round(part.height / ratio)))
    return part.resize(size, Image.BOX)


def standing(art: Image.Image, shadow: str | None, pad: int = 4) -> Image.Image:
    """Bottom-centred on an even art canvas with room for the contact shadow, at game scale."""
    width = art.width + 8 + art.width % 2
    canvas = Image.new("RGBA", (width, art.height + pad))
    canvas.alpha_composite(art, ((width - art.width) // 2, 0))
    game = finish.from_art(canvas)
    return finish.shadow(game, shadow) if shadow else game


def concept_objects() -> dict[str, Image.Image]:
    """Cottage, well and shipping chest cut from the concept, at art scale on their canvases."""
    concept = Image.open(LIBRARY / "scene.png").convert("RGBA")
    polygons = json.loads((LIBRARY / "cutouts.json").read_text())
    out = {}
    for name, (w, h) in CONCEPT.items():
        mask = Image.new("L", concept.size)
        ImageDraw.Draw(mask).polygon(
            [
                (round(x * concept.width / 1536), round(y * concept.height / 1152))
                for x, y in polygons[name]
            ],
            fill=255,
        )
        sprite = concept.copy()
        sprite.putalpha(mask)
        sprite = sprite.crop(mask.getbbox())
        sprite.thumbnail((w // 2 - 2, h // 2 - 4), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (w // 2, h // 2))
        canvas.alpha_composite(sprite, ((w // 2 - sprite.width) // 2, h // 2 - 2 - sprite.height))
        out[name] = canvas
    return out


class Piece:
    """One object sprite at art scale and how it is finished and described in the tileset."""

    def __init__(self, texture, art, block, shadow=None, pad=4, canvas=False, **extra):
        self.texture, self.art, self.block = texture, art, block
        self.shadow, self.pad, self.canvas, self.extra = shadow, pad, canvas, extra

    def finished(self, palette: Image.Image) -> Image.Image:
        art = lock(self.art, palette)
        if self.canvas:
            return finish.from_art(art)
        return standing(art, self.shadow, self.pad)


def cut_sprites() -> tuple[list[Piece], dict[str, list[Image.Image]]]:
    pieces: list[Piece] = []
    decals: dict[str, list[Image.Image]] = {}
    for name, art in concept_objects().items():
        pieces.append(Piece("farm_" + name, art, list(CONCEPT_BLOCK[name]), canvas=True))
    for sheet, (rows, ratio, names) in SHEETS.items():
        keyed = g.cut_out(Image.open(KIT / f"{sheet}.png").convert("RGBA"), key_magenta=True)
        for name, part in zip(names, components(keyed, rows, len(names))):
            if name in DECALS:
                art = art_sprite(part, max(ratio, max(part.size) / 15))
                decals[name] = [decal(art, flip) for flip in (False, True)]
                continue
            art = art_sprite(part, ratio / SCALE.get(name, 1.0))
            if name == CHOPPABLE:
                # TreeProp draws its own shadow and sways the sprite around its trunk.
                pieces.append(Piece("farm_tree", art, [0, 0, 0, 0], pad=2, role="tree"))
            shadow = None if name in OPEN else ("band" if name in BAND else "ellipse")
            block = [0, 0, 0, 0] if name in OPEN else footprint(name, art)
            pieces.append(Piece("farm_" + name, art, block, shadow))
            if name in MIRRORED:
                mirrored = art.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                pieces.append(Piece("farm_" + name + "_mirror", mirrored, block, shadow))
    return pieces, decals


def farm_palette(images: list[Image.Image]) -> Image.Image:
    """One shared palette for every farm tile, decal and object: a median cut over all of them."""
    rng = random.Random(23)
    pixels: list[tuple] = []
    for im in images:
        raw = im.convert("RGBA").tobytes()
        solid = [tuple(raw[i : i + 3]) for i in range(0, len(raw), 4) if raw[i + 3] > 127]
        pixels += rng.sample(solid, min(len(solid), 6000))
    side = int(len(pixels) ** 0.5) + 1
    mosaic = Image.new("RGB", (side, side))
    mosaic.putdata(pixels + [pixels[0]] * (side * side - len(pixels)))
    return mosaic.quantize(
        colors=PALETTE, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE
    )


def lock(art: Image.Image, palette: Image.Image) -> Image.Image:
    """Farm palette and hard 0/255 alpha."""
    art = art.convert("RGBA")
    alpha = art.getchannel("A").point(lambda a: 255 if a > 127 else 0)
    out = art.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
    out.putalpha(alpha)
    return out


def footprint(name: str, art: Image.Image) -> list[int]:
    """Blocked cells [dx, dy, w, h] relative to the cell under the ground point."""
    if name.startswith("tree_"):
        return [0, 0, 1, 1]
    w = max(1, ceil(art.width / T - 0.3))
    h = max(1, round((art.height - 12) / T)) if name.startswith("wall_v") else 1
    return [-(w // 2), 1 - h, w, h]


def decal(art: Image.Image, flip: bool) -> Image.Image:
    """One 16 x 16 decoration tile; the mirrored variant also sits off centre."""
    if art.width > T or art.height > T:
        raise ValueError(f"decal {art.size} does not fit a tile")
    if flip:
        art = art.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    tile = Image.new("RGBA", (T, T))
    x = (T - art.width) // 2 + ((T - art.width) // 3 if flip else 0)
    tile.alpha_composite(art, (x, T - art.height - (2 if flip else 1)))
    return tile


# --------------------------------------------------------------------------------------- tilesets


def write(tree: ET.Element, name: str) -> None:
    ET.indent(tree)
    ET.ElementTree(tree).write(MAPS / name, encoding="UTF-8", xml_declaration=True)


def properties(parent: ET.Element, values: dict) -> None:
    node = ET.SubElement(parent, "properties")
    for key, value in values.items():
        ET.SubElement(node, "property", name=key, value=str(value))


def build_tilesets(objects: list[dict], decals: list[Image.Image], palette: Image.Image) -> None:
    markers = Image.new("RGBA", (32 * len(MARKERS), 32))
    d = ImageDraw.Draw(markers)
    for i, (_, fill, dots) in enumerate(MARKERS):
        d.rectangle((i * 32, 0, i * 32 + 31, 31), fill=fill, outline=dots)
        for k in range(6):
            d.rectangle(
                (
                    i * 32 + 5 + (k % 3) * 9,
                    7 + (k // 3) * 12,
                    i * 32 + 7 + (k % 3) * 9,
                    9 + (k // 3) * 12,
                ),
                fill=dots,
            )
    markers.save(LIBRARY / "terrain_markers.png")
    root = ET.Element(
        "tileset",
        version="1.10",
        tiledversion="1.11.2",
        name="Farm terrain",
        tilewidth="32",
        tileheight="32",
        tilecount=str(len(MARKERS)),
        columns=str(len(MARKERS)),
    )
    ET.SubElement(
        root,
        "image",
        source="../../../assets/library/maps/farm/terrain_markers.png",
        width=str(markers.width),
        height="32",
    )
    for i, (terrain, _, _) in enumerate(MARKERS):
        properties(ET.SubElement(root, "tile", id=str(i)), {"terrain": terrain})
    write(root, "farm_terrain.tsx")

    columns = 16
    sheet = Image.new("RGBA", (columns * T, ceil(len(decals) / columns) * T))
    for i, tile in enumerate(decals):
        sheet.alpha_composite(tile, ((i % columns) * T, (i // columns) * T))
    sheet = finish.from_art(lock(sheet, palette))
    sheet.save(ART / "farm_details.png")
    root = ET.Element(
        "tileset",
        version="1.10",
        tiledversion="1.11.2",
        name="Farm details",
        tilewidth="32",
        tileheight="32",
        tilecount=str(len(decals)),
        columns=str(columns),
    )
    ET.SubElement(
        root,
        "image",
        source="../../../assets/art/farm_details.png",
        width=str(sheet.width),
        height=str(sheet.height),
    )
    for i, name in enumerate(n + suffix for n in DECALS for suffix in ("", "_mirror")):
        properties(ET.SubElement(root, "tile", id=str(i)), {"name": name})
    write(root, "farm_details.tsx")

    root = ET.Element(
        "tileset",
        version="1.10",
        tiledversion="1.11.2",
        name="Farm objects",
        tilewidth=str(max(o["width"] for o in objects)),
        tileheight=str(max(o["height"] for o in objects)),
        tilecount=str(len(objects)),
        columns="0",
        objectalignment="bottomleft",
    )
    for i, o in enumerate(objects):
        node = ET.SubElement(root, "tile", id=str(i))
        # The ground point sits on the contact shadow's row: 8 game pixels above the image bottom
        # (4 for the choppable tree, whose shadow the game draws).
        values = {
            "texture": o["texture"],
            "anchor_x": o["width"] // 2,
            "anchor_y": -4 if o.get("role") == "tree" else -8,
            "height": o["height"],
        }
        if any(o["block"]):
            values["block"] = ",".join(str(v) for v in o["block"])
        for key in ("role", "kind", "variant"):
            if key in o:
                values[key] = o[key]
        properties(node, values)
        ET.SubElement(
            node,
            "image",
            source=f"../../../assets/art/{o['texture']}.png",
            width=str(o["width"]),
            height=str(o["height"]),
        )
    write(root, "farm_objects.tsx")


# ---------------------------------------------------------------------------------------- preview


def preview() -> None:
    """The compiled terrain as one picture: the map overview's base and the Tiled preview layer."""
    from world import tiled_farm

    region = tiled_farm.read()
    sources = [
        Image.open(ART / f"{s['texture']}.png").convert("RGBA") for s in region["tile_sources"]
    ]
    im = Image.new("RGBA", (region["width"] * 32, region["height"] * 32))
    for layer in region["tile_layers"]:
        source = sources[layer["source"]]
        columns = region["tile_sources"][layer["source"]]["columns"]
        for i, gid in enumerate(layer["cells"]):
            if not gid:
                continue
            x, y = ((gid - 1) % columns) * 32, ((gid - 1) // columns) * 32
            at = (
                (i % layer["width"]) * 32 + layer["offset"][0],
                (i // layer["width"]) * 32 + layer["offset"][1],
            )
            im.alpha_composite(
                source.crop((x, y, x + 32, y + 32)),
                (max(at[0], 0), max(at[1], 0)),
                (max(-at[0], 0), max(-at[1], 0)),
            )
    im.save(ART / "home_farm_background.png")


def install() -> None:
    terrain = build_atlas(Kit())
    pieces, decals = cut_sprites()
    tiles = [tile for name in DECALS for tile in decals[name]]
    palette = farm_palette([terrain] + [p.art for p in pieces] + tiles)
    finish.from_art(lock(terrain, palette)).save(ART / "farm_tiles.png")
    objects = []
    for piece in pieces:
        im = piece.finished(palette)
        im.save(ART / f"{piece.texture}.png")
        objects.append(
            dict(
                texture=piece.texture,
                width=im.width,
                height=im.height,
                block=piece.block,
                **piece.extra,
            )
        )
    for kind, count in DEBRIS:
        for variant in range(count):
            im = Image.open(ART / f"{kind}_{variant}.png")
            objects.append(
                dict(
                    texture=f"{kind}_{variant}",
                    width=im.width,
                    height=im.height,
                    block=[0, 0, 0, 0],
                    kind=kind,
                    variant=variant,
                )
            )
    build_tilesets(objects, tiles, palette)
    preview()


if __name__ == "__main__":
    install()

"""Compile the authored farm, tools/world/maps/home_farm.tmx, into the game's map data.

The TMX is the only editing source and builds never rearrange it. Its painted layers, one cell per
map cell, hold terrain markers from farm_terrain.tsx and decorations from farm_details.tsx:

  Forest   woodland floor; blocked unless a path crosses it
  Paths    earth lanes and the yard; never planted
  Water    ponds; blocked, fished from the shore
  Details  flowers, tufts, pebbles and mushrooms drawn on the ground

The three terrain layers become dual-grid tile layers (world/farm_atlas.py): Ground (meadow and
woodland floor), Water (animated open water), Shore (banks) and Paths, followed by Details.
Object layers use farm_objects.tsx: Props (scenery, its footprint read from the tile's `block`),
Trees (choppable trees), Debris (weeds, branches, rocks). Building sites, Stations, Gameplay,
Places and No planting are plain rectangles and points.
"""

from pathlib import Path
import xml.etree.ElementTree as ET

from world import farm_atlas as atlas

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "tools/world/maps/home_farm.tmx"
CELL = 32
TERRAIN = ("Forest", "Paths", "Water")
MARKER = {"Forest": "forest", "Paths": "path", "Water": "water"}


def properties(node):
    return {
        p.attrib["name"]: p.attrib.get("value", p.text or "")
        for p in node.findall("properties/property")
    }


def points():
    root = ET.parse(SOURCE).getroot()
    return {
        o.attrib["name"]: (round(float(o.attrib["x"]) / CELL), round(float(o.attrib["y"]) / CELL))
        for o in root.findall("objectgroup[@name='Gameplay']/object")
    }


def place_points():
    root = ET.parse(SOURCE).getroot()
    return {
        "home_farm/" + o.attrib["name"]: (
            round(float(o.attrib["x"]) / CELL),
            round(float(o.attrib["y"]) / CELL),
        )
        for o in root.findall("objectgroup[@name='Places']/object")
    }


def row_rects(cells, width, height):
    result = []
    for y in range(height):
        x = 0
        while x < width:
            if (x, y) not in cells:
                x += 1
                continue
            start = x
            while x < width and (x, y) in cells:
                x += 1
            result.append([start, y, x - start, 1])
    return result


def tilesets(root):
    """firstgid and tiles of every tileset the map uses, keyed by the TSX file name."""
    result = {}
    for ref in root.findall("tileset"):
        tsx = ET.parse(SOURCE.parent / ref.attrib["source"]).getroot()
        tiles = {int(t.attrib["id"]): properties(t) for t in tsx.findall("tile")}
        result[ref.attrib["source"]] = dict(
            first=int(ref.attrib["firstgid"]), count=int(tsx.attrib["tilecount"]), tiles=tiles
        )
    expected = {"farm_terrain.tsx", "farm_details.tsx", "farm_objects.tsx"}
    if set(result) != expected:
        raise ValueError(f"Farm TMX must use exactly {sorted(expected)}")
    return result


def local(gid, tileset, what):
    if gid & 0xF0000000:
        raise ValueError(f"Flipped or rotated tiles are not used on the farm: {what}")
    index = gid - tileset["first"]
    if not 0 <= index < tileset["count"]:
        raise ValueError(f"Tile {gid} is not from the expected tileset: {what}")
    return index


def dual(cells, width, height, painter):
    """One visible tile per cell corner; corners outside the map repeat the nearest edge cell."""

    def has(x, y):
        return (min(max(x, 0), width - 1), min(max(y, 0), height - 1)) in cells

    layer = []
    for vy in range(height + 1):
        for vx in range(width + 1):
            mask = has(vx - 1, vy - 1) | has(vx, vy - 1) << 1 | has(vx - 1, vy) << 2
            mask |= has(vx, vy) << 3
            layer.append(painter(mask, vx % atlas.BLOCK, vy % atlas.BLOCK))
    return dict(
        source=0, offset=[-CELL // 2, -CELL // 2], width=width + 1, height=height + 1, cells=layer
    )


def compile_terrain(terrain, details, width, height):
    def ground(mask, x, y):
        return 1 + atlas.index("ground", mask, x, y)

    def water(mask, x, y):
        return 1 + atlas.water(x, y) if mask == atlas.FULL else 0

    def shore(mask, x, y):
        return 1 + atlas.index("shore", mask, x, y) if 0 < mask < atlas.FULL else 0

    def paths(mask, x, y):
        return 1 + atlas.index("paths", mask, x, y) if mask else 0

    return [
        dict(name="Ground", **dual(terrain["Forest"], width, height, ground)),
        dict(name="Water", **dual(terrain["Water"], width, height, water)),
        dict(name="Shore", **dual(terrain["Water"], width, height, shore)),
        dict(name="Paths", **dual(terrain["Paths"], width, height, paths)),
        dict(name="Details", source=1, offset=[0, 0], width=width, height=height, cells=details),
    ]


def read():
    root = ET.parse(SOURCE).getroot()
    width, height = int(root.attrib["width"]), int(root.attrib["height"])
    if (
        root.attrib.get("orientation") != "orthogonal"
        or root.attrib.get("tilewidth") != str(CELL)
        or root.attrib.get("tileheight") != str(CELL)
    ):
        raise ValueError("Farm TMX must use orthogonal 32px cells")
    sets = tilesets(root)
    markers, decor, kit = (
        sets["farm_terrain.tsx"],
        sets["farm_details.tsx"],
        sets["farm_objects.tsx"],
    )
    layers = {}
    for layer in root.findall("layer"):
        data = layer.find("data")
        if data.attrib.get("encoding") != "csv":
            raise ValueError("Save TMX tile layers with CSV encoding")
        cells = [int(v.strip()) for v in data.text.strip().split(",")]
        if len(cells) != width * height:
            raise ValueError("Invalid farm tile layer size: " + layer.attrib["name"])
        layers[layer.attrib["name"]] = cells
    if set(layers) != set(TERRAIN) | {"Details"}:
        raise ValueError(f"Farm TMX tile layers must be {TERRAIN + ('Details',)}")
    terrain = {}
    for name in TERRAIN:
        cells = set()
        for i, gid in enumerate(layers[name]):
            if gid == 0:
                continue
            tile = markers["tiles"][local(gid, markers, name)]
            if tile["terrain"] != MARKER[name]:
                raise ValueError(
                    f"{name} layer holds a {tile['terrain']} marker at {i % width},{i // width}"
                )
            cells.add((i % width, i // width))
        terrain[name] = cells
    if terrain["Paths"] & terrain["Water"]:
        raise ValueError(f"Paths cross water at {sorted(terrain['Paths'] & terrain['Water'])[:5]}")
    details = [0 if gid == 0 else 1 + local(gid, decor, "Details") for gid in layers["Details"]]
    result = dict(
        width=width,
        height=height,
        props=[],
        trees=[],
        debris=[],
        stations=[],
        building_sites={},
        no_plant=[],
        tile_sources=[
            dict(texture="farm_tiles", columns=atlas.COLUMNS, rows=atlas.ROWS),
            dict(texture="farm_details", columns=16, rows=-(-decor["count"] // 16)),
        ],
        tile_animation=dict(source=0, **atlas.animation()),
        tile_layers=compile_terrain(terrain, details, width, height),
    )
    blocked = (terrain["Forest"] - terrain["Paths"]) | terrain["Water"]
    footprints = []
    for group in root.findall("objectgroup"):
        name = group.attrib["name"]
        for obj in group.findall("object"):
            spec = properties(obj)
            x, y = float(obj.attrib.get("x", 0)), float(obj.attrib.get("y", 0))
            what = f"{name}/{obj.attrib.get('name', obj.attrib['id'])}"
            if name in ("Props", "Trees", "Debris"):
                tile = kit["tiles"][local(int(obj.attrib["gid"]), kit, what)]
                ground = [round(x + int(tile["anchor_x"])), round(y + int(tile["anchor_y"]))]
                cell = [ground[0] // CELL, ground[1] // CELL]
                if name == "Props":
                    if tile.get("role") == "tree" or "kind" in tile:
                        raise ValueError(
                            f"{what}: choppable trees and debris have their own layers"
                        )
                    result["props"].append(
                        dict(
                            texture=tile["texture"],
                            ground=ground,
                            offset=[
                                -int(tile["anchor_x"]),
                                -int(tile["height"]) - int(tile["anchor_y"]),
                            ],
                        )
                    )
                    if "block" in tile:
                        dx, dy, w, h = (int(v) for v in tile["block"].split(","))
                        footprints.append([cell[0] + dx, cell[1] + dy, w, h])
                elif name == "Trees":
                    if tile.get("role") != "tree":
                        raise ValueError(f"{what} is not a choppable tree")
                    result["trees"].append(cell)
                else:
                    if "kind" not in tile:
                        raise ValueError(f"{what} is not debris")
                    result["debris"].append(
                        dict(
                            id=f"d_{cell[0]}_{cell[1]}",
                            kind=tile["kind"],
                            cell=cell,
                            variant=int(tile["variant"]),
                        )
                    )
            elif name in ("No planting", "Building sites"):
                rect = [
                    round(x / CELL),
                    round(y / CELL),
                    round(float(obj.attrib["width"]) / CELL),
                    round(float(obj.attrib["height"]) / CELL),
                ]
                if name == "No planting":
                    result["no_plant"].append(rect)
                else:
                    footprints.append(rect)
                    result["building_sites"][obj.attrib["name"]] = dict(
                        rect=rect,
                        door=[int(spec["door_x"]), int(spec["door_y"])],
                        texture=spec["texture"],
                        offset=[int(spec["offset_x"]), int(spec["offset_y"])],
                    )
            elif name == "Stations":
                result["stations"].append(
                    dict(
                        id=obj.attrib["name"],
                        name=spec["label"],
                        kind=spec["kind"],
                        cell=[round(x / CELL), round(y / CELL)],
                    )
                )
            elif name not in ("Gameplay", "Places"):
                raise ValueError("Unknown farm object layer: " + name)
    walk = set()
    for o in root.findall("objectgroup[@name='Gameplay']/object") + root.findall(
        "objectgroup[@name='Places']/object"
    ):
        walk.add((round(float(o.attrib["x"]) / CELL), round(float(o.attrib["y"]) / CELL)))
    covered = set()
    for rect in footprints:
        covered |= {
            (fx, fy)
            for fx in range(rect[0], rect[0] + rect[2])
            for fy in range(rect[1], rect[1] + rect[3])
        }
    stuck = sorted(walk & (blocked | covered))
    if stuck:
        raise ValueError(f"Gameplay points and places stand on blocked cells: {stuck}")
    result["paths"] = row_rects(terrain["Paths"], width, height)
    result["water_rects"] = row_rects(terrain["Water"], width, height)
    result["obstacles"] = row_rects(blocked, width, height) + footprints
    result["no_plant"] += result["paths"]
    return result

"""Read the authored Tiled map. Builds never regenerate or rearrange this source map."""

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "tools/world/maps/home_farm.tmx"


def properties(node):
    return {
        p.attrib["name"]: p.attrib.get("value", p.text or "")
        for p in node.findall("properties/property")
    }


def points():
    root = ET.parse(SOURCE).getroot()
    return {
        o.attrib["name"]: (round(float(o.attrib["x"]) / 32), round(float(o.attrib["y"]) / 32))
        for o in root.findall("objectgroup[@name='Gameplay']/object")
    }


def place_points():
    root = ET.parse(SOURCE).getroot()
    return {
        "home_farm/" + o.attrib["name"]: (
            round(float(o.attrib["x"]) / 32),
            round(float(o.attrib["y"]) / 32),
        )
        for o in root.findall("objectgroup[@name='Places']/object")
    }


def row_rects(cells, width):
    result = []
    for y in range(len(cells) // width):
        x = 0
        while x < width:
            if not cells[y * width + x]:
                x += 1
                continue
            start = x
            while x < width and cells[y * width + x]:
                x += 1
            result.append([start, y, x - start, 1])
    return result


def read():
    root = ET.parse(SOURCE).getroot()
    width, height = int(root.attrib["width"]), int(root.attrib["height"])
    if (
        root.attrib.get("orientation") != "orthogonal"
        or root.attrib.get("tilewidth") != "32"
        or root.attrib.get("tileheight") != "32"
    ):
        raise ValueError("Farm TMX must use orthogonal 32px cells")
    layers = {}
    for layer in root.findall("layer"):
        data = layer.find("data")
        if data.attrib.get("encoding") != "csv":
            raise ValueError("Save TMX tile layers with CSV encoding")
        cells = [int(v.strip()) for v in data.text.strip().split(",")]
        if len(cells) != width * height or any(v < 0 or v > 528 for v in cells):
            raise ValueError("Invalid farm tile layer: " + layer.attrib["name"])
        layers[layer.attrib["name"]] = cells
    required = ("Ground", "Water", "Shore", "Paths", "Forest collision")
    if any(name not in layers for name in required):
        raise ValueError("Farm TMX is missing a named terrain layer")
    objects = {}
    for source in root.findall("tileset"):
        first = int(source.attrib["firstgid"])
        tileset = ET.parse(SOURCE.parent / source.attrib["source"]).getroot()
        for tile in tileset.findall("tile"):
            if tile.find("image") is not None:
                objects[first + int(tile.attrib["id"])] = properties(tile)
    result = dict(
        width=width,
        height=height,
        props=[],
        trees=[],
        debris=[],
        stations=[],
        building_sites={},
        paths=row_rects(layers["Paths"], width),
        water_rects=row_rects(layers["Water"], width),
    )
    result["obstacles"] = row_rects(layers["Forest collision"], width) + result["water_rects"]
    result["no_plant"] = result["paths"].copy()
    result["tile_layers"] = [dict(name=name, cells=layers[name]) for name in required[:-1]]
    for group in root.findall("objectgroup"):
        name = group.attrib["name"]
        for obj in group.findall("object"):
            spec = properties(obj)
            x, y = float(obj.attrib.get("x", 0)), float(obj.attrib.get("y", 0))
            if name in ("Props", "Trees", "Debris"):
                tile = objects[int(obj.attrib["gid"])]
                ground = [round(x + int(tile["anchor_x"])), round(y + int(tile["anchor_y"]))]
                cell = [int(v // 32) for v in ground]
                if name == "Props":
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
                elif name == "Trees":
                    result["trees"].append(cell)
                else:
                    result["debris"].append(
                        dict(
                            id=f"d_{cell[0]}_{cell[1]}",
                            kind=tile["kind"],
                            cell=cell,
                            variant=int(tile["variant"]),
                        )
                    )
            elif name in ("Collision", "No planting", "Building sites"):
                rect = [
                    round(x / 32),
                    round(y / 32),
                    round(float(obj.attrib["width"]) / 32),
                    round(float(obj.attrib["height"]) / 32),
                ]
                result["no_plant" if name == "No planting" else "obstacles"].append(rect)
                if name == "Building sites":
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
                        cell=[round(x / 32), round(y / 32)],
                    )
                )
    return result

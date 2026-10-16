"""Interior authoring primitives. Floors, solid bases and interaction approaches share a grid."""

from art.interior_asset_catalog import FURNITURE, CANVAS_PX


def pos(x, y):
    return [x * 32 + 16, y * 32 + 16]


class Interior:
    def __init__(self, ident, name, width, height):
        self.map = dict(
            id=ident,
            name=name,
            width=width,
            height=height,
            tile_size=32,
            environment="interior",
            art_version=2,
            background=ident + "_background",
            spawn=pos(width // 2, height - 4),
            obstacles=[],
            trees=[],
            props=[],
            stations=[],
            gather=[],
            debris=[],
            paths=[],
            water=[],
            floors=[],
            rooms=[],
            rugs=[],
            doorways=[],
        )
        self.walk = set()
        self.solid = set()
        self.places = {}

    def floor(self, x, y, w, h, name="", material="wood"):
        self.map["floors"].append(dict(rect=[x, y, w, h], material=material))
        if name:
            self.map["rooms"].append(dict(name=name, rect=[x, y, w, h]))
        self.walk.update((xx, yy) for yy in range(y, y + h) for xx in range(x, x + w))

    def doorway(self, x, y, w=2, h=2):
        self.floor(x, y, w, h)
        self.map["doorways"].append([x, y, w, h])

    def furnishing(self, kind, x, y, ident="", text=""):
        w, depth, height, _ = FURNITURE[kind]
        cells = {(xx, yy) for yy in range(y, y + depth) for xx in range(x, x + w)}
        if not cells <= self.walk or cells & self.solid:
            raise ValueError(f"{self.map['id']}: invalid {kind} footprint at {(x, y)}")
        self.solid.update(cells)
        rect = [x, y, w, depth]
        self.map["obstacles"].append(rect)
        canvas = CANVAS_PX.get(kind, (w * 32, height * 32))
        self.map["props"].append(
            dict(
                texture="room_" + kind,
                ground=[(x + w / 2) * 32, (y + depth) * 32],
                offset=[-canvas[0] // 2, -canvas[1]],
                footprint=rect,
            )
        )
        approach = (x + w // 2, y + depth)
        if ident:
            self.station(ident, text[0], "inspect", *approach, description=text[1])
        return approach

    def wall_art(self, kind, x, y):
        self.map.setdefault("wall_art", []).append(dict(kind=kind, cell=[x, y]))

    def station(self, ident, name, kind, x, y, **extra):
        self.map["stations"].append(dict(id=ident, name=name, kind=kind, cell=[x, y], **extra))

    def place(self, name, x, y):
        self.places[self.map["id"] + "/" + name] = (x, y)

    def entry(self, x, y):
        self.map["entry"] = [x, y]
        self.map["spawn"] = pos(x, y - 1)

    def finish(self):
        w, h = self.map["width"], self.map["height"]
        for y in range(h):
            x = 0
            while x < w:
                if (x, y) in self.walk:
                    x += 1
                    continue
                begin = x
                while x < w and (x, y) not in self.walk:
                    x += 1
                self.map["obstacles"].append([begin, y, x - begin, 1])
        # Reject disconnected rooms, inaccessible furniture and NPC spots at authoring time.
        start = tuple(self.map["entry"])
        free = self.walk - self.solid
        reached = {start}
        todo = [start]
        for x, y in todo:
            for cell in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if cell in free and cell not in reached:
                    reached.add(cell)
                    todo.append(cell)
        if reached != free:
            raise ValueError(f"{self.map['id']}: disconnected floor {sorted(free - reached)[:5]}")
        targets = list(self.places.values()) + [tuple(s["cell"]) for s in self.map["stations"]]
        targets += [(self.map["spawn"][0] // 32, self.map["spawn"][1] // 32)]
        if any(cell not in reached for cell in targets):
            raise ValueError(
                f"{self.map['id']}: blocked target {[c for c in targets if c not in reached]}"
            )
        return self.map, self.places

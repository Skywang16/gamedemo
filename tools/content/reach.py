"""Walkability and reachability over the generated maps, used to validate schedules.

Cells are walkable unless they are on the border, inside an obstacle or a tree. Exits join
maps; the bridge joins the town and the lake only once it is repaired.
"""

import json
from pathlib import Path

MAPS = Path(__file__).resolve().parents[2] / "data" / "maps"


def load_maps():
    maps = {}
    for map_id in json.loads((MAPS / "index.json").read_text())["maps"]:
        maps[map_id] = json.loads((MAPS / (map_id + ".json")).read_text())
    return maps


def blocked_grid(m):
    w, h = m["width"], m["height"]
    grid = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if x <= 0 or y <= 0 or x >= w - 1 or y >= h - 1:
                grid[y][x] = True
    for rx, ry, rw, rh in m["obstacles"]:
        for y in range(ry, ry + rh):
            for x in range(rx, rx + rw):
                if 0 <= x < w and 0 <= y < h:
                    grid[y][x] = True
    for x, y in m["trees"]:
        grid[y][x] = True
    return grid


class Reach:
    def __init__(self, maps):
        self.maps = maps
        self.blocked = {k: blocked_grid(m) for k, m in maps.items()}
        self.comp = {}
        for k, m in maps.items():
            self.comp[k] = self._label(k, m["width"], m["height"])

    def _label(self, map_id, w, h):
        grid = self.blocked[map_id]
        comp = [[-1] * w for _ in range(h)]
        count = 0
        for y in range(h):
            for x in range(w):
                if grid[y][x] or comp[y][x] != -1:
                    continue
                stack = [(x, y)]
                comp[y][x] = count
                while stack:
                    cx, cy = stack.pop()
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < w and 0 <= ny < h and not grid[ny][nx] and comp[ny][nx] == -1:
                            comp[ny][nx] = count
                            stack.append((nx, ny))
                count += 1
        return comp

    def node(self, map_id, cell):
        c = self.comp[map_id][cell[1]][cell[0]]
        return None if c < 0 else (map_id, c)

    def edges(self, bridge):
        graph = {}
        for map_id, m in self.maps.items():
            for s in m["stations"]:
                if s["kind"] == "exit":
                    a = self.node(map_id, s["cell"])
                    b = self.node(s["destination"], (s["arrival"][0] // 32, s["arrival"][1] // 32))
                    if a and b:
                        graph.setdefault(a, set()).add(b)
        if bridge:
            town = self.maps["town"]
            lake = self.maps["lake"]
            a = self.node(
                "town", tuple(next(s for s in town["stations"] if s["kind"] == "bridge")["cell"])
            )
            b = self.node("lake", (lake["spawn"][0] // 32, lake["spawn"][1] // 32))
            graph.setdefault(a, set()).add(b)
            graph.setdefault(b, set()).add(a)
        return graph

    def reachable(self, a, b, bridge):
        start, goal = self.node(*a), self.node(*b)
        if start is None or goal is None:
            return False
        graph = self.edges(bridge)
        seen = {start}
        stack = [start]
        while stack:
            cur = stack.pop()
            if cur == goal:
                return True
            for nxt in graph.get(cur, ()):
                if nxt not in seen:
                    seen.add(nxt)
                    stack.append(nxt)
        return False

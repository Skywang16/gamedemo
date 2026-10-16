"""Authoring command: writes docs/design/09-world-map.md from the generated map data.

Sizes, exits, stations, decoration counts and the connection graph are read from data/maps, so
the document always matches the maps the game loads.
"""

import collections
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MAPS = ROOT / "data" / "maps"

DECOR = {
    "lamp": "路灯",
    "flowerbed": "花坛",
    "planter": "盆栽",
    "hedge": "树篱",
    "crates": "木箱",
    "barrel": "木桶",
    "signpost": "路牌",
    "stall": "摊位",
    "hay": "干草垛",
    "trough": "饮水槽",
    "cart": "推车",
    "rocks": "岩石丛",
    "fence": "围栏",
}
PATHS = {
    "cobble": "石板",
    "dirt": "土路",
    "boardwalk": "木栈道",
    "packed": "压实土路",
}
BIOMES = {"meadow": "草地", "beach": "沙滩", "cave": "洞窟"}
OUTDOOR = ["home_farm", "town", "market", "ranch", "seaside", "forest", "lake", "far_shore"]
MINES = ["mine_1", "mine_2", "mine_3"]
INDOOR = [
    name
    for name in json.loads((MAPS / "index.json").read_text())["maps"]
    if json.loads((MAPS / (name + ".json")).read_text())["environment"] == "interior"
]

SPOT = {
    "pond": "池塘",
    "stream": "溪流",
    "river": "河",
    "lake": "湖",
    "sea": "海",
    "cave": "洞窟",
}


def load(name):
    return json.loads((MAPS / (name + ".json")).read_text("utf8"))


def main():
    maps = {name: load(name) for name in OUTDOOR + MINES + INDOOR}
    fish = json.loads((ROOT / "data" / "fish.json").read_text("utf8"))
    lines = [
        "# 09 · 世界地图与路网",
        "",
        "本文的表格由 `tools/world/build_map_doc.py` 从 `data/maps/` 生成。地图本身由 `tools/world/build_maps.py` "
        "从零生成（每次运行都完整重写）。",
        "",
        "## 1. 总连通图",
        "",
        "所有地图通过真实的道路相连，每条边在两端各有一个出口站点（交互提示“北行 · 芦苇渡镇”之类）。",
        "",
        "```mermaid",
        "graph TD",
    ]
    for name in OUTDOOR + MINES:
        lines.append(
            '  %s["%s %d×%d"]'
            % (name, maps[name]["name"], maps[name]["width"], maps[name]["height"])
        )
    seen = set()
    for name in OUTDOOR + MINES:
        for st in maps[name]["stations"]:
            if st["kind"] not in ("exit", "bridge", "ferry"):
                continue
            dest = st.get("destination", "lake")
            if dest in INDOOR or (dest, name) in seen:
                continue
            seen.add((name, dest))
            lines.append('  %s -- "(%d,%d)" --> %s' % (name, st["cell"][0], st["cell"][1], dest))
    lines += [
        "```",
        "",
        "读法：**农场是中心，向南进镇；镇向北进山（林地与矿洞），向南进集市街，向东过桥到湖；"
        "集市街向东通牧场（牧场又有一条路直通农场），向南通海边。** 农场—镇—集市街—牧场构成一个闭环，不用走回头路。"
        "小镇到萤火湖畔的桥在主线阶段 3（修好东桥）之后才通。",
        "",
        "## 2. 地图总表",
        "",
        "| 地图 | 尺寸（格） | 地面 | 路面 | 树 | 采集点 | 装饰 | 站点 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for name in OUTDOOR + MINES + INDOOR:
        m = maps[name]
        lines.append(
            "| %s | %d×%d | %s | %s | %d | %d | %d | %d |"
            % (
                m["name"],
                m["width"],
                m["height"],
                BIOMES.get(m.get("biome", ""), "室内"),
                PATHS.get(m.get("path_style", ""), "—"),
                len(m.get("trees", [])),
                len(m.get("gather", [])),
                len(m.get("decor", [])) + len(m.get("fences", [])),
                len(m["stations"]),
            )
        )
    lines += ["", "## 3. 出口", "", "| 从 | 站点 | 格 | 到 |", "| --- | --- | --- | --- |"]
    for name in OUTDOOR + MINES + INDOOR:
        for st in maps[name]["stations"]:
            if st["kind"] == "exit":
                lines.append(
                    "| %s | %s | (%d,%d) | %s |"
                    % (
                        maps[name]["name"],
                        st["name"],
                        st["cell"][0],
                        st["cell"][1],
                        maps[st["destination"]]["name"],
                    )
                )
    lines += [
        "",
        "## 4. 站点（按 E 交互的地方）",
        "",
        "| 地图 | 站点 | 类型 |",
        "| --- | --- | --- |",
    ]
    for name in OUTDOOR + MINES + INDOOR:
        for st in maps[name]["stations"]:
            if st["kind"] != "exit":
                lines.append("| %s | %s | %s |" % (maps[name]["name"], st["name"], st["kind"]))
    lines += [
        "",
        "站点类型：`inspect` 个人物件（查看）、`bed` 床（休息）、`letter` 祖母的信、`storage` 储物箱、`kitchen` 灶台、`shop` 柜台或摊位、"
        "`shipping` 收货箱、`board` 告示板、`bridge` 东桥、`lantern` 灯台、`ferry` 摆渡船（灯四亮后开放）、`story` 剧情地点（旧灯龛）。村民、采集点、鸡舍 / 谷仓门口"
        "是运行时加入的站点。",
        "",
        "## 5. 装饰与碰撞",
        "",
        "所有装饰烘焙进地形图，碰撞矩形由地图脚本同步写入，因此“看到的”和“撞到的”一致。",
        "",
        "| 地图 | 装饰构成 |",
        "| --- | --- |",
    ]
    for name in OUTDOOR + MINES:
        count = collections.Counter(d["kind"] for d in maps[name].get("decor", []))
        count["fence"] += len(maps[name].get("fences", []))
        parts = ["%s ×%d" % (DECOR.get(k, k), n) for k, n in sorted(count.items()) if n]
        lines.append("| %s | %s |" % (maps[name]["name"], "、".join(parts) or "—"))
    lines += [
        "",
        "## 6. 室内",
        "",
        "25 张室内按用途采用不同尺寸。住宅包含个人卧室、走廊和共享起居室；营业场所包含前厅、营业区和后间。"
        "房门和楼梯双向连接；30 位村民回到真实房间，个人物件可按 E 查看。家具以独立精灵排序，地板和墙体由同一份平面图生成；大房间镜头跟随玩家。",
        "",
        "## 7. 钓鱼水域",
        "",
        "| 水域 | 对应地图 |",
        "| --- | --- |",
    ]
    spots = collections.defaultdict(list)
    for name, spot in fish["spots"].items():
        spots[spot].append(maps[name]["name"])
    for spot, names in spots.items():
        lines.append("| %s | %s |" % (SPOT[spot], "、".join(names)))
    lines.append("")
    (ROOT / "docs" / "design" / "09-world-map.md").write_text("\n".join(lines))
    print("map doc written")


if __name__ == "__main__":
    main()

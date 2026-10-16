"""Authoring command: writes docs/design/02-cast.md from the villager data.

The roster, tastes, birthdays and heart events are read from story_data.py and the generated
items, so the cast document cannot drift from the game.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from content import calendar_data, romance, story_data  # noqa: E402

SEASON = {s["id"]: s["name"] for s in calendar_data.SEASONS}
GENDER = {"F": "女", "M": "男"}


def item_names(ids, items):
    return "、".join(items[i]["name"] for i in ids)


def stage_of(age):
    if age < 18:
        return "少年儿童"
    if age < 30:
        return "青年"
    if age < 50:
        return "中年"
    return "长者"


def first_line(pages):
    for who, text in pages:
        if who != "narrator":
            return text.split("\n")[0]
    return pages[0][1].split("\n")[0]


def build():
    items = json.loads((ROOT / "data" / "items.json").read_text("utf8"))
    npcs = story_data.NPCS
    lines = [
        "# 02 · 角色设定（30 位村民与祖母）",
        "",
        "本文由 `tools/content/build_cast_doc.py` 从村民数据生成，姓名、年龄、生日、喜好和事件与游戏一致。"
        "家庭与人际关系见 [08 · 人物、家庭与人际关系](08-people-and-families.md)，每个人的日常行程见 "
        "[13 · 村民日程总表](13-routines.md)。",
        "",
        "## 1. 规则",
        "",
        "- **好感**：0–100，每 20 点显示一颗心，共 5 颗。每天第一次交谈 +4；送礼：最爱 +12、喜欢 +8、普通 +4、讨厌 −4，"
        "生日当天正面礼物翻倍；每天每人只能送一次。参加节日全体 +2。",
        "- **心事件**：好感达到门槛时，在对方面板上出现“听听某某的故事”，读完得到回礼。"
        "可恋爱的 12 位有 5 段（20/40/60/80/100），其余村民有 3 段（30/60/90）。",
        "- **可恋爱**：12 位，6 女 6 男，玩家不限性别。孩子与少年（米洛、波比、艾兹拉、克拉拉）只有友情线。",
        "- 每个人都有英文原名（`en` 字段）、生日、最爱、喜欢与讨厌的物品，全部是游戏里真实存在的物品。",
        "- 祖母西尔维娅不在村民名单中：她在信里出现，并在第三章的灯夜回到镇上，之后在剧情里陪伴你。",
        "- 恋爱：第一章完成后，好感 80 并听完前 4 段心事件，可以送一盏心意灯成为恋人；好感 100、听完第 5 段后，用同心环求婚，三天后举行婚礼，之后对方住进农舍，"
        "每天清晨为你做一件事，婚后一周和四周各有一段新的心里话。同一时间只有一位伴侣。",
        "",
        "## 2. 总表",
        "",
        "| 人物 | English | 性别 | 年龄 | 身份 | 生日 | 可恋爱 |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for ident, n in npcs.items():
        b = n["birthday"]
        lines.append(
            "| %s | %s | %s | %d | %s | %s%d | %s |"
            % (
                n["name"],
                n["en"],
                GENDER[n["gender"]],
                n["age"],
                n["role"],
                SEASON[b["season"]],
                b["day"],
                "✔" if n["romance"] else "",
            )
        )
    lines += ["", "## 3. 逐人设定", ""]
    for ident, n in npcs.items():
        look = story_data.LOOKS[ident]
        b = n["birthday"]
        lines += [
            "### %s（%s）" % (n["name"], n["en"]),
            "",
            "- **%s · %d 岁 · %s**；%s；生日 %s%d 日。"
            % (
                GENDER[n["gender"]],
                n["age"],
                stage_of(n["age"]),
                n["household"],
                SEASON[b["season"]],
                b["day"],
            ),
            "- **身份**：%s。" % n["role"],
            "- **简介**：%s" % n["bio"],
            "- **最爱**：%s；**喜欢**：%s；**讨厌**：%s。"
            % (
                items[n["favorite"]]["name"],
                item_names(n["likes"], items),
                item_names(n["dislikes"], items),
            ),
            "- **外形**：%s发，%s%s。"
            % (
                look["hair"],
                "戴帽子，" if look.get("hat") else "",
                "配饰 " + "、".join(look.get("acc", [])) if look.get("acc") else "无额外配饰",
            ),
            "- **心事件**：",
        ]
        for e in n["events"]:
            reward = e["reward"]
            parts = []
            if reward["gold"]:
                parts.append("%d 金币" % reward["gold"])
            for item, count in reward["items"].items():
                parts.append("%s ×%d" % (items[item]["name"], count))
            lines.append(
                "  - %d 好感（%s）：“%s” 回礼：%s"
                % (e["at"], e["id"], first_line(e["pages"]), "、".join(parts))
            )
        if ident in romance.ROMANCE:
            r = romance.ROMANCE[ident]
            guest_id, guest_line = r["guest"]
            lines += [
                "- **恋爱与婚后**：",
                "  - 收下心意灯：“%s”" % r["dating"],
                "  - 答应求婚：“%s”" % r["engage"],
                "  - 婚礼誓词：“%s”" % r["vow"],
                "  - 婚礼上，%s说：“%s”" % (npcs[guest_id]["name"], guest_line),
                "  - 婚后日常：%s" % "；".join("“%s”" % t for t in r["talk"]),
                "  - 婚后每天清晨：%s"
                % __import__("content.economy", fromlist=["SPOUSES"]).SPOUSES[ident]["text"],
            ]
            for key, after in (("m1", "一周"), ("m2", "四周")):
                pages, reward = r[key]
                text = [p for p in pages if p[0] != "narrator"][0][1]
                lines.append("  - 婚后%s（%s_%s）：“%s”" % (after, ident, key, text.split("\n")[0]))
        lines.append("")
    (ROOT / "docs" / "design" / "02-cast.md").write_text("\n".join(lines))
    print("cast written:", len(npcs))


if __name__ == "__main__":
    build()

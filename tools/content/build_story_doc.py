"""Authoring command: writes docs/design/14-main-story.md from the quest and scene data."""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from content import calendar_data  # noqa: E402

CHAPTERS = {
    1: "第一章 · 灯夜重燃（春）",
    2: "第二章 · 留下的人（夏）",
    3: "第三章 · 水从哪里来（秋）",
    4: "第四章 · 写给明年的信（冬）",
    5: "终章 · 新的河灯",
}
SEASON = {s["id"]: s["name"] for s in calendar_data.SEASONS}


def need_text(needs, items):
    return "、".join("%s ×%d" % (items[i]["name"], n) for i, n in needs.items()) or "—"


def when_text(day):
    if not day:
        return "随时"
    season = ["spring", "summer", "autumn", "winter"][(day - 1) // 28]
    return "%s %d 日起" % (SEASON[season], (day - 1) % 28 + 1)


def main():
    items = json.loads((ROOT / "data" / "items.json").read_text("utf8"))
    story = json.loads((ROOT / "data" / "story.json").read_text("utf8"))
    npcs = story["npcs"]
    lines = [
        "# 14 · 主线全表",
        "",
        "本文由 `tools/content/build_story_doc.py` 从任务与场景数据生成。主线共 %d 个步骤，%d 个场景；"
        "每个场景都是一段全屏剧情动画（见 [03 · 主线与剧情动画](03-story.md)）。"
        % (len(story["quests"]), len(story["scenes"])),
        "",
    ]
    for chapter, title in CHAPTERS.items():
        lines += [
            "## %s" % title,
            "",
            "| # | 步骤 | 地点 / 人物 | 开放 | 需要 | 选择 | 点亮 | 奖励 |",
            "| --- | --- | --- | --- | --- | --- | --- | --- |",
        ]
        for index, q in enumerate(story["quests"]):
            if q["chapter"] != chapter:
                continue
            need = need_text(q["needs"], items)
            for who, value in q["friendship"].items():
                need += "；%s 好感 %d" % (npcs[who]["name"], value)
            choice = "、".join(c["label"].rstrip("。") for c in q["choice"]) or "—"
            reward = []
            if q["reward"]["gold"]:
                reward.append("%d G" % q["reward"]["gold"])
            for item, count in q["reward"]["items"].items():
                reward.append("%s ×%d" % (items[item]["name"], count))
            if q["build"]:
                reward.append("温室落成")
            scenes = story["scenes"].get(q["event"])
            where = q["where"]
            lines.append(
                "| %d | %s | %s | %s | %s | %s | %s | %s |"
                % (
                    index,
                    q["title"],
                    where,
                    when_text(q["available_day"]),
                    need,
                    choice,
                    ("第 %d 盏灯" % q["lamp"]) if q["lamp"] else "—",
                    "、".join(reward) or "—",
                )
            )
            _ = scenes
        lines.append("")
    lines += [
        "## 场景与回应",
        "",
        "选择之后会立刻播放对应的回应场景（`<步骤>_<选择>`）；终章的结局篇章按结局播放（`new_lantern_end_<结局>`）。",
        "",
    ]
    lines += ["| 场景 | 页数 | 开场背景 | 气氛 |", "| --- | --- | --- | --- |"]
    for q in story["quests"]:
        if not q["event"]:
            continue
        sc = story["scenes"][q["event"]]
        lines.append(
            "| %s（%s） | %d | %s | %s |"
            % (q["title"], q["event"], len(sc["pages"]), sc["bg"], sc["mood"])
        )
    lines.append("")
    replies = sorted(
        k
        for k in story["scenes"]
        if k not in {q["event"] for q in story["quests"]}
        and k.split("_")[0] not in npcs
        and not k.startswith(("dating_", "engage_", "wedding_"))
    )
    lines += [
        "回应场景（%d 个）：%s。" % (len(replies), "、".join("`%s`" % r for r in replies)),
        "",
    ]
    (ROOT / "docs" / "design" / "14-main-story.md").write_text("\n".join(lines))
    print("story doc written")


if __name__ == "__main__":
    main()

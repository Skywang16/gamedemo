"""Authoring command: writes docs/design/13-routines.md from the schedule data.

The document lists every villager's rules in the order the game tries them, so the table in the
docs can never drift from what the game does.
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

from content import calendar_data, story_data  # noqa: E402
from content.schedules import SCHEDULES  # noqa: E402

WEEKDAYS = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
SEASON_NAMES = {s["id"]: s["name"] for s in calendar_data.SEASONS}
WEATHER_NAMES = {
    "sunny": "晴",
    "cloudy": "多云",
    "rain": "雨",
    "storm": "雷暴",
    "wind": "大风",
    "snow": "雪",
}


def describe(when):
    if not when:
        return "其余日子"
    parts = []
    if when.get("birthday"):
        parts.append("生日当天")
    if when.get("festival"):
        parts.append("节日当天")
    if "weekdays" in when:
        parts.append("、".join(WEEKDAYS[d] for d in when["weekdays"]))
    if "week" in when:
        parts.append("每月第 %s 周" % "、".join(str(w) for w in when["week"]))
    if "seasons" in when:
        parts.append("、".join(SEASON_NAMES[s] for s in when["seasons"]))
    if "weather" in when:
        parts.append("天气：" + "、".join(WEATHER_NAMES[w] for w in when["weather"]))
    if "days" in when:
        parts.append("每季第 %s 天" % "、".join(str(d) for d in when["days"]))
    if "year_min" in when:
        parts.append("第 %d 年起" % when["year_min"])
    if "year_max" in when:
        parts.append("第 %d 年之前" % (when["year_max"] + 1))
    if "stage_min" in when:
        parts.append("故事进度 ≥ %d" % when["stage_min"])
    if "stage_max" in when:
        parts.append("故事进度 ≤ %d" % when["stage_max"])
    return " · ".join(parts)


def stop_line(stop):
    time, place, _, text = stop.partition(" ")[0], stop.split(" ")[1], "", stop.split("| ", 1)[1]
    return "%s %s｜%s" % (time, place, text)


def build():
    lines = [
        "# 13 · 村民日程总表",
        "",
        "本表由 `tools/content/build_routines_doc.py` 从日程数据生成。每位村民的规则按从上到下的顺序判断，"
        "第一条条件全部满足的规则生效；最后一条没有条件。规则写法见 [12 · 日程系统](12-schedules.md)。",
        "",
    ]
    for ident, npc in story_data.NPCS.items():
        rules = SCHEDULES[ident]
        lines += ["## %s（%s）" % (npc["name"], npc["role"]), ""]
        for i, entry in enumerate(rules, 1):
            lines.append("%d. **%s**" % (i, describe(entry["when"])))
            for stop in entry["stops"]:
                lines.append("   - " + stop_line(stop))
        lines.append("")
    (ROOT / "docs" / "design" / "13-routines.md").write_text("\n".join(lines))
    print("routines written:", len(story_data.NPCS))


if __name__ == "__main__":
    build()

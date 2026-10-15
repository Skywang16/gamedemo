"""Authoring command: writes data/story.json and data/calendar.json.

Sources: tools/content/story_data.py (quests, scenes, villagers), schedules.py (routines),
calendar_data.py, and the generated maps. Every reference is checked: an unknown item, place or
unreachable stop stops the build with a list of problems.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(ROOT / "tools" / "world"))

from content import calendar_data, story_data  # noqa: E402
from content.build_content import build  # noqa: E402
from content.reach import Reach, load_maps  # noqa: E402
from content.schedules import SCHEDULES  # noqa: E402
from places import PLACES, parse  # noqa: E402

CONDITIONS = {
    "birthday",
    "festival",
    "weekdays",
    "week",
    "seasons",
    "weather",
    "days",
    "year_min",
    "year_max",
    "stage_min",
    "stage_max",
}
STOP = re.compile(r"^(\d{1,2}):(\d{2}) (\S+) \| (.+)$")
BRIDGE_STAGE = 3


def parse_stops(npc, index, rule, problems):
    stops, last = [], -1
    for line in rule["stops"]:
        m = STOP.match(line)
        if not m:
            problems.append("%s rule %d: bad stop %r" % (npc, index, line))
            continue
        minute = int(m.group(1)) * 60 + int(m.group(2))
        place = m.group(3)
        if minute <= last:
            problems.append("%s rule %d: times must increase at %r" % (npc, index, line))
        if minute < 360 or minute >= 26 * 60:
            problems.append("%s rule %d: time outside the day at %r" % (npc, index, line))
        if place not in PLACES and place not in ("festival", "away"):
            problems.append("%s rule %d: unknown place %s" % (npc, index, place))
        last = minute
        stops.append([minute, place, m.group(4)])
    if any(s[1] == "away" for s in stops) and len(stops) != 1:
        problems.append("%s rule %d: an away rule has exactly one stop" % (npc, index))
    return stops


def festival_cells(maps):
    town = maps["town"]
    blocked = set()
    for rx, ry, rw, rh in town["obstacles"]:
        for y in range(ry, ry + rh):
            for x in range(rx, rx + rw):
                blocked.add((x, y))
    blocked |= {tuple(t) for t in town["trees"]}
    reserved = {tuple(parse(e)[:2]) for k, e in PLACES.items() if k.startswith("town/")}
    cells = []
    for y in range(29, 40):
        for x in range(30, 51):
            if (x, y) not in blocked and (x, y) not in reserved:
                cells.append((abs(x - 40) + abs(y - 35) * 1.2, x, y))
    cells.sort()
    return [[x, y] for _d, x, y in cells[:40]]


def main():
    items = build()
    maps = load_maps()
    reach = Reach(maps)
    problems = []
    cells = festival_cells(maps)
    npcs = {}
    scenes = dict(story_data.SCENES)
    for ident, npc in story_data.NPCS.items():
        rules = SCHEDULES.get(ident)
        if not rules:
            problems.append("%s has no schedule" % ident)
            continue
        entry = {k: v for k, v in npc.items() if k != "events"}
        entry["events"] = [
            {"id": e["id"], "at": e["at"], "reward": e["reward"]} for e in npc["events"]
        ]
        out_rules = []
        for i, rule in enumerate(rules):
            when = rule["when"]
            if set(when) - CONDITIONS:
                problems.append(
                    "%s rule %d: unknown condition %s" % (ident, i, sorted(set(when) - CONDITIONS))
                )
            if (i == len(rules) - 1) != (not when):
                problems.append(
                    "%s: only the last rule may be unconditional (rule %d)" % (ident, i)
                )
            stops = parse_stops(ident, i, rule, problems)
            bridge = when.get("stage_min", 0) >= BRIDGE_STAGE
            places = [s[1] for s in stops if s[1] != "away"]
            for a, b in zip(places, places[1:]):
                if "festival" in (a, b):
                    continue
                pa, pb = parse(PLACES[a]), parse(PLACES[b])
                if not reach.reachable(
                    (a.split("/")[0], pa[:2]), (b.split("/")[0], pb[:2]), bridge
                ):
                    problems.append("%s rule %d: %s cannot reach %s" % (ident, i, a, b))
            if "festival" in places:
                home = places[0]
                ph = parse(PLACES[home])
                for cell in cells:
                    if not reach.reachable(
                        (home.split("/")[0], ph[:2]), ("town", tuple(cell)), bridge
                    ):
                        problems.append(
                            "%s rule %d: %s cannot reach the festival plaza" % (ident, i, home)
                        )
                        break
            out_rules.append({"when": when, "stops": stops})
        entry["schedule"] = {"rules": out_rules}
        npcs[ident] = entry
        for taste in [npc["favorite"]] + npc["likes"] + npc["dislikes"]:
            if taste not in items:
                problems.append("%s: unknown item %s" % (ident, taste))
            elif items[taste]["kind"] == "seed":
                problems.append("%s: seeds cannot be gifts (%s)" % (ident, taste))
        for e in npc["events"]:
            scenes[e["id"]] = e["pages"]
            for it in e["reward"]["items"]:
                if it not in items:
                    problems.append("%s: unknown reward %s" % (e["id"], it))
            for speaker, _text in e["pages"]:
                if speaker != "narrator" and speaker not in story_data.NPCS:
                    problems.append("%s: unknown speaker %s" % (e["id"], speaker))
    for ident in SCHEDULES:
        if ident not in story_data.NPCS:
            problems.append("schedule for unknown villager %s" % ident)
    for q in story_data.QUESTS:
        for it in q["needs"]:
            if it not in items:
                problems.append("quest %s: unknown item %s" % (q["title"], it))
    if problems:
        raise SystemExit("Story problems:\n  " + "\n  ".join(problems))
    story = {"npcs": npcs, "quests": story_data.QUESTS, "scenes": scenes}
    (ROOT / "data" / "story.json").write_text(
        json.dumps(story, ensure_ascii=False, indent=2) + "\n", encoding="utf8"
    )
    calendar = {
        "days_per_season": 28,
        "seasons": calendar_data.SEASONS,
        "weekdays": calendar_data.WEEKDAYS,
        "weather_names": calendar_data.WEATHER_NAMES,
        "weather": calendar_data.WEATHER,
        "calm_days": 3,
        "plaza": {"map": "town", "cells": cells},
        "festivals": [
            {
                "id": i,
                "name": n,
                "season": s,
                "day": d,
                "kind": k,
                "weather": w,
                "text": t,
            }
            for i, n, s, d, k, w, t in calendar_data.FESTIVALS
        ],
    }
    (ROOT / "data" / "calendar.json").write_text(
        json.dumps(calendar, ensure_ascii=False, indent=2) + "\n", encoding="utf8"
    )
    print("villagers", len(npcs), "scenes", len(scenes), "festival cells", len(cells))


if __name__ == "__main__":
    main()

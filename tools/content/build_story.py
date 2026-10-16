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
from content.scene_kit import (  # noqa: E402
    BACKDROPS,
    EFFECTS,
    MOODS,
    OPTION_KEYS,
    SCENE_META,
    SLOTS,
    SOUNDS,
)
from content.romance import HOME_BACKDROP, ROMANCE  # noqa: E402
from content.build_content import build  # noqa: E402
from content.reach import Reach, load_maps  # noqa: E402
from content.schedules import SCHEDULES  # noqa: E402
from places import PLACES, parse  # noqa: E402
from world.residences import NPC_HOME  # noqa: E402

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
    "spouse",
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
        # Home stops now lead through actual entrances to each resident's own room.
        old_home = SCHEDULES[npc][-1]["stops"][-1].split(" | ")[0].split(" ")[1]
        if place == old_home and not rule["when"].get("spouse"):
            place = NPC_HOME[npc] + "/bed_" + npc
        place = {"town/school_door": "school/teacher", "town/hall_door": "town_hall/records"}.get(
            place, place
        )
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


ENDINGS = ["root", "shore", "stream"]
STATIONS = ["bridge", "lantern", "shrine"]
SPEAKERS = {"narrator", "letter"}


def story_flags():
    """Every story flag and the values it can hold, from the quests' choices."""
    flags = {"ending": list(ENDINGS)}
    for q in story_data.QUESTS:
        if q["flag"]:
            flags[q["flag"]] = [c["id"] for c in q["choice"]]
    return flags


def default_actors(ident):
    return ["%s@center_left" % ident, "player@center_right"]


def finish_scenes(scenes, flags, problems):
    """Wraps every scene as {pages, bg, mood, card, fx} and checks the director's notes."""
    people = set(story_data.NPCS) | set(story_data.GUESTS)
    quest_events = [q["event"] for q in story_data.QUESTS if q["event"]]
    out = {}
    for event, pages in scenes.items():
        info = SCENE_META.get(event)
        if info is None:
            parent = next((e for e in quest_events if event.startswith(e + "_")), "")
            if parent:
                info = SCENE_META[parent]
            else:
                owner = event.split("_")[0]
                if owner in story_data.NPCS:
                    info = {
                        "bg": HOME_BACKDROP.get(owner, "town"),
                        "mood": "day",
                        "card": [],
                        "fx": [],
                    }
                else:
                    problems.append("scene %s has no backdrop notes" % event)
                    continue
            if (
                event not in SCENE_META
                and event.split("_")[0] in story_data.NPCS
                and not any(event.startswith(e + "_") for e in quest_events)
            ):
                owner = event.split("_")[0]
                first = pages[0]
                options = dict(first[2]) if len(first) > 2 else {}
                options.setdefault("actors", default_actors(owner))
                pages = [[first[0], first[1], options]] + pages[1:]
        if info["bg"] not in BACKDROPS or any(m not in MOODS for m in [info["mood"]]):
            problems.append("scene %s: bad backdrop or mood" % event)
        normal = []
        for index, page in enumerate(pages):
            who, text = page[0], page[1]
            options = page[2] if len(page) > 2 else {}
            where = "%s page %d" % (event, index + 1)
            if who not in SPEAKERS and who not in people:
                problems.append("%s: unknown speaker %s" % (where, who))
            if not text.strip():
                problems.append("%s: empty text" % where)
            for key, value in options.items():
                if key not in OPTION_KEYS:
                    problems.append("%s: unknown note %s" % (where, key))
                elif key == "bg" and value not in BACKDROPS:
                    problems.append("%s: unknown backdrop %s" % (where, value))
                elif key == "mood" and value not in MOODS:
                    problems.append("%s: unknown mood %s" % (where, value))
                elif key == "fx" and not set(value) <= set(EFFECTS):
                    problems.append("%s: unknown effect in %s" % (where, value))
                elif key == "sfx" and value not in SOUNDS:
                    problems.append("%s: unknown sound %s" % (where, value))
                elif key == "flash" and value not in ("white", "gold", "black"):
                    problems.append("%s: unknown flash %s" % (where, value))
                elif key == "cam" and value not in (
                    "zoom_in",
                    "zoom_out",
                    "pan_left",
                    "pan_right",
                    "still",
                ):
                    problems.append("%s: unknown camera %s" % (where, value))
                elif key == "actors":
                    for entry in value:
                        name, _, slot = entry.partition("@")
                        if (name not in people and name != "player") or slot not in SLOTS:
                            problems.append("%s: bad actor %s" % (where, entry))
                elif key == "act":
                    for name, action in value.items():
                        if action not in ("hop", "nod", "shake", "bow", "step"):
                            problems.append("%s: unknown action %s" % (where, action))
                elif key == "when":
                    for flag, wanted in value.items():
                        if flag == "partner":
                            if wanted not in ROMANCE:
                                problems.append("%s: bad partner %s" % (where, wanted))
                        elif wanted not in flags.get(flag, []):
                            problems.append("%s: bad condition %s=%s" % (where, flag, wanted))
            normal.append([who, text, options])
        out[event] = {
            "pages": normal,
            "bg": info["bg"],
            "mood": info["mood"],
            "card": info["card"],
            "fx": info["fx"],
        }
    return out


def check_quests(items, flags, scenes, problems):
    ids = set()
    for index, q in enumerate(story_data.QUESTS):
        name = q["id"]
        if name in ids:
            problems.append("duplicate quest %s" % name)
        ids.add(name)
        for it in list(q["needs"]) + list(q["reward"]["items"]):
            if it not in items:
                problems.append("quest %s: unknown item %s" % (name, it))
        for who in list(q["friendship"]) + ([q["npc"]] if q["npc"] else []):
            if who not in story_data.NPCS:
                problems.append("quest %s: unknown villager %s" % (name, who))
        if q["event"] and q["event"] not in scenes:
            problems.append("quest %s has no scene" % name)
        if q["station"] and q["station"] not in STATIONS:
            problems.append("quest %s: unknown station %s" % (name, q["station"]))
        if q["event"] and not q["npc"] and not q["station"]:
            problems.append("quest %s has neither a villager nor a station" % name)
        for c in q["choice"]:
            reply = "%s_%s" % (q["event"], c["id"])
            if reply in scenes and not scenes[reply]["pages"]:
                problems.append("empty reply %s" % reply)
        if q["choice"] and not q["flag"]:
            problems.append("quest %s: a choice needs a flag" % name)
        if q["lamp"] and q["lamp"] != len([x for x in story_data.QUESTS[: index + 1] if x["lamp"]]):
            problems.append("quest %s: lamps must light in order" % name)
        if q["available_day"] > 112:
            problems.append("quest %s is available after the year ends" % name)
    lamps = sorted(q["lamp"] for q in story_data.QUESTS if q["lamp"])
    if lamps != [1, 2, 3, 4, 5, 6]:
        problems.append("the six lamps must each be lit once: %s" % lamps)
    for ending in ENDINGS:
        if "new_lantern_end_" + ending not in scenes:
            problems.append("missing ending scene %s" % ending)
    for heir in flags["ferryman_heir"]:
        if "new_lantern_" + heir not in scenes:
            problems.append("missing reply for heir %s" % heir)


def main():
    items = build()
    maps = load_maps()
    reach = Reach(maps)
    problems = []
    cells = festival_cells(maps)
    npcs = {}
    scenes = dict(story_data.SCENES)
    for key, pages in story_data.ROMANCE_SCENES.items():
        if key in scenes:
            problems.append("duplicate scene %s" % key)
        scenes[key] = pages
    for ident, npc in story_data.NPCS.items():
        rules = SCHEDULES.get(ident)
        if not rules:
            problems.append("%s has no schedule" % ident)
            continue
        entry = {k: v for k, v in npc.items() if k != "events"}
        entry["events"] = [
            {"id": e["id"], "at": e["at"], "reward": e["reward"]} for e in npc["events"]
        ]
        entry["married_talk"] = ROMANCE[ident]["talk"] if ident in ROMANCE else []
        entry["married_events"] = []
        if ident in ROMANCE:
            for key, after in (("m1", 7), ("m2", 28)):
                entry["married_events"].append(
                    {"id": ident + "_" + key, "after": after, "reward": ROMANCE[ident][key][1]}
                )
                scenes[ident + "_" + key] = ROMANCE[ident][key][0]
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
            if e["id"] in scenes:
                problems.append("duplicate scene %s" % e["id"])
            scenes[e["id"]] = e["pages"]
            for it in e["reward"]["items"]:
                if it not in items:
                    problems.append("%s: unknown reward %s" % (e["id"], it))

    for ident in SCHEDULES:
        if ident not in story_data.NPCS:
            problems.append("schedule for unknown villager %s" % ident)
    flags = story_flags()
    scenes_out = finish_scenes(scenes, flags, problems)
    check_quests(items, flags, scenes_out, problems)
    if problems:
        raise SystemExit("Story problems:\n  " + "\n  ".join(problems))
    story = {
        "npcs": npcs,
        "quests": story_data.QUESTS,
        "scenes": scenes_out,
        "flags": flags,
        "guests": story_data.GUESTS,
        "prologue_choices": [{"id": i, "label": t} for i, t in story_data.PROLOGUE_CHOICES],
    }
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

"""Helpers for writing quests and cutscenes.

A page is `[who, text]` or `[who, text, options]`. Options are the director's notes for the
cutscene player (src/ui/cutscene_view.gd); the backdrop, mood, effects and actors persist from the
page that sets them until a later page changes them:

    bg      backdrop id        (farm, town, market, ranch, seaside, forest, lake, greenhouse, river,
                                shore, canal, stage, hall, clock, quarry, vault, inn, shop, cottage,
                                train, feast)
    mood    day, dusk, night, dawn, rain, snow
    fx      list of effects    (fireflies, lanterns, petals, rain, snow, leaves, dust, confetti,
                                sparks, steam, bells, water)
    actors  list of "id@slot"  slots: far_left, left, center_left, center, center_right, right,
                                far_right; ids are villagers, "sylvia" or "player"
    act     {id: action}       one-shot: hop, nod, shake, bow, step
    sfx     one-shot sound     (bell, chime, lantern, water, cheer, wedding, hit, rumble, tick)
    flash   one-shot           white, gold or black
    shake   seconds of screen shake
    cam     slow camera move   zoom_in, zoom_out, pan_left, pan_right, still
    title   a caption card shown over the picture for a moment
    when    {flag: value}      show this page only when the story flag has that value
"""

SLOTS = ["far_left", "left", "center_left", "center", "center_right", "right", "far_right"]
BACKDROPS = [
    "farm",
    "town",
    "market",
    "ranch",
    "seaside",
    "forest",
    "lake",
    "greenhouse",
    "river",
    "shore",
    "canal",
    "stage",
    "hall",
    "clock",
    "quarry",
    "vault",
    "inn",
    "shop",
    "cottage",
    "train",
    "feast",
]
MOODS = ["day", "dusk", "night", "dawn", "rain", "snow"]
EFFECTS = [
    "fireflies",
    "lanterns",
    "petals",
    "rain",
    "snow",
    "leaves",
    "dust",
    "confetti",
    "sparks",
    "steam",
    "bells",
    "water",
]
SOUNDS = ["bell", "chime", "lantern", "water", "cheer", "wedding", "hit", "rumble", "tick"]
OPTION_KEYS = {"bg", "mood", "fx", "actors", "act", "sfx", "flash", "shake", "cam", "title", "when"}


def L(who, text, **options):
    """One line of a scene, with optional director's notes."""
    if not options:
        return [who, text]
    return [who, text, options]


def day_number(season, day):
    return {"spring": 0, "summer": 28, "autumn": 56, "winter": 84}[season] + day


def quest(
    ident,
    title,
    where,
    hint,
    npc="",
    needs=None,
    chapter=1,
    available="",
    friendship=None,
    reward=None,
    choice=None,
    flag="",
    lamp=0,
    station="",
    build="",
):
    """A main-story step. `event` is the id; `available` is "summer 1" style (first day it can
    be completed); `choice` is a list of (id, label) for the closing choice."""
    entry = {
        "id": ident,
        "title": title,
        "where": where,
        "hint": hint,
        "needs": needs or {},
        "npc": npc,
        "event": ident,
        "chapter": chapter,
        "available_day": 0,
        "friendship": friendship or {},
        "reward": reward or {"gold": 0, "items": {}},
        "choice": [{"id": i, "label": label} for i, label in (choice or [])],
        "flag": flag,
        "lamp": lamp,
        "station": station,
        "build": build,
    }
    if available:
        season, number = available.split()
        entry["available_day"] = day_number(season, int(number))
    return entry


def reward(gold=0, **items):
    return {"gold": gold, "items": items}


SCENE_META = {}


def meta(event, bg, mood="day", card=None, fx=None):
    """Where a scene starts: backdrop, mood, optional chapter card [title, subtitle], effects."""
    SCENE_META[event] = {"bg": bg, "mood": mood, "card": card or [], "fx": fx or []}

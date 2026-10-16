class_name FarmState
extends RefCounted

const SCHEMA_VERSION = 7
const MAX_STAMINA = 100
## The day runs from 06:00 to 02:00 the next morning (26:00).
const MORNING = 6 * 60
const NIGHT = 26 * 60
const TICK_MINUTES = 10
const GOALS = ["tilled", "planted", "watered", "slept", "harvested", "sold"]
const TOOLS = ["hoe", "axe", "pickaxe", "scythe", "water", "sword"]

var day: int = 1
var world_seed: int = 0
var minute: int = MORNING
var stamina: int = MAX_STAMINA
var gold: int = 40
var inventory: Dictionary = {}
var plots: Dictionary = {}
var progress: Dictionary = {}
var player_position: Vector2 = Vector2.ZERO
var current_map: String = "home_farm"
var profile: Dictionary = {
	"name": "小芽", "farm": "芽田农场", "skin": 0, "hair": 0, "outfit": 0, "hat": 1
}
var narrative: Dictionary = {
	"stage": 0, "intro_seen": false, "intent": "", "flags": {}, "active_scene": "", "page": 0
}
## Courtship by villager id: {stage: "dating" | "engaged" | "married", day: day it began}.
var romance: Dictionary = {}
var relationships: Dictionary = {}
var daily: Dictionary = {"talked": [], "gifted": [], "gathered": []}
var development: Dictionary = {}
var storage: Dictionary = {}
var cleared: Array = []
var tree_damage: Dictionary = {}
var buildings: Dictionary = {}
var animals: Array = []
var collected: Array = []
var festival_done: Array = []
var stats: Dictionary = {}
var board: Dictionary = {"week": 0, "done": []}


static func cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func key_cell(key: String) -> Vector2i:
	var parts = key.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


static func fresh_development() -> Dictionary:
	var tools: Dictionary = {}
	for tool in TOOLS:
		tools[tool] = 0
	return {
		"farming_xp": 0,
		"foraging_xp": 0,
		"fishing_xp": 0,
		"cooking_xp": 0,
		"mining_xp": 0,
		"rod": 0,
		"events": [],
		"tools": tools,
	}


static func fresh_stats() -> Dictionary:
	return {"earned": 0, "harvested": 0, "caught": 0, "cooked": 0, "defeated": 0}


static func new_game(catalog: ContentCatalog, seed_value: int = 0) -> FarmState:
	var s = FarmState.new()
	s.world_seed = seed_value
	s.development = fresh_development()
	s.stats = fresh_stats()
	for id in catalog.items:
		s.inventory[id] = 0
		s.storage[id] = 0
	for id in catalog.map.starting_inventory:
		s.inventory[id] = int(catalog.map.starting_inventory[id])
	for id in catalog.story.npcs:
		s.relationships[id] = 0
	s.gold = int(catalog.map.starting_gold)
	for goal in GOALS:
		s.progress[goal] = false
	s.player_position = Vector2(catalog.map.spawn[0], catalog.map.spawn[1])
	return s


func snapshot(_catalog: ContentCatalog) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"map_id": current_map,
		"profile": profile.duplicate(true),
		"narrative": narrative.duplicate(true),
		"romance": romance.duplicate(true),
		"relationships": relationships.duplicate(true),
		"daily": daily.duplicate(true),
		"development": development.duplicate(true),
		"storage": storage.duplicate(true),
		"cleared": cleared.duplicate(),
		"tree_damage": tree_damage.duplicate(),
		"buildings": buildings.duplicate(true),
		"animals": animals.duplicate(true),
		"collected": collected.duplicate(),
		"festival_done": festival_done.duplicate(),
		"stats": stats.duplicate(),
		"board": board.duplicate(true),
		"world_seed": world_seed,
		"day": day,
		"minute": minute,
		"stamina": stamina,
		"gold": gold,
		"inventory": inventory.duplicate(true),
		"plots": plots.duplicate(true),
		"progress": progress.duplicate(true),
		"player_position": [player_position.x, player_position.y],
	}


static func from_validated(data: Dictionary) -> FarmState:
	var s = FarmState.new()
	s.current_map = data.map_id
	s.cleared = data.cleared.duplicate()
	s.tree_damage = data.tree_damage.duplicate()
	for id in s.tree_damage:
		s.tree_damage[id] = int(s.tree_damage[id])
	for field in [
		"profile",
		"narrative",
		"relationships",
		"daily",
		"development",
		"storage",
		"buildings",
		"board",
		"stats",
		"romance"
	]:
		s.set(field, data[field].duplicate(true))
	for key in ["skin", "hair", "outfit", "hat"]:
		s.profile[key] = int(s.profile[key])
	for key in ["stage", "page"]:
		s.narrative[key] = int(s.narrative[key])
	for key in s.development:
		if s.development[key] is float:
			s.development[key] = int(s.development[key])
	for tool in s.development.tools:
		s.development.tools[tool] = int(s.development.tools[tool])
	for key in s.stats:
		s.stats[key] = int(s.stats[key])
	for id in s.relationships:
		s.relationships[id] = int(s.relationships[id])
	for id in s.storage:
		s.storage[id] = int(s.storage[id])
	for id in s.buildings:
		s.buildings[id].ready_day = int(s.buildings[id].ready_day)
	for id in s.romance:
		s.romance[id].day = int(s.romance[id].day)
	s.board.week = int(s.board.week)
	s.board.done = s.board.done.map(func(i): return int(i))
	s.animals = data.animals.duplicate(true)
	for a in s.animals:
		for key in ["friendship", "age", "wait"]:
			a[key] = int(a[key])
	s.collected = data.collected.duplicate()
	s.festival_done = data.festival_done.duplicate()
	s.world_seed = int(data.world_seed)
	s.day = int(data.day)
	s.minute = int(data.minute)
	s.stamina = int(data.stamina)
	s.gold = int(data.gold)
	s.inventory = data.inventory.duplicate(true)
	for id in s.inventory:
		s.inventory[id] = int(s.inventory[id])
	s.plots = data.plots.duplicate(true)
	for p in s.plots.values():
		p.growth = int(p.growth)
	s.progress = data.progress.duplicate(true)
	s.player_position = Vector2(data.player_position[0], data.player_position[1])
	return s

class_name NpcPlanner
extends RefCounted

## Turns each villager's daily rules into a timeline of where they are at every minute.
##
## Pure logic: nothing here touches nodes. The world asks `where()` for a minute and draws
## whatever it says, so reloading a save, changing map or sleeping always gives the same answer.

const WALK_SPEED = 2.0  # cells per game minute
const DOOR_MINUTES = 1.0
const DAY_END = 27.0 * 60.0
const BRIDGE_STAGE = 3

var catalog: ContentCatalog
var tree_damage: Dictionary
var grids: Dictionary = {}
var timelines: Dictionary = {}
var context: Dictionary = {}


func _init(content: ContentCatalog, damage: Dictionary) -> void:
	catalog = content
	tree_damage = damage


## Plans every villager for the day described by `ctx`:
## {day, date, weather, stage, birthdays (Array of ids), festival (bool)}.
func plan_day(ctx: Dictionary) -> void:
	context = ctx
	timelines.clear()
	var ids = catalog.story.npcs.keys()
	ids.sort()
	for i in ids.size():
		timelines[ids[i]] = build_timeline(ids[i], i)


# ---------------------------------------------------------------------------- rules


func rule_matches(when: Dictionary, npc_id: String) -> bool:
	var date: Dictionary = context.date
	for key in when:
		var wanted = when[key]
		match key:
			"birthday":
				if (npc_id in context.birthdays) != bool(wanted):
					return false
			"festival":
				if bool(context.festival) != bool(wanted):
					return false
			"weekdays":
				if not int(date.weekday) in _ints(wanted):
					return false
			"week":
				if not (int((int(date.day) - 1) / 7) + 1) in _ints(wanted):
					return false
			"seasons":
				if not str(date.season) in wanted:
					return false
			"weather":
				if not str(context.weather) in wanted:
					return false
			"days":
				if not int(date.day) in _ints(wanted):
					return false
			"year_min":
				if int(date.year) < int(wanted):
					return false
			"year_max":
				if int(date.year) > int(wanted):
					return false
			"stage_min":
				if int(context.stage) < int(wanted):
					return false
			"stage_max":
				if int(context.stage) > int(wanted):
					return false
	return true


func _ints(values: Array) -> Array:
	return values.map(func(v): return int(v))


func resolve(npc_id: String) -> Dictionary:
	for rule in catalog.story.npcs[npc_id].schedule.rules:
		if rule_matches(rule.when, npc_id):
			return rule
	push_error("no schedule rule matches " + npc_id)
	return {}


func bridge_open() -> bool:
	return int(context.stage) >= BRIDGE_STAGE


# ---------------------------------------------------------------------------- routes


func grid(map_id: String) -> AStarGrid2D:
	if grids.has(map_id):
		return grids[map_id]
	var area = catalog.region(map_id)
	var g = AStarGrid2D.new()
	g.region = Rect2i(0, 0, int(area.width), int(area.height))
	g.cell_size = Vector2.ONE
	g.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	g.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	g.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	g.update()
	for y in range(int(area.height)):
		for x in range(int(area.width)):
			if catalog.blocked(Vector2i(x, y), map_id, tree_damage):
				g.set_point_solid(Vector2i(x, y), true)
	grids[map_id] = g
	return g


func edges_from(map_id: String) -> Array:
	var list: Array = catalog.exits.get(map_id, []).duplicate()
	if map_id == "town" and bridge_open():
		for station in catalog.region("town").stations:
			if station.kind == "bridge":
				var lake = catalog.region("lake")
				list.append(
					{
						"cell": Vector2i(station.cell[0], station.cell[1]),
						"to": "lake",
						"arrival": Vector2i(int(lake.spawn[0] / 32), int(lake.spawn[1] / 32))
					}
				)
	return list


## The list of exits to take to get from one map to another (breadth first), or null.
func map_route(from_map: String, to_map: String) -> Variant:
	if from_map == to_map:
		return []
	var came: Dictionary = {from_map: null}
	var queue: Array = [from_map]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for edge in edges_from(current):
			if came.has(edge.to):
				continue
			came[edge.to] = {"from": current, "edge": edge}
			if edge.to == to_map:
				var path: Array = []
				var at: String = to_map
				while came[at] != null:
					path.push_front(came[at].edge)
					at = came[at].from
				return path
			queue.push_back(edge.to)
	return null


## Per-map walking segments: [{map, cells: Array[Vector2i]}], or null when unreachable.
func route(from_map: String, from_cell: Vector2i, to_map: String, to_cell: Vector2i) -> Variant:
	var hops = map_route(from_map, to_map)
	if hops == null:
		return null
	var out: Array = []
	var map_id = from_map
	var cell = from_cell
	for edge in hops:
		var cells = _walk(map_id, cell, edge.cell)
		if cells.is_empty():
			return null
		out.append({"map": map_id, "cells": cells})
		map_id = edge.to
		cell = edge.arrival
	var last = _walk(map_id, cell, to_cell)
	if last.is_empty():
		return null
	out.append({"map": map_id, "cells": last})
	return out


func _walk(map_id: String, from_cell: Vector2i, to_cell: Vector2i) -> Array:
	var g = grid(map_id)
	if from_cell == to_cell:
		return [from_cell]
	var ids = g.get_id_path(from_cell, to_cell)
	var cells: Array = []
	for point in ids:
		cells.append(Vector2i(point))
	return cells


func travel_minutes(legs: Array) -> float:
	var total = 0.0
	for i in legs.size():
		total += float(legs[i].cells.size() - 1) / WALK_SPEED
		if i < legs.size() - 1:
			total += DOOR_MINUTES
	return total


# ---------------------------------------------------------------------------- timelines


func stop_place(stop: Array, index: int) -> Dictionary:
	var key: String = stop[1]
	if key == "away":
		return {"away": true}
	if key == "festival":
		var cal = catalog.calendar
		return {"map": cal.plaza_map, "cell": cal.plaza_cell(index), "hidden": false}
	return catalog.place(key)


## Segments: {t0, t1, map, cells, move, hidden, activity}. A segment with one cell is a stay;
## with several it is a walk that takes `move` minutes and then waits out the door time.
func build_timeline(npc_id: String, index: int) -> Array:
	var rule = resolve(npc_id)
	var stops: Array = rule.stops
	var first = stop_place(stops[0], index)
	if first.has("away"):
		return [
			{
				"t0": 0.0,
				"t1": DAY_END,
				"map": "",
				"cells": [],
				"move": 0.0,
				"hidden": true,
				"activity": stops[0][2]
			}
		]
	var segments: Array = []
	var clock = 0.0
	var here = first
	var activity: String = stops[0][2]
	for i in range(1, stops.size()):
		var there = stop_place(stops[i], index)
		var due = float(stops[i][0])
		var legs = route(here.map, here.cell, there.map, there.cell)
		if legs == null:
			push_error("%s cannot walk from %s to %s" % [npc_id, stops[i - 1][1], stops[i][1]])
			legs = []
		var minutes = travel_minutes(legs)
		var depart = maxf(clock, due - minutes)
		segments.append(_stay(clock, depart, here, activity))
		clock = depart
		for k in legs.size():
			var leg = legs[k]
			var move = float(leg.cells.size() - 1) / WALK_SPEED
			var pause = DOOR_MINUTES if k < legs.size() - 1 else 0.0
			(
				segments
				. append(
					{
						"t0": clock,
						"t1": clock + move + pause,
						"map": leg.map,
						"cells": leg.cells,
						"move": move,
						"hidden": false,
						"activity": "正在路上",
					}
				)
			)
			clock += move + pause
		here = there
		activity = stops[i][2]
	segments.append(_stay(clock, DAY_END, here, activity))
	return segments


func _stay(t0: float, t1: float, place: Dictionary, text: String) -> Dictionary:
	return {
		"t0": t0,
		"t1": t1,
		"map": place.map,
		"cells": [place.cell],
		"move": 0.0,
		"hidden": place.hidden,
		"activity": text,
	}


## Where a villager is at `minute`: {present, map, position (cell units, may be fractional),
## facing, moving, hidden, activity}.
func where(npc_id: String, minute: float) -> Dictionary:
	var timeline: Array = timelines[npc_id]
	var segment: Dictionary = timeline[timeline.size() - 1]
	for s in timeline:
		if minute < s.t1:
			segment = s
			break
	if segment.map == "":
		return {
			"present": false,
			"map": "",
			"position": Vector2.ZERO,
			"facing": Vector2i.DOWN,
			"moving": false,
			"hidden": true,
			"activity": segment.activity
		}
	var cells: Array = segment.cells
	var at = Vector2(cells[0])
	var facing = Vector2i.DOWN
	var moving = false
	if cells.size() > 1:
		var progress = (
			1.0 if segment.move <= 0.0 else clampf((minute - segment.t0) / segment.move, 0.0, 1.0)
		)
		var along = progress * float(cells.size() - 1)
		var i = mini(int(along), cells.size() - 2)
		var from_cell: Vector2i = cells[i]
		var to_cell: Vector2i = cells[i + 1]
		at = Vector2(from_cell).lerp(Vector2(to_cell), along - float(i))
		facing = to_cell - from_cell
		moving = progress < 1.0
	return {
		"present": true,
		"map": segment.map,
		"position": at,
		"facing": facing,
		"moving": moving,
		"hidden": segment.hidden and not moving,
		"activity": segment.activity,
	}


## Villagers visible on `map_id` at some point today (the world creates a node for each).
func visitors(map_id: String) -> Array:
	var out: Array = []
	for npc_id in timelines:
		for s in timelines[npc_id]:
			if s.map == map_id:
				out.append(npc_id)
				break
	return out

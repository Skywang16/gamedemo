class_name FishingRules
extends RefCounted

const CAST_COST = 4
const JUNK = "seaweed"

var catalog: ContentCatalog
var stories: StoryRules


func _init(content: ContentCatalog) -> void:
	catalog = content
	stories = StoryRules.new(content)


func result(ok: bool, message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r


func level(s: FarmState) -> int:
	return stories.level(int(s.development.fishing_xp))


func rod(s: FarmState) -> Dictionary:
	return catalog.rods[int(s.development.rod)]


## The water type here ("pond", "river", "lake", "sea", ...), or "" where nothing can be fished.
func spot(s: FarmState) -> String:
	return catalog.fish_spots.get(s.current_map, "")


## The first water cell in front of the player within three cells, or (-1, -1).
func water_ahead(s: FarmState, from_cell: Vector2i, facing: Vector2i) -> Vector2i:
	for step in range(1, 4):
		var cell = from_cell + facing * step
		if catalog.is_water(cell, s.current_map):
			return cell
		if catalog.static_blocked(cell, s.current_map):
			break
	return Vector2i(-1, -1)


func weather_allows(entry: Dictionary, weather: String) -> bool:
	for w in entry.weather:
		if w == "any" or w == weather:
			return true
		if w == "any_clear" and weather in ["sunny", "cloudy", "wind"]:
			return true
	return false


func candidates(s: FarmState) -> Array:
	var out: Array = []
	var season = catalog.calendar.season_of(s.day)
	var weather = catalog.weather.weather_on(s.world_seed, s.day)
	var hour = float(s.minute) / 60.0
	var here = spot(s)
	for id in catalog.fish:
		var entry = catalog.fish[id]
		if (
			entry.spots.has(here)
			and entry.seasons.has(season)
			and weather_allows(entry, weather)
			and hour >= float(entry.hours[0])
			and hour < float(entry.hours[1])
		):
			out.append(entry)
	return out


## Rarer fish get likelier with a better rod and more experience. Returns a fish id, or
## the junk item one time in seven.
func pick(s: FarmState, rng: RandomNumberGenerator) -> String:
	var list = candidates(s)
	if list.is_empty() or rng.randf() < 0.14:
		return JUNK
	var bonus = int(s.development.rod) * 2 + int(level(s) / 2)
	var weights: Array = []
	var total = 0
	for entry in list:
		var w = int(entry.weight) + (bonus if int(entry.difficulty) >= 4 else 0)
		weights.append(w)
		total += w
	var roll = rng.randi_range(0, total - 1)
	for i in list.size():
		roll -= int(weights[i])
		if roll < 0:
			return list[i].id
	return list[0].id


## Seconds to wait for a bite; a better rod and bait shorten it.
func wait_seconds(s: FarmState, rng: RandomNumberGenerator, bait: bool) -> float:
	var base = rng.randf_range(2.0, 5.5)
	base -= float(rod(s).speed) * 0.4 + (0.8 if bait else 0.0)
	return maxf(1.0, base)


## Fraction of the timing bar that counts as a catch.
func zone_size(s: FarmState, fish_id: String) -> float:
	var difficulty = 1
	if catalog.fish.has(fish_id):
		difficulty = int(catalog.fish[fish_id].difficulty)
	var size = 0.5 - 0.07 * float(difficulty) + 0.04 * float(rod(s).window) + 0.01 * float(level(s))
	return clampf(size, 0.12, 0.6)


func cast(s: FarmState, bait: bool) -> Dictionary:
	if s.stamina < CAST_COST:
		return result(false, "体力不足")
	if bait and s.inventory.bait < 1:
		return result(false, "没有鱼饵")
	s.stamina -= CAST_COST
	if bait:
		s.inventory.bait -= 1
	return result(true, "")


func land(s: FarmState, fish_id: String) -> Dictionary:
	s.inventory[fish_id] += 1
	if fish_id == JUNK:
		s.development.fishing_xp += 1
		return result(true, "钩上来一团水草。", {"item": fish_id})
	s.development.fishing_xp += 3 + int(catalog.fish[fish_id].difficulty)
	s.stats.caught += 1
	return result(true, "钓到了%s！" % catalog.items[fish_id].name, {"item": fish_id})

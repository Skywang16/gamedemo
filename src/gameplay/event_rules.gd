class_name EventRules
extends RefCounted

## At most one small happening per morning, drawn from data/events.json. Which one is a pure
## function of the world seed and the day, so it can be replayed and tested.

var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func matches(e: Dictionary, season: String, weather: String, previous: String) -> bool:
	var w = e.when
	if w.has("seasons") and not season in w.seasons:
		return false
	if w.has("weather") and not weather in w.weather:
		return false
	if w.has("prev_weather") and not previous in w.prev_weather:
		return false
	return true


## The happening of the morning `s.day` (already advanced), or {}.
func roll(s: FarmState) -> Dictionary:
	if catalog.calendar.is_festival(s.day) or s.day <= 7:
		return {}
	var season = catalog.calendar.season_of(s.day)
	var weather = catalog.weather.weather_on(s.world_seed, s.day)
	var previous = catalog.weather.weather_on(s.world_seed, s.day - 1)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("event:%d:%d" % [s.world_seed, s.day])
	var order = range(catalog.events.size())
	for i in range(order.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var swap = order[i]
		order[i] = order[j]
		order[j] = swap
	for index in order:
		var e = catalog.events[index]
		if matches(e, season, weather, previous) and rng.randi_range(1, 100) <= int(e.when.chance):
			return e
	return {}


func apply(s: FarmState, e: Dictionary) -> void:
	var effect = e.effect
	for item in effect.get("items", {}):
		s.inventory[item] += int(effect.items[item])
	s.gold += int(effect.get("gold", 0))
	s.stats.earned += int(effect.get("gold", 0))
	var boost = int(effect.get("boost", 0))
	for key in s.plots:
		if boost <= 0:
			break
		var p = s.plots[key]
		if p.crop != "" and int(p.growth) < int(catalog.crops[p.crop].growth_days):
			p.growth += 1
			boost -= 1
	var friends = int(effect.get("friends", 0))
	if friends > 0:
		for id in s.relationships:
			s.relationships[id] = mini(100, int(s.relationships[id]) + friends)

class_name WeatherRules
extends RefCounted

## Weather is a pure function of (world seed, day). Nothing is stored, so saving,
## loading and the forecast can never disagree. Seed 0 means fair weather every
## day, which keeps rule tests independent of the weather table.

const WATERING = ["rain", "storm", "snow"]
var calendar: GameCalendar


func _init(cal: GameCalendar) -> void:
	calendar = cal


func weather_on(world_seed: int, day: int) -> String:
	if world_seed == 0 or day <= calendar.calm_days:
		return "sunny"
	var festival = calendar.festival_on(day)
	if not festival.is_empty() and festival.has("weather"):
		return festival.weather
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed * 1000003 + day * 7919
	var roll = rng.randi_range(0, 99)
	var running = 0
	for entry in calendar.weather_table[calendar.season_of(day)]:
		running += int(entry[1])
		if roll < running:
			return entry[0]
	return "sunny"


func waters_crops(weather: String) -> bool:
	return weather in WATERING


func short_name(weather: String) -> String:
	return calendar.weather_names[weather].name


func long_name(weather: String) -> String:
	return calendar.weather_names[weather].long

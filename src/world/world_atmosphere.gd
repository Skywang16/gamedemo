class_name WorldAtmosphere
extends RefCounted

## Colour grading by season and weather. Weather itself is decided by the rules layer;
## this only decides how it looks.

const SEASON_GRADE = {
	"spring": Color(1.0, 1.0, 1.0),
	"summer": Color(1.0, 0.99, 0.94),
	"autumn": Color(0.99, 0.93, 0.84),
	"winter": Color(0.88, 0.94, 1.0),
}
const WEATHER_GRADE = {
	"sunny": Color(1.0, 1.0, 1.0),
	"cloudy": Color(0.93, 0.94, 0.96),
	"rain": Color(0.78, 0.84, 0.92),
	"storm": Color(0.6, 0.66, 0.78),
	"wind": Color(0.97, 0.97, 0.97),
	"snow": Color(0.93, 0.96, 1.0),
}


static func grade(season: String, weather: String) -> Color:
	return SEASON_GRADE.get(season, Color.WHITE) * WEATHER_GRADE.get(weather, Color.WHITE)


## Fraction of the evening dusk applied at `minute` (0 during the day, 1 at nightfall).
static func dusk(minute: int) -> float:
	return clampf(float(minute - 17 * 60) / 180.0, 0.0, 1.0)


static func lit(season: String, weather: String, minute: int) -> Color:
	var base = grade(season, weather)
	return base.lerp(base * Color(0.83, 0.78, 0.69), dusk(minute) * 0.45)


const SEASON_ORDER = ["spring", "summer", "autumn", "winter"]
const BLEND_DAYS = 4


## How much of each season's look to show on `day` (1-based) of season `season_index`.
## The last days of a season lean towards the next one and the first days still carry
## some of the last, so the world drifts between looks instead of jumping on day 1.
static func season_weights(season_index: int, day: int, per_season: int) -> Dictionary:
	var weights = {"spring": 0.0, "summer": 0.0, "autumn": 0.0, "winter": 0.0}
	var here = SEASON_ORDER[season_index]
	var next = SEASON_ORDER[(season_index + 1) % 4]
	var before = SEASON_ORDER[(season_index + 3) % 4]
	var toward_next = 0.0
	var from_before = 0.0
	if day > per_season - BLEND_DAYS:
		toward_next = float(day - (per_season - BLEND_DAYS)) / float(BLEND_DAYS * 2)
	elif day <= BLEND_DAYS:
		from_before = float(BLEND_DAYS - day) / float(BLEND_DAYS * 2)
	weights[here] += 1.0 - toward_next - from_before
	weights[next] += toward_next
	weights[before] += from_before
	return weights

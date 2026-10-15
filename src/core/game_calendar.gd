class_name GameCalendar
extends RefCounted

## Pure date arithmetic. The save stores one counter (`FarmState.day`, 1-based);
## season, weekday, year and festivals are all derived from it here.

var days_per_season: int = 28
var seasons: Array = []
var weekdays: Array = []
var festivals: Array = []
var weather_names: Dictionary = {}
var weather_table: Dictionary = {}
var calm_days: int = 0


func load_data(data: Dictionary) -> String:
	if not data.has_all(
		["days_per_season", "seasons", "weekdays", "weather_names", "weather", "festivals"]
	):
		return "日历配置不完整"
	days_per_season = int(data.days_per_season)
	seasons = data.seasons
	weekdays = data.weekdays
	festivals = data.festivals
	weather_names = data.weather_names
	weather_table = data.weather
	calm_days = int(data.get("calm_days", 0))
	if days_per_season < 7 or days_per_season % weekdays.size() != 0 or seasons.size() != 4:
		return "日历长度必须是 4 个季节、且每季天数为一周的整数倍"
	for season in seasons:
		if not season is Dictionary or not season.has_all(["id", "name"]):
			return "季节配置无效"
		var entries = weather_table.get(season.id)
		if not entries is Array or entries.is_empty():
			return "季节缺少天气表：" + str(season.id)
		var total = 0
		for entry in entries:
			if not entry is Array or entry.size() != 2 or not weather_names.has(entry[0]):
				return "天气表引用了未知天气：" + str(season.id)
			total += int(entry[1])
		if total != 100:
			return "天气概率之和必须为 100：" + str(season.id)
	var seen: Dictionary = {}
	for f in festivals:
		if not f is Dictionary or not f.has_all(["id", "name", "season", "day", "kind"]):
			return "节日配置不完整"
		if season_index(f.season) < 0 or int(f.day) < 1 or int(f.day) > days_per_season:
			return "节日日期无效：" + str(f.id)
		if f.kind not in ["festival", "minor"]:
			return "节日类型无效：" + str(f.id)
		if f.has("weather") and not weather_names.has(f.weather):
			return "节日天气无效：" + str(f.id)
		var key = "%s:%d" % [f.season, int(f.day)]
		if seen.has(key):
			return "节日日期重复：" + key
		seen[key] = true
	return ""


func days_per_year() -> int:
	return days_per_season * seasons.size()


func season_index(season_id: String) -> int:
	for i in seasons.size():
		if seasons[i].id == season_id:
			return i
	return -1


func date(day: int) -> Dictionary:
	var index = maxi(day, 1) - 1
	var in_year = index % days_per_year()
	var s = in_year / days_per_season
	var of_season = in_year % days_per_season + 1
	return {
		"year": index / days_per_year() + 1,
		"season_index": s,
		"season": seasons[s].id,
		"season_name": seasons[s].name,
		"day": of_season,
		"weekday": (of_season - 1) % weekdays.size(),
		"weekday_name": weekdays[(of_season - 1) % weekdays.size()],
	}


func season_of(day: int) -> String:
	return date(day).season


func day_number(year: int, season_id: String, day_of_season: int) -> int:
	return (year - 1) * days_per_year() + season_index(season_id) * days_per_season + day_of_season


func label(day: int) -> String:
	var d = date(day)
	return "%s %d 日" % [d.season_name, d.day]


func long_label(day: int) -> String:
	var d = date(day)
	return "第 %d 年 %s %d 日 %s" % [d.year, d.season_name, d.day, d.weekday_name]


func festival_on(day: int) -> Dictionary:
	var d = date(day)
	for f in festivals:
		if f.season == d.season and int(f.day) == d.day:
			return f
	return {}


func is_festival(day: int) -> bool:
	return not festival_on(day).is_empty()


func next_festival(day: int) -> Dictionary:
	## The nearest festival strictly after `day`, with its absolute day number.
	var year = date(day).year
	var best: Dictionary = {}
	for y in [year, year + 1]:
		for f in festivals:
			var n = day_number(y, f.season, int(f.day))
			if n > day and (best.is_empty() or n < best.day):
				best = {"festival": f, "day": n}
	return best


func birthdays_on(day: int, npcs: Dictionary) -> Array:
	var d = date(day)
	var found: Array = []
	for id in npcs:
		var b = npcs[id].get("birthday")
		if b is Dictionary and b.season == d.season and int(b.day) == d.day:
			found.append(id)
	return found

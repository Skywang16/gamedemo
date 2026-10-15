extends SceneTree

var failures: Array[String] = []
var checks: int = 0
var catalog: ContentCatalog
var rules: FarmRules


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)


func run() -> void:
	catalog = ContentCatalog.new()
	check(catalog.load_content().is_empty(), "content loads")
	rules = FarmRules.new(catalog)
	test_dates()
	test_festivals()
	test_weather()
	test_rain_and_seasons()
	test_save()
	test_data()
	print("CALENDAR_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func test_dates() -> void:
	var cal = catalog.calendar
	var d = cal.date(1)
	check(d.year == 1 and d.season == "spring" and d.day == 1, "day 1 is spring 1 of year 1")
	check(d.weekday == 0 and d.weekday_name == "周一", "day 1 is Monday")
	d = cal.date(28)
	check(d.season == "spring" and d.day == 28 and d.weekday == 6, "day 28 ends spring on Sunday")
	d = cal.date(29)
	check(d.season == "summer" and d.day == 1 and d.weekday == 0, "seasons start on Monday")
	d = cal.date(112)
	check(d.season == "winter" and d.day == 28 and d.year == 1, "day 112 closes year one")
	d = cal.date(113)
	check(d.year == 2 and d.season == "spring" and d.day == 1, "year rolls over")
	check(cal.date(0).day == 1, "day below 1 clamps instead of crashing")
	check(cal.label(35) == "夏 7 日", "short label")
	check(cal.long_label(35) == "第 1 年 夏 7 日 周日", "long label")
	for day in range(1, 450):
		var x = cal.date(day)
		check(
			cal.day_number(x.year, x.season, x.day) == day,
			"date and day_number are inverse for day %d" % day
		)


func test_festivals() -> void:
	var cal = catalog.calendar
	check(cal.festival_on(8).id == "plow_rite", "spring 8 is the plow rite")
	check(cal.festival_on(2).is_empty(), "ordinary day has no festival")
	check(cal.festival_on(112).id == "year_end_feast", "winter 28 is the year-end feast")
	check(cal.festival_on(112 + 8).id == "plow_rite", "festivals repeat every year")
	var big = 0
	var minor = 0
	for f in cal.festivals:
		if f.kind == "festival":
			big += 1
		else:
			minor += 1
	check(big == 9 and minor == 4, "nine festivals and four minor festivals")
	var upcoming = cal.next_festival(1)
	check(upcoming.festival.id == "plow_rite" and upcoming.day == 8, "next festival from day 1")
	upcoming = cal.next_festival(8)
	check(upcoming.festival.id == "kite_day", "next festival is strictly later")
	upcoming = cal.next_festival(112)
	check(upcoming.day == 112 + 8, "next festival wraps into the next year")
	check(cal.birthdays_on(3, catalog.story.npcs) == ["ahe"], "Ahe's birthday is spring 3")
	check(cal.birthdays_on(2, catalog.story.npcs).is_empty(), "no birthday on an ordinary day")
	var bad = {"days_per_season": 28}
	check(not GameCalendar.new().load_data(bad).is_empty(), "incomplete calendar is rejected")


func test_weather() -> void:
	var w = catalog.weather
	for day in range(1, 400):
		check(w.weather_on(0, day) == "sunny", "seed 0 is always fair")
	for seed_value in [1, 77, 123456, 2147483647]:
		for day in range(1, 4):
			check(w.weather_on(seed_value, day) == "sunny", "first days are calm")
		for day in range(1, 300):
			check(
				w.weather_on(seed_value, day) == w.weather_on(seed_value, day),
				"weather is deterministic"
			)
	var counts = {}
	for day in range(1, 112 * 6 + 1):
		var weather = w.weather_on(4242, day)
		var season = catalog.calendar.season_of(day)
		counts[weather] = int(counts.get(weather, 0)) + 1
		check(catalog.calendar.weather_names.has(weather), "known weather id")
		var allowed = []
		for entry in catalog.calendar.weather_table[season]:
			allowed.append(entry[0])
		var festival = catalog.calendar.festival_on(day)
		if festival.is_empty() or not festival.has("weather"):
			check(weather in allowed or day <= 3, "%s weather is legal in %s" % [weather, season])
		else:
			check(weather == festival.weather, "festival forces its weather")
	check(counts.get("sunny", 0) > 100, "sunny days are common")
	check(counts.get("rain", 0) > 40, "rain does occur")
	check(counts.get("snow", 0) > 40, "snow does occur")
	check(not counts.has("tsunami"), "no unknown weather")
	var other = 0
	for day in range(4, 400):
		if w.weather_on(1, day) != w.weather_on(2, day):
			other += 1
	check(other > 50, "different seeds give different years")
	check(
		w.waters_crops("rain") and w.waters_crops("storm") and w.waters_crops("snow"), "wet weather"
	)
	check(not w.waters_crops("sunny") and not w.waters_crops("wind"), "dry weather")


func seed_with(day: int, wanted_wet: bool) -> int:
	for candidate in range(1, 2000):
		if catalog.weather.waters_crops(catalog.weather.weather_on(candidate, day)) == wanted_wet:
			return candidate
	return 0


func planted(day: int, seed_value: int) -> Array:
	var s = FarmState.new_game(catalog, seed_value)
	s.day = day
	var cell = Vector2i(34, 20)
	rules.apply_tool(s, "scythe", cell, cell, "turnip")
	rules.apply_tool(s, "hoe", cell, cell, "turnip")
	rules.apply_tool(s, "seed", cell, cell, "turnip")
	return [s, FarmState.cell_key(cell)]


func test_rain_and_seasons() -> void:
	var rainy = seed_with(4, true)
	var dry = seed_with(4, false)
	check(rainy > 0 and dry > 0, "found a wet and a dry seed for spring 4")
	var pair = planted(3, rainy)
	var s: FarmState = pair[0]
	check(not s.plots[pair[1]].watered, "fresh seed is dry")
	var morning = rules.next_day(s)
	check(s.day == 4 and catalog.weather.waters_crops(morning.weather), "the morning is wet")
	check(s.plots[pair[1]].watered, "rain waters every plot overnight")
	check(not morning.season_changed and morning.withered == 0, "no season change in spring")
	pair = planted(3, dry)
	s = pair[0]
	rules.next_day(s)
	check(not s.plots[pair[1]].watered, "dry morning leaves soil dry")
	# Planting honours the season.
	var turnip = catalog.crops.turnip
	var saved = turnip.seasons
	turnip.seasons = ["spring"]
	s = FarmState.new_game(catalog)
	s.day = 29
	var cell = Vector2i(34, 20)
	rules.apply_tool(s, "scythe", cell, cell, "turnip")
	rules.apply_tool(s, "hoe", cell, cell, "turnip")
	var before = s.snapshot(catalog)
	var response = rules.apply_tool(s, "seed", cell, cell, "turnip")
	check(not response.ok and not response.message.is_empty(), "out-of-season seed explains why")
	check(before == s.snapshot(catalog), "out-of-season planting is atomic")
	s.day = 28
	check(rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "in-season planting works")
	# Season change withers what cannot live in the new season, but keeps the soil.
	morning = rules.next_day(s)
	check(s.day == 29 and morning.season_changed, "spring turns into summer")
	check(morning.withered == 1, "the out-of-season crop withers")
	var key = FarmState.cell_key(cell)
	check(s.plots.has(key) and s.plots[key].crop == "", "tilled soil survives the season")
	check(s.inventory.turnip_seed == 7, "withering does not refund or duplicate seeds")
	turnip.seasons = saved
	s = FarmState.new_game(catalog)
	s.day = 28
	rules.apply_tool(s, "scythe", cell, cell, "turnip")
	rules.apply_tool(s, "hoe", cell, cell, "turnip")
	rules.apply_tool(s, "seed", cell, cell, "turnip")
	morning = rules.next_day(s)
	check(morning.withered == 0 and s.plots[key].crop == "turnip", "all-season crops survive")
	# A full-grown crop that withers must not stay counted as ready.
	turnip.seasons = ["spring"]
	s = FarmState.new_game(catalog)
	s.day = 28
	rules.apply_tool(s, "scythe", cell, cell, "turnip")
	rules.apply_tool(s, "hoe", cell, cell, "turnip")
	rules.apply_tool(s, "seed", cell, cell, "turnip")
	s.plots[key].growth = int(turnip.growth_days)
	morning = rules.next_day(s)
	check(morning.ready == 0 and morning.withered == 1, "withered crops are not ready")
	turnip.seasons = saved


func test_save() -> void:
	var validator = SaveValidator.new(catalog)
	var s = FarmState.new_game(catalog, 987654)
	s.day = 40
	var snapshot = s.snapshot(catalog)
	check(snapshot.schema_version == 5, "schema is 5")
	check(validator.validate(snapshot).is_empty(), "calendar state validates")
	var restored = FarmState.from_validated(snapshot)
	check(restored.world_seed == 987654 and restored.day == 40, "seed and day round-trip")
	var json = JSON.parse_string(JSON.stringify(snapshot))
	check(validator.validate(json).is_empty(), "calendar state survives JSON")
	check(
		FarmState.from_validated(json).world_seed == 987654,
		"seed is an integer after JSON round-trip"
	)
	for bad in [-1, 2147483648, 1.5, "7", null]:
		var broken = s.snapshot(catalog)
		broken.world_seed = bad
		check(not validator.validate(broken).is_empty(), "bad seed rejected: " + str(bad))
	var missing = s.snapshot(catalog)
	missing.erase("world_seed")
	check(not validator.validate(missing).is_empty(), "missing seed rejected")
	var old = s.snapshot(catalog)
	old.schema_version = 4
	check(not validator.validate(old).is_empty(), "schema 4 saves are not accepted")
	var a = FarmState.new_game(catalog, 5)
	var b = FarmState.new_game(catalog, 5)
	a.day = 50
	b.day = 50
	check(
		(
			catalog.weather.weather_on(a.world_seed, a.day)
			== catalog.weather.weather_on(
				FarmState.from_validated(b.snapshot(catalog)).world_seed, b.day
			)
		),
		"forecast is identical before and after save/load"
	)


func test_data() -> void:
	for id in catalog.crops:
		for season in catalog.crops[id].seasons:
			check(catalog.calendar.season_index(season) >= 0, "crop season is real: " + id)
	for id in catalog.story.npcs:
		var b = catalog.story.npcs[id].get("birthday")
		check(b is Dictionary, "npc has a birthday: " + id)
		if b is Dictionary:
			check(catalog.calendar.season_index(b.season) >= 0, "birthday season: " + id)
			check(int(b.day) >= 1 and int(b.day) <= 28, "birthday day: " + id)
			check(
				not catalog.calendar.is_festival(
					catalog.calendar.day_number(1, b.season, int(b.day))
				),
				"birthday is not on a festival: " + id
			)

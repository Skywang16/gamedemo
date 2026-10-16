extends SceneTree

## Villager routines: rule choice, timelines, walking and the festival crowd.

var failures: Array[String] = []
var checks: int = 0
var catalog: ContentCatalog


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)


func run() -> void:
	catalog = ContentCatalog.new()
	var error = catalog.load_content()
	check(error.is_empty(), "content loads: " + error)
	if error.is_empty():
		test_rules()
		test_timelines()
		test_walking()
		test_festival_crowd()
		test_determinism()
		test_married_life()
		test_days_of_the_year()
	print("WORLD_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func plan(day: int, weather: String = "sunny", stage: int = 0, spouse: String = "") -> NpcPlanner:
	var planner = NpcPlanner.new(catalog, {})
	(
		planner
		. plan_day(
			{
				"day": day,
				"date": catalog.calendar.date(day),
				"weather": weather,
				"stage": stage,
				"birthdays": catalog.calendar.birthdays_on(day, catalog.story.npcs),
				"festival": catalog.calendar.is_festival(day),
				"spouse": spouse,
			}
		)
	)
	return planner


func test_rules() -> void:
	var rainy = plan(2, "rain")
	var fair = plan(2, "sunny")
	check(rainy.resolve("hazel") != fair.resolve("hazel"), "rain changes the routine")
	check(
		rainy.where("hazel", 9.0 * 60.0).activity == "在雨棚下分装种子",
		"hazel packs seeds under the awning when it rains"
	)
	var birthday = plan(3)
	check(
		birthday.where("hazel", 11.0 * 60.0).activity == "在摊位前收邻居们的小礼物",
		"birthdays have their own day"
	)
	check(plan(10).resolve("hazel") == plan(17).resolve("hazel"), "ordinary Tuesdays share a rule")
	var stages = {}
	for npc_id in catalog.story.npcs:
		for rule in catalog.story.npcs[npc_id].schedule.rules:
			for key in rule.when:
				stages[key] = true
	for key in ["birthday", "festival", "weekdays", "weather"]:
		check(stages.has(key), "the cast uses %s conditions" % key)
	check(
		not plan(1, "sunny", 2).bridge_open() and plan(1, "sunny", 3).bridge_open(),
		"the bridge opens at stage three"
	)


func test_timelines() -> void:
	for day in [1, 2, 3, 8, 13, 29, 45, 120]:
		for weather in ["sunny", "rain"]:
			var planner = plan(day, weather, 3)
			for npc_id in catalog.story.npcs:
				var timeline: Array = planner.timelines[npc_id]
				var label = "%s day %d %s" % [npc_id, day, weather]
				check(not timeline.is_empty(), "has a timeline: " + label)
				check(
					is_equal_approx(timeline[0].t0, 0.0),
					"the timeline starts at midnight: " + label
				)
				check(
					is_equal_approx(timeline[timeline.size() - 1].t1, NpcPlanner.DAY_END),
					"and ends after the day: " + label
				)
				for i in timeline.size():
					var s: Dictionary = timeline[i]
					check(s.t1 >= s.t0, "segments never run backwards: " + label)
					if i > 0:
						check(is_equal_approx(s.t0, timeline[i - 1].t1), "segments join: " + label)
					if s.map == "":
						continue
					for cell in s.cells:
						check(
							not catalog.blocked(cell, s.map),
							"cells are walkable: %s %s %s" % [label, s.map, cell]
						)
					for k in range(1, s.cells.size()):
						var step: Vector2i = s.cells[k] - s.cells[k - 1]
						check(
							absi(step.x) + absi(step.y) == 1,
							"walks go one cell at a time: " + label
						)
	var planner = plan(2)
	var early = planner.where("hazel", 6.0 * 60.0 + 10.0)
	check(
		early.present and not early.hidden and early.map == "hazel_home", "hazel is indoors at dawn"
	)
	var late = 0
	for npc_id in catalog.story.npcs:
		var info = planner.where(npc_id, 25.0 * 60.0)
		if not info.present or catalog.region(info.map).environment == "interior":
			late += 1
	check(late >= 24, "almost everyone is home or away by one in the morning (%d)" % late)


func test_walking() -> void:
	var planner = plan(2)
	var walkers = 0
	for npc_id in catalog.story.npcs:
		for s in planner.timelines[npc_id]:
			if s.cells.size() < 2 or s.map == "":
				continue
			walkers += 1
			var a = planner.where(npc_id, s.t0 + 0.01)
			var b = planner.where(npc_id, s.t0 + 1.01)
			if s.move > 1.1:
				check(a.moving and b.moving, "walkers are moving: " + npc_id)
				check(
					a.position.distance_to(b.position) <= NpcPlanner.WALK_SPEED + 0.01,
					"nobody outruns the walk speed: " + npc_id
				)
				check(
					a.position.distance_to(b.position) > 0.5,
					"walkers actually cover ground: " + npc_id
				)
	check(walkers >= 60, "a normal day has plenty of walking (%d legs)" % walkers)
	var crossed = 0
	for npc_id in catalog.story.npcs:
		var maps = []
		for s in planner.timelines[npc_id]:
			if s.map != "" and (maps.is_empty() or maps[maps.size() - 1] != s.map):
				maps.append(s.map)
		if maps.size() >= 3:
			crossed += 1
	check(crossed >= 10, "many villagers cross between maps in a day (%d)" % crossed)
	for map_id in catalog.regions:
		if map_id == "home_farm" or map_id.begins_with("mine"):
			continue
		var found = false
		for day in [2, 3, 8]:
			if not plan(day, "sunny", 3).visitors(map_id).is_empty():
				found = true
		check(found or map_id in ["lake", "cottage", "far_shore"], "someone visits %s" % map_id)


func test_festival_crowd() -> void:
	var day = catalog.calendar.day_number(1, "spring", 8)
	var planner = plan(day)
	var plaza = {}
	for i in 40:
		plaza[catalog.calendar.plaza_cell(i)] = true
	for cell in plaza:
		check(
			not catalog.blocked(cell, catalog.calendar.plaza_map),
			"festival stand is walkable: " + str(cell)
		)
		check(
			planner.route("town", Vector2i(3, 30), catalog.calendar.plaza_map, cell) != null,
			"festival stand is reachable: " + str(cell)
		)
	var gathered = 0
	for npc_id in catalog.story.npcs:
		var info = planner.where(npc_id, 11.0 * 60.0)
		if info.present and info.map == catalog.calendar.plaza_map:
			gathered += 1
			check(
				plaza.has(Vector2i(info.position.round())),
				"festival guests stand on the plaza: " + npc_id
			)
	check(gathered >= 22, "most of the town comes to the festival (%d)" % gathered)
	var cells = {}
	for npc_id in catalog.story.npcs:
		var info = planner.where(npc_id, 11.0 * 60.0)
		if info.present and info.map == catalog.calendar.plaza_map:
			check(not cells.has(info.position), "no two guests share a spot")
			cells[info.position] = true


func test_determinism() -> void:
	var a = plan(45, "snow", 2)
	var b = plan(45, "snow", 2)
	check(a.timelines == b.timelines, "the same day always plans the same")
	var c = plan(46, "snow", 2)
	check(a.timelines != c.timelines, "different days differ")
	for npc_id in catalog.story.npcs:
		check(
			a.where(npc_id, 800.0) == b.where(npc_id, 800.0),
			"where() is a pure function: " + npc_id
		)


func test_married_life() -> void:
	var lovers = []
	for id in catalog.story.npcs:
		if catalog.story.npcs[id].romance:
			lovers.append(id)
	check(lovers.size() == 12, "twelve people can be married")
	for id in lovers:
		for day in [2, 8, 14]:
			if catalog.calendar.birthdays_on(day, catalog.story.npcs).has(id):
				continue
			var weather = "rain" if day == 14 else "sunny"
			var planner = plan(day, weather, 6, id)
			var timeline: Array = planner.timelines[id]
			var rule = planner.resolve(id)
			var festival = catalog.calendar.is_festival(day)
			if not festival:
				check(
					rule.when.get("spouse", false),
					"a spouse follows the married rule: %s day %d" % [id, day]
				)
				var homes = timeline.filter(func(t): return t.map == "cottage")
				check(not homes.is_empty(), "a spouse lives in the farmhouse: " + id)
				var late = planner.where(id, 22.0 * 60.0 + 30.0)
				check(late.map == "cottage", "and sleeps there: " + id)
			for s in timeline:
				if s.map == "":
					continue
				for cell in s.cells:
					check(
						not catalog.blocked(cell, s.map),
						"married routes are walkable: %s %s" % [id, s.map]
					)
	var single = plan(2, "sunny", 6, "").resolve("hazel")
	check(not single.when.get("spouse", false), "single villagers keep their own days")
	var wedded = plan(2, "sunny", 6, "hazel")
	check(wedded.resolve("silas").when.get("spouse", false) == false, "only the spouse moves in")


func test_days_of_the_year() -> void:
	# Every weekday of every season resolves a rule for everyone (no gaps in the rule lists).
	var counted = 0
	for day in range(1, 113, 3):
		var planner = plan(day, ["sunny", "rain", "snow", "cloudy"][day % 4], day % 7)
		for npc_id in catalog.story.npcs:
			check(
				not planner.resolve(npc_id).is_empty(), "a rule matches: %s day %d" % [npc_id, day]
			)
			counted += 1
	check(counted > 1000, "the sweep covers the year")

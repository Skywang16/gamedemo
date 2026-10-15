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
	test_quiet_feedback()
	test_trees()
	test_clearing()
	test_crops()
	test_transactions()
	test_saves()
	test_reachability()
	print("DOMAIN_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func test_quiet_feedback() -> void:
	var s = FarmState.new_game(catalog)
	var cell = Vector2i(34, 20)
	for tool in ["hoe", "seed", "water", "harvest", "axe", "pickaxe"]:
		var before = s.snapshot(catalog)
		var response = rules.apply_tool(s, tool, cell, cell, "turnip")
		check(
			not response.ok and response.message.is_empty() and before == s.snapshot(catalog),
			"wrong tool stays silent and atomic: " + tool
		)
	rules.apply_tool(s, "scythe", cell, cell, "turnip")
	check(
		rules.apply_tool(s, "seed", cell, cell, "turnip").message.is_empty(),
		"unprepared ground does not teach sequence"
	)
	for tool in ["hoe", "seed", "water"]:
		var response = rules.apply_tool(s, tool, cell, cell, "turnip")
		check(
			response.ok and response.message.is_empty(),
			"routine action uses world feedback: " + tool
		)
	check(
		rules.apply_tool(s, "water", cell, cell, "turnip").message.is_empty(),
		"wet soil stays silent"
	)
	check(
		rules.apply_tool(s, "harvest", cell, cell, "turnip").message.is_empty(),
		"immature crops stay silent"
	)


func test_trees() -> void:
	var s = FarmState.new_game(catalog)
	var cell = Vector2i(32, 14)
	var id = catalog.tree_at(cell, s)
	check(not id.is_empty(), "tree indexed independently from static obstacles")
	var before = s.snapshot(catalog)
	check(
		not rules.apply_tool(s, "hoe", cell, cell, "turnip").ok and s.snapshot(catalog) == before,
		"wrong tool cannot damage tree"
	)
	check(
		not rules.apply_tool(s, "axe", cell, cell + Vector2i(3, 0), "turnip").ok,
		"tree chopping respects reach"
	)
	for hit in range(1, 6):
		var response = rules.apply_tool(s, "axe", cell, cell + Vector2i.DOWN, "turnip")
		check(
			response.ok and response.tree_hits == hit and s.tree_damage[id] == hit,
			"tree hit commits exactly once"
		)
		check(
			catalog.blocked(cell, s.current_map, s.tree_damage) == (hit < 5),
			"standing tree and stump block until cleared"
		)
		check(
			s.inventory.wood == (0 if hit < 3 else (4 if hit < 5 else 5)),
			"wood only awarded at fell and uproot"
		)
	check(s.stamina == 85, "five axe hits cost fifteen stamina")
	before = s.snapshot(catalog)
	check(
		not rules.apply_tool(s, "axe", cell, cell, "turnip").ok and before == s.snapshot(catalog),
		"cleared tree cannot pay again"
	)
	var restored = FarmState.from_validated(s.snapshot(catalog))
	check(
		(
			restored.tree_damage[id] == 5
			and not catalog.blocked(cell, s.current_map, restored.tree_damage)
		),
		"tree clearance persists"
	)
	s.player_position = Vector2(cell) * 32 + Vector2(16, 16)
	check(
		SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(),
		"player can save on cleared tree tile"
	)
	for tree_id in catalog.tree_ids:
		var entry = catalog.tree_ids[tree_id]
		if entry.map == "home_farm" and catalog.plantable(entry.cell, {tree_id: 5}):
			s.tree_damage[tree_id] = 5
			check(
				rules.apply_tool(s, "hoe", entry.cell, entry.cell, "turnip").ok,
				"cleared tree ground can be farmed"
			)
			check(
				SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(),
				"farming reclaimed tree tile validates"
			)
			break
	s.tree_damage[id] = 1
	s.stamina = 0
	before = s.snapshot(catalog)
	check(
		not rules.apply_tool(s, "axe", cell, cell, "turnip").ok and before == s.snapshot(catalog),
		"exhaustion cannot damage trees"
	)
	var invalid = before.duplicate(true)
	invalid.tree_damage[id] = 7
	check(not SaveStore.new(catalog).validate(invalid).is_empty(), "invalid tree stage rejected")
	s.current_map = "forest"
	var p = catalog.regions.forest.trees[0]
	cell = Vector2i(p[0], p[1])
	s.stamina = 100
	check(rules.apply_tool(s, "axe", cell, cell, "turnip").ok, "forest trees support chopping")


func test_clearing() -> void:
	var s = FarmState.new_game(catalog)
	for entry in [
		[Vector2i(34, 20), "scythe", "fiber", 1],
		[Vector2i(35, 22), "axe", "wood", 3],
		[Vector2i(37, 23), "pickaxe", "stone", 3]
	]:
		var cell = entry[0]
		var before = s.snapshot(catalog)
		check(not rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "debris prevents tilling")
		check(before == s.snapshot(catalog), "blocked till leaves state unchanged")
		check(not rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "debris prevents planting")
		var wrong = "axe" if entry[1] != "axe" else "scythe"
		check(
			not rules.apply_tool(s, wrong, cell, cell, "turnip").ok,
			"correct clearing tool required"
		)
		var stamina = s.stamina
		check(rules.apply_tool(s, entry[1], cell, cell, "turnip").ok, "clear debris")
		check(
			s.inventory[entry[2]] == 1 and s.stamina == stamina - entry[3],
			"clearing gives material and charges stamina"
		)
		before = s.snapshot(catalog)
		check(
			(
				not rules.apply_tool(s, entry[1], cell, cell, "turnip").ok
				and before == s.snapshot(catalog)
			),
			"clearing reward cannot repeat"
		)
		check(rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "cleared land can be tilled")
	rules.next_day(s)
	check(s.cleared.size() == 3, "debris stays cleared across days")
	var restored = FarmState.from_validated(s.snapshot(catalog))
	check(
		catalog.debris_at(Vector2i(34, 20), restored).is_empty(), "clearing survives serialization"
	)


func test_crops() -> void:
	var s = FarmState.new_game(catalog)
	var cell = Vector2i(34, 20)
	var key = FarmState.cell_key(cell)
	check(s.plots.is_empty() and s.cleared.is_empty(), "new farm starts wild")
	check(rules.apply_tool(s, "scythe", cell, cell, "turnip").ok, "clear grass before planting")
	s.stamina = 100
	var before = s.snapshot(catalog)
	check(not rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "planting requires tilling")
	check(before == s.snapshot(catalog), "failed planting is atomic")
	check(not rules.apply_tool(s, "hoe", cell, Vector2i(1, 1), "turnip").ok, "tool reach limited")
	check(
		not rules.apply_tool(s, "hoe", Vector2i(40, 20), Vector2i(40, 20), "turnip").ok,
		"plantable boundary"
	)
	check(rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "till succeeds")
	check(s.stamina == 98, "tilling costs stamina")
	check(rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "seed succeeds")
	check(s.inventory.turnip_seed == 7, "one seed consumed")
	before = s.snapshot(catalog)
	check(
		not rules.apply_tool(s, "seed", cell, cell, "carrot").ok,
		"occupied plot cannot be overwritten"
	)
	check(before == s.snapshot(catalog), "occupied planting atomic")
	rules.next_day(s)
	check(s.plots[key].growth == 0, "dry crops do not grow")
	check(s.stamina == 100 and s.minute == 480, "sleep restores stamina and morning")
	for day in range(3):
		check(rules.apply_tool(s, "water", cell, cell, "turnip").ok, "water succeeds")
		before = s.snapshot(catalog)
		check(not rules.apply_tool(s, "water", cell, cell, "turnip").ok, "double watering rejected")
		check(before == s.snapshot(catalog), "double watering does not charge")
		rules.next_day(s)
		check(s.plots[key].growth == day + 1, "exactly one growth per wet day")
		check(not s.plots[key].watered, "water resets on next day")
	check(rules.apply_tool(s, "harvest", cell, cell, "turnip").ok, "mature crop harvested")
	check(s.inventory.turnip == 1 and s.plots[key].crop == "", "harvest transfers crop once")
	check(not rules.apply_tool(s, "harvest", cell, cell, "turnip").ok, "cannot harvest twice")
	check(
		rules.apply_tool(s, "seed", cell, cell, "carrot").ok,
		"harvested plot reusable for another crop"
	)
	for i in range(3):
		rules.apply_tool(s, "water", cell, cell, "carrot")
		rules.next_day(s)
	check(
		not rules.apply_tool(s, "harvest", cell, cell, "carrot").ok,
		"carrot uses its configured four days"
	)
	rules.apply_tool(s, "water", cell, cell, "carrot")
	rules.next_day(s)
	check(rules.apply_tool(s, "harvest", cell, cell, "carrot").ok, "carrot matures on day four")
	s.stamina = 0
	before = s.snapshot(catalog)
	check(
		not rules.apply_tool(s, "hoe", Vector2i(35, 20), cell, "turnip").ok, "exhaustion enforced"
	)
	check(before == s.snapshot(catalog), "exhaustion failure atomic")
	s.inventory.turnip_seed = 0
	s.stamina = 100
	before = s.snapshot(catalog)
	check(not rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "empty seed inventory enforced")
	check(before == s.snapshot(catalog), "seed shortage atomic")


func test_transactions() -> void:
	var s = FarmState.new_game(catalog)
	check(rules.buy_seeds(s, "turnip", 5).ok, "bulk purchase")
	check(s.gold == 20 and s.inventory.turnip_seed == 13, "purchase balances")
	var before = s.snapshot(catalog)
	check(not rules.buy_seeds(s, "carrot", 5).ok, "insufficient funds")
	check(before == s.snapshot(catalog), "failed purchase atomic")
	check(not rules.buy_seeds(s, "carrot", -1).ok, "negative purchase rejected")
	s.inventory.turnip = 2
	s.inventory.carrot = 1
	check(rules.sale_quote(s) == {"gold": 44, "count": 3}, "sale quote")
	check(rules.sell_produce(s).ok, "produce sold")
	check(s.gold == 64 and s.inventory.turnip == 0 and s.inventory.carrot == 0, "sale balances")
	check(s.inventory.turnip_seed == 13 and s.inventory.carrot_seed == 4, "seeds preserved on sale")
	check(not rules.sell_produce(s).ok, "empty sale rejected")


func write_json(path: String, value: Variant) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


func test_saves() -> void:
	var folder = "user://tests-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var store = SaveStore.new(catalog, folder)
	var s = FarmState.new_game(catalog)
	check(store.validate(s.snapshot(catalog)).is_empty(), "new state is valid")
	check(store.save_game(s).is_empty(), "first save succeeds")
	s.gold = 77
	check(store.save_game(s).is_empty(), "second save succeeds")
	var reader = SaveStore.new(catalog, folder)
	var recovered = reader.load_game()
	check(
		recovered.state != null and recovered.state.snapshot(catalog) == s.snapshot(catalog),
		"save roundtrip preserves complete state"
	)
	var data = s.snapshot(catalog)
	data.schema_version = 1
	write_json(store.slot_path(), data)
	check(reader.load_game().state == null, "old development format rejected without migration")
	check(reader.save_game(s).is_empty(), "new game overwrites development save directly")
	check(not FileAccess.file_exists(store.slot_path() + ".bak"), "no backup produced")
	write_json(store.slot_path(), "broken")
	check(reader.load_game().state == null, "invalid save cannot enter domain")
	data = s.snapshot(catalog)
	data.stamina = -1
	check(not store.validate(data).is_empty(), "negative stamina rejected")
	data = s.snapshot(catalog)
	data.inventory.turnip = "one"
	check(not store.validate(data).is_empty(), "inventory type checked")
	data = s.snapshot(catalog)
	data.plots["not,a-coordinate"] = {"crop": "", "growth": 0, "watered": false}
	check(not store.validate(data).is_empty(), "bad coordinate rejected")
	data = s.snapshot(catalog)
	data.plots["34,20"] = {"crop": "missing_crop", "growth": 0, "watered": false}
	check(not store.validate(data).is_empty(), "unknown crop rejected")
	data = s.snapshot(catalog)
	data.player_position = [1200, 432]
	check(not store.validate(data).is_empty(), "obstructed spawn rejected")
	data = s.snapshot(catalog)
	data.day = 1.25
	check(not store.validate(data).is_empty(), "fractional days rejected")
	# Clean up only this run's isolated directory.
	var dir = DirAccess.open(folder)
	for name in dir.get_files():
		dir.remove(name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))


func test_reachability() -> void:
	var start = Vector2i(int(catalog.map.spawn[0] / 32), int(catalog.map.spawn[1] / 32))
	var visited = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current = queue.pop_front()
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = current + offset
			if not catalog.blocked(n) and not visited.has(n):
				visited[n] = true
				queue.append(n)
	for station in catalog.map.stations:
		check(
			visited.has(Vector2i(station.cell[0], station.cell[1])),
			"station reachable: " + station.id
		)
	for y in range(int(catalog.map.height)):
		for x in range(int(catalog.map.width)):
			if catalog.plantable(Vector2i(x, y)):
				check(visited.has(Vector2i(x, y)), "field reachable: %d,%d" % [x, y])

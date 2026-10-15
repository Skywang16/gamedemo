extends SceneTree

var failures: Array[String] = []
var checks: int = 0
var catalog: ContentCatalog
var rules: FarmRules
var shops: ShopRules


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
		rules = FarmRules.new(catalog)
		shops = ShopRules.new(catalog)
		test_quiet_feedback()
		test_trees()
		test_clearing()
		test_crops()
		test_regrowing_crops()
		test_seasons()
		test_transactions()
		test_saves()
		test_reachability()
	print("DOMAIN_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


## A plantable farm cell with no tree or debris, optionally the `skip`-th such cell.
func free_cell(s: FarmState, skip: int = 0) -> Vector2i:
	var seen = 0
	for y in range(18, 66):
		for x in range(4, 90):
			var cell = Vector2i(x, y)
			if (
				catalog.plantable(cell, s.tree_damage)
				and catalog.tree_at(cell, s).is_empty()
				and catalog.debris_at(cell, s).is_empty()
			):
				if seen == skip:
					return cell
				seen += 1
	return Vector2i(-1, -1)


func debris_cell(s: FarmState, kind: String) -> Vector2i:
	for cell in catalog.debris_cells:
		var node = catalog.debris_cells[cell]
		if (
			node.kind == kind
			and catalog.plantable(cell, s.tree_damage)
			and catalog.tree_at(cell, s).is_empty()
		):
			return cell
	return Vector2i(-1, -1)


func test_quiet_feedback() -> void:
	var s = FarmState.new_game(catalog)
	var cell = free_cell(s)
	check(cell.x >= 0, "the farm has free ground")
	for tool in ["seed", "water", "harvest", "axe", "pickaxe", "scythe"]:
		var before = s.snapshot(catalog)
		var response = rules.apply_tool(s, tool, cell, cell, "turnip")
		check(
			not response.ok and response.message.is_empty() and before == s.snapshot(catalog),
			"wrong tool stays silent and atomic: " + tool
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
	var id = ""
	var cell = Vector2i.ZERO
	for tree_id in catalog.tree_ids:
		if catalog.tree_ids[tree_id].map == "home_farm":
			id = tree_id
			cell = catalog.tree_ids[tree_id].cell
			break
	check(not id.is_empty() and catalog.tree_at(cell, s) == id, "trees are indexed on the farm")
	var before = s.snapshot(catalog)
	check(
		not rules.apply_tool(s, "hoe", cell, cell, "turnip").ok and s.snapshot(catalog) == before,
		"wrong tool cannot damage a tree"
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
		"a cleared tree cannot pay again"
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
		"the player can save on a cleared tree tile"
	)
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
	var kinds = {
		"weeds": ["scythe", "fiber", 1],
		"branch": ["axe", "wood", 3],
		"rock": ["pickaxe", "stone", 3]
	}
	for kind in kinds:
		var cell = debris_cell(s, kind)
		var tool: String = kinds[kind][0]
		var item: String = kinds[kind][1]
		check(cell.x >= 0, "the farm has %s to clear" % kind)
		var before = s.snapshot(catalog)
		check(not rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "debris prevents tilling")
		check(before == s.snapshot(catalog), "blocked till leaves state unchanged")
		check(not rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "debris prevents planting")
		var wrong = "axe" if tool != "axe" else "scythe"
		check(
			not rules.apply_tool(s, wrong, cell, cell, "turnip").ok,
			"the right clearing tool is required"
		)
		var stamina = s.stamina
		check(rules.apply_tool(s, tool, cell, cell, "turnip").ok, "clear " + kind)
		check(
			s.inventory[item] == 1 and s.stamina == stamina - int(kinds[kind][2]),
			"clearing gives material and charges stamina"
		)
		before = s.snapshot(catalog)
		check(
			(
				not rules.apply_tool(s, tool, cell, cell, "turnip").ok
				and before == s.snapshot(catalog)
			),
			"clearing reward cannot repeat"
		)
		check(rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "cleared land can be tilled")
	rules.next_day(s)
	check(s.cleared.size() == 3, "debris stays cleared across days")
	var restored = FarmState.from_validated(s.snapshot(catalog))
	check(restored.cleared.size() == 3, "clearing survives serialization")
	s.development.tools.axe = 2
	check(rules.cost(s, "axe", 3) == 1, "tool upgrades lower stamina cost but never below one")


func test_crops() -> void:
	var s = FarmState.new_game(catalog)
	var cell = free_cell(s)
	var key = FarmState.cell_key(cell)
	check(s.plots.is_empty() and s.cleared.is_empty(), "a new farm starts wild")
	var before = s.snapshot(catalog)
	check(not rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "planting requires tilling")
	check(before == s.snapshot(catalog), "failed planting is atomic")
	check(
		not rules.apply_tool(s, "hoe", cell, Vector2i(1, 1), "turnip").ok, "tool reach is limited"
	)
	check(
		not rules.apply_tool(s, "hoe", Vector2i(2, 2), Vector2i(2, 2), "turnip").ok,
		"the field has a boundary"
	)
	check(rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "till succeeds")
	check(s.stamina == 98, "tilling costs stamina")
	check(rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "seed succeeds")
	check(s.inventory.turnip_seed == 7, "one seed consumed")
	before = s.snapshot(catalog)
	check(
		not rules.apply_tool(s, "seed", cell, cell, "carrot").ok,
		"an occupied plot cannot be overwritten"
	)
	check(before == s.snapshot(catalog), "occupied planting is atomic")
	var morning = rules.next_day(s)
	check(s.plots[key].growth == 0 and morning.grew == 0, "dry crops do not grow")
	check(s.stamina == 100 and s.minute == FarmState.MORNING, "sleep restores stamina and morning")
	for day in range(3):
		check(rules.apply_tool(s, "water", cell, cell, "turnip").ok, "water succeeds")
		before = s.snapshot(catalog)
		check(not rules.apply_tool(s, "water", cell, cell, "turnip").ok, "double watering rejected")
		check(before == s.snapshot(catalog), "double watering does not charge")
		rules.next_day(s)
		check(s.plots[key].growth == day + 1, "exactly one growth per wet day")
		check(not s.plots[key].watered, "water resets on the next day")
	check(rules.apply_tool(s, "harvest", cell, cell, "turnip").ok, "a mature crop is harvested")
	check(s.inventory.turnip == 1 and s.plots[key].crop == "", "harvest transfers the crop once")
	check(s.development.farming_xp == 10 and s.stats.harvested == 1, "harvest earns experience")
	check(not rules.apply_tool(s, "harvest", cell, cell, "turnip").ok, "cannot harvest twice")
	check(
		rules.apply_tool(s, "seed", cell, cell, "carrot").ok,
		"a harvested plot can take another crop"
	)
	for i in range(3):
		rules.apply_tool(s, "water", cell, cell, "carrot")
		rules.next_day(s)
	check(not rules.apply_tool(s, "harvest", cell, cell, "carrot").ok, "carrot takes its four days")
	rules.apply_tool(s, "water", cell, cell, "carrot")
	rules.next_day(s)
	check(rules.apply_tool(s, "harvest", cell, cell, "carrot").ok, "carrot matures on day four")
	s.stamina = 0
	before = s.snapshot(catalog)
	var other = free_cell(s, 1)
	check(not rules.apply_tool(s, "hoe", other, other, "turnip").ok, "exhaustion is enforced")
	check(before == s.snapshot(catalog), "exhaustion failure is atomic")
	s.inventory.turnip_seed = 0
	s.stamina = 100
	before = s.snapshot(catalog)
	check(not rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "an empty seed bag is enforced")
	check(before == s.snapshot(catalog), "seed shortage is atomic")


func test_regrowing_crops() -> void:
	var s = FarmState.new_game(catalog)
	s.day = catalog.calendar.day_number(1, "summer", 1)
	s.inventory.corn_seed = 1
	var cell = free_cell(s)
	var key = FarmState.cell_key(cell)
	rules.apply_tool(s, "hoe", cell, cell, "corn")
	check(rules.apply_tool(s, "seed", cell, cell, "corn").ok, "summer corn can be planted")
	for i in range(8):
		rules.apply_tool(s, "water", cell, cell, "corn")
		rules.next_day(s)
	check(rules.apply_tool(s, "harvest", cell, cell, "corn").ok, "corn harvest")
	check(
		s.plots[key].crop == "corn" and s.plots[key].growth == 4,
		"a regrowing crop stays planted and rewinds"
	)
	for i in range(4):
		rules.apply_tool(s, "water", cell, cell, "corn")
		rules.next_day(s)
	check(rules.apply_tool(s, "harvest", cell, cell, "corn").ok, "corn gives a second harvest")
	check(s.inventory.corn == 2, "two harvests, two ears")


func test_seasons() -> void:
	var s = FarmState.new_game(catalog)
	var cell = free_cell(s)
	s.inventory.corn_seed = 1
	rules.apply_tool(s, "hoe", cell, cell, "corn")
	var before = s.snapshot(catalog)
	var response = rules.apply_tool(s, "seed", cell, cell, "corn")
	check(not response.ok and not response.message.is_empty(), "off-season planting explains why")
	check(before == s.snapshot(catalog), "off-season planting is atomic")
	s.inventory.pea_seed = 1
	rules.apply_tool(s, "seed", cell, cell, "pea")
	var last_spring = catalog.calendar.day_number(1, "spring", catalog.calendar.days_per_season)
	s.day = last_spring
	var morning = rules.next_day(s)
	check(
		morning.season_changed and morning.withered == 1, "out-of-season crops wither at the turn"
	)
	check(s.plots[FarmState.cell_key(cell)].crop == "", "the withered plot is empty")


func test_transactions() -> void:
	var s = FarmState.new_game(catalog)
	s.minute = 10 * 60
	check(shops.buy(s, "seeds", "turnip_seed", 5).ok, "bulk purchase")
	var price = int(catalog.items.turnip_seed.buy_price)
	check(s.gold == 40 - 5 * price and s.inventory.turnip_seed == 13, "purchase balances")
	var before = s.snapshot(catalog)
	check(not shops.buy(s, "seeds", "turnip_seed", 99).ok, "insufficient funds")
	check(before == s.snapshot(catalog), "failed purchase is atomic")
	check(not shops.buy(s, "seeds", "turnip_seed", -1).ok, "negative purchase rejected")
	check(
		not shops.buy(s, "seeds", "corn_seed", 1).ok, "out-of-season seeds are not on the counter"
	)
	s.inventory.turnip = 2
	s.inventory.carrot = 1
	var worth = 2 * int(catalog.items.turnip.sell_price) + int(catalog.items.carrot.sell_price)
	check(rules.sale_quote(s) == {"gold": worth, "count": 3}, "sale quote")
	var gold = s.gold
	check(rules.sell_produce(s).ok, "produce sold")
	check(s.gold == gold + worth and s.inventory.turnip == 0, "sale balances")
	check(s.inventory.turnip_seed == 13, "seeds are never sold with the produce")
	check(not rules.sell_produce(s).ok, "empty sale rejected")
	s.inventory.turnip_seed = 0
	s.inventory.turnip = 3
	check(rules.eat(s, "turnip").message.begins_with("现在体力充沛"), "no eating at full stamina")
	s.stamina = 10
	check(rules.eat(s, "turnip").ok and s.stamina == 18, "edible items restore stamina")
	check(not rules.eat(s, "wood").ok, "materials are not food")
	var fresh = rules.record_collection(s)
	check(fresh.has("turnip") and s.collected.has("turnip"), "the collection records finds")
	check(rules.record_collection(s).is_empty(), "a find is recorded once")


func write_json(path: String, value: Variant) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()


func test_saves() -> void:
	var folder = "user://tests-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	var store = SaveStore.new(catalog, folder)
	var s = FarmState.new_game(catalog)
	check(store.validate(s.snapshot(catalog)).is_empty(), "a new state is valid")
	check(store.latest().state == null, "no slots, no latest")
	check(store.save_game(s, 2).is_empty(), "first save succeeds")
	s.gold = 77
	check(store.save_game(s, 2).is_empty(), "second save succeeds")
	var reader = SaveStore.new(catalog, folder)
	var recovered = reader.load_slot(2)
	check(
		recovered.state != null and recovered.state.snapshot(catalog) == s.snapshot(catalog),
		"a save roundtrip preserves the complete state"
	)
	check(
		reader.load_slot(1).state == null and reader.load_slot(3).state == null,
		"other slots stay empty"
	)
	check(reader.latest().slot == 2, "latest finds the written slot")
	check(reader.first_empty_slot() == 1, "first empty slot")
	check(
		store.slot_path(1).ends_with("farm.json") and store.slot_path(3).ends_with("farm_3.json"),
		"slot paths"
	)
	var data = s.snapshot(catalog)
	data.schema_version = 1
	write_json(store.slot_path(3), data)
	var old = reader.load_slot(3)
	check(
		old.state == null and not old.message.is_empty(), "an old format is reported, not migrated"
	)
	check(reader.save_game(s, 3).is_empty(), "a new game overwrites that slot directly")
	check(not FileAccess.file_exists(store.slot_path(3) + ".bak"), "no backup produced")
	write_json(store.slot_path(3), "broken")
	check(reader.load_slot(3).state == null, "an invalid save cannot enter the domain")
	check(
		reader.delete_slot(3).is_empty() and not FileAccess.file_exists(store.slot_path(3)),
		"delete"
	)
	check(reader.delete_slot(3).is_empty(), "deleting an empty slot is harmless")
	var cell = free_cell(s)
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
	data.plots[FarmState.cell_key(cell)] = {"crop": "missing_crop", "growth": 0, "watered": false}
	check(not store.validate(data).is_empty(), "unknown crop rejected")
	data = s.snapshot(catalog)
	data.player_position = [16, 16]
	check(not store.validate(data).is_empty(), "an obstructed spawn is rejected")
	data = s.snapshot(catalog)
	data.day = 1.25
	check(not store.validate(data).is_empty(), "fractional days rejected")
	data = s.snapshot(catalog)
	data.minute = FarmState.NIGHT
	check(not store.validate(data).is_empty(), "the clock cannot rest past the end of the day")
	data = s.snapshot(catalog)
	data.buildings = {"castle": {"ready_day": 1}}
	check(not store.validate(data).is_empty(), "unknown building rejected")
	data = s.snapshot(catalog)
	data.animals = [{"species": "dragon"}]
	check(not store.validate(data).is_empty(), "unknown animal rejected")
	data = s.snapshot(catalog)
	data.collected = ["not_an_item"]
	check(not store.validate(data).is_empty(), "unknown collection entry rejected")
	data = s.snapshot(catalog)
	data.development.tools.hoe = 9
	check(not store.validate(data).is_empty(), "tool level range checked")
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
	var reachable_plots = 0
	for y in range(int(catalog.map.height)):
		for x in range(int(catalog.map.width)):
			if catalog.plantable(Vector2i(x, y)) and visited.has(Vector2i(x, y)):
				reachable_plots += 1
	check(reachable_plots >= 40, "the farm has room to plant before any clearing")

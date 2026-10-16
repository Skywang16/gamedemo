extends SceneTree

## Real scene integration, with no OS input, window or player save access.
var checks: int = 0
var failures: Array[String] = []
var game: Node
var folder: String


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://interior-test-"):
			folder = arg.trim_prefix("--save-dir=")
	if DisplayServer.get_name() != "headless" or folder.is_empty():
		push_error("Interior tests require --headless and an isolated interior-test save folder")
		quit(2)
		return
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var state = FarmState.new_game(game.catalog, 0)
	state.narrative.intro_seen = true
	state.narrative.stage = 3
	state.day = 2
	game._start_game(state)
	var residents: Dictionary = {}
	var interiors: int = 0
	var sizes: Dictionary = {}
	for ident in game.catalog.regions:
		var region: Dictionary = game.catalog.region(ident)
		if region.environment != "interior":
			continue
		interiors += 1
		test_geometry(region)
		sizes[str([region.width, region.height])] = true
		game._travel(ident, Vector2(region.spawn[0], region.spawn[1]))
		await physics_frame
		game.world.player.set_physics_process(false)
		check_routes(region)
		check(game.state.current_map == ident, "enter " + ident)
		check(
			not game.world.outdoors and not game.world.weather_layer.visible,
			"no indoor weather " + ident
		)
		check(
			(
				(game.world.camera.get_parent() == game.world.player)
				== (region.width * 32 > 1280 / 1.5 or region.height * 32 > 800 / 1.5)
			),
			"camera matches room size " + ident
		)
		var loaded: Dictionary = game.store.load_slot(1)
		check(loaded.state != null, "indoor save loads " + ident)
		if loaded.state != null:
			check(loaded.state.current_map == ident, "save restores indoor location " + ident)
			check(
				loaded.state.player_position == game.world.player.position,
				"save restores entrance " + ident
			)
		for station in region.stations:
			if station.kind == "inspect":
				game.world.player.position = Vector2(
					station.cell[0] * 32 + 16, station.cell[1] * 32 + 16
				)
				var before: Dictionary = game.state.snapshot(game.catalog)
				game._interact()
				game._interact()
				check(
					game.hud.toast_label.text == station.description,
					"inspect displays personal detail " + station.id
				)
				check(
					game.state.snapshot(game.catalog) == before,
					"repeat inspection cannot change game state " + station.id
				)
		for npc in region.get("residents", []):
			check(not residents.has(npc), "unique home for " + npc)
			residents[npc] = ident
			var at_home: Dictionary = game.planner.where(npc, 5.0 * 60.0)
			if at_home.present:
				check(
					at_home.map == ident and not at_home.hidden,
					"resident physically at home " + npc
				)
		for station in region.stations:
			if station.kind == "exit":
				game.world.player.position = Vector2(
					station.cell[0] * 32 + 16, station.cell[1] * 32 + 16
				)
				game._interact()
				check(
					game.state.current_map == station.destination,
					"door interaction leaves " + ident
				)
				game._travel(ident, Vector2(region.spawn[0], region.spawn[1]))
				await process_frame
	check(interiors == 25 and sizes.size() >= 7, "interiors have diverse dimensions")
	check(residents.size() == 30, "all thirty villagers have a home")
	await test_home_services()
	game._next_day()
	await game.audio.day.finished
	check(game.state.current_map == "cottage", "sleep wakes in farmhouse")
	check(
		not game.catalog.blocked(game.world.player.cell(), "cottage"), "morning spawn is walkable"
	)
	game.store.delete_slot(1)
	game.queue_free()
	await process_frame
	var absolute = ProjectSettings.globalize_path(folder)
	for name in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(absolute.path_join(name))
	DirAccess.remove_absolute(absolute)
	print("INTERIOR_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func test_geometry(region: Dictionary) -> void:
	var floors: Dictionary = {}
	var occupied: Dictionary = {}
	for patch in region.floors:
		var r: Array = patch.rect
		for y in range(r[1], r[1] + r[3]):
			for x in range(r[0], r[0] + r[2]):
				floors[Vector2i(x, y)] = true
	for prop in region.props:
		var r: Array = prop.footprint
		for y in range(r[1], r[1] + r[3]):
			for x in range(r[0], r[0] + r[2]):
				var cell = Vector2i(x, y)
				check(
					floors.has(cell),
					"furniture supported by floor: %s %s" % [region.id, prop.texture]
				)
				check(
					not occupied.has(cell),
					"furniture footprints cannot overlap: %s %s" % [region.id, cell]
				)
				occupied[cell] = true
				check(
					game.catalog.blocked(cell, region.id),
					"solid furniture blocks movement: %s %s" % [region.id, cell]
				)


func check_routes(region: Dictionary) -> void:
	var start = Vector2i(region.spawn[0] / 32, region.spawn[1] / 32)
	var targets: Array = region.stations.map(func(s): return Vector2i(s.cell[0], s.cell[1]))
	for key in game.catalog.places:
		if key.begins_with(region.id + "/"):
			targets.append(game.catalog.place(key).cell)
	for target in targets:
		var legs = game.planner.route(region.id, start, region.id, target)
		check(legs != null, "route to interaction/NPC: %s %s" % [region.id, target])
		if legs == null:
			continue
		for leg in legs:
			for i in range(1, leg.cells.size()):
				var a = Vector2(leg.cells[i - 1]) * 32 + Vector2(16, 16)
				var b = Vector2(leg.cells[i]) * 32 + Vector2(16, 16)
				check(
					not game.world.player.test_move(Transform2D(0.0, a), b - a),
					"player body fits route: %s %s" % [region.id, leg.cells[i]]
				)


func use_station(ident: String) -> void:
	game.hud.close_modal()
	for station in game.world.region.stations:
		if station.id == ident:
			game.world.player.position = Vector2(
				station.cell[0] * 32 + 16, station.cell[1] * 32 + 16
			)
			game._interact()
			return
	check(false, "missing station " + ident)


func test_home_services() -> void:
	var region = game.catalog.region("cottage")
	game._travel("cottage", Vector2(region.spawn[0], region.spawn[1]))
	await physics_frame
	game.world.player.set_physics_process(false)
	use_station("chest")
	check(game.hud.dialogs.modal_kind == "storage", "chest opens storage")
	game.state.inventory.wood = 3
	game.state.storage.wood = 0
	game._on_action("store", {"id": "wood", "deposit": true})
	check(game.state.storage.wood == 1 and game.state.inventory.wood == 2, "deposit moves one item")
	game._save(false)
	var loaded = game.store.load_slot(1)
	check(loaded.state.storage.wood == 1, "storage survives reload")
	game._on_action("store", {"id": "wood", "deposit": false})
	check(game.state.storage.wood == 0 and game.state.inventory.wood == 3, "withdraw restores item")
	use_station("kitchen")
	check(game.hud.dialogs.modal_kind == "cooking", "kitchen opens recipes")
	use_station("sleep")
	check(game.hud.dialogs.modal_kind == "sleep", "bed offers sleep")
	var day = game.state.day
	game._on_action("close", {})
	check(game.state.day == day, "cancel sleep keeps the day")
	use_station("letter")
	check(game.hud.dialogs.modal_kind == "dialogue", "desk opens grandmother's letter")
	game.hud.close_modal()
	# The two upper rooms are separated by a solid partition.
	game.world.player.position = Vector2(8 * 32 + 24, 5 * 32 + 16)
	check(
		not game.world.station_accessible(Vector2(11 * 32 + 16, 5 * 32 + 16)),
		"wall blocks interaction"
	)

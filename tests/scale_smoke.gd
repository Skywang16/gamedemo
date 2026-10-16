extends "res://tests/ui_driver.gd"

## Uses scene calls only: never warps the OS pointer or synthesizes desktop input.
## Headless runs exercise routes and action contacts; a window additionally captures proportions.
const SPOTS = {
	"home_farm": Vector2i(27, 12),
	"town": Vector2i(24, 30),
	"market": Vector2i(16, 28),
	"forest": Vector2i(38, 21),
	"lake": Vector2i(37, 46),
	"ranch": Vector2i(37, 25),
	"seaside": Vector2i(47, 12),
}
## Interiors are photographed where the player appears when entering.
const ROOMS = ["cottage", "inn"]


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://ui-test-scale-"):
			folder = arg.trim_prefix("--save-dir=")
	if folder.is_empty() or DirAccess.dir_exists_absolute(folder):
		push_error("Use a fresh --save-dir=user://ui-test-scale-UNIQUE")
		quit(2)
		return
	scene = load("res://scenes/main.tscn")
	await spawn()
	game.set_process(false)
	var state = FarmState.new_game(game.catalog, 0)
	state.narrative.intro_seen = true
	state.narrative.stage = 6
	state.minute = 12 * 60
	game._start_game(state)
	var spots = SPOTS.duplicate()
	var farm_only = OS.get_cmdline_user_args().has("--farm-only")
	if farm_only:
		spots = {"home_farm": SPOTS.home_farm}
	for id in [] if farm_only else ROOMS:
		var room = game.catalog.region(id)
		spots[id] = Vector2i(floori(room.spawn[0] / 32.0), floori(room.spawn[1] / 32.0))
	for id in spots:
		check_routes(id)
		game.state.current_map = id
		game.state.player_position = Vector2(spots[id]) * 32 + Vector2(16, 16)
		game._plan_day()
		game._build_world()
		game._refresh()
		await process_frame
		game.world.player.set_physics_process(false)
		game.world.camera.force_update_scroll()
		await picture("scale-" + id)
	if farm_only:
		await farm_pictures()
	# Exercise the real tool-contact -> rule -> effect pipeline at a fixed foot anchor.
	game.state.current_map = "home_farm"
	game._plan_day()
	game._build_world()
	await process_frame
	var open = free_cells(100000)
	open.sort_custom(
		func(a, b):
			return a.distance_squared_to(Vector2i(38, 21)) < b.distance_squared_to(Vector2i(38, 21))
	)
	var target = Vector2i(-1, -1)
	for candidate in open:
		if open.has(candidate + Vector2i.DOWN):
			target = candidate
			break
	check(target.x >= 0, "two free farming cells exist")
	if target.x >= 0:
		place_cell(target + Vector2i.DOWN)
		var player = game.world.player
		player.set_physics_process(false)
		player.can_move = true
		var anchor: Vector2 = player.position
		var stamina = game.state.stamina
		var plot = FarmState.cell_key(target)
		check(player.swing_tool("hoe", target), "hoe starts")
		player._physics_process(player.action_duration * 0.49)
		check(not game.state.plots.has(plot), "windup does not change soil")
		player._physics_process(player.action_duration * 0.02)
		check(game.state.plots.has(plot), "contact tills the selected adjacent tile")
		await picture("scale-hoe-contact")
		player._physics_process(player.action_duration)
		check(game.state.stamina == stamina - 2, "one swing charges exactly once")
		check(player.position == anchor, "tool swing keeps the foot anchor fixed")
		check(player.swing_tool("water", target), "watering starts")
		player._physics_process(player.action_duration * 0.51)
		check(game.state.plots[plot].watered, "watering reaches the same tile")
		check(not game.world.effects.streams.is_empty(), "watering emits a stream")
		game.world.effects.set_process(false)
		game.world.effects._process(0.08)
		game.world.effects.queue_redraw()
		await picture("scale-water-contact")
		game.world.effects.set_process(true)
		player._physics_process(player.action_duration)
		check(player.position == anchor, "watering keeps the foot anchor fixed")
		await picture("scale-recovery")
	for sound in game.audio.values():
		sound.stop()
	# Allow the audio mixer to release action samples before tearing down the scene.
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	scene = null
	game = null
	await process_frame
	print("SCALE_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func picture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await capture(label)


func farm_pictures() -> void:
	var world = game.world
	for cell in [Vector2i(23, 18), Vector2i(19, 24), Vector2i(43, 23)]:
		place_cell(cell)
		world.camera.force_update_scroll()
		await picture("farm-detail-%d-%d" % [cell.x, cell.y])
	game.hud.hide()
	world.camera.reparent(world)
	world.camera.position = Vector2(world.region.width * 16, world.region.height * 16)
	world.camera.offset = Vector2.ZERO
	world.camera.zoom = (
		Vector2.ONE * minf(1280.0 / (world.region.width * 32), 800.0 / (world.region.height * 32))
	)
	world.camera.force_update_scroll()
	await picture("farm-overview")
	game.hud.show()


func check_routes(id: String) -> void:
	var region: Dictionary = game.catalog.region(id)
	var start = Vector2i(int(region.spawn[0] / 32), int(region.spawn[1] / 32))
	var seen = {start: true}
	var queue: Array[Vector2i] = [start]
	var index = 0
	while index < queue.size():
		var cell = queue[index]
		index += 1
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or game.catalog.blocked(next, id):
				continue
			seen[next] = true
			queue.append(next)
	for station in region.stations:
		if station.kind == "exit":
			var cell = Vector2i(station.cell[0], station.cell[1])
			check(seen.has(cell), "%s: entrance reachable: %s" % [id, station.name])

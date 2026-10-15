extends "res://tests/ui_driver.gd"

## Visual review: walks the camera through every map and saves screenshots. Not a pass/fail test
## beyond "every map builds and renders".


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://ui-test-"):
			folder = arg.trim_prefix("--save-dir=")
	if folder.is_empty():
		push_error("Use a fresh -- --save-dir=user://ui-test-UNIQUE")
		quit(2)
		return
	scene = load("res://scenes/main.tscn")
	await spawn()
	game._on_front(
		"create",
		{
			"profile": {"name": "小雨", "farm": "青苇小院", "skin": 0, "hair": 0, "outfit": 1, "hat": 0},
			"slot": 1
		}
	)
	game.state.narrative.stage = 6
	game.state.minute = 12 * 60
	for id in game.catalog.regions:
		var area = game.catalog.region(id)
		var spots = [Vector2(area.spawn[0], area.spawn[1])]
		if area.width > 40:
			var w = area.width * 32.0
			var h = area.height * 32.0
			spots.append(Vector2(w * 0.5, h * 0.5))
			spots.append(Vector2(w * 0.25, h * 0.7))
			spots.append(Vector2(w * 0.75, h * 0.3))
		var index = 0
		for spot in spots:
			var cell = Vector2i(int(spot.x / 32), int(spot.y / 32))
			var best = cell
			var best_distance = 1000000
			for dy in range(-8, 9):
				for dx in range(-8, 9):
					var candidate = cell + Vector2i(dx, dy)
					if not game.catalog.blocked(candidate, id, game.state.tree_damage):
						if dx * dx + dy * dy < best_distance:
							best = candidate
							best_distance = dx * dx + dy * dy
			game.state.current_map = id
			game.state.player_position = Vector2(best) * 32 + Vector2(16, 16)
			game._plan_day()
			game._build_world()
			game._refresh()
			await process_frame
			game.world.camera.force_update_scroll()
			await capture("tour-%s-%d" % [id, index])
			index += 1
	check(true, "tour finished")
	print("MAP_TOUR: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

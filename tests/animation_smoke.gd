extends "res://tests/ui_driver.gd"


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://ui-test-"):
			folder = arg.trim_prefix("--save-dir=")
	if folder.is_empty() or FileAccess.file_exists(folder + "/farm.json"):
		push_error("Use a fresh --save-dir=user://ui-test-UNIQUE")
		quit(2)
		return
	scene = load("res://scenes/main.tscn")
	await spawn()
	var backdrop: TitleBackdrop = game.front.get_child(0)
	await create_timer(.15).timeout
	check(backdrop.time > 0.1, "title scene animates while menu is open")
	game._on_front(
		"create",
		{
			"profile": {"name": "小雨", "farm": "青苇小院", "skin": 0, "hair": 0, "outfit": 1, "hat": 0},
			"slot": 1
		}
	)
	var cell = Vector2i(-1, -1)
	var open = free_cells(100000)
	for candidate in open:
		if open.has(candidate + Vector2i.DOWN):
			cell = candidate
			break
	check(cell.x >= 0, "the farm has two free cells in a column")
	place_cell(cell + Vector2i.DOWN)
	game.world.player.facing = Vector2i.UP
	var key_text = FarmState.cell_key(cell)
	await key(KEY_1)
	var energy = game.state.stamina
	await key(KEY_SPACE)
	check(
		not game.state.plots.has(key_text) and game.state.stamina == energy,
		"windup does not apply farming early"
	)
	await key(KEY_ESCAPE)
	var remaining = game.world.player.action_remaining
	await create_timer(.35).timeout
	check(
		game.world.player.action_remaining == remaining and not game.state.plots.has(key_text),
		"menu pauses pending action"
	)
	await key(KEY_ESCAPE)
	await create_timer(.32).timeout
	check(
		game.state.plots.has(key_text) and game.state.stamina == energy - 2,
		"hoe applies at contact frame"
	)
	check(not game.world.effects.particles.is_empty(), "hoe impact emits soil particles")
	await create_timer(.4).timeout
	check(game.state.stamina == energy - 2, "recovery cannot apply a second hit")
	await key(KEY_3)
	await key(KEY_SPACE)
	await create_timer(.4).timeout
	check(
		game.state.plots[key_text].watered and not game.world.effects.streams.is_empty(),
		"watering pose emits visible water at contact"
	)
	await capture("watering-action")
	await create_timer(.5).timeout
	var tree_cell = Vector2i(-1, -1)
	var tree_id = ""
	for id in game.catalog.tree_ids:
		var entry = game.catalog.tree_ids[id]
		var below = entry.cell + Vector2i.DOWN
		if entry.map == "home_farm" and below.y < 70 and not game.catalog.blocked(below):
			tree_cell = entry.cell
			tree_id = id
			break
	check(not tree_id.is_empty(), "a tree with free ground below it")
	place_cell(tree_cell + Vector2i.DOWN)
	await key(KEY_6)
	for hit in range(3):
		await click_cell(tree_cell)
	var tree: TreeProp = game.world.tree_nodes[tree_id]
	check(
		game.state.tree_damage[tree_id] == 3 and tree.fall_time >= 0,
		"third axe contact starts physical fall"
	)
	await capture("tree-falling")
	await create_timer(.9).timeout
	check(
		not tree.trunk.visible and not tree.collider.disabled, "fallen tree leaves blocking stump"
	)
	await capture("tree-stump")
	for hit in range(2):
		await click_cell(tree_cell)
	check(
		(
			game.state.tree_damage[tree_id] == 5
			and tree.collider.disabled
			and game.state.inventory.wood == 5
		),
		"stump clears collision and rewards once"
	)
	await key(KEY_W, .26)
	check(
		game.world.player.position.y < (tree_cell.y + 1) * 32,
		"player can walk through cleared trunk"
	)
	game._save(false)
	game.queue_free()
	await process_frame
	await spawn()
	await press("继续生活")
	tree = game.world.tree_nodes[tree_id]
	check(
		game.state.tree_damage[tree_id] == 5 and tree.collider.disabled and not tree.trunk.visible,
		"reload restores felled tree and cleared collision"
	)
	print("ANIMATION_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

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
		"create", {"name": "小雨", "farm": "青苇小院", "skin": 0, "hair": 0, "outfit": 1, "hat": 0}
	)
	var cell = Vector2i(34, 20)
	game.rules.apply_tool(game.state, "scythe", cell, cell, "turnip")
	game.world.remove_debris("d_34_20")
	place_cell(cell + Vector2i.DOWN)
	game.world.player.facing = Vector2i.UP
	await key(KEY_1)
	var energy = game.state.stamina
	await key(KEY_SPACE)
	check(
		not game.state.plots.has("34,20") and game.state.stamina == energy,
		"windup does not apply farming early"
	)
	await key(KEY_ESCAPE)
	var remaining = game.world.player.action_remaining
	await create_timer(.35).timeout
	check(
		game.world.player.action_remaining == remaining and not game.state.plots.has("34,20"),
		"menu pauses pending action"
	)
	await key(KEY_ESCAPE)
	await create_timer(.32).timeout
	check(
		game.state.plots.has("34,20") and game.state.stamina == energy - 2,
		"hoe applies at contact frame"
	)
	check(not game.world.effects.particles.is_empty(), "hoe impact emits soil particles")
	await create_timer(.4).timeout
	check(game.state.stamina == energy - 2, "recovery cannot apply a second hit")
	await key(KEY_3)
	await key(KEY_SPACE)
	await create_timer(.4).timeout
	check(
		game.state.plots["34,20"].watered and not game.world.effects.streams.is_empty(),
		"watering pose emits visible water at contact"
	)
	await capture("watering-action")
	await create_timer(.5).timeout
	var tree_cell = Vector2i(32, 14)
	var tree_id = game.catalog.tree_at(tree_cell, game.state)
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

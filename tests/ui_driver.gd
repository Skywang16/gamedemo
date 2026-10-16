extends SceneTree
var game: Node
var checks = 0
var failures: Array[String] = []
var scene: PackedScene
var folder: String


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("UI FAIL: " + message)


func key(code: Key, held: float = 0.045) -> void:
	var e = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await create_timer(held).timeout
	e = InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = false
	Input.parse_input_event(e)
	await process_frame


func click(point: Vector2) -> void:
	Input.warp_mouse(point)
	var m = InputEventMouseMotion.new()
	m.position = point
	m.global_position = point
	Input.parse_input_event(m)
	await process_frame
	var e = InputEventMouseButton.new()
	e.position = point
	e.global_position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	e = InputEventMouseButton.new()
	e.position = point
	e.global_position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	Input.parse_input_event(e)
	await process_frame


func button_in(node: Node, text: String) -> Button:
	if (
		node is Button
		and (node.text == text or node.tooltip_text == text)
		and node.is_visible_in_tree()
	):
		return node
	for child in node.get_children():
		var found = button_in(child, text)
		if found != null:
			return found
	return null


func press(text: String) -> void:
	var button = button_in(game, text)
	if button == null:
		check(false, "button found: " + text)
		return
	await click(button.get_global_rect().get_center())


func interact(id: String) -> void:
	var target: Dictionary = {}
	for station in game.world.available_stations():
		if station.id == id:
			target = station
	if target.is_empty():
		check(false, "station found: " + id)
		return
	game.world.player.position = Vector2(target.cell[0] * 32 + 16, target.cell[1] * 32 + 16)
	game.world.player.velocity = Vector2.ZERO
	await key(KEY_E)
	await process_frame


func click_cell(cell: Vector2i) -> void:
	game.world.camera.force_update_scroll()
	await process_frame
	await click(
		game.WORLD_RECT.position + game.world.world_to_screen(Vector2(cell) * 32 + Vector2(16, 16))
	)

	await create_timer(ToolMotion.MAX_DURATION + 0.02).timeout


func place_cell(cell: Vector2i) -> void:
	game.world.player.position = Vector2(cell) * 32 + Vector2(16, 16)
	game.world.player.velocity = Vector2.ZERO
	game.world.camera.force_update_scroll()


## `count` farm cells with no tree or debris, so tools act on them straight away.
func free_cells(count: int) -> Array:
	var out: Array = []
	for y in range(1, int(game.catalog.map.height) - 1):
		for x in range(1, int(game.catalog.map.width) - 1):
			var cell = Vector2i(x, y)
			if (
				game.catalog.plantable(cell, game.state.tree_damage)
				and game.catalog.tree_at(cell, game.state).is_empty()
				and game.catalog.debris_at(cell, game.state).is_empty()
			):
				out.append(cell)
				if out.size() == count:
					return out
	return out


func visible_villagers() -> Array:
	var out: Array = []
	for id in game.world.npc_nodes:
		if game.world.npc_nodes[id].visible:
			out.append(id)
	return out


func dialogue(choice: String = "") -> void:
	if game.hud.modal_kind != "dialogue":
		check(false, "dialogue open")
		return
	while game.scene_index < game.pages.size() - 1:
		await key(KEY_E)
	if choice == "grow":
		await press("我想好好照料这片土地")
	elif choice == "together":
		await press("愿我们以后常常见面")
	else:
		await press("记住这一刻")


func capture(name: String) -> void:
	if is_instance_valid(game.hud):
		game.hud.toast_remaining = 0
		game.hud.toast_box.hide()
		game.hud.toast_label.hide()
	var output_dir = "res://build/test-results".path_join(folder.get_file())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var ignore_file = FileAccess.open("res://build/.gdignore", FileAccess.WRITE)
	ignore_file.close()
	await process_frame
	# Screenshots must show the settled UI, not a fade or a panel sliding in.
	await create_timer(0.3).timeout
	while is_instance_valid(game.get("fade")) and game.fade.active:
		await process_frame
	await create_timer(0.05).timeout
	# macOS can skip window draws while occluded; capture must not wait for visibility.
	RenderingServer.force_draw()
	var path = ProjectSettings.globalize_path(output_dir.path_join(name + ".png"))
	var error = game.get_viewport().get_texture().get_image().save_png(path)
	check(error == OK, "screenshot saved: " + name)
	print("CAPTURE_SAVED ", path, " ", error)


func spawn() -> void:
	game = scene.instantiate()
	game.fixed_seed = 0
	root.add_child(game)
	await process_frame
	await process_frame


func sleep_day() -> void:
	await key(KEY_ESCAPE)
	await press("回家休息")
	await press("结束今天，回家睡觉")
	check(
		game.state.current_map == "cottage" and not game.hud.is_modal(),
		"sleep wakes inside cottage"
	)

extends "res://tests/ui_driver.gd"


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://ui-test-"):
			folder = arg.trim_prefix("--save-dir=")
	if folder.is_empty() or FileAccess.file_exists(folder + "/farm.json"):
		push_error("Use a fresh -- --save-dir=user://ui-test-UNIQUE")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	scene = load("res://scenes/main.tscn")
	await spawn()
	check(not game.initialized and game.front.screen == "title", "boots to title")
	check(
		not FileAccess.file_exists(folder + "/farm.json"), "title does not create or overwrite save"
	)
	await capture("title")
	await press("开始新生活")
	check(game.front.screen == "creator", "new game opens creator")
	await press("返回")
	check(
		not FileAccess.file_exists(folder + "/farm.json"), "cancel creation leaves save untouched"
	)
	await press("开始新生活")
	game.front.name_input.text = ""
	await press("带着这份期待，出发")
	check(not game.initialized, "empty name rejected")
	game.front.name_input.text = "小雨"
	game.front.farm_input.text = "青苇小院"
	game.front.name_input.text_changed.emit("小雨")
	await press("衣服：湖蓝  ›")
	await press("帽子：草帽  ›")
	await capture("creator")
	await press("带着这份期待，出发")
	check(
		game.initialized and not game.hud.is_modal(),
		"creator enters playable world without tutorial"
	)
	check(game.world_display.size == Vector2(1280, 800), "world fills viewport")
	await capture("farm-wild")
	place_cell(Vector2i(34, 20))
	await key(KEY_6)
	game.world.player.facing = Vector2i.RIGHT
	await key(KEY_SPACE)
	check(game.world.player.action_remaining > 0, "wrong tool still animates")
	var action_time = game.world.player.action_remaining
	await key(KEY_SPACE)
	check(
		game.world.player.action_remaining < action_time, "rapid repeat cannot restart active swing"
	)
	await create_timer(ToolMotion.MAX_DURATION).timeout
	place_cell(Vector2i(34, 20))
	var before_wrong_tool = [
		game.state.stamina, game.state.inventory.duplicate(), game.state.cleared.duplicate()
	]
	await key(KEY_6)
	await click_cell(Vector2i(34, 20))
	check(
		[game.state.stamina, game.state.inventory, game.state.cleared] == before_wrong_tool,
		"wrong tool does not consume resources"
	)
	check(not game.hud.toast_box.visible, "wrong tool does not show instructional toast")
	await key(KEY_1)
	var before_toolbar = [
		game.state.stamina, game.state.inventory.duplicate(), game.state.plots.duplicate(true)
	]
	await press("水壶")
	check(
		(
			game.selected_tool == "water"
			and [game.state.stamina, game.state.inventory, game.state.plots] == before_toolbar
		),
		"toolbar click selects without operating ground"
	)
	await key(KEY_B)
	await capture("bag")
	await press("胡萝卜种子")
	check(game.hud.dialogs.selected_item == "carrot_seed", "inventory grid selects item details")
	await press("萝卜种子")
	await press("关闭")
	await key(KEY_J)
	await capture("journal")
	await press("合上手记")
	await interact("bed")
	await interact("letter")
	await key(KEY_ESCAPE)
	check(
		not game.hud.is_modal() and game.state.narrative.active_scene.is_empty(),
		"optional letter can be dismissed without forced resume"
	)
	await interact("letter")
	check(game.hud.modal_kind == "dialogue", "letter is an optional interaction inside home")
	check(
		(
			game.state.profile.name == "小雨"
			and game.state.profile.outfit == 1
			and game.state.profile.hat == 0
		),
		"custom profile applied"
	)
	await key(KEY_E)
	check(game.scene_index == 1, "dialogue input advances")
	game.queue_free()
	await process_frame
	await spawn()
	await press("继续生活")
	check(
		game.hud.modal_kind == "dialogue" and game.scene_index == 1,
		"restart resumes exact dialogue page"
	)
	await dialogue("grow")
	check(
		game.state.narrative.intro_seen and game.state.narrative.intent == "grow",
		"intro choice persisted"
	)
	check(
		game.state.plots.is_empty() and game.state.inventory.turnip == 0,
		"new farm has no tilled land or crops"
	)
	await interact("farm")
	await interact("ahe")
	await capture("dialogue")
	await dialogue()
	check(game.state.narrative.stage == 1, "welcome advances quest")
	# Real input for farming; position placement keeps the integration run short.
	for x in range(34, 39):
		place_cell(Vector2i(x, 20))
		await key(KEY_5)
		await click_cell(Vector2i(x, 20))
		await key(KEY_1)
		await click_cell(Vector2i(x, 20))
		await key(KEY_2)
		await click_cell(Vector2i(x, 20))
		await key(KEY_3)
		await click_cell(Vector2i(x, 20))
	check(game.state.plots.get("34,20", {}).get("watered", false), "mouse tools seed and water")
	await key(KEY_ESCAPE)
	place_cell(Vector2i(40, 35))
	var pos = game.world.player.position
	var minute = game.state.minute
	await key(KEY_D, 1.1)
	check(
		game.state.minute == minute and game.world.player.position == pos,
		"modal freezes clock and movement"
	)
	await key(KEY_ESCAPE)
	await key(KEY_S, 0.2)
	check(game.world.player.position.y > pos.y + 5, "movement input")
	var camera_before = game.world.camera.get_screen_center_position()
	place_cell(Vector2i(40, 50))
	await process_frame
	check(
		game.world.camera.get_screen_center_position().y > camera_before.y + 300,
		"camera follows across large farm"
	)
	var pointer = Vector2(300, 250)
	check(
		game.world.world_to_screen(game.world.screen_to_world(pointer)).distance_to(pointer) < 0.1,
		"mouse coordinates survive camera scroll"
	)
	game.world.player.position = Vector2(1160, 432)
	await key(KEY_D, 0.4)
	check(game.world.player.position.x < 1180, "house collision")
	place_cell(Vector2i(40, 18))
	await process_frame
	await key(KEY_M)
	await capture("map")
	await press("收起地图")
	await capture("farm")
	await interact("bed")
	check(game.state.current_map == "cottage", "farm door enters physical interior")
	await capture("cottage")
	await interact("chest")
	check(game.hud.modal_kind == "storage", "house storage opens")
	await capture("storage")
	await press("存入")
	check(game.state.storage.turnip_seed == 1, "storage button deposits item")
	await press("取出")
	await press("关闭")
	await interact("farm")
	check(game.state.current_map == "home_farm", "exit house returns to farm")
	for day in range(3):
		await sleep_day()
		await interact("farm")
		if day < 2:
			for x in range(34, 39):
				place_cell(Vector2i(x, 20))
				await key(KEY_3)
				await click_cell(Vector2i(x, 20))
	for x in range(34, 39):
		place_cell(Vector2i(x, 20))
		await key(KEY_4)
		await click_cell(Vector2i(x, 20))
	check(
		game.state.inventory.turnip == 5 and game.state.development.farming_xp == 50,
		"five crops harvested via UI"
	)
	await interact("shop")
	await capture("shop")
	await press("萝卜种子 ×1 / 4 G")
	check(game.state.gold == 36, "shop transaction UI")
	await press("离开摊位")
	await interact("to_town")
	check(game.state.current_map == "town", "road enters town")
	place_cell(Vector2i(24, 23))
	await process_frame
	await capture("town")
	await interact("inn")
	check(game.state.current_map == "inn", "inn has interior")
	await interact("town")
	await interact("workshop")
	check(game.state.current_map == "workshop", "workshop has interior")
	await interact("town")
	await interact("mido")
	await capture("npc")
	await press("聊聊「一顿饭的距离」")
	await dialogue()
	check(
		game.state.narrative.stage == 2 and game.state.inventory.turnip == 3,
		"meal quest consumes crops"
	)
	await interact("forest")
	await capture("forest")
	for node in game.catalog.regions.forest.gather:
		await interact(node.id)
	check(game.state.inventory.wood == 4 and game.state.inventory.berry == 3, "gathering through E")
	await interact("town")
	await interact("bridge")
	await dialogue()
	check(game.state.narrative.stage == 3, "bridge quest commits")
	await interact("bridge")
	check(game.state.current_map == "lake", "repaired bridge opens lake")
	await interact("lin")
	await press("聊聊「湖边的记录员」")
	await dialogue()
	check(game.state.narrative.stage == 4, "lake character advances plot")
	await interact("town")
	await interact("mido")
	await press("聊聊「请大家再聚一次」")
	await dialogue()
	check(
		game.state.narrative.stage == 5 and game.state.inventory.berry == 0,
		"feast consumes exact materials"
	)
	await interact("bridge")
	await interact("lantern")
	await dialogue("together")
	check(
		game.state.narrative.stage == 6 and game.state.narrative.wish == "together",
		"full story finished through input"
	)
	await capture("ending")
	await press("继续我的农场生活")
	await capture("lake")
	await interact("town")
	await interact("farm")
	await interact("shipping")
	var gold_before_sale = game.state.gold
	await press("出售全部农产品 / +12 G")
	check(
		game.state.inventory.turnip == 0 and game.state.gold == gold_before_sale + 12,
		"shipping UI sells produce"
	)
	await sleep_day()
	await interact("farm")
	await interact("to_town")
	await interact("forest")
	for node in game.catalog.regions.forest.gather:
		await interact(node.id)
	await interact("town")
	await interact("workshop")
	await interact("upgrade")
	await press("制作铜水壶")
	check(game.state.development.watering_level == 1, "upgrade through workshop")
	await capture("upgrade")
	await press("离开工作台")
	await interact("town")
	await interact("inn")
	await interact("kitchen")
	var old_berries = game.state.inventory.berry
	await press("煮一碗野莓粥并吃下")
	check(
		game.state.inventory.berry == old_berries - 2 and game.state.stamina == 100,
		"cooking through interior UI"
	)
	await press("离开灶台")
	await interact("town")
	await interact("mido")
	var relationship_before_gift = game.state.relationships.mido
	await press("送一份礼物")
	await press("野莓 ×1（持有 1）")
	check(
		game.state.relationships.mido == relationship_before_gift + 10,
		"favorite gift through NPC UI"
	)
	# Fixture isolates a relationship milestone; its accumulation is tested in chapter_tests.
	game.state.relationships.mido = 40
	await interact("mido")
	await press("听听你的故事")
	await capture("memory")
	await dialogue()
	check(game.state.development.memories.has("mido"), "personal story and reward through dialogue")
	await interact("farm")
	for entry in [[Vector2i(35, 22), KEY_6], [Vector2i(37, 23), KEY_7]]:
		var cell = entry[0]
		var id = "d_%d_%d" % [cell.x, cell.y]
		place_cell(cell + Vector2i.DOWN)
		await key(entry[1])
		await click_cell(cell)
		check(
			game.state.cleared.has(id) and not game.world.debris_nodes.has(id),
			"clearing removes resource sprite and collision"
		)
	await interact("to_town")
	await interact("inn")
	await key(KEY_M)
	check(game.hud.modal_kind == "map", "map shortcut")
	await press("收起地图")
	await key(KEY_J)
	check(game.hud.modal_kind == "journal", "journal shortcut")
	await press("合上手记")
	await key(KEY_B)
	check(game.hud.modal_kind == "bag", "bag shortcut")
	await press("关闭")
	await key(KEY_ESCAPE)
	await press("保存并返回标题")
	check(
		not game.initialized and game.front.cached_state.narrative.stage == 6,
		"return title saves chapter"
	)
	await press("开始新生活")
	await press("返回")
	await press("继续生活")
	check(
		(
			game.state.profile.name == "小雨"
			and game.state.narrative.stage == 6
			and game.state.current_map == "inn"
		),
		"cancel new creator preserves existing world"
	)
	check(
		game.state.development.watering_level == 1 and game.state.profile.outfit == 1,
		"appearance and growth survive reload"
	)
	check(
		game.state.cleared.has("d_35_22") and game.state.cleared.has("d_37_23"),
		"cleared branch and rock survive reload"
	)
	print("UI_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

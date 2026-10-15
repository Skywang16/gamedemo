extends "res://tests/ui_driver.gd"


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://ui-test-"):
			folder = arg.trim_prefix("--save-dir=")
	if folder.is_empty() or FileAccess.file_exists(folder + "/farm.json"):
		push_error("Use a fresh -- --save-dir=user://ui-test-UNIQUE")
		quit(2)
		return
	scene = load("res://scenes/main.tscn")
	await spawn()
	await test_title_and_creator()
	await test_settings_from_pause()
	await test_hud_motion()
	await test_farming()
	await test_panels()
	await test_fishing_minigame()
	await test_story_and_people()
	await test_day_and_travel()
	await test_slots_and_reload()
	print("UI_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func nodes_of(node: Node, type: String, found: Array = []) -> Array:
	if node.is_class(type) and node.is_visible_in_tree():
		found.append(node)
	for child in node.get_children():
		nodes_of(child, type, found)
	return found


# ---------------------------------------------------------------------------- front menu


func test_title_and_creator() -> void:
	check(not game.initialized and game.front.screen == "title", "boots to title")
	check(not FileAccess.file_exists(folder + "/farm.json"), "title does not create a save")
	check(button_in(game, "继续生活").disabled, "no save, nothing to continue")
	await capture("title")
	await test_settings_from_title()
	await press("开始新生活")
	check(game.front.screen == "creator", "new game opens the creator")
	await press("返回")
	check(game.front.screen == "title", "cancelling returns to the title")
	await press("开始新生活")
	game.front.name_input.text = ""
	await press("带着这份期待，出发")
	check(
		game.front.screen == "creator" and not game.front.error_label.text.is_empty(),
		"empty name rejected"
	)
	game.front.name_input.text = "小雨"
	game.front.farm_input.text = "青苇小院"
	game.front.name_input.text_changed.emit("小雨")
	await press("衣服：湖蓝  ›")
	await press("帽子：草帽  ›")
	await capture("creator")
	await press("带着这份期待，出发")
	check(game.front.screen == "slots", "the creator asks for a save slot")
	check(
		not game.initialized and not FileAccess.file_exists(folder + "/farm.json"),
		"nothing is written before a slot is chosen"
	)
	await capture("slots-create")
	await press("开始在这里")
	check(game.initialized and not game.hud.is_modal(), "the creator enters the world")
	check(FileAccess.file_exists(folder + "/farm.json"), "the first slot is written at once")
	check(game.world_display.size == Vector2(1280, 800), "world fills the viewport")
	check(
		game.state.profile.name == "小雨" and game.state.profile.outfit == 1, "custom profile applied"
	)
	check(game.state.minute == 6 * 60 and game.state.day == 1, "the first day starts at six")
	await capture("farm-wild")


func test_settings_from_title() -> void:
	await press("设置")
	check(game.front.screen == "settings", "title opens settings")
	await capture("settings-audio")
	var sliders = nodes_of(game.front, "HSlider")
	check(sliders.size() == 2, "audio tab has master and effects sliders")
	sliders[0].value = 40
	sliders[0].drag_ended.emit(true)
	check(game.settings.get_value("master") == 40, "slider updates master volume")
	var bus = AudioServer.get_bus_index("Master")
	check(
		absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.4)) < 0.01,
		"master volume reaches the audio bus"
	)
	check(FileAccess.file_exists(folder + "/settings.json"), "settings are written to disk")
	sliders[1].value = 0
	sliders[1].drag_ended.emit(true)
	check(
		AudioServer.is_bus_mute(AudioServer.get_bus_index(GameSettings.SFX_BUS)),
		"zero effects volume mutes the effects bus"
	)
	await press("画面")
	await capture("settings-display")
	var toggles = nodes_of(game.front, "TextureButton")
	check(toggles.size() == 3, "display tab has three switches")
	await click(toggles[2].get_global_rect().get_center())
	check(game.settings.get_value("reduce_motion") == true, "switch flips the setting")
	await press("操作")
	await capture("settings-controls")
	await press("E")
	await key(KEY_G)
	check(game.settings.key_for("interact") == KEY_G, "key can be rebound")
	await press("G")
	await key(KEY_ESCAPE)
	check(game.settings.key_for("interact") == KEY_G, "escape cancels a rebind")
	check(game.front.screen == "settings", "escape during rebind does not leave the page")
	await press("G")
	await key(KEY_3)
	check(game.settings.key_for("interact") == KEY_G, "reserved keys are refused")
	await press("G")
	await key(KEY_Q)
	check(
		game.settings.key_for("interact") == KEY_Q and game.settings.key_for("cycle_seed") == KEY_G,
		"taking a used key swaps the two actions"
	)
	await press("恢复默认")
	check(
		game.settings.key_for("interact") == KEY_E and game.settings.key_for("cycle_seed") == KEY_Q,
		"restore defaults resets key bindings"
	)
	await press("游戏")
	await capture("settings-game")
	await press("返回")
	check(game.front.screen == "title", "back returns to the title")
	var reloaded = GameSettings.new(folder)
	check(reloaded.load_file().is_empty(), "saved settings load back")
	check(
		reloaded.get_value("master") == 40 and reloaded.get_value("reduce_motion") == true,
		"settings persist across sessions"
	)


func test_settings_from_pause() -> void:
	await key(KEY_ESCAPE)
	check(game.hud.modal_kind == "pause", "escape opens the pause menu")
	await capture("pause")
	await press("设置")
	check(game.hud.modal_kind == "settings", "pause menu opens settings")
	await press("返回")
	check(game.hud.modal_kind == "pause", "closing settings returns to the pause menu")
	check(game.world.reduce_motion == true, "world follows the reduce-motion setting")
	await press("继续生活")
	check(not game.hud.is_modal(), "resume closes the menu")
	game.settings.set_value("reduce_motion", false)
	game.settings.apply()
	game.settings.save_file()
	game._apply_settings()
	check(not UIMotion.reduced and not game.world.reduce_motion, "reduced motion switched off")


func test_hud_motion() -> void:
	var hud = game.hud
	var gold = game.state.gold
	game.state.gold = gold + 200
	hud.refresh(game.selected_tool, game.selected_crop)
	check(int(hud.gold_label.text) == gold, "gold counter starts from the old value")
	await create_timer(0.25).timeout
	var mid = int(hud.gold_label.text)
	check(mid > gold and mid < gold + 200, "gold counts up smoothly")
	await create_timer(1.2).timeout
	check(int(hud.gold_label.text) == gold + 200, "gold settles on the real value")
	game.state.gold = gold
	hud.refresh(game.selected_tool, game.selected_crop)
	await create_timer(1.2).timeout


# ---------------------------------------------------------------------------- farming


func test_farming() -> void:
	var cells = free_cells(3)
	place_cell(cells[0])
	await key(KEY_6)
	game.world.player.facing = Vector2i.RIGHT
	await key(KEY_SPACE)
	check(game.world.player.action_remaining > 0, "a swing animates")
	var action_time = game.world.player.action_remaining
	await key(KEY_SPACE)
	check(
		game.world.player.action_remaining < action_time, "a rapid repeat cannot restart the swing"
	)
	await create_timer(ToolMotion.MAX_DURATION).timeout
	place_cell(cells[0])
	var before = [
		game.state.stamina, game.state.inventory.duplicate(), game.state.cleared.duplicate()
	]
	game.hud.toast_remaining = 0
	game.hud.toast_box.hide()
	await click_cell(cells[0])
	check(
		[game.state.stamina, game.state.inventory, game.state.cleared] == before,
		"the wrong tool does not consume resources"
	)
	check(not game.hud.toast_box.visible, "the wrong tool does not show an instructional toast")
	await key(KEY_1)
	var snapshot = [
		game.state.stamina, game.state.inventory.duplicate(), game.state.plots.duplicate(true)
	]
	await press("水壶")
	check(
		(
			game.selected_tool == "water"
			and [game.state.stamina, game.state.inventory, game.state.plots] == snapshot
		),
		"the toolbar selects without operating the ground"
	)
	for cell in cells:
		place_cell(cell)
		await key(KEY_1)
		await click_cell(cell)
		await key(KEY_2)
		await click_cell(cell)
		await key(KEY_3)
		await click_cell(cell)
	check(game.state.plots.size() == 3, "the mouse tills three cells")
	check(game.state.plots[FarmState.cell_key(cells[0])].watered, "the mouse plants and waters")
	await key(KEY_ESCAPE)
	place_cell(cells[0])
	var pos = game.world.player.position
	var minute = game.state.minute
	await key(KEY_D, 1.1)
	check(
		game.state.minute == minute and game.world.player.position == pos,
		"a modal freezes clock and movement"
	)
	await key(KEY_ESCAPE)
	await key(KEY_S, 0.2)
	check(game.world.player.position.y > pos.y + 5, "movement input")
	var pointer = Vector2(300, 250)
	check(
		game.world.world_to_screen(game.world.screen_to_world(pointer)).distance_to(pointer) < 0.1,
		"mouse coordinates survive camera scroll"
	)
	await key(KEY_8)
	check(game.selected_tool == "rod", "the fishing rod sits on key eight")
	await key(KEY_1)


# ---------------------------------------------------------------------------- panels


func test_panels() -> void:
	game.state.minute = 10 * 60
	game.state.gold = 500
	await key(KEY_B)
	check(game.hud.modal_kind == "bag", "bag shortcut")
	await capture("bag")
	await key(KEY_ESCAPE)
	await key(KEY_J)
	check(game.hud.modal_kind == "journal", "journal shortcut")
	await capture("journal")
	await press("合上手记")
	place_cell(Vector2i(40, 20))
	await key(KEY_M)
	check(game.hud.modal_kind == "map", "map shortcut")
	await capture("map")
	await press("收起地图")
	game._on_action("collection", {})
	check(game.hud.modal_kind == "collection", "collection opens")
	await capture("collection")
	await key(KEY_ESCAPE)
	await interact("shop")
	check(game.hud.modal_kind == "shop", "the seed stall opens")
	await capture("shop")
	var gold = game.state.gold
	await press("买 1 份")
	check(game.state.gold < gold and game.hud.modal_kind == "shop", "buying keeps the counter open")
	await press("出售")
	await capture("shop-sell")
	await press("离开")
	game.state.minute = 20 * 60
	await interact("shop")
	check(not game.hud.is_modal() and game.hud.toast_box.visible, "a closed shop says why")
	game.state.minute = 10 * 60
	game.state.inventory.turnip = 3
	await interact("shipping")
	check(game.hud.modal_kind == "shipping", "shipping box opens")
	var coins = game.state.gold
	await press("出售全部 / +%d G" % game.rules.sale_quote(game.state).gold)
	check(game.state.inventory.turnip == 0 and game.state.gold > coins, "shipping sells produce")
	game.hud.dialogs.show_cooking()
	await capture("cooking")
	await key(KEY_ESCAPE)
	game.hud.dialogs.show_animals("coop")
	await capture("animals")
	await key(KEY_ESCAPE)
	game.hud.dialogs.show_board()
	await capture("board")
	await key(KEY_ESCAPE)
	for shop_id in game.catalog.shops:
		game.hud.dialogs.show_shop(shop_id)
		await process_frame
		check(game.hud.modal_kind == "shop", "every shop panel builds: " + shop_id)
	game.hud.close_modal()


func test_fishing_minigame() -> void:
	var panel = game.hud.dialogs.show_fishing(false)
	var outcome = {"done": false, "fish": "?"}
	panel.finished.connect(
		func(fish):
			outcome.done = true
			outcome.fish = fish
	)
	await capture("fishing-wait")
	check(panel.phase == "wait", "the line starts quiet")
	await key(KEY_SPACE)
	check(outcome.done and outcome.fish == "", "pulling too early scares the fish")
	game.hud.close_modal()
	panel = game.hud.dialogs.show_fishing(true)
	outcome.done = false
	panel.finished.connect(
		func(fish):
			outcome.done = true
			outcome.fish = fish
	)
	panel.left = 0.01
	await create_timer(0.1).timeout
	check(panel.phase == "bite", "a bite follows the wait")
	await key(KEY_SPACE)
	check(panel.phase == "reel", "lifting the rod starts the timing bar")
	await capture("fishing-reel")
	panel.marker.position.x = panel.zone.position.x + panel.zone.size.x / 2.0 - 5.0
	panel.set_process(false)
	await key(KEY_SPACE)
	check(
		outcome.done and outcome.fish == panel.fish_id, "stopping inside the zone lands the catch"
	)
	game.hud.close_modal()


# ---------------------------------------------------------------------------- people and story


func test_story_and_people() -> void:
	game._talk_npc("hazel")
	await process_frame
	check(game.hud.modal_kind == "dialogue", "the neighbour's first words are a scene")
	await capture("dialogue")
	await dialogue()
	check(game.state.narrative.stage == 1, "welcome advances the quest")
	game.state.relationships.hazel = 20
	game.state.inventory.turnip = 1
	game._talk_npc("hazel")
	await process_frame
	check(game.hud.modal_kind == "npc", "a villager's panel opens")
	await capture("npc")
	var friendship = game.state.relationships.hazel
	await press("送一份礼物")
	await press("萝卜 ×1")
	check(game.state.relationships.hazel == friendship + 12, "a favourite gift through the UI")
	game.state.daily.gifted.clear()
	game._talk_npc("hazel")
	await process_frame
	await press("听听黑兹尔的故事")
	await capture("heart-event")
	await dialogue()
	check(game.state.development.events.has("hazel_20"), "a heart event pays out through dialogue")
	game.state.minute = 12 * 60
	await interact("to_town")
	check(game.state.current_map == "town", "the road leads to town")
	await interact("to_market")
	check(game.state.current_map == "market", "the market street is connected")
	await process_frame
	await process_frame
	var seen = visible_villagers()
	check(not seen.is_empty(), "villagers are out on the market street at noon")
	if not seen.is_empty():
		await interact(seen[0])
		check(game.hud.modal_kind in ["npc", "dialogue"], "a villager can be talked to in person")
		await key(KEY_ESCAPE)
	await capture("market")
	await interact("to_general_store")
	check(game.state.current_map == "general_store", "shops have interiors")
	await interact("counter")
	check(game.hud.modal_kind == "shop", "the general store counter opens")
	await capture("general-store")
	await press("离开")
	await interact("to_market")
	await interact("to_seaside")
	check(game.state.current_map == "seaside", "the seaside is reachable")
	await capture("seaside")
	await interact("to_market")
	await interact("to_town")


func test_day_and_travel() -> void:
	await interact("to_forest")
	check(game.state.current_map == "forest", "the forest is connected")
	await capture("forest")
	var gathered = 0
	for node in game.catalog.region("forest").gather:
		if game.world.available_stations().any(func(st): return st.id == node.id):
			await interact(node.id)
			gathered += 1
			if gathered == 2:
				break
	check(game.state.daily.gathered.size() == gathered, "gathering through E")
	await interact("to_mine_1")
	check(game.state.current_map == "mine_1", "the old quarry opens")
	await capture("mine")
	await interact("to_forest")
	await interact("to_town")
	await interact("to_home_farm")
	check(game.state.current_map == "home_farm", "the road home")
	await interact("to_cottage")
	check(game.state.current_map == "cottage", "the farm door enters the cottage")
	await capture("cottage")
	game.state.minute = 25 * 60 + 50
	game.clock_accumulator = game.TICK_SECONDS
	await process_frame
	await process_frame
	check(game.state.day == 2 and game.state.minute == 6 * 60, "staying up past 26:00 ends the day")
	check(game.state.current_map == "cottage", "waking up in bed")
	await create_timer(1.4).timeout
	await sleep_day()
	check(game.state.day == 3, "the pause menu puts you to bed")
	check(game.fade.active, "a new day starts behind the day card")
	await create_timer(1.4).timeout
	check(not game.fade.active, "the card fades away on its own")
	check(game.hud.time_label.text.ends_with("06:00"), "the clock shows morning")


# ---------------------------------------------------------------------------- slots


func test_slots_and_reload() -> void:
	game.state.relationships.margot = 33
	var day = game.state.day
	await key(KEY_ESCAPE)
	await press("保存并返回标题")
	check(not game.initialized and game.front.screen == "title", "return to the title saves")
	check(not button_in(game, "继续生活").disabled, "continue is available once a slot exists")
	await press("继续生活")
	check(game.initialized and game.state.relationships.margot == 33, "continue restores the save")
	check(game.state.day == day and game.state.profile.name == "小雨", "day and profile survive")
	check(
		game.state.narrative.stage == 1 and game.state.development.events.has("hazel_20"),
		"story progress survives"
	)
	check(game.state.current_map == "cottage", "the player wakes where they slept")
	await key(KEY_ESCAPE)
	await press("保存并返回标题")
	await press("读取存档")
	check(game.front.screen == "slots", "load screen opens")
	await capture("slots-load")
	await press("返回")
	await press("开始新生活")
	await press("带着这份期待，出发")
	await press("开始在这里")
	check(game.initialized and game.active_slot == 1, "a new life overwrites the chosen slot")
	check(
		game.state.profile.name == "小芽" and game.state.day == 1,
		"a new life starts fresh from the creator defaults"
	)
	await key(KEY_ESCAPE)
	await press("保存并返回标题")
	await press("读取存档")
	var buttons = nodes_of(game.front, "Button")
	var reads = buttons.filter(func(b): return b.text == "读取" and not b.disabled)
	check(reads.size() == 1, "one occupied slot can be read")
	await press("删除")
	await press("再点一次确认删除")
	check(not FileAccess.file_exists(folder + "/farm.json"), "deleting removes the file")
	check(button_in(game, "读取") == null or button_in(game, "读取").disabled, "nothing left to read")

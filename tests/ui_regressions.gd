extends "res://tests/ui_driver.gd"

## Real input regressions at component boundaries and crowded panel layouts.


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://ui-test-"):
			folder = arg.trim_prefix("--save-dir=")
	if folder.is_empty():
		quit(2)
		return
	scene = load("res://scenes/main.tscn")
	await spawn()
	game._on_front(
		"create",
		{
			"profile":
			{"name": "Review", "farm": "Review", "skin": 0, "hair": 0, "outfit": 0, "hat": 0},
			"slot": 1
		}
	)
	game.set_process(false)
	await create_timer(0.8).timeout
	UIMotion.reduced = true
	await test_runtime_sync()
	await test_panel_layouts()
	print("UI_REGRESSIONS: %d checks, %d failures" % [checks, failures.size()])
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)


func buttons_under(node: Node) -> Array:
	var result: Array = []
	if node is Button and node.is_visible_in_tree():
		result.append(node)
	for child in node.get_children():
		result.append_array(buttons_under(child))
	return result


func check_buttons(label: String) -> void:
	var panel = game.hud.dialogs.modal_panel
	var bounds: Rect2 = panel.get_global_rect()
	var buttons = buttons_under(panel)
	for i in buttons.size():
		var rect: Rect2 = buttons[i].get_global_rect()
		check(
			bounds.grow(-12).encloses(rect),
			label + " button stays inside border: " + buttons[i].text
		)
		for j in range(i):
			check(
				not rect.intersects(buttons[j].get_global_rect()),
				label + " buttons don't overlap: " + buttons[i].text + " / " + buttons[j].text
			)


func test_runtime_sync() -> void:
	game.state.inventory.bait = 2
	game._refresh()
	await click(game.hud.pocket_buttons.bait.get_global_rect().get_center())
	check(game.hud.modal_kind == "bag", "quick pocket opens backpack")
	check(
		game.hud.dialogs.modal_panel.get_child(0).selected == "bait",
		"quick pocket selects its item"
	)
	game.hud.close_modal()
	game.hud.dialogs.show_settings(game.settings)
	await press("游戏")
	var settings_panel = game.hud.dialogs.modal_panel.get_child(0)
	for node in settings_panel.body.get_children():
		if node is TextureButton and is_equal_approx(node.position.y, 122.0):
			await click(node.get_global_rect().get_center())
	await key(KEY_ESCAPE)
	check(game.hud.modal_kind == "pause", "Esc from settings returns to pause")
	check(
		game.settings.get_value("sprint_toggle") and game.world.player.sprint_toggle,
		"Esc applies sprint mode"
	)
	game.hud.close_modal()
	game.state.minute = 600
	game.clock_accumulator = 6.99
	game._process(0.02)
	var now = game.state.minute + game.world.clock_fraction
	game._process(0.02)
	check(
		game.state.minute == 610 and game.world.clock_fraction < 1, "fraction excludes elapsed tick"
	)
	check(game.state.minute + game.world.clock_fraction >= now, "NPC time cannot reverse at a tick")
	game.state.day = 2
	game.state.minute = 600
	var spawn: Array = game.catalog.region("workshop").spawn
	game._travel("workshop", Vector2(spawn[0], spawn[1]))
	game.world.player.position += Vector2(64, 0)
	var position = game.world.player.position
	game.state.gold = 3000
	game.state.inventory.wood = 100
	game.state.inventory.stone = 100
	game._on_panel_action("build", {"id": "coop", "shop": "builder", "tab": "build", "page": 0})
	check(game.state.buildings.has("coop"), "construction accepted")
	check(game.world.player.position == position, "construction preserves live player position")
	game.hud.close_modal()
	game.settings.set_value("autosave", false)
	game.world.player.position += Vector2(32, 0)
	position = game.world.player.position
	game._start_scene("welcome", "quest")
	game._finish_scene("")
	check(
		game.state.narrative.stage == 1 and game.world.player.position == position,
		"story rebuild preserves position with autosave disabled"
	)
	game.hud.close_modal()
	UIMotion.reduced = true


func test_panel_layouts() -> void:
	for id in game.catalog.items:
		game.state.inventory[id] = 999
	game.state.gold = 9999999
	game._refresh()
	game.hud.dialogs.show_shop("tea", "sell", 0)
	await process_frame
	check_buttons("sale")
	var inventory = game.state.inventory.duplicate()
	await press("下一页 ›")
	check(game.hud.dialogs.modal_panel.get_child(0).page == 1, "mouse can turn sale page")
	check(game.state.inventory == inventory, "turning sale page never sells inventory")
	await capture("layout-sale")
	for id in game.catalog.shops:
		game.hud.dialogs.show_shop(id)
		var tabs = game.hud.dialogs.modal_panel.get_child(0)._tabs()
		for tab in tabs:
			game.hud.dialogs.show_shop(id, tab[0])
			await process_frame
			check_buttons(id + "/" + tab[0])
	game.hud.dialogs.show_shop("builder", "build")
	await process_frame
	var building_panel = game.hud.dialogs.modal_panel.get_child(0)
	for node in building_panel.get_children():
		if node is TextureRect:
			check(
				node.size.x <= 76 and node.size.y <= 76,
				"building thumbnails respect their allotted size"
			)
	await capture("layout-building")
	game.hud.dialogs.show_shop("smith", "upgrade")
	await capture("layout-upgrades")
	game.hud.dialogs.show_bag(false, "bait")
	await process_frame
	var bag = game.hud.dialogs.modal_panel.get_child(0)
	check(
		int(bag._items().find("bait") / BagPanel.PER_PAGE) == bag.page,
		"quick item is on the visible page"
	)
	check_buttons("bag")
	await capture("layout-bag")
	game.hud.dialogs.show_collection()
	await process_frame
	check_buttons("collection")
	await capture("layout-collection")
	game.hud.dialogs.show_cooking()
	await process_frame
	check_buttons("cooking")
	await capture("layout-cooking")
	game.hud.dialogs.show_board()
	await process_frame
	check_buttons("board")
	var largest = 0
	for i in game.catalog.story.quests.size():
		var quest = game.catalog.story.quests[i]
		var score = quest.needs.size() * 44 + quest.friendship.size() * 38
		if score > largest:
			largest = score
			game.state.narrative.stage = i
	# Stress the variable-height requirements list without changing authored content.
	var quest = game.stories.quest(game.state)
	var original_needs = quest.needs.duplicate()
	for item in ["copper_ore", "iron_ore", "silver_ore", "gold_ore", "coal"]:
		quest.needs[item] = 99
	game.hud.dialogs.show_journal()
	await process_frame
	check_buttons("journal")
	await capture("layout-journal")
	var scrolls = game.hud.dialogs.modal_panel.get_child(0).get_children().filter(
		func(n): return n is ScrollContainer
	)
	check(scrolls.size() == 2, "journal columns scroll independently")
	var detail: ScrollContainer = scrolls[1]
	detail.scroll_vertical = 10000
	await process_frame
	check(detail.scroll_vertical > 0, "long quest requirements can scroll")
	await capture("layout-journal-scrolled")
	quest.needs = original_needs
	game.state.narrative.stage = game.catalog.story.quests.size() - 1
	game.hud.dialogs.show_journal()
	await process_frame
	check_buttons("final journal")
	game.hud.close_modal()

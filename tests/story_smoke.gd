extends "res://tests/ui_driver.gd"

## Plays the story on screen: every scene runs through the cutscene player, the main scenes are
## photographed, and the mine fights and the wedding are driven the way a player would.


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
	game._on_front(
		"create",
		{
			"profile": {"name": "小雨", "farm": "青苇小院", "skin": 0, "hair": 0, "outfit": 1, "hat": 1},
			"slot": 1
		}
	)
	await process_frame
	await test_every_scene()
	await test_main_scenes()
	await test_chapter_card()
	await test_mine()
	await test_wedding()
	print("STORY_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


## Starts a scene the way the game does, whatever the story state, and reads it to the end.
func read_scene(id: String, kind: String) -> int:
	game.hud.close_modal()
	game._start_scene(id, kind)
	await process_frame
	var dialogs: GameDialogs = game.hud.dialogs
	if game.hud.modal_kind != "dialogue":
		check(false, "scene opens: " + id)
		return 0
	dialogs.cutscene_skip()
	var shown = 1
	while game.scene_index < game.pages.size() - 1:
		dialogs.cutscene_skip()
		game._on_action("dialogue_next", {})
		await process_frame
		shown += 1
	check(shown == game.pages.size(), "every page is shown: " + id)
	return shown


func test_every_scene() -> void:
	var total = 0
	for id in game.catalog.story.scenes:
		var kind = "follow"
		if game.catalog.quest_index(id) >= 0:
			kind = "quest"
		# Flags the pages ask about, so every branch of a scene gets played.
		game.state.narrative.flags = {"ending": ["root", "shore", "stream"][hash(id) % 3]}
		total += await read_scene(id, kind)
		game.state.narrative.active_scene = ""
	game.hud.close_modal()
	check(total >= 600, "the whole story played through the cutscene player (%d pages)" % total)


func test_main_scenes() -> void:
	var chosen = [
		"prologue",
		"bridge",
		"festival",
		"ledger",
		"bell",
		"greenhouse_bloom",
		"return",
		"water_runs",
		"first_snow",
		"vault",
		"ferryman",
		"playhouse_night",
		"town_meeting",
		"year_end_feast",
		"new_lantern_end_root",
	]
	game.state.narrative.flags = {"ending": "root"}
	game.state.narrative.stage = game.catalog.story.quests.size() - 1
	for id in chosen:
		game.hud.close_modal()
		game._start_scene(id, "quest" if game.catalog.quest_index(id) >= 0 else "follow")
		await process_frame
		game.hud.dialogs.cutscene_skip()
		await capture("cut-%s-first" % id)
		while game.scene_index < game.pages.size() - 1:
			game.hud.dialogs.cutscene_skip()
			game._on_action("dialogue_next", {})
			await process_frame
		game.hud.dialogs.cutscene_skip()
		await create_timer(0.6).timeout
		await capture("cut-%s-last" % id)
	game.hud.close_modal()
	game.state.narrative.active_scene = ""


func test_chapter_card() -> void:
	game.hud.close_modal()
	game._start_scene("ledger", "quest")
	await process_frame
	var view: CutsceneView = game.hud.dialogs.cutscene
	check(view.card_active, "a new chapter opens with its card")
	await create_timer(0.9).timeout
	await capture("chapter-card")
	check(view.body.visible_characters == 0 or not view.panel.visible, "no words under the card")
	await key(KEY_E)
	check(not view.card_active and view.panel.visible, "a key press skips the card")
	check(view.typing, "the first line is typed out")
	await key(KEY_E)
	check(not view.typing, "a key press finishes the line")
	check(game.scene_index == 0, "and the next one turns the page")
	await key(KEY_E)
	check(game.scene_index == 1, "pages turn in order")
	game.hud.close_modal()
	game.state.narrative.active_scene = ""
	var view2 = CutsceneView.new()
	check(view2.skip() == false, "nothing to skip before a scene starts")
	view2.free()


func test_mine() -> void:
	game.hud.close_modal()
	game.state.narrative.stage = 0
	game.state.current_map = "mine_1"
	game.stories.enter(game.state, "mine_1", Vector2(32 * 32 + 16, 44 * 32 + 16))
	game._build_world()
	await process_frame
	check(
		game.world.enemies.size() == 7,
		"seven slimes on the first floor (%d)" % game.world.enemies.size()
	)
	check(game.hud.hp_group.visible, "the life bar appears in the mine")
	var enemy: MineEnemy = game.world.enemies[0]
	enemy.position = game.world.player.position + Vector2(28, 0)
	game.world.player.facing = Vector2i.RIGHT
	await key(KEY_9)
	check(game.selected_tool == "sword", "the sword sits on key nine")
	var stamina = game.state.stamina
	var hp = enemy.hp
	await key(KEY_SPACE)
	check(
		game.state.stamina == stamina - game.combat.swing_cost(game.state), "a swing costs stamina"
	)
	await create_timer(0.7).timeout
	check(
		not is_instance_valid(enemy) or enemy.hp < hp or not game.world.enemies.has(enemy),
		"the blow lands"
	)
	await capture("mine-fight")
	var before = game.player_hp
	game.hit_cooldown = 0.0
	game._on_player_hit(10, Vector2.LEFT)
	check(game.player_hp == before - 10, "a monster's touch hurts")
	game._on_player_hit(10, Vector2.LEFT)
	check(game.player_hp == before - 10, "but not twice in a breath")
	game.hit_cooldown = 0.0
	game._on_player_hit(500, Vector2.LEFT)
	await create_timer(0.3).timeout
	check(
		game.state.current_map == "forest" and game.player_hp == game.combat.hero_hp(),
		"a knockout carries you out of the mine"
	)
	check(game.state.stamina >= 20, "and costs only some stamina")
	var kills = game.state.stats.defeated
	game.state.current_map = "mine_1"
	game._build_world()
	await process_frame
	var target: MineEnemy = game.world.enemies[0]
	target.hurt(999, game.world.player.position, 10.0)
	await process_frame
	check(game.state.stats.defeated == kills + 1, "a defeated monster is counted")
	game._next_day()
	await process_frame
	check(game.defeated_today.is_empty(), "the mine fills up again overnight")
	await key(KEY_1)


func test_wedding() -> void:
	game.hud.close_modal()
	var s: FarmState = game.state
	s.narrative.stage = 6
	s.narrative.flags = {"wish": "stay"}
	s.relationships.hazel = 100
	for at in [20, 40, 60, 80, 100]:
		game.stories.claim_event(s, "hazel_%d" % at)
	s.inventory.heart_lantern = 1
	s.inventory.union_ring = 1
	game.stories.enter(s, "home_farm", Vector2(41 * 32 + 16, 17 * 32 + 16))
	game._build_world()
	game._talk_npc("hazel")
	await process_frame
	check(game.hud.modal_kind == "npc", "the villager's panel shows the new buttons")
	await capture("romance-panel")
	await press("递上心意灯")
	await process_frame
	check(
		game.hud.modal_kind == "dialogue" and s.romance.has("hazel"),
		"the lantern is accepted in a scene"
	)
	await dialogue()
	check(game.stories.stage_of(s, "hazel") == "dating", "they are courting")
	game._talk_npc("hazel")
	await process_frame
	await press("拿出同心环，求婚")
	await dialogue()
	check(game.stories.stage_of(s, "hazel") == "engaged", "they are engaged")
	game._next_day()
	game._next_day()
	await process_frame
	check(game.hud.modal_kind != "dialogue", "no wedding yet")
	game._next_day()
	await process_frame
	check(
		game.hud.modal_kind == "dialogue" and game.scene_event == "wedding_hazel",
		"the wedding begins on the third morning"
	)
	await create_timer(0.5).timeout
	game.hud.dialogs.cutscene_skip()
	await capture("wedding")
	await dialogue()
	check(game.stories.spouse(s) == "hazel", "married")
	check(
		game.planner.where("hazel", 22.0 * 60.0 + 30.0).map == "cottage",
		"she lives in the farmhouse now"
	)
	s.minute = 12 * 60 + 30
	game.state.current_map = "cottage"
	game._build_world()
	await process_frame
	check(game.world.npc_nodes.has("hazel"), "the spouse is in the house at noon")
	await capture("married-cottage")
	game._next_day()
	await process_frame
	check(
		s.plots.is_empty() or s.plots.values().all(func(p): return p.watered),
		"the spouse waters the field before breakfast"
	)

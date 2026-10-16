extends Node

const WORLD_RECT = Rect2(0, 0, 1280, 800)
## Real seconds for one 10-minute clock tick: a day lasts about 14 minutes.
const TICK_SECONDS = 7.0

var catalog: ContentCatalog
var state: FarmState
var rules: FarmRules
var stories: StoryRules
var shops: ShopRules
var cooking: CookingRules
var fishing: FishingRules
var animals: AnimalRules
var happenings: EventRules
var board: BoardRules
var combat: CombatRules
var planner: NpcPlanner
var store: SaveStore
var settings: GameSettings
var fade: ScreenFade
var active_slot: int = 1
## -1 draws a random world seed per new game; tests pin it (0 is always fair weather).
var fixed_seed: int = -1
var world: FarmWorld
var world_viewport: SubViewport
var world_display: TextureRect
var hud: FarmHUD
var front: FrontMenu
var selected_tool: String = "hoe"
var selected_crop: String = "turnip"
var action_crop: String = "turnip"
var mouse_aim: bool = false
var clock_accumulator: float = 0.0
var autosave_accumulator: float = 0.0
var audio: Dictionary = {}
var initialized: bool = false
var pages: Array = []
var scene_id: String = ""
var scene_kind: String = ""
var scene_event: String = ""
var scene_index: int = 0
var scene_queue: Array = []
var pending_ending: bool = false
var player_hp: int = 40
var hit_cooldown: float = 0.0
var defeated_today: Dictionary = {}
var drop_rng := RandomNumberGenerator.new()


func _ready() -> void:
	get_tree().auto_accept_quit = false
	catalog = ContentCatalog.new()
	var error = catalog.load_content()
	if not error.is_empty():
		push_error(error)
		get_tree().quit(1)
		return
	rules = FarmRules.new(catalog)
	stories = StoryRules.new(catalog)
	shops = ShopRules.new(catalog)
	cooking = CookingRules.new(catalog)
	fishing = FishingRules.new(catalog)
	animals = AnimalRules.new(catalog)
	happenings = EventRules.new(catalog)
	board = BoardRules.new(catalog)
	combat = CombatRules.new(catalog)
	drop_rng.randomize()
	var directory = "user://"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="):
			directory = argument.trim_prefix("--save-dir=")
	store = SaveStore.new(catalog, directory)
	settings = GameSettings.new(directory)
	settings.load_file()
	settings.apply()
	fade = ScreenFade.new()
	add_child(fade)
	for kind in [
		"action",
		"harvest",
		"day",
		"bell",
		"chime",
		"lantern",
		"water",
		"cheer",
		"wedding",
		"hit",
		"rumble",
		"tick",
		"swing",
		"hurt",
		"defeat"
	]:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/%s.wav" % kind)
		player.volume_db = -8
		player.bus = GameSettings.SFX_BUS
		add_child(player)
		audio[kind] = player
	_show_front()


func _show_front() -> void:
	initialized = false
	for node in [world_display, world_viewport, hud, front]:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	world = null
	world_display = null
	world_viewport = null
	hud = null
	front = FrontMenu.new()
	add_child(front)
	front.initialize(catalog, store, settings)
	front.action_requested.connect(_on_front)


func _on_front(action: String, payload: Dictionary) -> void:
	match action:
		"continue", "load":
			var entry = store.load_slot(int(payload.slot))
			if entry.state != null:
				active_slot = int(payload.slot)
				_start_game(entry.state)
		"create":
			var candidate = FarmState.new_game(
				catalog, fixed_seed if fixed_seed >= 0 else randi_range(1, 2147483647)
			)
			candidate.profile = payload.profile.duplicate(true)
			var invalid = store.validate(candidate.snapshot(catalog))
			if not invalid.is_empty():
				front.error_label.text = invalid
				return
			active_slot = int(payload.slot)
			_start_game(candidate)
		"delete":
			var failure = store.delete_slot(int(payload.slot))
			front.show_slots(payload.mode, failure)
		"preview_sound":
			_sound("action")
		"front_quit":
			get_tree().quit()


func _start_game(initial_state: FarmState) -> void:
	state = initial_state
	if is_instance_valid(front):
		remove_child(front)
		front.queue_free()
		front = null
	hud = FarmHUD.new()
	add_child(hud)
	hud.configure(catalog, state)
	hud.action_requested.connect(_on_action)
	hud.dialogs.cutscene_sound.connect(_sound)
	player_hp = combat.hero_hp()
	hit_cooldown = 0.0
	defeated_today.clear()
	scene_queue.clear()
	pending_ending = false
	_plan_day()
	_build_world()
	initialized = true
	clock_accumulator = 0
	autosave_accumulator = 0
	selected_tool = "hoe"
	selected_crop = _default_crop()
	board.refresh(state)
	_refresh()
	_save(false, true)
	fade.reveal(0.7)
	if not state.narrative.active_scene.is_empty():
		_start_scene(state.narrative.active_scene, _kind_of(state.narrative.active_scene))
	else:
		_check_wedding()


## The first crop that can be planted today, so the seed slot starts on something useful.
func _default_crop() -> String:
	var season = catalog.calendar.season_of(state.day)
	for id in catalog.crops:
		if catalog.crops[id].seasons.has(season):
			return id
	return catalog.crops.keys()[0]


func _plan_day() -> void:
	planner = NpcPlanner.new(catalog, state.tree_damage)
	var context = {
		"day": state.day,
		"date": catalog.calendar.date(state.day),
		"weather": catalog.weather.weather_on(state.world_seed, state.day),
		"stage": int(state.narrative.stage),
		"birthdays": catalog.calendar.birthdays_on(state.day, catalog.story.npcs),
		"festival": catalog.calendar.is_festival(state.day),
		"spouse": stories.spouse(state),
	}
	planner.plan_day(context)


func _build_world() -> void:
	for node in [world_display, world_viewport]:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	world_viewport = SubViewport.new()
	world_viewport.size = Vector2i(WORLD_RECT.size)
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	world_viewport.handle_input_locally = false
	add_child(world_viewport)
	world = FarmWorld.new()
	world_viewport.add_child(world)
	world.configure(catalog, state, planner)
	world.player.action_contact.connect(_tool_contact)
	world.player.can_move = false
	world.player_hit.connect(_on_player_hit)
	world.enemy_defeated.connect(_on_enemy_defeated)
	_apply_settings()
	_spawn_enemies()
	hud.set_hp(player_hp, combat.hero_hp())
	world_display = TextureRect.new()
	world_display.position = WORLD_RECT.position
	world_display.size = WORLD_RECT.size
	world_display.texture = world_viewport.get_texture()
	world_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_display.z_index = -1
	add_child(world_display)


func _pointer_in_world() -> Vector2:
	return get_viewport().get_mouse_position() - WORLD_RECT.position


func _process(delta: float) -> void:
	if not initialized:
		return
	world.player.can_move = not hud.is_modal()
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	if world.player.velocity.length_squared() > 0.1:
		mouse_aim = false
	world.update_target(mouse_aim, _pointer_in_world())
	var station = world.nearby_station()
	var hint: String = station.get("name", "") if settings.get_value("show_hints") else ""
	hud.set_target(hint, world.world_to_screen(world.player.position))
	if hud.is_modal():
		return
	clock_accumulator += delta
	world.clock_fraction = clock_accumulator / TICK_SECONDS * float(FarmState.TICK_MINUTES)
	if clock_accumulator >= TICK_SECONDS:
		clock_accumulator -= TICK_SECONDS
		state.minute += FarmState.TICK_MINUTES
		_on_tick()
	autosave_accumulator += delta
	if autosave_accumulator >= 30 and settings.get_value("autosave"):
		autosave_accumulator = 0
		_save(false)
	world.modulate = world.light_color()


func _on_tick() -> void:
	if state.minute >= FarmState.NIGHT:
		hud.toast("实在太困了，你倒在床上睡着了。")
		_next_day()
		return
	if state.minute == 24 * 60:
		hud.toast("已经很晚了，该回家睡觉了。")
	if (
		stories.clock_ringing(state)
		and state.minute % 60 == 0
		and state.minute >= 7 * 60
		and state.minute <= 22 * 60
	):
		var strokes = int(state.minute / 60) % 12
		hud.toast("钟楼敲了 %d 下。" % (12 if strokes == 0 else strokes))
		_sound("bell")
	var festival = stories.attend_festival(state)
	if festival.ok:
		hud.toast(festival.message, 5)
		_sound("day")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not initialized:
		if event.is_action_pressed("menu") and is_instance_valid(front):
			front.show_title()
		return
	if event is InputEventMouseMotion:
		mouse_aim = true
	if hud.modal_kind == "dialogue":
		if event.is_action_pressed("use_tool") or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			if hud.dialogs.cutscene_skip():
				return
			if scene_index < pages.size() - 1:
				_on_action("dialogue_next", {})
			elif _choices_for(scene_event).is_empty():
				_on_action("dialogue_finish", {})
		elif event.is_action_pressed("menu") and scene_kind != "wedding":
			state.narrative.active_scene = ""
			state.narrative.page = 0
			scene_queue.clear()
			pending_ending = false
			hud.close_modal()
			_save(false)
		return
	if event.is_action_pressed("menu"):
		if hud.modal_kind == "fishing":
			return
		if hud.is_modal():
			hud.close_modal()
		else:
			hud.dialogs.show_pause()
		get_viewport().set_input_as_handled()
		return
	if hud.is_modal():
		return
	for action in ["journal", "map", "bag"]:
		if event.is_action_pressed(action):
			_on_action(action, {})
			return
	for i in range(FarmHUD.TOOLS.size()):
		if event.is_action_pressed("tool_%d" % [i + 1]):
			_on_action("select_tool", {"tool": FarmHUD.TOOLS[i]})
			return
	if event.is_action_pressed("cycle_seed"):
		_on_action("cycle_seed", {})
	elif event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("use_tool"):
		mouse_aim = false
		world.update_target(false)
		_use_tool()
	elif (
		event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	):
		if WORLD_RECT.has_point(get_viewport().get_mouse_position()):
			mouse_aim = true
			world.update_target(true, _pointer_in_world())
			_use_tool()


func _use_tool() -> void:
	if selected_tool == "rod":
		_cast()
	elif selected_tool == "sword":
		_swing_sword()
	elif world.player.swing_tool(selected_tool, world.target):
		action_crop = selected_crop


func _tool_contact(tool: String, cell: Vector2i) -> void:
	if tool == "sword":
		_sword_hit()
		return
	var response = rules.apply_tool(state, tool, cell, world.player.cell(), action_crop)
	_feedback(response, false)
	if response.ok:
		if response.has("cleared_id"):
			world.remove_debris(response.cleared_id)
		if response.has("tree_id"):
			world.strike_tree(response.tree_id, response.tree_hits)
		world.effect(cell, tool)
		if response.has("harvest"):
			world.effects.pickup(
				world.tex(catalog.items[response.harvest].icon),
				Vector2(cell) * 32 + Vector2(16, 16)
			)
		_sound("harvest" if tool == "harvest" else "action")


# ---------------------------------------------------------------------------- fishing


func _cast() -> void:
	if world.player.action_remaining > 0:
		return
	var water = fishing.water_ahead(state, world.player.cell(), world.player.facing)
	if water == Vector2i(-1, -1):
		hud.toast("面前三格内没有水。")
		return
	var bait = state.inventory.bait > 0
	var response = fishing.cast(state, bait)
	if not response.ok:
		hud.toast(response.message)
		return
	_refresh()
	var panel = hud.dialogs.show_fishing(bait)
	panel.finished.connect(_on_fished)


func _on_fished(fish_id: String) -> void:
	hud.close_modal()
	if fish_id == "":
		hud.toast("鱼跑了……")
		return
	_feedback(fishing.land(state, fish_id))


# ---------------------------------------------------------------------------- interaction


func _interact() -> void:
	if world.player.action_remaining > 0:
		return
	var station = world.nearby_station()
	if station.is_empty():
		return
	match station.kind:
		"exit":
			_travel(station.destination, Vector2(station.arrival[0], station.arrival[1]))
		"bed":
			hud.dialogs.show_sleep()
		"shop":
			_open_shop(station.shop_id)
		"shipping":
			hud.dialogs.show_shipping(rules.sale_quote(state))
		"npc":
			_talk_npc(station.id)
		"gather":
			_feedback(stories.gather(state, station.id))
		"bridge", "lantern", "story":
			_story_station(station)
		"ferry":
			if stories.ferry_open(state):
				_travel(station.destination, Vector2(station.arrival[0], station.arrival[1]))
			else:
				hud.toast("渡口的老船还搁浅在泥滩上。")
		"letter":
			if state.narrative.intro_seen:
				_start_scene("letter", "letter")
			else:
				_start_scene("prologue", "prologue")
		"storage":
			hud.dialogs.show_bag(true)
		"kitchen":
			hud.dialogs.show_cooking()
		"board":
			hud.dialogs.show_board()
		"animals":
			hud.dialogs.show_animals(station.id)


func _open_shop(shop_id: String) -> void:
	var reason = shops.closed_reason(shop_id, state)
	if reason.is_empty():
		hud.dialogs.show_shop(shop_id)
	else:
		hud.toast(reason, 4)


func _travel(destination: String, at: Vector2) -> void:
	var from_mine = state.current_map.begins_with("mine_")
	var response = stories.enter(state, destination, at)
	if response.ok:
		if destination.begins_with("mine_") and not from_mine:
			player_hp = combat.hero_hp()
		_build_world()
		hud.close_modal()
		_refresh()
		_save(false)
		fade.reveal(0.4)
	hud.toast(response.message)


func _activity_of(id: String) -> String:
	return planner.where(id, float(state.minute))["activity"]


func _talk_npc(id: String) -> void:
	var line = stories.talk(state, id)
	var quest = stories.quest(state)
	var event = quest.event if quest.npc == id else ""
	_save(false)
	if event == "welcome":
		_start_scene(event, "quest")
	else:
		hud.dialogs.show_npc(id, line, event, _activity_of(id))


## Bridge, lantern stand and old shrine: each is where one step of the story happens, and
## otherwise only shows what it is.
func _story_station(station: Dictionary) -> void:
	var quest = stories.quest(state)
	if quest.station == station.id:
		_request_scene(quest.event)
	elif station.kind == "bridge":
		if stories.bridge_open(state):
			var spawn = catalog.region("lake").spawn
			_travel("lake", Vector2(spawn[0], spawn[1]))
		else:
			hud.toast("桥面断了，下面是湍急的水。")
	elif station.kind == "lantern":
		hud.toast("灯台上，%d 盏灯亮着。" % stories.lamps(state), 3)
	else:
		hud.toast(str(station.get("idle", "")))


func _request_scene(event: String) -> void:
	var error = stories.can_complete(state, event)
	if not error.is_empty():
		hud.toast(error, 6)
		return
	_start_scene(event, "quest")


func _start_scene(id: String, kind: String) -> void:
	scene_event = id
	scene_kind = kind
	scene_id = "prologue" if id == "letter" else id
	pages = stories.scene_pages(state, scene_id)
	scene_index = int(state.narrative.page) if state.narrative.active_scene == id else 0
	scene_index = clampi(scene_index, 0, pages.size() - 1)
	if kind != "letter":
		state.narrative.active_scene = id
		state.narrative.page = scene_index
		_save(false)
	hud.dialogs.show_dialogue(pages, scene_index, scene_id, _choices_for(id), id)


## What kind of scene a saved scene id is, so an interrupted scene resumes the right way.
func _kind_of(id: String) -> String:
	if id == "prologue":
		return "prologue"
	if catalog.quest_index(id) >= 0:
		return "quest"
	if stories.is_heart_event(id):
		return "heart"
	if id.begins_with("wedding_"):
		return "wedding"
	if id.begins_with("dating_") or id.begins_with("engage_"):
		return "romance"
	return "follow"


## The closing answers of a scene: the letter's two, or the current step's own choices.
func _choices_for(id: String) -> Array:
	if id == "prologue":
		return catalog.story.prologue_choices
	var quest = stories.quest(state)
	if quest.event == id:
		return quest.choice
	return []


func _finish_scene(choice: String) -> void:
	var response = {"ok": true, "message": ""}
	var before = int(state.narrative.stage)
	var follow: Array = []
	match scene_kind:
		"quest":
			response = stories.complete(state, scene_event, choice)
			follow = response.get("follow", [])
		"prologue":
			response = stories.complete(state, "prologue", choice)
		"heart":
			response = stories.claim_event(state, scene_event)
		"wedding":
			response = stories.wed(state, scene_event.trim_prefix("wedding_"))
	if not response.ok:
		hud.toast(response.message)
		return
	if scene_kind != "letter":
		state.narrative.active_scene = ""
		state.narrative.page = 0
	hud.close_modal()
	if int(state.narrative.stage) != before or scene_kind == "wedding":
		# The bridge, a lamp or a marriage changes where people are and what can be done.
		_plan_day()
		_build_world()
	_refresh()
	_save(false)
	world.queue_redraw()
	if scene_event == "festival":
		pending_ending = true
	scene_queue = follow
	if not response.message.is_empty():
		hud.toast(response.message)
	_next_in_queue()


## Plays the next follow-up scene (a reply, an epilogue), or the closing card of the first story.
func _next_in_queue() -> void:
	if not scene_queue.is_empty():
		_start_scene(scene_queue.pop_front(), "follow")
	elif pending_ending:
		pending_ending = false
		hud.dialogs.show_ending()
		_sound("day")


# ---------------------------------------------------------------------------- menu actions


func _on_action(action: String, payload: Dictionary) -> void:
	match action:
		"select_tool":
			selected_tool = payload.tool
			_refresh()
		"cycle_seed":
			_cycle_seed()
		"ask_sleep":
			hud.dialogs.show_sleep()
		"sleep":
			_next_day()
		"pause":
			hud.dialogs.show_pause()
		"close":
			hud.close_modal()
		"save":
			_save(true)
		"settings":
			hud.dialogs.show_settings(settings)
		"settings_closed":
			_apply_settings()
			hud.dialogs.show_pause()
		"preview_sound":
			_sound("action")
		"ship_all":
			hud.close_modal()
			_feedback(rules.sell_produce(state))
		"journal":
			hud.dialogs.show_journal()
		"map":
			state.player_position = world.player.position
			hud.dialogs.show_map(_villager_cells())
		"bag":
			hud.dialogs.show_bag()
		"collection":
			hud.dialogs.show_collection()
		"story":
			_request_scene(payload.event)
		"confess":
			var response = stories.confess(state, payload.npc)
			hud.close_modal()
			_feedback(response)
			if response.ok:
				_start_scene(response.scene, "romance")
		"propose":
			var response = stories.propose(state, payload.npc)
			hud.close_modal()
			_feedback(response)
			if response.ok:
				_start_scene(response.scene, "romance")
		"gift_menu":
			hud.dialogs.show_gifts(payload.npc, int(payload.get("page", 0)))
		"gift":
			var response = stories.gift(state, payload.npc, payload.item)
			hud.close_modal()
			_feedback(response)
		"heart_event":
			if not stories.available_event(state, payload.npc).is_empty():
				_start_scene(payload.event, "heart")
		"dialogue_next":
			if scene_index < pages.size() - 1:
				scene_index += 1
				if scene_event != "letter":
					state.narrative.page = scene_index
					_save(false)
				hud.dialogs.show_dialogue(
					pages, scene_index, scene_id, _choices_for(scene_event), scene_event
				)
		"dialogue_finish":
			if scene_index == pages.size() - 1:
				_finish_scene(payload.get("choice", ""))
		"title":
			if _save(false, true).is_empty():
				_show_front()
		"quit":
			if _save(false, true).is_empty():
				get_tree().quit()
		_:
			_on_panel_action(action, payload)


## Actions that come from the shop, bag, stove, animal, board panels.
func _on_panel_action(action: String, payload: Dictionary) -> void:
	var response: Dictionary = {}
	match action:
		"buy":
			response = shops.buy(state, payload.shop, payload.item, int(payload.qty))
			_reopen_shop(payload)
		"sell":
			response = shops.sell_item(state, payload.shop, payload.item, int(payload.qty))
			_reopen_shop(payload)
		"sell_all":
			response = shops.sell_all(state, payload.shop)
			_reopen_shop(payload)
		"smelt":
			response = shops.smelt(state, payload.ore)
			_reopen_shop(payload)
		"upgrade_tool":
			response = shops.upgrade_tool(state, payload.tool)
			_reopen_shop(payload)
		"upgrade_rod":
			response = shops.upgrade_rod(state)
			_reopen_shop(payload)
		"heal":
			response = shops.heal(state)
			_reopen_shop(payload)
		"buy_animal":
			var species: String = payload.species
			response = animals.buy(state, species, animals.default_name(state, species))
			_reopen_shop(payload)
		"build":
			response = animals.build(state, payload.id)
			if response.ok:
				_build_world()
			_reopen_shop(payload)
		"eat":
			response = rules.eat(state, payload.item)
			hud.dialogs.show_bag(false, payload.item, payload.category, int(payload.page))
		"transfer":
			response = stories.transfer(state, payload.id, payload.deposit)
			hud.dialogs.show_bag(true, payload.id, payload.category, int(payload.page))
		"cook":
			response = cooking.cook(state, payload.recipe)
			hud.dialogs.show_cooking(int(payload.page))
		"animals_feed":
			response = animals.feed_all(state, payload.building)
			hud.dialogs.show_animals(payload.building, int(payload.page))
		"animals_collect":
			response = animals.collect(state, payload.building)
			hud.dialogs.show_animals(payload.building, int(payload.page))
		"animals_pet":
			response = animals.pet(state, int(payload.index))
			hud.dialogs.show_animals(payload.building, int(payload.page))
		"board_deliver":
			response = board.deliver(state, int(payload.index))
			hud.dialogs.show_board()
	if not response.is_empty():
		_feedback(response)


func _reopen_shop(payload: Dictionary) -> void:
	hud.dialogs.show_shop(payload.shop, payload.tab, int(payload.page))


func _cycle_seed() -> void:
	var season = catalog.calendar.season_of(state.day)
	var ids: Array = []
	for id in catalog.crops:
		if (
			catalog.crops[id].seasons.has(season)
			and state.inventory[catalog.crops[id].seed_item] > 0
		):
			ids.append(id)
	if ids.is_empty():
		hud.toast("没有适合这个季节的种子。")
		return
	selected_crop = ids[(ids.find(selected_crop) + 1) % ids.size()]
	selected_tool = "seed"
	_refresh()


func _villager_cells() -> Array:
	var out: Array = []
	for id in catalog.story.npcs:
		var info = planner.where(id, float(state.minute))
		if info.present and info.map == state.current_map and not info.hidden:
			out.append(info.position)
	return out


# ---------------------------------------------------------------------------- the day


func _next_day() -> void:
	var morning = rules.next_day(state)
	animals.next_day(state, morning.weather)
	var happening = happenings.roll(state)
	if not happening.is_empty():
		happenings.apply(state, happening)
	var chore = stories.spouse_morning(state)
	board.refresh(state)
	hud.close_modal()
	clock_accumulator = 0
	defeated_today.clear()
	player_hp = combat.hero_hp()
	stories.enter(state, "cottage", Vector2(464, 464))
	_plan_day()
	_build_world()
	world.modulate = Color.WHITE
	hud.toast(_morning_message(morning, happening))
	fade.reveal(1.1, _day_card(morning, happening, chore))
	_sound("day")
	_refresh()
	_save(false)
	_check_wedding()


## The wedding scene starts on the morning three days after the ring.
func _check_wedding() -> void:
	var id = stories.wedding_due(state)
	if id != "" and not hud.is_modal():
		_start_scene("wedding_" + id, "wedding")


func _day_card(morning: Dictionary, happening: Dictionary, chore: Dictionary) -> String:
	var date = catalog.calendar.date(state.day)
	var lines = [
		"第 %d 年 · %s季" % [date.year, date.season_name],
		(
			"%s %d 日 · %s · %s"
			% [
				date.season_name,
				date.day,
				date.weekday_name,
				catalog.weather.long_name(morning.weather)
			]
		),
	]
	var festival = catalog.calendar.festival_on(state.day)
	if not festival.is_empty():
		lines.append("今天是" + festival.name)
	var summary: Dictionary = morning.summary
	var recap: Array[String] = []
	if int(summary.earned) > 0:
		recap.append("昨日收入 %d G" % int(summary.earned))
	if int(summary.harvested) > 0:
		recap.append("收获 %d" % int(summary.harvested))
	if int(summary.caught) > 0:
		recap.append("钓到 %d 条鱼" % int(summary.caught))
	if int(summary.cooked) > 0:
		recap.append("做了 %d 道菜" % int(summary.cooked))
	if int(summary.defeated) > 0:
		recap.append("击退 %d 只怪物" % int(summary.defeated))
	if not recap.is_empty():
		lines.append("，".join(recap))
	if not chore.is_empty():
		lines.append(chore.text)
	if not happening.is_empty():
		lines.append(happening.text)
	return "\n".join(lines)


func _morning_message(morning: Dictionary, happening: Dictionary) -> String:
	var parts = [
		"%s · %s" % [catalog.calendar.label(state.day), catalog.weather.long_name(morning.weather)]
	]
	var festival = catalog.calendar.festival_on(state.day)
	if not festival.is_empty():
		parts.append("今天是" + festival.name)
	if morning.season_changed:
		parts.append("换季了" + ("，%d 株作物枯萎" % morning.withered if morning.withered > 0 else ""))
	if not happening.is_empty():
		parts.append(happening.name)
	return "，".join(parts)


func _feedback(response: Dictionary, play_sound: bool = true) -> void:
	hud.toast(response.message)
	if response.ok:
		_refresh()
		_save(false)
		if play_sound:
			_sound("action")


func _apply_settings() -> void:
	world.player.sprint_toggle = settings.get_value("sprint_toggle")
	world.reduce_motion = settings.get_value("reduce_motion")


## Autosaves are skipped when the player turned them off; manual saves, returning to the title
## and quitting always write (`force`).
func _save(show_toast: bool, force: bool = false) -> String:
	if not force and not show_toast and not settings.get_value("autosave"):
		return ""
	state.player_position = world.player.position
	var error = store.save_game(state, active_slot)
	hud.notify_saved(error)
	if show_toast and error.is_empty():
		hud.toast("已保存")
	return error


func _refresh() -> void:
	var fresh = rules.record_collection(state)
	hud.refresh(selected_tool, selected_crop)
	hud.set_hp(player_hp, combat.hero_hp())
	world.queue_redraw()
	if not fresh.is_empty() and hud.toast_remaining <= 0.0:
		hud.toast("图志新增：%s" % catalog.items[fresh[0]].name)


func _sound(kind: String) -> void:
	audio[kind].play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if initialized:
			_on_action("quit", {})
		else:
			get_tree().quit()


# ---------------------------------------------------------------------------- the mine


## Fills a mine floor with today's monsters, skipping the ones already beaten today.
func _spawn_enemies() -> void:
	if not catalog.spawns.has(state.current_map):
		return
	var region = catalog.region(state.current_map)
	var open: Array = []
	for y in range(int(region.height)):
		for x in range(int(region.width)):
			var cell = Vector2i(x, y)
			if (
				not catalog.blocked(cell, state.current_map, state.tree_damage)
				and not catalog.is_water(cell, state.current_map)
			):
				open.append(cell)
	var boss_cell = Vector2i(32, 8)
	for cell in open:
		if absi(cell.x - 32) + absi(cell.y - 8) < absi(boss_cell.x - 32) + absi(boss_cell.y - 8):
			boss_cell = cell
	if not open.has(boss_cell):
		boss_cell = open[0]
	var plan = combat.spawn_plan(state, state.current_map, open, boss_cell)
	var beaten: Array = defeated_today.get(state.current_map, [])
	world.add_enemies(plan.filter(func(e): return not beaten.has(_enemy_key(e.kind, e.cell))))


func _enemy_key(kind: String, cell: Vector2i) -> String:
	return "%s:%d,%d" % [kind, cell.x, cell.y]


func _swing_sword() -> void:
	if world.player.action_remaining > 0:
		return
	var response = combat.swing(state)
	if not response.ok:
		hud.toast(response.message)
		return
	_sound("swing")
	world.player.swing_tool("sword", world.player.cell() + world.player.facing)
	_refresh()


func _sword_hit() -> void:
	var centre = world.player.position + Vector2(world.player.facing) * 26.0 + Vector2(0, -10)
	var hits = world.strike_enemies(centre, 30.0, combat.damage(state), combat.knockback())
	if hits > 0:
		_sound("hit")


func _on_enemy_defeated(kind: String, at: Vector2) -> void:
	var response = combat.defeat(state, kind, drop_rng)
	var cell = Vector2i(floori(at.x / 32.0), floori(at.y / 32.0))
	var beaten: Array = defeated_today.get(state.current_map, [])
	beaten.append(_enemy_key(kind, cell))
	defeated_today[state.current_map] = beaten
	for item in response.drops:
		world.effects.pickup(world.tex(catalog.items[item].icon), at + Vector2(0, -14))
	_sound("defeat")
	_feedback(response, false)
	if catalog.enemies[kind].boss:
		hud.toast("守渠石像倒下了！把核心拿给德克兰。", 5)


func _on_player_hit(damage: int, direction: Vector2) -> void:
	if hit_cooldown > 0.0 or hud.is_modal():
		return
	hit_cooldown = 1.1
	player_hp = maxi(0, player_hp - damage)
	world.player.move_and_collide(direction * combat.knockback())
	_sound("hurt")
	_refresh()
	if player_hp <= 0:
		_faint()


## Knocked out: villagers carry you to the mine gate. Nothing is lost.
func _faint() -> void:
	hud.toast("你被打晕了，路过的矿工把你抬出了洞口。", 5)
	state.stamina = maxi(20, int(state.stamina / 2))
	player_hp = combat.hero_hp()
	var gate = Vector2(38 * 32 + 16, 10 * 32 + 16)
	stories.enter(state, "forest", gate)
	_build_world()
	fade.reveal(0.8)
	_refresh()
	_save(false)

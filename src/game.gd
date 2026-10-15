extends Node

var catalog: ContentCatalog
var state: FarmState
var rules: FarmRules
var stories: StoryRules
var store: SaveStore
const WORLD_RECT = Rect2(16, 96, 960, 608)
var world: FarmWorld
var world_viewport: SubViewport
var world_display: TextureRect
var hud: FarmHUD
var front: FrontMenu
var loaded: Dictionary
var selected_tool: String = "hoe"
var selected_crop: String = "turnip"
var mouse_aim: bool = false
var clock_accumulator: float = 0.0
var autosave_accumulator: float = 0.0
var sound_on: bool = true
var audio: Dictionary = {}
var initialized: bool = false
var pages: Array = []
var scene_event: String = ""
var scene_index: int = 0


func _ready() -> void:
	get_tree().auto_accept_quit = false
	_setup_input()
	catalog = ContentCatalog.new()
	var error = catalog.load_content()
	if not error.is_empty():
		push_error(error)
		get_tree().quit(1)
		return
	rules = FarmRules.new(catalog)
	stories = StoryRules.new(catalog)
	var directory = "user://"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--save-dir="):
			directory = argument.trim_prefix("--save-dir=")
	store = SaveStore.new(catalog, directory)
	loaded = store.load_game()
	for kind in ["action", "harvest", "day"]:
		var player = AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/%s.wav" % kind)
		player.volume_db = -8
		add_child(player)
		audio[kind] = player
	_show_front()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_after_frame.call_deferred(argument.trim_prefix("--capture="))


func _setup_input() -> void:
	var bindings = {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"use_tool": [KEY_SPACE],
		"interact": [KEY_E],
		"cycle_seed": [KEY_Q],
		"menu": [KEY_ESCAPE],
		"tool_1": [KEY_1],
		"tool_2": [KEY_2],
		"tool_3": [KEY_3],
		"tool_4": [KEY_4],
		"tool_5": [KEY_5],
		"tool_6": [KEY_6],
		"tool_7": [KEY_7],
		"sprint": [KEY_SHIFT],
		"journal": [KEY_J],
		"map": [KEY_M],
		"bag": [KEY_B],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if not InputMap.action_get_events(action).is_empty():
			continue
		for code in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)


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
	front.initialize(catalog, loaded.state, loaded.message)
	front.action_requested.connect(_on_front)


func _on_front(action: String, payload: Dictionary) -> void:
	match action:
		"continue":
			if loaded.state != null:
				_start_game(loaded.state)
		"create":
			var candidate = FarmState.new_game(catalog)
			candidate.profile = payload.duplicate(true)
			var invalid = store.validate(candidate.snapshot(catalog))
			if not invalid.is_empty():
				front.error_label.text = invalid
				return
			_start_game(candidate)
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
	_build_world()
	initialized = true
	clock_accumulator = 0
	autosave_accumulator = 0
	selected_tool = "hoe"
	selected_crop = catalog.crops.keys()[0]
	_refresh()
	_save(false)
	if not state.narrative.intro_seen:
		_start_scene("prologue")
	elif not state.narrative.active_scene.is_empty():
		_start_scene(state.narrative.active_scene)
	else:
		hud.toast("欢迎回来，" + state.profile.name + "。" + stories.quest(state).hint, 7)


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
	world.configure(catalog, state)
	world.player.can_move = false
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
	if world.player.velocity.length_squared() > 0.1:
		mouse_aim = false
	world.update_target(mouse_aim, _pointer_in_world())
	var station = world.nearby_station()
	hud.set_target(_target_description(), station.get("name", ""))
	if hud.is_modal():
		return
	clock_accumulator += delta
	if clock_accumulator >= 1.0:
		var ticks = int(clock_accumulator)
		clock_accumulator -= ticks
		state.minute += ticks * 3
		if state.minute >= FarmState.NIGHT:
			_next_day()
		else:
			_refresh()
	autosave_accumulator += delta
	if autosave_accumulator >= 30:
		autosave_accumulator = 0
		_save(false)
	var dusk = clampf(float(state.minute - 17 * 60) / 180.0, 0.0, 1.0)
	world.modulate = Color.WHITE.lerp(Color(0.83, 0.78, 0.69), dusk * 0.45)


func _unhandled_input(event: InputEvent) -> void:
	if not initialized:
		if event.is_action_pressed("menu") and is_instance_valid(front):
			front.show_title()
		return
	if event is InputEventMouseMotion:
		mouse_aim = true
	if hud.modal_kind == "dialogue":
		if event.is_action_pressed("use_tool") or event.is_action_pressed("interact"):
			if scene_index < pages.size() - 1:
				_on_action("dialogue_next", {})
			elif scene_event not in ["festival", "prologue"]:
				_on_action("dialogue_finish", {})
		elif event.is_action_pressed("menu"):
			if scene_event != "prologue":
				hud.close_modal()
		return
	if event.is_action_pressed("menu"):
		if hud.is_modal():
			hud.close_modal()
		else:
			hud.show_pause(sound_on)
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
	var response = rules.apply_tool(
		state, selected_tool, world.target, world.player.cell(), selected_crop
	)
	_feedback(response)
	if response.ok:
		if response.has("cleared_id"):
			world.remove_debris(response.cleared_id)
		world.effect(world.target, selected_tool)
		_sound("harvest" if selected_tool == "harvest" else "action")


func _interact() -> void:
	var station = world.nearby_station()
	if station.is_empty():
		hud.toast("靠近门口、路标、人物或采集物，按 E 互动。")
		return
	match station.kind:
		"exit":
			_travel(station.destination, Vector2(station.arrival[0], station.arrival[1]))
		"bed":
			hud.show_sleep()
		"shop":
			hud.show_shop()
		"shipping":
			hud.show_shipping(rules.sale_quote(state))
		"npc":
			_talk_npc(station.id)
		"gather":
			_feedback(stories.gather(state, station.id))
		"bridge":
			if state.narrative.stage >= 3:
				_travel(
					"lake",
					Vector2(catalog.region("lake").spawn[0], catalog.region("lake").spawn[1])
				)
			elif state.narrative.stage == 2:
				_request_scene("bridge")
			else:
				hud.toast("沈砚说：先去米朵的小馆坐坐吧，大家有话想跟你说。")
		"lantern":
			if state.narrative.stage == 5:
				_request_scene("festival")
			elif state.narrative.stage == 6:
				hud.show_ending()
			else:
				hud.toast("河灯台还在等大家。先完成手记里的准备吧。")
		"letter":
			_start_scene("letter")
		"storage":
			hud.show_bag(true)
		"kitchen":
			hud.show_cooking()
		"upgrade":
			hud.show_upgrade()
		"board":
			_on_action("map", {})


func _travel(destination: String, at: Vector2) -> void:
	var response = stories.enter(state, destination, at)
	if response.ok:
		_build_world()
		hud.close_modal()
		_refresh()
		_save(false)
	hud.toast(response.message)


func _talk_npc(id: String) -> void:
	var line = stories.talk(state, id)
	var event = ""
	match int(state.narrative.stage):
		0:
			if id == "ahe":
				event = "welcome"
		1:
			if id == "mido":
				event = "first_meal"
		3:
			if id == "lin":
				event = "notebook"
		4:
			if id == "mido":
				event = "feast"
	_save(false)
	if event == "welcome":
		_start_scene(event)
	else:
		hud.show_npc(id, line, event)


func _request_scene(event: String) -> void:
	var error = stories.can_complete(state, event)
	if not error.is_empty():
		hud.toast(error, 6)
		return
	_start_scene(event)


func _start_scene(event: String) -> void:
	scene_event = event
	if event == "letter":
		pages = catalog.story.scenes.prologue
	else:
		pages = catalog.story.scenes[event].duplicate(true)
		if event == "welcome":
			pages[0][1] += (
				"\n\n"
				+ (
					"想重新开始的话，就先把今天过好。"
					if state.narrative.intent == "restart"
					else "想照料土地？那我们一定有很多话聊！"
				)
			)
	scene_index = int(state.narrative.page) if state.narrative.active_scene == event else 0
	scene_index = clampi(scene_index, 0, pages.size() - 1)
	if event != "letter":
		state.narrative.active_scene = event
		state.narrative.page = scene_index
		_save(false)
	hud.show_dialogue(pages, scene_index, event)


func _finish_scene(choice: String) -> void:
	var response = {"ok": true, "message": ""}
	if scene_event.begins_with("memory_"):
		response = stories.memory(state, scene_event.trim_prefix("memory_"))
	elif scene_event != "letter":
		response = stories.complete(state, scene_event, choice)
	if not response.ok:
		hud.toast(response.message)
		return
	if scene_event != "letter":
		state.narrative.active_scene = ""
		state.narrative.page = 0
	hud.close_modal()
	_refresh()
	_save(false)
	world.queue_redraw()
	if scene_event == "festival":
		hud.show_ending()
		_sound("day")
	elif not response.message.is_empty():
		hud.toast(response.message)


func _on_action(action: String, payload: Dictionary) -> void:
	match action:
		"select_tool":
			selected_tool = payload.tool
			_refresh()
		"cycle_seed":
			var ids = catalog.crops.keys()
			selected_crop = ids[(ids.find(selected_crop) + 1) % ids.size()]
			selected_tool = "seed"
			_refresh()
		"ask_sleep":
			hud.show_sleep()
		"sleep":
			_next_day()
		"pause":
			hud.show_pause(sound_on)
		"close":
			hud.close_modal()
		"save":
			_save(true)
		"sound":
			sound_on = not sound_on
			hud.show_pause(sound_on)
		"buy":
			var response = rules.buy_seeds(state, payload.crop, int(payload.quantity))
			hud.show_shop()
			_feedback(response)
		"sell":
			hud.close_modal()
			_feedback(rules.sell_produce(state))
		"journal":
			hud.show_journal()
		"map":
			state.player_position = world.player.position
			hud.show_map()
		"bag":
			hud.show_bag()
		"story":
			_request_scene(payload.event)
		"gift_menu":
			hud.show_gifts(payload.npc)
		"gift":
			var response = stories.gift(state, payload.npc, payload.item)
			hud.close_modal()
			_feedback(response)
		"memory":
			if (
				state.relationships[payload.npc] >= 40
				and not state.development.memories.has(payload.npc)
			):
				_start_scene("memory_" + payload.npc)
		"transfer":
			var response = stories.transfer(state, payload.id, payload.deposit)
			hud.show_bag(true)
			_feedback(response)
		"cook":
			var response = stories.cook(state)
			hud.show_cooking()
			_feedback(response)
		"upgrade":
			var response = stories.upgrade(state)
			hud.show_upgrade()
			_feedback(response)
		"dialogue_next":
			if scene_index < pages.size() - 1:
				scene_index += 1
				if scene_event != "letter":
					state.narrative.page = scene_index
					_save(false)
				hud.show_dialogue(pages, scene_index, scene_event)
		"dialogue_finish":
			if scene_index == pages.size() - 1:
				_finish_scene(payload.get("choice", ""))
		"title":
			if _save(false).is_empty():
				loaded = store.load_game()
				_show_front()
		"quit":
			if _save(false).is_empty():
				get_tree().quit()


func _next_day() -> void:
	var response = rules.next_day(state)
	clock_accumulator = 0
	stories.enter(state, "cottage", Vector2(464, 464))
	_build_world()
	world.modulate = Color.WHITE
	hud.show_morning(response.message)
	_sound("day")
	_refresh()
	_save(false)


func _feedback(response: Dictionary) -> void:
	hud.toast(response.message)
	if response.ok:
		_refresh()
		_save(false)
		_sound("action")


func _save(show_toast: bool) -> String:
	state.player_position = world.player.position
	var error = store.save_game(state)
	if error.is_empty():
		hud.save_label.text = (
			"已保存 · 第 %d 天 · %s" % [state.day, catalog.region(state.current_map).name]
		)
		if show_toast:
			hud.toast("这一天的故事，已经保存。")
	else:
		hud.save_label.text = "保存失败，请重试"
		if show_toast or not error.is_empty():
			hud.toast(error, 7)
	return error


func _refresh() -> void:
	hud.refresh(selected_tool, selected_crop)
	world.queue_redraw()


func _sound(kind: String) -> void:
	if sound_on:
		audio[kind].play()


func _target_description() -> String:
	if not world.target_visible:
		return catalog.region(state.current_map).name + " · 靠近人物、路口或门前按 E · M 查看路线"
	var debris = catalog.debris_at(world.target, state)
	if not debris.is_empty():
		return {"weeds": "杂草 · 按 5 选镰刀清理", "branch": "枯枝 · 按 6 选斧头清理", "rock": "碎石 · 按 7 选镐清理"}[
			debris.kind
		]
	var p = state.plots.get(FarmState.cell_key(world.target))
	if p == null:
		return "空地 · 用锄头翻土后播种"
	var water = "已浇水" if p.watered else "今天还没浇水"
	if p.crop == "":
		return "已翻土 · " + water
	var c = catalog.crops[p.crop]
	if int(p.growth) >= int(c.growth_days):
		return "%s成熟了 · 按 4 收获" % c.name
	return "%s · 生长 %d / %d 天 · %s" % [c.name, p.growth, c.growth_days, water]


func capture_after_frame(path: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error = get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ", path, " ", error)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if initialized:
			_on_action("quit", {})
		else:
			get_tree().quit()

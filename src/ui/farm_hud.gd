class_name FarmHUD
extends GameScreen

const TOOLS = ["hoe", "seed", "water", "harvest", "scythe", "axe", "pickaxe", "rod", "sword"]
const TOOL_NAMES = ["锄头", "种子", "水壶", "收获", "镰刀", "斧头", "镐", "钓竿", "长剑"]
const TOOL_ICONS = [
	"hoe",
	"seed_bag",
	"watering_can",
	"turnip_item",
	"scythe",
	"axe",
	"pickaxe",
	"fishing_rod",
	"sword"
]
const BAR_TOP = 571
const BAR_HEIGHT = 148
const POCKET_ITEMS = ["turnip", "carrot", "bait"]
var state: FarmState
var stories: StoryRules
var hp_group: Control
var hp_fill: ColorRect
var hp_label: Label
var hp_shown: float = -1.0
var lamp_pips: Array = []
var dialogs: GameDialogs
var chrome: Control
var day_label: Label
var clock_frame: Panel
var coin_icon: TextureRect
var energy_shown: float = -1.0
var gold_shown: float = -1.0
var toast_tween_age: float = 0.0
var time_label: Label
var gold_label: Label
var stamina_fill: ColorRect
var stamina_label: Label
var location_label: Label
var location_frame: Panel
var quest_frame: Panel
var quest_label: Label
var tool_buttons: Dictionary = {}
var seed_button: Button
var seed_icon: TextureRect
var seed_count: Label
var pocket_counts: Dictionary = {}
var pocket_buttons: Dictionary = {}
var station_label: Label
var station_frame: Panel
var toast_label: Label
var toast_box: Panel
var toast_remaining: float = 0.0
var location_remaining: float = 0.0
var last_region: String = ""
var modal_kind: String:
	get:
		return dialogs.modal_kind if is_instance_valid(dialogs) else ""


func configure(content: ContentCatalog, initial_state: FarmState) -> void:
	catalog = content
	state = initial_state
	stories = StoryRules.new(content)
	setup_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome = Control.new()
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chrome)
	location_frame = _frame(Rect2(22, 22, 220, 48), "wood", chrome)
	location_label = _label("", Rect2(38, 28, 188, 34), 19, LIGHT, false, chrome)
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_frame = _frame(Rect2(22, 78, 330, 42), "paper", chrome)
	quest_label = _label("", Rect2(36, 82, 304, 34), 17, INK, false, chrome)
	clock_frame = _frame(Rect2(1044, 18, 216, 152), "paper", chrome)
	clock_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_icon("sun", Rect2(1063, 38, 44, 44), chrome)
	day_label = _label("", Rect2(1114, 31, 130, 33), 21, INK, false, chrome)
	time_label = _label("", Rect2(1114, 68, 130, 30), 24, INK, false, chrome)
	_panel(Rect2(1060, 108, 184, 2), Color("b99150"), chrome)
	coin_icon = ui_icon("coin", Rect2(1064, 120, 30, 30), chrome)
	gold_label = _label("", Rect2(1098, 117, 142, 36), 23, INK, false, chrome)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for entry in [
		["book", "journal", "J  故事手记"],
		["map", "map", "M  地图册"],
		["bag", "bag", "B  背包"],
		["menu", "pause", "菜单"]
	]:
		var i = ["book", "map", "bag", "menu"].find(entry[0])
		var action: String = entry[1]
		var button = _button(
			"", Rect2(1048 + i * 54, 181, 48, 46), func(): action_requested.emit(action, {}), chrome
		)
		button.tooltip_text = entry[2]
		ui_icon(entry[0], Rect2(11, 10, 26, 26), button)
	# Thirteen physical slots: nine tools, the selected seed, three quick inventory views.
	_frame(Rect2(212, 704, 856, 80), "wood", chrome).mouse_filter = Control.MOUSE_FILTER_STOP
	for i in range(TOOLS.size()):
		var id: String = TOOLS[i]
		var button = _slot(
			Rect2(224 + i * 64, 713, 60, 60),
			func(): action_requested.emit("select_tool", {"tool": id}),
			chrome
		)
		button.tooltip_text = TOOL_NAMES[i]
		icon(TOOL_ICONS[i], Rect2(10, 11, 40, 40), button)
		_label(str(i + 1), Rect2(8, 3, 20, 18), 12, INK, false, button)
		tool_buttons[id] = button
	seed_button = _slot(
		Rect2(800, 713, 60, 60), func(): action_requested.emit("cycle_seed", {}), chrome
	)
	seed_icon = icon("turnip_packet", Rect2(10, 11, 40, 40), seed_button)
	_label("Q", Rect2(8, 3, 20, 18), 12, INK, false, seed_button)
	seed_count = _label("", Rect2(29, 37, 23, 20), 15, INK, false, seed_button)
	seed_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for i in range(POCKET_ITEMS.size()):
		var id: String = POCKET_ITEMS[i]
		var button = _slot(
			Rect2(864 + i * 64, 713, 60, 60),
			func():
				dialogs.selected_item = id
				dialogs.show_bag(),
			chrome
		)
		button.tooltip_text = catalog.items[id].name
		icon(catalog.items[id].icon, Rect2(10, 10, 40, 40), button)
		var count = _label("", Rect2(28, 37, 24, 20), 15, INK, false, button)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pocket_counts[id] = count
		pocket_buttons[id] = button
	_frame(Rect2(1221, 558, 39, 186), "wood", chrome).mouse_filter = Control.MOUSE_FILTER_STOP
	_panel(Rect2(1233, 571, 14, 148), Color("55402a"), chrome)
	stamina_fill = ColorRect.new()
	stamina_fill.mouse_filter = Control.MOUSE_FILTER_STOP
	chrome.add_child(stamina_fill)
	stamina_label = _label("E", Rect2(1227, 718, 26, 21), 14, LIGHT, false, chrome)
	stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_group = Control.new()
	hp_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_group.hide()
	chrome.add_child(hp_group)
	_frame(Rect2(1176, 558, 39, 186), "wood", hp_group).mouse_filter = Control.MOUSE_FILTER_STOP
	_panel(Rect2(1188, BAR_TOP - 13, 14, BAR_HEIGHT), Color("55402a"), hp_group)
	hp_fill = ColorRect.new()
	hp_fill.mouse_filter = Control.MOUSE_FILTER_STOP
	hp_group.add_child(hp_fill)
	hp_label = _label("HP", Rect2(1182, 718, 26, 21), 14, LIGHT, false, hp_group)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(6):
		var pip = ColorRect.new()
		pip.position = Vector2(38 + i * 20, 126)
		pip.size = Vector2(14, 14)
		pip.color = Color("5a4a3a")
		chrome.add_child(pip)
		lamp_pips.append(pip)
	station_frame = _frame(Rect2(0, 0, 224, 40), "paper", chrome)
	station_label = _label("", Rect2(12, 3, 200, 34), 17, INK, false, station_frame)
	station_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	station_frame.hide()
	toast_box = _frame(Rect2(22, 620, 440, 66), "paper")
	toast_box.z_index = 20
	toast_label = _label("", Rect2(40, 631, 404, 44), 16, INK, true)
	toast_label.z_index = 20
	toast_box.hide()
	toast_label.hide()
	dialogs = GameDialogs.new()
	add_child(dialogs)
	dialogs.configure(catalog, state)
	dialogs.action_requested.connect(func(action, payload): action_requested.emit(action, payload))
	dialogs.opened.connect(
		func():
			chrome.hide()
			toast_remaining = 0
			toast_box.hide()
			toast_label.hide()
	)
	dialogs.closed.connect(func(): chrome.show())
	refresh("hoe", "turnip")


func refresh(selected_tool: String, selected_crop: String) -> void:
	var date = catalog.calendar.date(state.day)
	var weather = catalog.weather.weather_on(state.world_seed, state.day)
	day_label.text = (
		"%s %d 日 %s" % [date.season_name, date.day, catalog.weather.short_name(weather)]
	)
	time_label.text = "%s %s" % [date.weekday_name, GameCalendar.clock(state.minute)]
	var current_quest = catalog.story.quests[int(state.narrative.stage)]
	if current_quest.event == "":
		quest_label.text = "› 自由经营"
	elif state.day < int(current_quest.available_day):
		quest_label.text = (
			"› %s（%s起）"
			% [current_quest.title, catalog.calendar.label(int(current_quest.available_day))]
		)
	else:
		quest_label.text = "› " + current_quest.title
	for i in lamp_pips.size():
		lamp_pips[i].color = Color("f6d890") if stories.lamp_lit(state, i + 1) else Color("5a4a3a")
		lamp_pips[i].tooltip_text = "第 %d 盏灯" % (i + 1)
	clock_frame.tooltip_text = _calendar_tooltip(weather)
	if gold_shown < 0.0:
		gold_shown = float(state.gold)
		energy_shown = float(state.stamina)
	elif state.gold > gold_shown + 0.5:
		UIMotion.pulse(coin_icon)
	_update_meters(0.0)
	stamina_fill.tooltip_text = "体力 %d / 100" % state.stamina
	if last_region != state.current_map:
		last_region = state.current_map
		location_label.text = (
			state.profile.farm if last_region == "home_farm" else catalog.region(last_region).name
		)
		location_remaining = 5
		location_frame.show()
		location_label.show()
	for id in tool_buttons:
		tool_buttons[id].add_theme_stylebox_override(
			"normal", _skin("selected" if id == selected_tool else "slot")
		)
	var seed = catalog.crops[selected_crop].seed_item
	seed_icon.texture = load("res://assets/art/%s.png" % catalog.items[seed].icon)
	seed_count.text = str(state.inventory[seed])
	seed_button.tooltip_text = catalog.items[seed].name + " · Q 切换"
	for id in pocket_counts:
		pocket_counts[id].text = str(state.inventory[id]) if state.inventory[id] else ""
		pocket_buttons[id].modulate = Color.WHITE if state.inventory[id] else Color(1, 1, 1, .45)
		pocket_buttons[id].disabled = state.inventory[id] == 0


## The hero's hit points, shown only on a mine floor.
func set_hp(hp: int, hp_max: int) -> void:
	var in_mine = state.current_map.begins_with("mine_")
	hp_group.visible = in_mine
	if not in_mine:
		return
	hp_shown = float(hp) if hp_shown < 0.0 else hp_shown
	var ratio = clampf(float(hp) / float(hp_max), 0.0, 1.0)
	hp_fill.position = Vector2(1188, BAR_TOP - 13 + (1 - ratio) * BAR_HEIGHT)
	hp_fill.size = Vector2(14, ratio * BAR_HEIGHT)
	hp_fill.color = Color("d85a4a") if ratio > 0.3 else Color("f08a3a")
	hp_fill.tooltip_text = "生命 %d / %d" % [hp, hp_max]


func set_target(station: String, player_screen: Vector2) -> void:
	station_frame.visible = not station.is_empty()
	station_label.text = "E  " + station
	station_frame.position = Vector2(
		clampf(player_screen.x - 112, 12, 1040), clampf(player_screen.y + 24, 240, 650)
	)


func toast(message: String, seconds: float = 2.4) -> void:
	if message.is_empty():
		return
	toast_label.text = message
	toast_remaining = seconds
	toast_box.position = Vector2(420, 24) if is_modal() else Vector2(22, 620)
	toast_label.position = toast_box.position + Vector2(18, 11)
	toast_box.show()
	toast_label.show()
	UIMotion.appear(toast_box, 0.18, 10.0)
	UIMotion.appear(toast_label, 0.18, 10.0)


func notify_saved(error: String) -> void:
	if not error.is_empty():
		toast(error, 5)


## Eases the stamina bar and the gold counter towards their real values.
func _update_meters(delta: float) -> void:
	gold_shown = UIMotion.ease_toward(gold_shown, float(state.gold), delta, 7.0)
	energy_shown = UIMotion.ease_toward(energy_shown, float(state.stamina), delta, 9.0, 0.3)
	gold_label.text = "%d" % roundi(gold_shown)
	var energy = clampf(energy_shown / FarmState.MAX_STAMINA, 0.0, 1.0)
	stamina_fill.position = Vector2(1233, 571 + (1 - energy) * 148)
	stamina_fill.size = Vector2(14, energy * 148)
	stamina_fill.color = Color("86b34b") if energy > .3 else Color("d28e3f")


func _process(delta: float) -> void:
	_update_meters(delta)
	toast_remaining = maxf(0, toast_remaining - delta)
	if toast_remaining < 0.3 and toast_remaining > 0.0 and not UIMotion.reduced:
		toast_box.modulate.a = toast_remaining / 0.3
		toast_label.modulate.a = toast_remaining / 0.3
	if toast_remaining == 0:
		toast_box.hide()
		toast_label.hide()
	location_remaining = maxf(0, location_remaining - delta)
	location_frame.visible = location_remaining > 0
	location_label.visible = location_remaining > 0


func is_modal() -> bool:
	return is_instance_valid(dialogs) and dialogs.visible


func close_modal() -> void:
	dialogs.close_modal()


func _calendar_tooltip(weather: String) -> String:
	var lines = [
		catalog.calendar.long_label(state.day) + " · " + catalog.weather.long_name(weather),
		(
			"明天："
			+ catalog.weather.long_name(catalog.weather.weather_on(state.world_seed, state.day + 1))
		),
	]
	var festival = catalog.calendar.festival_on(state.day)
	if not festival.is_empty():
		lines.append("今天：" + festival.name)
	for id in catalog.calendar.birthdays_on(state.day, catalog.story.npcs):
		lines.append("%s 生日" % catalog.story.npcs[id].name)
	var upcoming = catalog.calendar.next_festival(state.day)
	if not upcoming.is_empty():
		lines.append("下个节日：%s（%d 天后）" % [upcoming.festival.name, upcoming.day - state.day])
	return "\n".join(lines)

class_name GameDialogs
extends GameScreen

signal opened
signal closed

const WIDE = Rect2(130, 50, 1020, 700)

var state: FarmState
var stories: StoryRules
var shop_rules: ShopRules
var cooking_rules: CookingRules
var animal_rules: AnimalRules
var board_rules: BoardRules
var fishing_rules: FishingRules
var modal_panel: Panel
var modal_extra: Control
var modal_kind: String = ""
var shade: ColorRect


func configure(content: ContentCatalog, initial_state: FarmState) -> void:
	catalog = content
	state = initial_state
	stories = StoryRules.new(catalog)
	shop_rules = ShopRules.new(catalog)
	cooking_rules = CookingRules.new(catalog)
	animal_rules = AnimalRules.new(catalog)
	board_rules = BoardRules.new(catalog)
	fishing_rules = FishingRules.new(catalog)
	setup_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	hide()


func close_modal() -> void:
	hide()
	modal_kind = ""
	closed.emit()


func open_modal(
	kind: String, title: String, description: String, bounds: Rect2 = Rect2(310, 105, 660, 590)
) -> void:
	if is_instance_valid(modal_panel):
		remove_child(modal_panel)
		modal_panel.queue_free()
	if is_instance_valid(modal_extra):
		remove_child(modal_extra)
		modal_extra.queue_free()
	var fresh = not visible or modal_kind != kind
	modal_kind = kind
	shade.color = Color("172a2480") if kind not in ["dialogue", "npc"] else Color("172a241a")
	modal_panel = _frame(bounds)
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_extra = Control.new()
	modal_extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_extra)
	if not title.is_empty():
		_label(title, Rect2(30, 20, bounds.size.x - 60, 46), 28, INK, false, modal_panel)
	if not description.is_empty():
		_label(description, Rect2(30, 75, bounds.size.x - 60, 100), 18, MUTED, true, modal_panel)
	show()
	if fresh:
		UIMotion.appear(modal_panel, 0.15, 14.0)
		UIMotion.appear(shade, 0.15, 0.0)
	opened.emit()


func modal_button(
	text: String, y: float, action: String, payload: Dictionary = {}, disabled: bool = false
) -> Button:
	var button = _button(
		text, Rect2(30, y, 600, 43), func(): action_requested.emit(action, payload), modal_panel
	)
	button.disabled = disabled
	return button


func _forward(panel: GameScreen) -> void:
	panel.action_requested.connect(func(action, payload): action_requested.emit(action, payload))


# ---------------------------------------------------------------------------- panels


func show_shop(shop_id: String, tab: String = "", page: int = 0) -> void:
	open_modal("shop", "", "", WIDE)
	var panel = ShopPanel.new()
	modal_panel.add_child(panel)
	panel.open(catalog, state, shop_rules, animal_rules, shop_id, tab, page, WIDE.size)
	_forward(panel)


func show_bag(
	storage_mode: bool = false, selected: String = "", category: String = "all", page: int = 0
) -> void:
	open_modal("storage" if storage_mode else "bag", "", "", WIDE)
	var panel = BagPanel.new()
	modal_panel.add_child(panel)
	panel.open(catalog, state, storage_mode, selected, category, page, WIDE.size)
	_forward(panel)


func show_cooking(page: int = 0) -> void:
	open_modal("kitchen", "", "", WIDE)
	var panel = CookingPanel.new()
	modal_panel.add_child(panel)
	panel.open(catalog, state, cooking_rules, page, WIDE.size)
	_forward(panel)


func show_animals(building: String, page: int = 0) -> void:
	open_modal("animals", "", "", WIDE)
	var panel = AnimalPanel.new()
	modal_panel.add_child(panel)
	panel.open(catalog, state, animal_rules, building, page, WIDE.size)
	_forward(panel)


func show_board() -> void:
	open_modal("board", "", "", WIDE)
	var panel = BoardPanel.new()
	modal_panel.add_child(panel)
	panel.open(catalog, state, board_rules, WIDE.size)
	_forward(panel)


func show_collection() -> void:
	open_modal("collection", "", "", WIDE)
	var panel = CollectionPanel.new()
	modal_panel.add_child(panel)
	panel.open(catalog, state, WIDE.size)
	_forward(panel)


## Opens the fishing minigame and returns it so the caller can wait for `finished`.
func show_fishing(bait: bool) -> FishingPanel:
	open_modal("fishing", "", "", Rect2(190, 150, 900, 460))
	var panel = FishingPanel.new()
	modal_panel.add_child(panel)
	panel.open(catalog, state, fishing_rules, bait, Vector2(900, 460))
	return panel


# ---------------------------------------------------------------------------- small dialogs


func show_sleep() -> void:
	open_modal("sleep", "休息", "要睡到明天早上吗？")
	modal_button("结束今天，回家睡觉", 260, "sleep")
	modal_button("再逛一会儿", 320, "close")


func show_shipping(quote: Dictionary) -> void:
	open_modal("shipping", "收货箱", "%d 件物品 · 合计 %d G" % [quote.count, quote.gold])
	var y = 180
	var shown = 0
	for id in catalog.items:
		if catalog.items[id].kind in ContentCatalog.SELLABLE and state.inventory[id] > 0:
			if shown == 4:
				_label("……还有更多", Rect2(104, y, 460, 42), 18, MUTED, false, modal_panel)
				break
			icon(catalog.items[id].icon, Rect2(40, y, 42, 42), modal_panel)
			_label(
				"%s ×%d" % [catalog.items[id].name, state.inventory[id]],
				Rect2(104, y, 460, 42),
				20,
				INK,
				false,
				modal_panel
			)
			y += 52
			shown += 1
	modal_button("出售全部 / +%d G" % quote.gold, 386, "ship_all", {}, quote.count == 0)
	modal_button("返回", 510, "close")


func show_pause() -> void:
	open_modal("pause", "菜单", "")
	modal_button("继续生活", 134, "close")
	modal_button("手动保存", 190, "save")
	modal_button("设置", 246, "settings")
	modal_button("回家休息", 302, "ask_sleep")
	modal_button("保存并返回标题", 414, "title")
	modal_button("保存并退出", 470, "quit")


func show_settings(current: GameSettings) -> void:
	open_modal("settings", "", "", Rect2(190, 50, 900, 700))
	var panel = SettingsPanel.new()
	modal_panel.add_child(panel)
	panel.open(current, Vector2(900, 700))
	panel.finished.connect(func(): action_requested.emit("settings_closed", {}))
	panel.preview_sound.connect(func(): action_requested.emit("preview_sound", {}))


func show_journal() -> void:
	open_modal("journal", "故事手记", "", Rect2(180, 90, 920, 620))
	_panel(Rect2(370, 80, 2, 440), Color("cba365"), modal_panel)
	for i in range(catalog.story.quests.size()):
		var q = catalog.story.quests[i]
		var mark = (
			"✓" if i < state.narrative.stage else ("›" if i == state.narrative.stage else "·")
		)
		_label(
			"%s  %s" % [mark, q.title],
			Rect2(36, 98 + i * 48, 320, 35),
			18,
			INK if i <= state.narrative.stage else MUTED,
			false,
			modal_panel
		)
	var current = stories.quest(state)
	_label(current.title, Rect2(410, 98, 465, 44), 28, INK, false, modal_panel)
	_label(current.where, Rect2(410, 150, 460, 36), 17, GOLD, false, modal_panel)
	_label(current.hint, Rect2(410, 203, 460, 124), 21, INK, true, modal_panel)
	var row = 0
	for id in current.needs:
		icon(catalog.items[id].icon, Rect2(410, 350 + row * 57, 42, 42), modal_panel)
		_label(
			"%s   %d / %d" % [catalog.items[id].name, state.inventory[id], current.needs[id]],
			Rect2(470, 350 + row * 57, 380, 42),
			21,
			INK,
			false,
			modal_panel
		)
		row += 1
	_button(
		"合上手记", Rect2(590, 540, 280, 48), func(): action_requested.emit("close", {}), modal_panel
	)


func show_map(places: Array) -> void:
	var region_name = (
		state.profile.farm
		if state.current_map == "home_farm"
		else catalog.region(state.current_map).name
	)
	open_modal("map", region_name, "", Rect2(210, 80, 860, 640))
	var overview = MapOverview.new()
	overview.position = Vector2(35, 88)
	overview.size = Vector2(790, 416)
	modal_panel.add_child(overview)
	overview.configure(catalog, state, places)
	for i in range(3):
		var color = [Color("ffe18d"), Color("e19e9f"), Color("f1e7c3")][i]
		_frame(Rect2(38 + i * 115, 529, 25, 28), "wood", modal_panel)
		_label("●", Rect2(42 + i * 115, 531, 18, 22), 16, color, false, modal_panel)
		_label(["你", "村民", "入口"][i], Rect2(72 + i * 115, 524, 74, 40), 18, INK, false, modal_panel)
	_button(
		"收起地图", Rect2(540, 558, 280, 48), func(): action_requested.emit("close", {}), modal_panel
	)


func show_npc(id: String, line: String, event: String, activity: String) -> void:
	var npc = catalog.story.npcs[id]
	open_modal("npc", "", "", Rect2(110, 420, 1060, 350))
	_frame(Rect2(24, 30, 142, 172), "inset", modal_panel)
	icon(npc.portrait, Rect2(35, 40, 120, 146), modal_panel)
	_label(npc.name, Rect2(192, 20, 300, 42), 27, INK, false, modal_panel)
	_label(
		"%s · %d 岁 · %s" % [npc.role, npc.age, activity],
		Rect2(192, 58, 640, 26),
		15,
		MUTED,
		false,
		modal_panel
	)
	for i in range(5):
		ui_icon(
			"heart" if state.relationships[id] >= (i + 1) * 20 else "heart_empty",
			Rect2(852 + i * 32, 29, 24, 24),
			modal_panel
		)
	_label(line, Rect2(192, 90, 824, 100), 22, INK, true, modal_panel)
	var choices = []
	if not event.is_empty():
		choices.append(["聊聊「%s」" % stories.quest(state).title, "story", {"event": event}])
	if not state.daily.gifted.has(id):
		choices.append(["送一份礼物", "gift_menu", {"npc": id}])
	var pending = stories.available_event(state, id)
	if not pending.is_empty():
		choices.append(["听听%s的故事" % npc.name, "heart_event", {"npc": id, "event": pending.id}])
	choices.append(["下次见", "close", {}])
	for i in range(choices.size()):
		var choice = choices[i]
		_button(
			choice[0],
			Rect2(192 + i % 2 * 420, 214 + int(i / 2) * 55, 404, 45),
			func(): action_requested.emit(choice[1], choice[2]),
			modal_panel
		)


func show_gifts(id: String, page: int = 0) -> void:
	open_modal("gifts", "送给" + catalog.story.npcs[id].name, "", Rect2(310, 60, 660, 680))
	var owned: Array = []
	for item in catalog.items:
		if catalog.items[item].kind != "seed" and state.inventory[item] > 0:
			owned.append(item)
	if owned.is_empty():
		_label("口袋里没有能送的东西。", Rect2(30, 100, 600, 40), 20, MUTED, false, modal_panel)
	var per_page = 8
	var pages = page_count(owned.size(), per_page)
	page = clampi(page, 0, pages - 1)
	var from = page * per_page
	for i in range(from, mini(owned.size(), from + per_page)):
		var item: String = owned[i]
		var y = 90 + (i - from) * 56
		icon(catalog.items[item].icon, Rect2(30, y, 44, 44), modal_panel)
		_button(
			"%s ×%d" % [catalog.items[item].name, state.inventory[item]],
			Rect2(86, y, 544, 43),
			func(): action_requested.emit("gift", {"npc": id, "item": item}),
			modal_panel
		)
	add_pager(
		modal_panel,
		Vector2(30, 546),
		600,
		page,
		pages,
		func(p): action_requested.emit("gift_menu", {"npc": id, "page": p})
	)
	modal_button("暂时不送", 610, "close")


func show_dialogue(pages: Array, index: int, event: String) -> void:
	var page = pages[index]
	var who: String = page[0]
	var text: String = page[1].replace("{name}", state.profile.name).replace(
		"{farm}", state.profile.farm
	)
	open_modal("dialogue", "", "", Rect2(110, 552, 1060, 224))
	_frame(Rect2(24, 27, 128, 168), "inset", modal_panel)
	var speaker = "祖母的信" if who == "letter" else "灯夜"
	if catalog.story.npcs.has(who):
		var npc = catalog.story.npcs[who]
		speaker = npc.name
		icon(npc.portrait, Rect2(32, 37, 112, 145), modal_panel)
	else:
		ui_icon("letter" if who == "letter" else "book", Rect2(49, 70, 78, 78), modal_panel)
	_frame(Rect2(16, -28, 172, 46), "wood", modal_panel)
	var nameplate = _label(speaker, Rect2(28, -23, 148, 36), 21, LIGHT, false, modal_panel)
	nameplate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(text, Rect2(180, 25, 840, 133), 22, INK, true, modal_panel)
	_label(
		"%d / %d" % [index + 1, pages.size()],
		Rect2(180, 174, 200, 26),
		15,
		MUTED,
		false,
		modal_panel
	)
	if index < pages.size() - 1:
		_button(
			"继续",
			Rect2(840, 166, 180, 40),
			func(): action_requested.emit("dialogue_next", {}),
			modal_panel
		)
	elif event in ["prologue", "festival"]:
		var choices = (
			[["我想好好照料这片土地", "grow"], ["我想在这里重新开始", "restart"]]
			if event == "prologue"
			else [["愿我找到想留下的地方", "stay"], ["愿我有勇气出发，也有路回来", "explore"], ["愿我们以后常常见面", "together"]]
		)
		for i in range(choices.size()):
			var choice = choices[i]
			_button(
				choice[0],
				Rect2(630, 514 - (choices.size() - i) * 57, 530, 48),
				func(): action_requested.emit("dialogue_finish", {"choice": choice[1]}),
				modal_extra
			)
	else:
		_button(
			"记住这一刻",
			Rect2(810, 166, 210, 40),
			func(): action_requested.emit("dialogue_finish", {}),
			modal_panel
		)


func show_ending() -> void:
	var wishes = {
		"stay": "你决定留下来，让农场成为一个真正的家。",
		"explore": "你愿意出发，也相信这里永远有一条回家的路。",
		"together": "你希望下一次相聚，不必等到一年后的灯夜。"
	}
	open_modal("ending", "灯亮之后", wishes[state.narrative.wish])
	ui_icon("letter", Rect2(278, 190, 104, 104), modal_panel)
	_label("湖面重新亮起纸灯。\n桥、朋友和一顿热饭，\n都成了你生活的一部分。", Rect2(90, 318, 480, 118), 23, INK, true, modal_panel).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_button("继续我的农场生活", 510, "close")

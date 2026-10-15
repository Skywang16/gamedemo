class_name GameDialogs
extends GameScreen

signal opened
signal closed

var state: FarmState
var stories: StoryRules
var modal_panel: Panel
var modal_extra: Control
var modal_kind: String = ""
var shade: ColorRect
var selected_item: String = "turnip_seed"


func configure(content: ContentCatalog, initial_state: FarmState) -> void:
	catalog = content
	state = initial_state
	stories = StoryRules.new(catalog)
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
	opened.emit()


func modal_button(
	text: String, y: float, action: String, payload: Dictionary = {}, disabled: bool = false
) -> Button:
	var button = _button(
		text, Rect2(30, y, 600, 43), func(): action_requested.emit(action, payload), modal_panel
	)
	button.disabled = disabled
	return button


func show_shop() -> void:
	open_modal("shop", "阿禾的种子摊", "")
	ui_icon("coin", Rect2(440, 27, 26, 26), modal_panel)
	_label(str(state.gold), Rect2(476, 20, 140, 40), 22, INK, false, modal_panel)
	var i = 0
	for id in catalog.crops:
		var crop = catalog.crops[id]
		var price = int(catalog.items[crop.seed_item].buy_price)
		_frame(Rect2(30, 96 + i * 130, 600, 112), "inset", modal_panel)
		icon(catalog.items[crop.seed_item].icon, Rect2(50, 114 + i * 130, 64, 64), modal_panel)
		_label(crop.name + "种子", Rect2(137, 108 + i * 130, 350, 32), 21, INK, false, modal_panel)
		_label(
			"%d 天成熟 · 售价 %d G" % [crop.growth_days, catalog.items[crop.harvest_item].sell_price],
			Rect2(137, 146 + i * 130, 310, 36),
			16,
			MUTED,
			false,
			modal_panel
		)
		_button("%s种子 ×1 / %d G" % [crop.name, price], Rect2(340, 154 + i * 130, 266, 43), func(): action_requested.emit("buy", {"crop": id, "quantity": 1}), modal_panel).disabled = (
			state.gold < price
		)
		i += 1
	modal_button("萝卜种子 ×5 / 20 G", 386, "buy", {"crop": "turnip", "quantity": 5}, state.gold < 20)
	modal_button("离开摊位", 510, "close")


func show_sleep() -> void:
	open_modal("sleep", "休息", "要睡到明天早上吗？")
	modal_button("结束今天，回家睡觉", 260, "sleep")
	modal_button("再逛一会儿", 320, "close")


func show_shipping(quote: Dictionary) -> void:
	open_modal("shipping", "收货箱", "%d 份农产品 · 合计 %d G" % [quote.count, quote.gold])
	var y = 180
	for id in catalog.items:
		if catalog.items[id].kind == "produce" and state.inventory[id] > 0:
			icon(catalog.items[id].icon, Rect2(40, y, 42, 42), modal_panel)
			_label(
				"%s ×%d" % [catalog.items[id].name, state.inventory[id]],
				Rect2(104, y, 460, 42),
				20,
				INK,
				false,
				modal_panel
			)
			y += 60
	modal_button("出售全部农产品 / +%d G" % quote.gold, 386, "sell", {}, quote.count == 0)
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
	_label("河灯归来", Rect2(36, 88, 300, 42), 22, GOLD, false, modal_panel)
	for i in range(catalog.story.quests.size()):
		var q = catalog.story.quests[i]
		var mark = (
			"✓" if i < state.narrative.stage else ("›" if i == state.narrative.stage else "·")
		)
		_label(
			"%s  %s" % [mark, q.title],
			Rect2(36, 151 + i * 48, 320, 35),
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


func show_map() -> void:
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
	overview.configure(catalog, state)
	for i in range(3):
		var color = [Color("ffe18d"), Color("e19e9f"), Color("f1e7c3")][i]
		_frame(Rect2(38 + i * 115, 529, 25, 28), "wood", modal_panel)
		_label("●", Rect2(42 + i * 115, 531, 18, 22), 16, color, false, modal_panel)
		_label(["你", "村民", "入口"][i], Rect2(72 + i * 115, 524, 74, 40), 18, INK, false, modal_panel)
	_button(
		"收起地图", Rect2(540, 558, 280, 48), func(): action_requested.emit("close", {}), modal_panel
	)


func show_bag(storage_mode: bool = false) -> void:
	open_modal(
		"storage" if storage_mode else "bag",
		"储物箱" if storage_mode else "背包",
		"",
		Rect2(200, 110, 880, 580)
	)
	var i = 0
	for id in catalog.items:
		var at = Vector2(36 + i % 4 * 92, 98 + int(i / 4) * 96)
		var button = _slot(
			Rect2(at, Vector2(80, 82)),
			func():
				selected_item = id
				show_bag(storage_mode),
			modal_panel
		)
		button.tooltip_text = catalog.items[id].name
		if selected_item == id:
			button.add_theme_stylebox_override("normal", _skin("selected"))
		icon(catalog.items[id].icon, Rect2(16, 12, 48, 48), button)
		var count = _label(str(state.inventory[id]), Rect2(30, 53, 38, 23), 17, INK, false, button)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		i += 1
	var item = catalog.items[selected_item]
	_frame(Rect2(432, 94, 410, 360), "inset", modal_panel)
	icon(item.icon, Rect2(459, 117, 64, 64), modal_panel)
	_label(item.name, Rect2(540, 123, 270, 44), 25, INK, false, modal_panel)
	_label(item.description, Rect2(459, 198, 350, 96), 20, INK, true, modal_panel)
	_label(
		"持有 %d" % state.inventory[selected_item],
		Rect2(459, 309, 170, 34),
		19,
		MUTED,
		false,
		modal_panel
	)
	if storage_mode:
		_label(
			"箱内 %d" % state.storage[selected_item],
			Rect2(642, 309, 170, 34),
			19,
			MUTED,
			false,
			modal_panel
		)
		_button("存入", Rect2(459, 370, 164, 48), func(): action_requested.emit("transfer", {"id": selected_item, "deposit": true}), modal_panel).disabled = (
			state.inventory[selected_item] == 0
		)
		_button("取出", Rect2(646, 370, 164, 48), func(): action_requested.emit("transfer", {"id": selected_item, "deposit": false}), modal_panel).disabled = (
			state.storage[selected_item] == 0
		)
	else:
		_label(
			"售价 %d G" % item.sell_price if item.sell_price else "",
			Rect2(642, 309, 170, 34),
			19,
			GOLD,
			false,
			modal_panel
		)
		ui_icon("leaf", Rect2(43, 341, 32, 32), modal_panel)
		_label(
			"种植  Lv.%d" % stories.level(int(state.development.farming_xp)),
			Rect2(90, 338, 290, 37),
			21,
			INK,
			false,
			modal_panel
		)
		ui_icon("leaf", Rect2(43, 397, 32, 32), modal_panel)
		_label(
			"采集  Lv.%d" % stories.level(int(state.development.foraging_xp)),
			Rect2(90, 394, 290, 37),
			21,
			INK,
			false,
			modal_panel
		)
	_button("关闭", Rect2(572, 492, 270, 48), func(): action_requested.emit("close", {}), modal_panel)


func show_cooking() -> void:
	open_modal("kitchen", "厨房", "野莓粥\n野莓 ×2    ·    体力 +30")
	icon("berry", Rect2(48, 187, 84, 84), modal_panel)
	_label(
		"野莓 %d / 2       体力 %d / 100" % [state.inventory.berry, state.stamina],
		Rect2(165, 195, 430, 60),
		21,
		INK,
		false,
		modal_panel
	)
	modal_button("煮一碗野莓粥并吃下", 340, "cook", {}, state.inventory.berry < 2 or state.stamina >= 100)
	modal_button("离开灶台", 510, "close")


func show_upgrade() -> void:
	open_modal("upgrade", "沈砚的工作台", "铜水壶\n一次浇灌三格 · 体力消耗 1")
	icon("watering_can", Rect2(48, 187, 84, 84), modal_panel)
	_label(
		"种植 Lv.2 · 40 G\n木材 %d / 3 · 石料 %d / 2" % [state.inventory.wood, state.inventory.stone],
		Rect2(165, 185, 440, 100),
		21,
		INK,
		true,
		modal_panel
	)
	modal_button(
		"制作铜水壶" if not state.development.watering_level else "铜水壶已完成",
		340,
		"upgrade",
		{},
		state.development.watering_level > 0
	)
	modal_button("离开工作台", 510, "close")


func show_npc(id: String, line: String, event: String) -> void:
	var npc = catalog.story.npcs[id]
	open_modal("npc", "", "", Rect2(110, 430, 1060, 338))
	_frame(Rect2(24, 30, 142, 172), "inset", modal_panel)
	icon(npc.portrait, Rect2(35, 40, 120, 146), modal_panel)
	_label(npc.name, Rect2(192, 22, 300, 42), 27, INK, false, modal_panel)
	for i in range(5):
		ui_icon(
			"heart" if state.relationships[id] >= (i + 1) * 20 else "heart_empty",
			Rect2(852 + i * 32, 29, 24, 24),
			modal_panel
		)
	_label(line, Rect2(192, 81, 824, 103), 23, INK, true, modal_panel)
	var choices = []
	if not event.is_empty():
		choices.append(["聊聊「%s」" % stories.quest(state).title, "story", {"event": event}])
	if not state.daily.gifted.has(id):
		choices.append(["送一份礼物", "gift_menu", {"npc": id}])
	if state.relationships[id] >= 40 and not state.development.memories.has(id):
		choices.append(["听听你的故事", "memory", {"npc": id}])
	choices.append(["下次见", "close", {}])
	for i in range(choices.size()):
		var choice = choices[i]
		_button(
			choice[0],
			Rect2(192 + i % 2 * 420, 205 + int(i / 2) * 55, 404, 45),
			func(): action_requested.emit(choice[1], choice[2]),
			modal_panel
		)


func show_gifts(id: String) -> void:
	open_modal("gifts", "送给" + catalog.story.npcs[id].name, "")
	var i = 0
	for item in catalog.items:
		if catalog.items[item].kind == "seed":
			continue
		modal_button(
			"%s ×1（持有 %d）" % [catalog.items[item].name, state.inventory[item]],
			118 + i * 56,
			"gift",
			{"npc": id, "item": item},
			state.inventory[item] < 1
		)
		i += 1
	modal_button("暂时不送", 510, "close")


func show_dialogue(pages: Array, index: int, event: String) -> void:
	var page = pages[index]
	var who: String = page[0]
	var text: String = page[1].replace("{name}", state.profile.name).replace(
		"{farm}", state.profile.farm
	)
	open_modal("dialogue", "", "", Rect2(110, 552, 1060, 224))
	_frame(Rect2(24, 27, 128, 168), "inset", modal_panel)
	var speaker = "祖母的信" if who == "letter" else "河灯归来"
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
		"together": "你希望下一次相聚，不必等到一年后的河灯夜。"
	}
	open_modal("ending", "灯亮之后", wishes[state.narrative.wish])
	ui_icon("letter", Rect2(278, 190, 104, 104), modal_panel)
	_label("湖面重新亮起河灯。\n桥、朋友和一顿热饭，\n都成了你生活的一部分。", Rect2(90, 318, 480, 118), 23, INK, true, modal_panel).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_button("继续我的农场生活", 510, "close")

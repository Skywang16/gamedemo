class_name FarmHUD
extends GameScreen

const TOOLS = ["hoe", "seed", "water", "harvest", "scythe", "axe", "pickaxe"]
const TOOL_NAMES = ["锄头", "种子", "水壶", "收获", "镰刀", "斧头", "镐"]
var state: FarmState
var stories: StoryRules
var day_label: Label
var time_label: Label
var gold_label: Label
var stamina_label: Label
var title_label: Label
var area_label: Label
var quest_title: Label
var quest_where: Label
var next_hint: Label
var needs_label: Label
var growth_label: Label
var tool_buttons: Dictionary = {}
var seed_button: Button
var target_label: Label
var station_label: Label
var toast_label: Label
var toast_box: Panel
var toast_remaining: float = 0.0
var save_label: Label
var modal_root: Control
var modal_panel: Panel
var modal_kind: String = ""
var speaker_label: Label


func configure(content: ContentCatalog, initial_state: FarmState) -> void:
	catalog = content
	state = initial_state
	stories = StoryRules.new(catalog)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_theme()
	_panel(Rect2(0, 0, 1280, 800), Color("14291f")).z_index = -2
	_panel(Rect2(12, 88, 968, 624), Color("9a8555")).z_index = -2
	title_label = _label("", Rect2(28, 12, 430, 42), 29, CREAM)
	area_label = _label("", Rect2(30, 55, 430, 24), 15, GOLD)
	day_label = _label("", Rect2(500, 20, 175, 32), 23, CREAM)
	time_label = _label("", Rect2(500, 54, 175, 24), 15, MUTED)
	stamina_label = _label("", Rect2(700, 22, 260, 36), 22, CREAM)
	_label("慢慢生活，也会有所成长", Rect2(702, 58, 260, 22), 14, MUTED)
	gold_label = _label("", Rect2(1000, 24, 250, 36), 25, GOLD)
	_label("青苇镇 · 春日篇", Rect2(1002, 60, 225, 20), 14, MUTED)
	_panel(Rect2(992, 96, 272, 608), Color("203a2d"))
	_label("河灯归来", Rect2(1010, 112, 235, 36), 25, CREAM)
	_label("第一章 / 正在发生的故事", Rect2(1010, 153, 235, 24), 14, GOLD)
	quest_title = _label("", Rect2(1010, 195, 235, 34), 23, CREAM)
	quest_where = _label("", Rect2(1010, 235, 235, 45), 15, GOLD, true)
	next_hint = _label("", Rect2(1010, 285, 232, 102), 17, CREAM, true)
	needs_label = _label("", Rect2(1010, 391, 232, 63), 16, MUTED, true)
	growth_label = _label("", Rect2(1010, 462, 232, 70), 16, GOLD, true)
	_button("J  故事手记", Rect2(1008, 546, 238, 39), func(): action_requested.emit("journal", {}))
	_button("M  地图册", Rect2(1008, 593, 113, 39), func(): action_requested.emit("map", {}))
	_button("B  背包", Rect2(1131, 593, 115, 39), func(): action_requested.emit("bag", {}))
	_button("回家休息", Rect2(1008, 650, 140, 39), func(): action_requested.emit("ask_sleep", {}))
	_button("菜单", Rect2(1157, 650, 90, 39), func(): action_requested.emit("pause", {}))
	for i in range(TOOLS.size()):
		var id = TOOLS[i]
		var button = _button(
			"%d  %s" % [i + 1, TOOL_NAMES[i]],
			Rect2(24 + i * 135, 724, 127, 48),
			func(): action_requested.emit("select_tool", {"tool": id})
		)
		button.icon = load(
			(
				"res://assets/art/%s.png"
				% ["hoe", "seed_bag", "watering_can", "turnip_item", "scythe", "axe", "pickaxe"][i]
			)
		)
		button.add_theme_constant_override("icon_max_width", 30)
		button.expand_icon = true
		tool_buttons[id] = button
	seed_button = _button(
		"", Rect2(995, 724, 265, 48), func(): action_requested.emit("cycle_seed", {})
	)
	save_label = _label("", Rect2(1010, 686, 240, 20), 13, MUTED, true)
	_label(
		"WASD 移动 · Shift 跑步   1–7 工具   点击 / 空格 使用   Q 换种子   E 交互 / 进入房屋   J 手记   M 地图   B 背包   Esc 菜单",
		Rect2(26, 778, 1230, 20),
		13,
		MUTED
	)
	target_label = _label("", Rect2(35, 101, 850, 29), 15, Color("fff0c4"))
	target_label.add_theme_color_override("font_shadow_color", Color("243a27"))
	target_label.add_theme_constant_override("shadow_offset_y", 2)
	station_label = _label("", Rect2(160, 660, 700, 33), 19, CREAM)
	station_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	station_label.add_theme_color_override("font_shadow_color", Color("1b3224"))
	station_label.add_theme_constant_override("shadow_offset_y", 2)
	toast_box = _panel(Rect2(155, 135, 690, 49), Color("203c31ed"))
	toast_box.z_index = 20
	toast_label = _label("", Rect2(168, 142, 664, 35), 16, CREAM)
	toast_label.z_index = 20
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_box.hide()
	toast_label.hide()
	modal_root = Control.new()
	modal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_root.z_index = 10
	add_child(modal_root)
	_panel(Rect2(0, 0, 1280, 800), Color("0b1b16d9"), modal_root)
	modal_root.hide()
	refresh("hoe", "turnip")


func refresh(selected_tool: String, selected_crop: String) -> void:
	title_label.text = state.profile.farm
	title_label.add_theme_font_size_override(
		"font_size", 22 if state.profile.farm.length() > 12 else 29
	)
	area_label.text = catalog.region(state.current_map).name + "  /  " + state.profile.name
	day_label.text = "春 · 第 %02d 天" % state.day
	time_label.text = "%02d:%02d" % [state.minute / 60, state.minute % 60]
	gold_label.text = "%d  G" % state.gold
	stamina_label.text = "体力   %d / %d" % [state.stamina, FarmState.MAX_STAMINA]
	var q = stories.quest(state)
	quest_title.text = q.title
	quest_where.text = q.where
	next_hint.text = q.hint
	var needs: Array[String] = []
	for id in q.needs:
		needs.append("%s  %d / %d" % [catalog.items[id].name, state.inventory[id], q.needs[id]])
	if state.narrative.stage == 1:
		needs.append(
			"播种、浇水 " + ("✓" if state.progress.planted and state.progress.watered else "待完成")
		)
	needs_label.text = "\n".join(needs)
	growth_label.text = (
		"种植 Lv.%d   采集 Lv.%d\n%s"
		% [
			stories.level(int(state.development.farming_xp)),
			stories.level(int(state.development.foraging_xp)),
			"铜水壶 · 横向三格" if state.development.watering_level else "普通水壶 · 单格浇水"
		]
	)
	for id in tool_buttons:
		tool_buttons[id].add_theme_stylebox_override(
			"normal",
			_style(
				Color("786b42") if id == selected_tool else GREEN,
				6,
				Color("d2b77c") if id == selected_tool else Color("496044")
			)
		)
	seed_button.text = (
		"Q  %s种子 · %d"
		% [
			catalog.crops[selected_crop].name,
			int(state.inventory[catalog.crops[selected_crop].seed_item])
		]
	)


func set_target(text: String, station: String) -> void:
	target_label.text = text
	station_label.text = "E  " + station if not station.is_empty() else ""


func toast(message: String, seconds: float = 4.5) -> void:
	toast_label.text = message
	toast_remaining = seconds
	toast_box.position.y = 30 if is_modal() else 135
	toast_label.position.y = toast_box.position.y + 7
	toast_box.show()
	toast_label.show()


func _process(delta: float) -> void:
	if toast_remaining > 0:
		toast_remaining -= delta
		if toast_remaining <= 0:
			toast_box.hide()
			toast_label.hide()


func is_modal() -> bool:
	return modal_root != null and modal_root.visible


func close_modal() -> void:
	modal_root.hide()
	modal_kind = ""


func open_modal(kind: String, title: String, description: String) -> void:
	toast_remaining = 0
	toast_box.hide()
	toast_label.hide()
	if modal_panel != null:
		modal_root.remove_child(modal_panel)
		modal_panel.queue_free()
	modal_kind = kind
	modal_panel = _panel(Rect2(310, 105, 660, 590), Color("203c31"), modal_root)
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_label(title, Rect2(30, 20, 600, 46), 28, CREAM, false, modal_panel)
	_label(description, Rect2(30, 75, 600, 100), 17, MUTED, true, modal_panel)
	modal_root.show()


func modal_button(
	text: String, y: float, action: String, payload: Dictionary = {}, disabled: bool = false
) -> Button:
	var button = _button(
		text, Rect2(30, y, 600, 43), func(): action_requested.emit(action, payload), modal_panel
	)
	button.disabled = disabled
	return button


func show_shop() -> void:
	open_modal("shop", "阿禾的种子摊", "需要几颗种子？每天浇水，跨天时生长。\n萝卜成熟需要 3 个浇水日，胡萝卜需要 4 个。")
	var i = 0
	for id in catalog.crops:
		var c = catalog.crops[id]
		var price = int(catalog.items[c.seed_item].buy_price)
		modal_button(
			"%s种子 ×1 / %d G" % [c.name, price],
			190 + i * 60,
			"buy",
			{"crop": id, "quantity": 1},
			state.gold < price
		)
		i += 1
	modal_button("萝卜种子 ×5 / 20 G", 330, "buy", {"crop": "turnip", "quantity": 5}, state.gold < 20)
	modal_button("离开摊位", 510, "close")


func show_sleep() -> void:
	open_modal("sleep", "回家，好好休息", "睡到明天早上，体力会恢复。\n已浇水的作物生长一天，林地资源重新出现。\n你将在自己的农舍醒来。")
	modal_button("结束今天，回家睡觉", 260, "sleep")
	modal_button("再逛一会儿", 320, "close")


func show_shipping(quote: Dictionary) -> void:
	open_modal(
		"shipping",
		"把收成送往小镇",
		(
			"%d 份农产品可卖出 %d 金币。\n种子和采集材料会保留。任务需要的萝卜也会出售，\n可以先放进家里的储物箱，或先完成交付。"
			% [quote.count, quote.gold]
		)
	)
	modal_button("出售全部农产品 / +%d G" % quote.gold, 260, "sell", {}, quote.count == 0)
	modal_button("返回", 320, "close")


func show_pause(sound_on: bool) -> void:
	open_modal("pause", "歇一会儿", "故事、人物与农场一起保存。菜单中时间暂停。")
	modal_button("继续生活", 190, "close")
	modal_button("手动保存", 246, "save")
	modal_button("音效：" + ("开启" if sound_on else "关闭"), 302, "sound")
	modal_button("保存并返回标题", 358, "title")
	modal_button("保存并退出", 470, "quit")


func show_morning(message: String) -> void:
	open_modal(
		"morning",
		"早安，" + state.profile.name,
		message + "\n\n厨房能做野莓粥；储物箱就在地毯左边。\n今天想种田、去林地，还是找朋友聊聊？"
	)
	modal_button("开始新的一天", 320, "close")


func show_journal() -> void:
	open_modal("journal", "故事手记 · 河灯归来", "祖母的信让你来到青苇镇。日子没有期限，\n每一次照料土地和彼此，都会让这里有所不同。")
	for i in range(7):
		var q = catalog.story.quests[i]
		var mark = (
			"✓" if i < state.narrative.stage else ("→" if i == state.narrative.stage else "·")
		)
		_label(
			"%s  %s  /  %s" % [mark, q.title, q.where],
			Rect2(30, 183 + i * 39, 600, 33),
			16,
			GOLD if i == state.narrative.stage else MUTED,
			false,
			modal_panel
		)
	modal_button("回到此刻", 510, "close")


func show_map() -> void:
	var region = catalog.region(state.current_map)
	open_modal("map", region.name + " · 地图册", "金点是你，粉点是村民，浅色点是入口。按住 Shift 跑步。")
	var overview = MapOverview.new()
	overview.position = Vector2(30, 160)
	overview.size = Vector2(600, 280)
	modal_panel.add_child(overview)
	overview.configure(catalog, state)
	var routes = {
		"home_farm": "南 → 青苇镇  |  屋前 → 农舍、种子摊、收货箱",
		"town": "西 → 农场  ·  北 → 林地  ·  东 → 湖畔（修桥后）",
		"forest": "南 → 青苇镇  |  林间可采集木料、碎石与野莓",
		"lake": "西 → 青苇镇  |  河灯台在西南岸，林栖在岸边"
	}
	_label(
		routes.get(state.current_map, "南门 → 返回屋外"),
		Rect2(30, 451, 600, 45),
		16,
		CREAM,
		true,
		modal_panel
	)
	modal_button("收起地图", 520, "close")


func show_bag(storage_mode: bool = false) -> void:
	open_modal(
		"storage" if storage_mode else "bag",
		"家里的储物箱" if storage_mode else "随身口袋",
		(
			"每次存取一份。箱内物品不会被出售或用于交付。"
			if storage_mode
			else (
				"生产、采集和朋友的回礼，都收在这里。\n种植经验 %d · 采集经验 %d"
				% [state.development.farming_xp, state.development.foraging_xp]
			)
		)
	)
	var i = 0
	for id in catalog.items:
		icon(catalog.items[id].icon, Rect2(32, 176 + i * 39, 30, 30), modal_panel)
		_label(
			"%s ×%d" % [catalog.items[id].name, state.inventory[id]],
			Rect2(78, 175 + i * 39, 240, 34),
			17,
			CREAM,
			false,
			modal_panel
		)
		if storage_mode:
			_label(
				"箱内 %d" % state.storage[id],
				Rect2(306, 175 + i * 39, 110, 34),
				16,
				MUTED,
				false,
				modal_panel
			)
			_button(
				"存入",
				Rect2(422, 175 + i * 39, 91, 34),
				func(): action_requested.emit("transfer", {"id": id, "deposit": true}),
				modal_panel
			)
			_button(
				"取出",
				Rect2(530, 175 + i * 39, 91, 34),
				func(): action_requested.emit("transfer", {"id": id, "deposit": false}),
				modal_panel
			)
		i += 1
	modal_button("关闭", 525, "close")


func show_cooking() -> void:
	open_modal(
		"kitchen",
		"让锅里热起来",
		(
			"野莓粥：野莓 ×2 → 立即恢复 30 体力。\n\n手里的野莓：%d\n当前体力：%d / 100"
			% [state.inventory.berry, state.stamina]
		)
	)
	modal_button("煮一碗野莓粥并吃下", 260, "cook", {}, state.inventory.berry < 2 or state.stamina >= 100)
	modal_button("离开灶台", 320, "close")


func show_upgrade() -> void:
	open_modal(
		"upgrade",
		"沈砚的工作台",
		(
			"铜水壶：一次浇灌目标与左右两格，消耗 1 体力。\n需要种植 Lv.2、40 金币、3 木材、2 石料。\n\n当前：种植 Lv.%d · 木材 %d · 石料 %d"
			% [
				stories.level(int(state.development.farming_xp)),
				state.inventory.wood,
				state.inventory.stone
			]
		)
	)
	modal_button(
		"制作铜水壶" if not state.development.watering_level else "铜水壶已完成",
		280,
		"upgrade",
		{},
		state.development.watering_level > 0
	)
	modal_button("离开工作台", 340, "close")


func show_npc(id: String, line: String, event: String) -> void:
	var npc = catalog.story.npcs[id]
	open_modal("npc", npc.name + " · 关系 %d / 100" % state.relationships[id], "")
	icon(npc.portrait, Rect2(30, 83, 96, 112), modal_panel)
	_label(npc.role, Rect2(150, 84, 470, 30), 18, GOLD, false, modal_panel)
	_label(line, Rect2(150, 120, 470, 110), 18, CREAM, true, modal_panel)
	var y = 260
	if not event.is_empty():
		modal_button("聊聊「%s」" % stories.quest(state).title, y, "story", {"event": event})
		y += 54
	modal_button("送一份礼物", y, "gift_menu", {"npc": id}, state.daily.gifted.has(id))
	y += 54
	modal_button(
		"听听你的故事 / 关系 40",
		y,
		"memory",
		{"npc": id},
		state.relationships[id] < 40 or state.development.memories.has(id)
	)
	modal_button("下次见", 510, "close")


func show_gifts(id: String) -> void:
	var npc = catalog.story.npcs[id]
	open_modal(
		"gifts",
		"送给" + npc.name,
		"她 / 他喜欢：%s。喜欢的礼物 +10 关系，其他礼物 +4。\n每天可送一份。首次交谈每天 +4 关系。" % catalog.items[npc.favorite].name
	)
	var i = 0
	for item in catalog.items:
		if catalog.items[item].kind == "seed":
			continue
		modal_button(
			"%s ×1（持有 %d）" % [catalog.items[item].name, state.inventory[item]],
			185 + i * 53,
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
	open_modal("dialogue", "", "")
	if catalog.story.npcs.has(who):
		var npc = catalog.story.npcs[who]
		icon(npc.portrait, Rect2(30, 28, 96, 112), modal_panel)
		_label(npc.name, Rect2(151, 30, 450, 50), 30, GOLD, false, modal_panel)
		_label(npc.role, Rect2(151, 84, 460, 50), 17, MUTED, false, modal_panel)
	else:
		_label(
			"祖母的手记" if who == "letter" else "河灯归来",
			Rect2(30, 30, 600, 52),
			29,
			GOLD,
			false,
			modal_panel
		)
	_label(text, Rect2(35, 160, 590, 225), 22, CREAM, true, modal_panel)
	_label(
		"%d / %d   ·   空格 / E 继续" % [index + 1, pages.size()],
		Rect2(35, 395, 590, 25),
		14,
		MUTED,
		false,
		modal_panel
	)
	if index < pages.size() - 1:
		modal_button("继续", 500, "dialogue_next")
	elif event == "prologue":
		modal_button("我想好好照料这片土地", 440, "dialogue_finish", {"choice": "grow"})
		modal_button("我想在这里重新开始", 498, "dialogue_finish", {"choice": "restart"})
	elif event == "festival":
		modal_button("愿我找到想留下的地方", 425, "dialogue_finish", {"choice": "stay"})
		modal_button("愿我有勇气出发，也有路回来", 477, "dialogue_finish", {"choice": "explore"})
		modal_button("愿我们以后常常见面", 529, "dialogue_finish", {"choice": "together"})
	else:
		modal_button("记住这一刻", 500, "dialogue_finish")


func show_ending() -> void:
	var wishes = {
		"stay": "你决定留下来，让农场成为一个真正的家。",
		"explore": "你愿意出发，也相信这里永远有一条回家的路。",
		"together": "你希望下一次相聚，不必等到一年后的河灯夜。"
	}
	open_modal(
		"ending",
		"第一章完成 · 灯亮之后",
		wishes[state.narrative.wish] + "\n\n湖面重新亮起河灯。桥、朋友和一顿热饭，\n都成了你生活的一部分。获得 50 金币。"
	)
	_label(
		"你仍可以种植、采集、做饭、升级工具，\n也可以用一次次交谈和礼物了解朋友。\n\n后续章节「留下的人」尚在规划中。",
		Rect2(30, 260, 600, 150),
		19,
		CREAM,
		true,
		modal_panel
	)
	modal_button("继续我的农场生活", 510, "close")

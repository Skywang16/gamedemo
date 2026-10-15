class_name FrontMenu
extends GameScreen

var screen: String = "title"
var cached_state: FarmState
var load_message: String = ""
var draft: Dictionary = {}
var name_input: LineEdit
var farm_input: LineEdit
var avatar: TextureRect
var appearance_buttons: Dictionary = {}
var error_label: Label


func initialize(content: ContentCatalog, saved: FarmState, message: String) -> void:
	catalog = content
	cached_state = saved
	load_message = message
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_theme(18)
	show_title()


func clear_screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg = TextureRect.new()
	bg.texture = load("res://assets/art/title_landscape.png")
	bg.size = Vector2(1280, 800)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_panel(Rect2(0, 0, 1280, 800), Color("102c294d"))


func show_title() -> void:
	screen = "title"
	clear_screen()
	_panel(Rect2(65, 65, 530, 664), Color("16382feb"))
	_label("SPROUT VALLEY", Rect2(108, 110, 450, 35), 18, GOLD)
	_label("芽田农场", Rect2(100, 153, 460, 90), 62, CREAM)
	_label("河 灯 归 来", Rect2(110, 245, 410, 45), 26, GOLD)
	_label("种下一颗种子。\n认识一个人。\n让一座小镇的灯，再次亮起来。", Rect2(110, 312, 425, 115), 20, CREAM, true)
	var button = _button(
		"继续生活", Rect2(110, 466, 425, 54), func(): action_requested.emit("continue", {})
	)
	button.disabled = cached_state == null
	_button("开始新生活", Rect2(110, 533, 425, 54), show_creator)
	_button("操作说明", Rect2(110, 602, 204, 44), show_help)
	_button("退出", Rect2(330, 602, 205, 44), func(): action_requested.emit("front_quit", {}))
	var text = "第一次来到青苇镇？从创建自己的角色开始。"
	if cached_state != null:
		text = (
			"%s · %s\n第 %d 天 / %s"
			% [
				cached_state.profile.name,
				cached_state.profile.farm,
				cached_state.day,
				catalog.story.quests[int(cached_state.narrative.stage)].title
			]
		)
	elif load_message.contains("存档"):
		text = load_message
	_label(text, Rect2(700, 600, 480, 100), 20, CREAM, true)
	_label("0.3  /  春日篇 · 第一章可完整游玩", Rect2(86, 750, 800, 28), 15, CREAM)


func show_help() -> void:
	screen = "help"
	clear_screen()
	_panel(Rect2(240, 110, 800, 580), Color("17392fee"))
	_label("把日子过成自己的样子", Rect2(290, 148, 720, 55), 34, CREAM)
	_label(
		"WASD / 方向键移动，Shift 跑步，靠近人物、门口和采集物按 E。\n1–7 切工具，点击身边地块或按空格操作，Q 换种子。\nJ 看故事，M 看地图，B 看背包，Esc 暂停。\n\n种田与采集会积累经验；工坊能升级水壶。\n家里能储物、做饭和休息。交谈和赠礼增进关系。\n\n没有错过就失败的日期。想慢一点，也没关系。",
		Rect2(290, 230, 700, 320),
		21,
		CREAM,
		true
	)
	_button("回到标题", Rect2(290, 584, 700, 52), show_title)


func show_creator() -> void:
	screen = "creator"
	clear_screen()
	draft = {"name": "小芽", "farm": "芽田农场", "skin": 0, "hair": 0, "outfit": 0, "hat": 1}
	appearance_buttons.clear()
	_panel(Rect2(120, 65, 1040, 665), Color("18392ff5"))
	_label("从你开始的故事", Rect2(165, 100, 900, 55), 36, CREAM)
	_label("你的名字会写进信里，心愿会留在河灯上。", Rect2(168, 165, 890, 30), 19, MUTED)
	_panel(Rect2(165, 228, 285, 357), Color("344e3c"))
	avatar = TextureRect.new()
	avatar.position = Vector2(212, 260)
	avatar.size = Vector2(192, 288)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avatar)
	_label("外观不限制玩法与人物关系", Rect2(167, 591, 290, 35), 15, MUTED)
	_label("怎么称呼你", Rect2(500, 219, 200, 30), 18, GOLD)
	name_input = field("小芽", Rect2(500, 259, 600, 48), 12)
	_label("给农场起个名字", Rect2(500, 319, 330, 30), 18, GOLD)
	farm_input = field("芽田农场", Rect2(500, 359, 600, 48), 18)
	var keys = ["skin", "hair", "outfit", "hat"]
	for i in range(4):
		var key = keys[i]
		appearance_buttons[key] = _button(
			"", Rect2(500 + (i % 2) * 310, 434 + int(i / 2) * 60, 290, 46), func(): cycle(key)
		)
	error_label = _label("", Rect2(500, 554, 600, 40), 16, Color("efb891"), true)
	name_input.text_changed.connect(func(_value): error_label.text = "")
	farm_input.text_changed.connect(func(_value): error_label.text = "")
	_label(
		(
			"确认后开始新故事；将覆盖现有开发存档。"
			if cached_state != null or load_message.contains("存档")
			else "可以随时取消。确认后会自动保存你的角色。"
		),
		Rect2(166, 632, 900, 24),
		15,
		MUTED
	)
	_button("返回", Rect2(165, 670, 285, 44), show_title)
	_button("带着这份期待，出发", Rect2(500, 610, 600, 48), submit)
	update_appearance()


func field(value: String, rect: Rect2, limit: int) -> LineEdit:
	var input = LineEdit.new()
	input.position = rect.position
	input.size = rect.size
	input.text = value
	input.max_length = limit
	input.add_theme_color_override("font_color", CREAM)
	input.add_theme_stylebox_override("normal", _style(Color("102a23"), 6, Color("648065")))
	input.add_theme_stylebox_override("focus", _style(Color("1d3b2c"), 6, GOLD))
	add_child(input)
	return input


func cycle(key: String) -> void:
	var sizes = {"skin": 3, "hair": 3, "outfit": 4, "hat": 2}
	draft[key] = (int(draft[key]) + 1) % sizes[key]
	update_appearance()


func update_appearance() -> void:
	var atlas = AtlasTexture.new()
	atlas.atlas = load(ContentCatalog.avatar_path(draft))
	atlas.region = Rect2(0, 0, 32, 48)
	avatar.texture = atlas
	var labels = {
		"skin": ["浅暖", "小麦", "深棕"],
		"hair": ["深棕", "栗色", "银灰"],
		"outfit": ["湖蓝", "陶红", "苔绿", "藤紫"],
		"hat": ["不戴帽子", "草帽"]
	}
	var names = {"skin": "肤色", "hair": "发色", "outfit": "衣服", "hat": "帽子"}
	for key in appearance_buttons:
		appearance_buttons[key].text = "%s：%s  ›" % [names[key], labels[key][int(draft[key])]]


func submit() -> void:
	draft.name = name_input.text.strip_edges()
	draft.farm = farm_input.text.strip_edges()
	if draft.name.is_empty() or draft.farm.is_empty():
		error_label.text = "给自己和农场都起个名字吧。"
		return
	action_requested.emit("create", draft.duplicate(true))

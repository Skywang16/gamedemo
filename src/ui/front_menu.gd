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
var preview_direction: int = 0
var settings: GameSettings


func initialize(
	content: ContentCatalog, saved: FarmState, message: String, current: GameSettings
) -> void:
	catalog = content
	settings = current
	cached_state = saved
	load_message = message
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_theme(18)
	show_title()


func clear_screen() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var backdrop = TitleBackdrop.new()
	backdrop.size = Vector2(1280, 800)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)


func show_title() -> void:
	screen = "title"
	clear_screen()
	_frame(Rect2(330, 96, 620, 206), "wood")
	var title = _label("芽田农场", Rect2(350, 120, 580, 100), 72, LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color("482717"))
	title.add_theme_constant_override("shadow_offset_y", 5)
	var subtitle = _label("河 灯 归 来", Rect2(360, 229, 560, 40), 24, Color("f3cb75"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var resume = _button(
		"继续生活", Rect2(460, 422, 360, 58), func(): action_requested.emit("continue", {})
	)
	resume.disabled = cached_state == null
	_button("开始新生活", Rect2(460, 496, 360, 58), show_creator)
	_button("设置", Rect2(460, 574, 170, 48), show_settings)
	_button("退出", Rect2(650, 574, 170, 48), func(): action_requested.emit("front_quit", {}))
	if cached_state != null:
		var saved = _label(
			"%s · 春 %d 日" % [cached_state.profile.farm, cached_state.day],
			Rect2(370, 658, 540, 36),
			18,
			LIGHT
		)
		saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		saved.add_theme_color_override("font_shadow_color", Color("36523a"))
		saved.add_theme_constant_override("shadow_offset_y", 2)
	elif load_message.contains("存档"):
		_frame(Rect2(370, 650, 540, 70))
		_label(load_message, Rect2(394, 660, 492, 48), 17, INK, true)


func show_settings(first_tab: String = "audio") -> void:
	screen = "settings"
	clear_screen()
	_frame(Rect2(190, 50, 900, 700))
	var panel = SettingsPanel.new()
	panel.position = Vector2(190, 50)
	add_child(panel)
	panel.open(settings, Vector2(900, 700), first_tab)
	panel.finished.connect(show_title)
	panel.preview_sound.connect(func(): action_requested.emit("preview_sound", {}))


func show_creator() -> void:
	screen = "creator"
	clear_screen()
	draft = {"name": "小芽", "farm": "芽田农场", "skin": 0, "hair": 0, "outfit": 0, "hat": 1}
	preview_direction = 0
	appearance_buttons.clear()
	_frame(Rect2(190, 85, 900, 635))
	var title = _label("新生活", Rect2(230, 111, 820, 55), 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frame(Rect2(230, 190, 250, 368), "inset")
	ui_icon("leaf", Rect2(327, 207, 56, 56), self)
	avatar = TextureRect.new()
	avatar.position = Vector2(275, 274)
	avatar.size = Vector2(160, 240)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avatar)
	_button("‹", Rect2(245, 572, 82, 40), func(): turn_preview(-1))
	_button("›", Rect2(383, 572, 82, 40), func(): turn_preview(1))
	_label("姓名", Rect2(520, 190, 300, 32), 19)
	name_input = field("小芽", Rect2(520, 230, 520, 49), 12)
	_label("农场名", Rect2(520, 302, 300, 32), 19)
	farm_input = field("芽田农场", Rect2(520, 342, 520, 49), 18)
	var keys = ["skin", "hair", "outfit", "hat"]
	for i in range(keys.size()):
		var key = keys[i]
		appearance_buttons[key] = _button(
			"", Rect2(520 + i % 2 * 270, 428 + int(i / 2) * 62, 250, 48), func(): cycle(key)
		)
	error_label = _label("", Rect2(520, 552, 520, 48), 17, Color("a4432e"), true)
	name_input.text_changed.connect(func(_value): error_label.text = "")
	farm_input.text_changed.connect(func(_value): error_label.text = "")
	if cached_state != null:
		_label("开始后替换当前存档", Rect2(520, 602, 520, 24), 15, MUTED)
	_button("返回", Rect2(230, 642, 250, 48), show_title)
	_button("带着这份期待，出发", Rect2(680, 642, 360, 48), submit)
	update_appearance()


func field(value: String, rect: Rect2, limit: int) -> LineEdit:
	var input = LineEdit.new()
	input.position = rect.position
	input.size = rect.size
	input.text = value
	input.max_length = limit
	input.add_theme_color_override("font_color", INK)
	input.add_theme_color_override("caret_color", INK)
	input.add_theme_color_override("selection_color", Color("c99552"))
	input.add_theme_stylebox_override("normal", _skin("inset"))
	input.add_theme_stylebox_override("focus", _skin("selected"))
	add_child(input)
	return input


func turn_preview(direction: int) -> void:
	preview_direction = posmod(preview_direction + direction, 4)
	update_appearance()


func cycle(key: String) -> void:
	var sizes = {"skin": 3, "hair": 3, "outfit": 4, "hat": 2}
	draft[key] = (int(draft[key]) + 1) % sizes[key]
	update_appearance()


func update_appearance() -> void:
	var atlas = AtlasTexture.new()
	atlas.atlas = load(ContentCatalog.avatar_path(draft))
	atlas.region = Rect2(0, preview_direction * 48, 32, 48)
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
		error_label.text = "名字和农场名不能为空"
		return
	action_requested.emit("create", draft.duplicate(true))

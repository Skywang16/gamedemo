class_name SettingsPanel
extends GameScreen

## Settings page shared by the title screen and the in-game pause menu. It edits a
## GameSettings object in place, applies every change immediately and writes the file
## whenever a change is committed, so there is no "apply" button to forget.

signal finished
signal preview_sound

const TABS = [["audio", "声音"], ["display", "画面"], ["controls", "操作"], ["game", "游戏"]]
const KEY_NAMES = {
	KEY_SPACE: "空格",
	KEY_ENTER: "回车",
	KEY_TAB: "Tab",
	KEY_BACKSPACE: "退格",
	KEY_UP: "↑",
	KEY_DOWN: "↓",
	KEY_LEFT: "←",
	KEY_RIGHT: "→",
}

var settings: GameSettings
var panel_size: Vector2
var tab: String = "audio"
var body: Control
var tab_buttons: Dictionary = {}
var capturing: String = ""
var rebind_buttons: Dictionary = {}
var note: Label


func open(current: GameSettings, size_px: Vector2, first_tab: String = "audio") -> void:
	settings = current
	panel_size = size_px
	tab = first_tab
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	_build()


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	tab_buttons.clear()
	rebind_buttons.clear()
	capturing = ""
	_label("设置", Rect2(40, 20, 300, 46), 30)
	var x = 340.0
	for entry in TABS:
		var id: String = entry[0]
		var button = _button(entry[1], Rect2(x, 24, 118, 42), func(): _select(id))
		button.add_theme_stylebox_override("normal", _skin("selected" if id == tab else "button"))
		button.add_theme_stylebox_override("hover", _skin("selected" if id == tab else "hover"))
		button.add_theme_color_override("font_color", INK if id == tab else LIGHT)
		button.add_theme_color_override("font_hover_color", INK if id == tab else Color("fff8db"))
		tab_buttons[id] = button
		x += 128
	_panel(Rect2(40, 80, panel_size.x - 80, 2), Color("cba365"), self)
	body = Control.new()
	body.position = Vector2(0, 92)
	body.size = Vector2(panel_size.x, panel_size.y - 190)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	note = _label("", Rect2(40, panel_size.y - 96, panel_size.x - 80, 28), 16, Color("a4432e"))
	_button("恢复默认", Rect2(40, panel_size.y - 62, 220, 46), _reset_current_tab)
	_button("返回", Rect2(panel_size.x - 260, panel_size.y - 62, 220, 46), _close)
	match tab:
		"audio":
			_build_audio()
		"display":
			_build_display()
		"controls":
			_build_controls()
		"game":
			_build_game()


func _select(id: String) -> void:
	if tab == id:
		return
	tab = id
	_build()


func _close() -> void:
	_commit()
	finished.emit()


func _commit() -> void:
	settings.apply()
	var error = settings.save_file()
	note.text = error


func _reset_current_tab() -> void:
	match tab:
		"audio":
			for key in ["master", "sfx"]:
				settings.set_value(key, GameSettings.DEFAULTS[key])
		"display":
			for key in ["fullscreen", "vsync", "reduce_motion"]:
				settings.set_value(key, GameSettings.DEFAULTS[key])
		"controls":
			settings.reset_bindings()
		"game":
			for key in ["autosave", "sprint_toggle", "show_hints"]:
				settings.set_value(key, GameSettings.DEFAULTS[key])
	_commit()
	_build()


# --- audio -----------------------------------------------------------------------


func _build_audio() -> void:
	_row_title("音量", 6)
	_slider("master", "主音量", 50)
	_slider("sfx", "音效", 120)
	_label(
		"拖动后松开会播放一声提示音。把音量拖到 0 即静音。", Rect2(40, 200, panel_size.x - 80, 30), 16, MUTED, false, body
	)


func _slider(key: String, text: String, y: float) -> void:
	_label(text, Rect2(40, y, 180, 44), 20, INK, false, body)
	var slider = HSlider.new()
	slider.position = Vector2(230, y + 8)
	slider.size = Vector2(panel_size.x - 400, 30)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = int(settings.get_value(key))
	slider.focus_mode = Control.FOCUS_NONE
	slider.scrollable = false
	slider.add_theme_stylebox_override("slider", _bar("track", 5))
	slider.add_theme_stylebox_override("grabber_area", _bar("fill", 5))
	slider.add_theme_stylebox_override("grabber_area_highlight", _bar("fill", 5))
	var knob = load("res://assets/ui/knob.png")
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)
	slider.add_theme_icon_override("grabber_disabled", knob)
	body.add_child(slider)
	var value_label = _label(
		"%d%%" % int(slider.value), Rect2(panel_size.x - 150, y, 110, 44), 20, MUTED, false, body
	)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect(
		func(value):
			settings.set_value(key, int(value))
			value_label.text = "%d%%" % int(value)
			settings.apply()
	)
	slider.drag_ended.connect(
		func(_changed):
			_commit()
			preview_sound.emit()
	)


func _bar(texture_name: String, margin: int) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = load("res://assets/ui/%s.png" % texture_name)
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = 0
	style.texture_margin_bottom = 0
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


# --- display & game toggles ------------------------------------------------------


func _row_title(text: String, y: float) -> void:
	_label(text, Rect2(40, y, 400, 36), 22, GOLD, false, body)


func _toggle(key: String, text: String, hint: String, y: float) -> void:
	_label(text, Rect2(40, y, 420, 34), 20, INK, false, body)
	_label(hint, Rect2(40, y + 32, panel_size.x - 260, 26), 15, MUTED, false, body)
	var button = TextureButton.new()
	button.position = Vector2(panel_size.x - 132, y + 8)
	button.size = Vector2(52, 28)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_toggle(button, bool(settings.get_value(key)))
	button.pressed.connect(
		func():
			var now = not bool(settings.get_value(key))
			settings.set_value(key, now)
			_set_toggle(button, now)
			_commit()
			preview_sound.emit()
	)
	body.add_child(button)


func _set_toggle(button: TextureButton, on: bool) -> void:
	button.texture_normal = load("res://assets/ui/toggle_%s.png" % ("on" if on else "off"))
	button.tooltip_text = "已开启" if on else "已关闭"


func _build_display() -> void:
	_row_title("窗口", 6)
	_toggle("fullscreen", "全屏", "全屏运行；随时可以在这里切回窗口。", 44)
	_toggle("vsync", "垂直同步", "避免画面撕裂；老旧电脑上画面卡顿时可以关闭。", 114)
	_row_title("动态", 196)
	_toggle("reduce_motion", "减弱动态效果", "减少草木摇摆与漂浮的花粉，更适合容易晕眩的玩家。砍树等操作反馈保留。", 234)


func _build_game() -> void:
	_row_title("存档与操作", 6)
	_toggle("autosave", "自动保存", "每隔一段时间与每次进入新地点时自动保存。关闭后请用菜单手动保存。", 44)
	_toggle("sprint_toggle", "切换式跑步", "开启后按一下跑步键开始跑，再按一下停止；关闭则按住才跑。", 114)
	_toggle("show_hints", "显示互动提示", "在可交谈、可进入的物体上方显示名称提示。", 184)


# --- key bindings ------------------------------------------------------------------


func _build_controls() -> void:
	var ids = GameSettings.REBINDABLE
	var half = int(ceil(ids.size() / 2.0))
	for i in ids.size():
		var action: String = ids[i]
		var column = i / half
		var row = i % half
		var x = 40.0 + column * 410.0
		var y = 4.0 + row * 54.0
		_label(GameSettings.ACTION_NAMES[action], Rect2(x, y, 170, 44), 19, INK, false, body)
		var button = _button(
			_key_text(settings.key_for(action)),
			Rect2(x + 176, y + 2, 190, 40),
			func(): _begin_capture(action),
			body
		)
		rebind_buttons[action] = button
	_label(
		"点击按键后按下新的键即可改键；Esc 取消。已被占用的键会与对方互换。固定：Esc 菜单，1–7 选工具。",
		Rect2(40, 4.0 + half * 54.0 + 4, panel_size.x - 80, 52),
		16,
		MUTED,
		true,
		body
	)


func _key_text(code: int) -> String:
	return KEY_NAMES.get(code, OS.get_keycode_string(code))


func _begin_capture(action: String) -> void:
	capturing = action
	note.text = ""
	for id in rebind_buttons:
		rebind_buttons[id].text = ("按下新按键…" if id == capturing else _key_text(settings.key_for(id)))


func _input(event: InputEvent) -> void:
	if capturing.is_empty() or not event is InputEventKey or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	var code = event.physical_keycode
	if code == KEY_ESCAPE:
		capturing = ""
		_refresh_keys()
		return
	var problem = settings.rebind(capturing, code)
	note.text = problem
	if problem.is_empty():
		_commit()
		preview_sound.emit()
	capturing = ""
	_refresh_keys()


func _refresh_keys() -> void:
	for id in rebind_buttons:
		rebind_buttons[id].text = _key_text(settings.key_for(id))

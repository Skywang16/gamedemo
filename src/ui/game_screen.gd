class_name GameScreen
extends Control

signal action_requested(action: String, payload: Dictionary)

const INK = Color("59391f")
const MUTED = Color("8b6845")
const GOLD = Color("a7652c")
const LIGHT = Color("fff0c3")
const PANEL_MARGIN = 36.0
const FOOTER_HEIGHT = 46.0

var catalog: ContentCatalog
var font: Font
var skins: Dictionary = {}


func setup_theme(size_px: int = 18) -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var variation = FontVariation.new()
	variation.base_font = load("res://assets/fonts/NotoSansSC.ttf")
	variation.variation_opentype = {2003265652: 550.0}
	font = variation
	var theme_data = Theme.new()
	theme_data.default_font = font
	theme_data.default_font_size = size_px
	theme_data.set_stylebox("panel", "TooltipPanel", _skin("paper"))
	theme_data.set_color("font_color", "TooltipLabel", INK)
	theme_data.set_font_size("font_size", "TooltipLabel", 17)
	theme = theme_data


func _skin(name: String) -> StyleBoxTexture:
	if not skins.has(name):
		var style = StyleBoxTexture.new()
		style.texture = load("res://assets/ui/%s.png" % name)
		style.texture_margin_left = 11
		style.texture_margin_right = 11
		style.texture_margin_top = 12
		style.texture_margin_bottom = 12
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		skins[name] = style
	return skins[name]


func icon(id: String, rect: Rect2, parent: Node) -> TextureRect:
	return _picture("res://assets/art/%s.png" % id, rect, parent)


func ui_icon(id: String, rect: Rect2, parent: Node) -> TextureRect:
	return _picture("res://assets/ui/%s.png" % id, rect, parent)


func _picture(path: String, rect: Rect2, parent: Node) -> TextureRect:
	var picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.texture = load(path)
	picture.position = rect.position
	picture.size = rect.size
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)
	return picture


func _frame(rect: Rect2, skin: String = "paper", parent: Node = self) -> Panel:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _skin(skin))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _panel(rect: Rect2, color: Color, parent: Node = self) -> Panel:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style = StyleBoxFlat.new()
	style.bg_color = color
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _label(
	text: String,
	rect: Rect2,
	size_px: int,
	color: Color = INK,
	wrap: bool = false,
	parent: Node = self
) -> Label:
	var label = Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label


func _button(text: String, rect: Rect2, action: Callable, parent: Node = self) -> Button:
	var button = Button.new()
	button.text = text
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", LIGHT)
	button.add_theme_color_override("font_hover_color", Color("fff8db"))
	button.add_theme_color_override("font_pressed_color", LIGHT)
	button.add_theme_color_override("font_disabled_color", Color("8c7754"))
	button.add_theme_color_override("font_shadow_color", Color("684222"))
	button.add_theme_constant_override("shadow_offset_y", 1)
	for pair in [
		["normal", "button"], ["hover", "hover"], ["pressed", "pressed"], ["disabled", "disabled"]
	]:
		button.add_theme_stylebox_override(pair[0], _skin(pair[1]))
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _slot(rect: Rect2, action: Callable, parent: Node = self) -> Button:
	var button = _button("", rect, action, parent)
	button.add_theme_stylebox_override("normal", _skin("slot"))
	button.add_theme_stylebox_override("hover", _skin("selected"))
	return button


## Previous / next page buttons with a "page x / y" label between them.
func add_pager(
	parent: Node, at: Vector2, width: float, page: int, pages: int, on_page: Callable
) -> void:
	var prev = _button(
		"‹ 上一页", Rect2(at, Vector2(140, FOOTER_HEIGHT)), func(): on_page.call(page - 1), parent
	)
	prev.disabled = page <= 0
	var label = _label(
		"第 %d / %d 页" % [page + 1, maxi(1, pages)],
		Rect2(at + Vector2(width / 2.0 - 70.0, 0), Vector2(140, FOOTER_HEIGHT)),
		18,
		MUTED,
		false,
		parent
	)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next = _button(
		"下一页 ›",
		Rect2(at + Vector2(width - 140.0, 0), Vector2(140, FOOTER_HEIGHT)),
		func(): on_page.call(page + 1),
		parent
	)
	next.disabled = page >= pages - 1


static func page_count(total: int, per_page: int) -> int:
	return maxi(1, int(ceil(float(total) / float(per_page))))


## A row of tab buttons; the current one is drawn raised.
func add_tabs(
	parent: Node, at: Vector2, tabs: Array, current: String, width: float, on_select: Callable
) -> void:
	var x = at.x
	for entry in tabs:
		var id: String = entry[0]
		var button = _button(
			entry[1],
			Rect2(Vector2(x, at.y), Vector2(width, 42)),
			func(): on_select.call(id),
			parent
		)
		var raised = id == current
		button.add_theme_stylebox_override("normal", _skin("selected" if raised else "button"))
		button.add_theme_stylebox_override("hover", _skin("selected" if raised else "hover"))
		button.add_theme_color_override("font_color", INK if raised else LIGHT)
		button.add_theme_color_override("font_hover_color", INK if raised else Color("fff8db"))
		x += width + 8.0


static func footer_y(panel_size: Vector2) -> float:
	return panel_size.y - PANEL_MARGIN - FOOTER_HEIGHT


## A bounded, vertically scrollable column for variable-length journal content.
func scroll_column(rect: Rect2, content_height: float, parent: Node) -> Control:
	var scroll = ScrollContainer.new()
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var content = Control.new()
	content.custom_minimum_size = Vector2(rect.size.x - 18, content_height)
	scroll.add_child(content)
	return content

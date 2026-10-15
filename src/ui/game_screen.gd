class_name GameScreen
extends Control

signal action_requested(action: String, payload: Dictionary)

const CREAM = Color("f2e8ca")
const MUTED = Color("a6b89c")
const GOLD = Color("e2bd75")
const GREEN = Color("203c31")

var catalog: ContentCatalog
var font: Font


func setup_theme(size_px: int = 17) -> void:
	var variation = FontVariation.new()
	variation.base_font = load("res://assets/fonts/NotoSansSC.ttf")
	variation.variation_opentype = {2003265652: 500.0}
	font = variation
	var theme_data = Theme.new()
	theme_data.default_font = font
	theme_data.default_font_size = size_px
	theme = theme_data


func icon(id: String, rect: Rect2, parent: Node) -> void:
	var picture = TextureRect.new()
	picture.texture = load("res://assets/art/%s.png" % id)
	picture.position = rect.position
	picture.size = rect.size
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(picture)


func _style(color: Color, radius: int = 8, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = border
	s.content_margin_left = 12
	s.content_margin_right = 12
	return s


func _panel(rect: Rect2, color: Color, parent: Node = self) -> Panel:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(color, 8))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel


func _label(
	text: String, rect: Rect2, size_px: int, color: Color, wrap: bool = false, parent: Node = self
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
	parent.add_child(label)
	return label


func _button(text: String, rect: Rect2, action: Callable, parent: Node = self) -> Button:
	var button = Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", CREAM)
	button.add_theme_color_override("font_hover_color", Color("fff3c9"))
	button.add_theme_color_override("font_disabled_color", Color("7e8b72"))
	button.add_theme_stylebox_override("normal", _style(GREEN, 6, Color("496044")))
	button.add_theme_stylebox_override("hover", _style(Color("3e5840"), 6, GOLD))
	button.add_theme_stylebox_override("pressed", _style(Color("65704b"), 6, GOLD))
	button.add_theme_stylebox_override("disabled", _style(Color("283a2d"), 6))
	button.add_theme_stylebox_override("focus", _style(Color("ffffff08"), 6, GOLD))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

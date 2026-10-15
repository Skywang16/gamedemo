class_name ScreenFade
extends CanvasLayer

## Fade-from-black overlay for scene changes. The change itself happens first, then this
## reveals the result, so game state is never delayed behind an animation. A card with a
## few lines of text can be shown while the screen is still dark (e.g. a new day).

var cover: ColorRect
var card: Label
var tween: Tween
var active: bool:
	get:
		return cover != null and cover.visible


func _init() -> void:
	layer = 100


func _ready() -> void:
	cover = ColorRect.new()
	cover.color = Color("101a16")
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.hide()
	add_child(cover)
	card = Label.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_font_size_override("font_size", 40)
	card.add_theme_color_override("font_color", Color("fff0c3"))
	card.add_theme_color_override("font_shadow_color", Color("482717"))
	card.add_theme_constant_override("shadow_offset_y", 3)
	var variation = FontVariation.new()
	variation.base_font = load("res://assets/fonts/NotoSansSC.ttf")
	variation.variation_opentype = {2003265652: 600.0}
	card.add_theme_font_override("font", variation)
	card.hide()
	add_child(card)


## Starts fully dark (so the change underneath is hidden) and fades out over `seconds`.
func reveal(seconds: float = 0.45, text: String = "") -> void:
	if cover == null:
		return
	if tween != null and tween.is_valid():
		tween.kill()
	if UIMotion.reduced:
		seconds = minf(seconds, 0.12)
		text = ""
	cover.modulate.a = 1.0
	cover.show()
	card.text = text
	card.modulate.a = 1.0
	card.visible = not text.is_empty()
	tween = create_tween()
	if not text.is_empty():
		tween.tween_interval(seconds * 0.55)
		tween.tween_property(card, "modulate:a", 0.0, seconds * 0.2)
		tween.parallel().tween_property(cover, "modulate:a", 0.0, seconds * 0.45)
	else:
		tween.tween_property(cover, "modulate:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	tween.tween_callback(
		func():
			cover.hide()
			card.hide()
	)

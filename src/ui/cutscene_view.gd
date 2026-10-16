class_name CutsceneView
extends GameScreen

## A story scene played as a short film: the painted picture fills the screen, people walk on and
## off, the camera drifts, lanterns rise, and the words appear one letter at a time in a box at
## the bottom. Chapter cards open the big moments. The game only hears three things from here:
## "dialogue_next", "dialogue_finish" (with the chosen answer) and `sound` requests.

signal sound(name: String)

const TEXT_SPEED = 46.0
const CARD_HOLD = 2.0
const BOX = Rect2(90, 586, 1100, 196)

var state: FarmState
var stories: StoryRules
var scene_id: String = ""
var event: String = ""
var pages: Array = []
var choices: Array = []
var scene_meta: Dictionary = {}
var index: int = 0
var viewport: SubViewport
var canvas: CutsceneCanvas
var picture: TextureRect
var top_bar: ColorRect
var fade: ColorRect
var panel: Panel
var plate: Panel
var plate_label: Label
var body: Label
var counter: Label
var letter_icon: TextureRect
var action_row: Control
var caption: Label
var card: Control
var card_kicker: Label
var card_title: Label
var chars_shown: float = 0.0
var typing: bool = false
var card_active: bool = false
var card_tween: Tween
var fade_tween: Tween
var caption_tween: Tween
var backdrop: String = ""
var mood: String = ""


func play(
	content: ContentCatalog,
	s: FarmState,
	scene_pages: Array,
	start: int,
	id: String,
	choice_list: Array,
	scene_event: String
) -> void:
	catalog = content
	state = s
	stories = StoryRules.new(content)
	pages = scene_pages
	scene_id = id
	event = scene_event
	choices = choice_list
	scene_meta = catalog.story.scenes[id]
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_theme(18)
	_build()
	canvas.reduced = UIMotion.reduced
	canvas.set_backdrop(scene_meta.bg, scene_meta.mood)
	canvas.set_effects(scene_meta.fx)
	backdrop = scene_meta.bg
	mood = scene_meta.mood
	index = clampi(start, 0, pages.size() - 1)
	for i in range(index):
		_apply(pages[i][2], true)
	if index == 0 and not scene_meta.card.is_empty() and not UIMotion.reduced:
		_play_card()
	else:
		show_page(index)


func _build() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(320, 200)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = (
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)
	add_child(viewport)
	canvas = CutsceneCanvas.new()
	viewport.add_child(canvas)
	canvas.configure(catalog, state.profile, stories.lamps(state))
	picture = TextureRect.new()
	picture.texture = viewport.get_texture()
	picture.size = Vector2(1280, 800)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	top_bar = ColorRect.new()
	top_bar.color = Color.BLACK
	top_bar.size = Vector2(1280, 56)
	top_bar.position = Vector2(0, -56)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_bar)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(1280, 800)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	panel = _frame(BOX)
	plate = _frame(Rect2(BOX.position.x + 22, BOX.position.y - 30, 200, 46), "wood")
	plate_label = _label("", Rect2(BOX.position.x + 30, BOX.position.y - 25, 184, 36), 21, LIGHT)
	plate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter_icon = ui_icon("letter", Rect2(BOX.position.x + 28, BOX.position.y + 52, 64, 64), self)
	body = _label(
		"", Rect2(BOX.position.x + 40, BOX.position.y + 26, BOX.size.x - 80, 122), 23, INK, true
	)
	counter = _label(
		"", Rect2(BOX.position.x + 40, BOX.position.y + BOX.size.y - 36, 160, 26), 15, MUTED
	)
	action_row = Control.new()
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(action_row)
	caption = _label("", Rect2(240, 250, 800, 100), 46, LIGHT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_shadow_color", Color("1c1410"))
	caption.add_theme_constant_override("shadow_offset_y", 4)
	caption.modulate.a = 0.0
	var card_back = ColorRect.new()
	card_back.color = Color.BLACK
	card_back.size = Vector2(1280, 800)
	card = card_back
	card.hide()
	add_child(card)
	card_kicker = _label("", Rect2(0, 292, 1280, 44), 26, Color("d8b868"), false, card)
	card_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title = _label("", Rect2(0, 340, 1280, 110), 74, LIGHT, false, card)
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not UIMotion.reduced:
		var bars = create_tween()
		bars.tween_property(top_bar, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		)
	else:
		top_bar.position.y = 0.0


# ---------------------------------------------------------------------------- chapter card


func _play_card() -> void:
	card_active = true
	panel.hide()
	plate.hide()
	plate_label.hide()
	body.hide()
	counter.hide()
	letter_icon.hide()
	card.show()
	card_kicker.text = scene_meta.card[0]
	card_title.text = scene_meta.card[1]
	card_kicker.modulate.a = 0.0
	card_title.modulate.a = 0.0
	sound.emit("chime")
	card_tween = create_tween()
	card_tween.tween_property(card_kicker, "modulate:a", 1.0, 0.7)
	card_tween.parallel().tween_property(card_title, "modulate:a", 1.0, 1.0).set_delay(0.3)
	card_tween.tween_interval(CARD_HOLD)
	card_tween.tween_property(card, "modulate:a", 0.0, 0.8)
	card_tween.tween_callback(_end_card)


func _end_card() -> void:
	if not card_active:
		return
	card_active = false
	if card_tween != null and card_tween.is_valid():
		card_tween.kill()
	card.hide()
	panel.show()
	show_page(index)


# ---------------------------------------------------------------------------- pages


## Plays one page: applies the director's notes, then types the line.
func show_page(i: int) -> void:
	index = clampi(i, 0, pages.size() - 1)
	var page: Array = pages[index]
	_apply(page[2], false)
	panel.show()
	body.show()
	counter.show()
	var who: String = page[0]
	canvas.speaker = who
	var speaker_name = _speaker_name(who)
	plate.visible = not speaker_name.is_empty()
	plate_label.visible = plate.visible
	plate_label.text = speaker_name
	letter_icon.visible = who == "letter"
	body.position.x = BOX.position.x + (112.0 if who == "letter" else 40.0)
	body.size.x = BOX.size.x - (152.0 if who == "letter" else 80.0)
	body.text = (page[1].replace("{name}", state.profile.name).replace(
		"{farm}", state.profile.farm
	))
	counter.text = "%d / %d" % [index + 1, pages.size()]
	if UIMotion.reduced:
		body.visible_characters = -1
		typing = false
	else:
		body.visible_characters = 0
		chars_shown = 0.0
		typing = true
	_build_actions()


func _speaker_name(who: String) -> String:
	if who == "letter":
		return "祖母的信"
	if who == "narrator":
		return ""
	if catalog.story.npcs.has(who):
		return catalog.story.npcs[who].name
	return catalog.story.guests[who].name


func _build_actions() -> void:
	for child in action_row.get_children():
		action_row.remove_child(child)
		child.queue_free()
	var last = index == pages.size() - 1
	if not last:
		_button(
			"继续",
			Rect2(BOX.end.x - 220, BOX.end.y - 54, 190, 42),
			func(): action_requested.emit("dialogue_next", {}),
			action_row
		)
		return
	if choices.is_empty():
		_button(
			"记住这一刻",
			Rect2(BOX.end.x - 250, BOX.end.y - 54, 220, 42),
			func(): action_requested.emit("dialogue_finish", {}),
			action_row
		)
		return
	for i in range(choices.size()):
		var choice: Dictionary = choices[i]
		_button(
			choice.label,
			Rect2(BOX.end.x - 560, BOX.position.y - 18 - (choices.size() - i) * 54.0, 560, 48),
			func(): action_requested.emit("dialogue_finish", {"choice": choice.id}),
			action_row
		)


## True when the key press was spent finishing the chapter card or the line being typed.
func skip() -> bool:
	if card_active:
		_end_card()
		return true
	if typing:
		typing = false
		body.visible_characters = -1
		return true
	return false


func _process(delta: float) -> void:
	if typing:
		chars_shown += delta * TEXT_SPEED
		var total = body.get_total_character_count()
		body.visible_characters = int(chars_shown)
		if int(chars_shown) >= total:
			typing = false
			body.visible_characters = -1


# ---------------------------------------------------------------------------- director's notes


func _apply(notes: Dictionary, instant: bool) -> void:
	if notes.has("bg") or notes.has("mood"):
		var new_bg: String = notes.get("bg", backdrop)
		var new_mood: String = notes.get("mood", mood)
		if new_bg != backdrop or new_mood != mood:
			backdrop = new_bg
			mood = new_mood
			_change_backdrop(instant)
	if notes.has("fx"):
		canvas.set_effects(notes.fx)
	if notes.has("cam"):
		canvas.set_camera(notes.cam)
	if notes.has("actors"):
		canvas.set_actors(notes.actors, instant)
	if instant:
		return
	if notes.has("act"):
		for id in notes.act:
			canvas.trigger_act(id, notes.act[id])
	if notes.has("sfx"):
		sound.emit(notes.sfx)
	if notes.has("flash"):
		canvas.flash(notes.flash)
	if notes.has("shake"):
		canvas.shake(float(notes.shake))
	if notes.has("title"):
		_show_caption(notes.title)


func _change_backdrop(instant: bool) -> void:
	if instant or UIMotion.reduced:
		canvas.set_backdrop(backdrop, mood)
		return
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "color:a", 1.0, 0.22)
	fade_tween.tween_callback(func(): canvas.set_backdrop(backdrop, mood))
	fade_tween.tween_property(fade, "color:a", 0.0, 0.3)


func _show_caption(text: String) -> void:
	caption.text = text
	if caption_tween != null and caption_tween.is_valid():
		caption_tween.kill()
	caption_tween = create_tween()
	caption_tween.tween_property(caption, "modulate:a", 1.0, 0.5)
	caption_tween.tween_interval(1.8)
	caption_tween.tween_property(caption, "modulate:a", 0.0, 0.6)

class_name FishingPanel
extends GameScreen

## The fishing minigame: wait for a bite, lift the rod in time, then stop the moving marker
## inside the catch zone. `finished` carries the fish item id, or "" when it got away.

signal finished(fish_id: String)

const BAR = Rect2(120, 250, 640, 44)

var state: FarmState
var fishing: FishingRules
var rng := RandomNumberGenerator.new()
var fish_id: String = ""
var phase: String = "wait"
var left: float = 0.0
var zone: Rect2
var marker: Panel
var zone_panel: Panel
var bobber: Panel
var caption: Label
var hint: Label
var clock: float = 0.0
var swing: float = 1.6
var panel_size: Vector2


func open(
	content: ContentCatalog, s: FarmState, rules: FishingRules, bait: bool, size_px: Vector2
) -> void:
	catalog = content
	state = s
	fishing = rules
	panel_size = size_px
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	rng.randomize()
	fish_id = fishing.pick(state, rng)
	left = fishing.wait_seconds(state, rng, bait)
	var title = _label("钓鱼", Rect2(36, 16, 300, 44), 28)
	title.add_theme_color_override("font_color", INK)
	_label(
		fishing.rod(state).name + " · 钓鱼 Lv.%d" % fishing.level(state),
		Rect2(36, 58, 400, 28),
		17,
		MUTED
	)
	_frame(Rect2(60, 110, panel_size.x - 120, 120), "inset")
	bobber = _panel(Rect2(panel_size.x / 2.0 - 8.0, 150, 16, 16), Color("d8402f"))
	caption = _label("浮标静静漂着……", Rect2(60, 176, panel_size.x - 120, 40), 22)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint = _label(
		"等到浮标沉下去，再按空格或点击提竿。太早会吓跑鱼。Esc 收竿。", Rect2(60, 330, panel_size.x - 120, 60), 18, MUTED, true
	)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _process(delta: float) -> void:
	clock += delta
	match phase:
		"wait":
			bobber.position.y = 150.0 + sin(clock * 3.0) * 3.0
			left -= delta
			if left <= 0.0:
				phase = "bite"
				left = 0.9 + 0.12 * float(fishing.rod(state).window)
				caption.text = "有动静！快提竿！"
				bobber.position.y = 176.0
				hint.text = "现在！按空格或点击。"
		"bite":
			bobber.position.y = 176.0 + sin(clock * 30.0) * 4.0
			left -= delta
			if left <= 0.0:
				_end("")
		"reel":
			var t = (sin(clock * swing * TAU * 0.5) + 1.0) / 2.0
			marker.position.x = BAR.position.x + t * (BAR.size.x - marker.size.x)


func _input(event: InputEvent) -> void:
	if phase == "done":
		return
	var pressed = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_end("")
			return
		pressed = event.is_action_pressed("use_tool") or event.is_action_pressed("interact")
	elif (
		event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	):
		pressed = true
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	match phase:
		"wait":
			_end("")
		"bite":
			_start_reel()
		"reel":
			_stop_reel()


func _start_reel() -> void:
	phase = "reel"
	caption.text = "把游标停在绿区里！"
	hint.text = "游标来回移动，按空格或点击停下。"
	bobber.hide()
	var width = BAR.size.x * fishing.zone_size(state, fish_id)
	var start = rng.randf_range(BAR.position.x + 40.0, BAR.position.x + BAR.size.x - width - 40.0)
	zone = Rect2(start, BAR.position.y, width, BAR.size.y)
	_panel(Rect2(BAR.position - Vector2(6, 6), BAR.size + Vector2(12, 12)), Color("3d2417"))
	_panel(BAR, Color("55402a"))
	zone_panel = _panel(zone, Color("86b34b"))
	marker = _panel(
		Rect2(BAR.position.x, BAR.position.y - 10.0, 10, BAR.size.y + 20.0), Color("fff0c3")
	)
	var difficulty = 1
	if catalog.fish.has(fish_id):
		difficulty = int(catalog.fish[fish_id].difficulty)
	swing = 1.2 + 0.35 * float(difficulty)


func _stop_reel() -> void:
	var middle = marker.position.x + marker.size.x / 2.0
	_end(fish_id if middle >= zone.position.x and middle <= zone.end.x else "")


func _end(result: String) -> void:
	phase = "done"
	finished.emit(result)

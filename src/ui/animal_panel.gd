class_name AnimalPanel
extends GameScreen

## One animal building: feed everyone, collect the day's produce, pet each animal.

const PER_PAGE = 5
const ROW_HEIGHT = 92

var state: FarmState
var animals: AnimalRules
var building: String
var page: int = 0
var panel_size: Vector2


func open(
	content: ContentCatalog,
	s: FarmState,
	rules: AnimalRules,
	id: String,
	first_page: int,
	size_px: Vector2
) -> void:
	catalog = content
	state = s
	animals = rules
	building = id
	page = first_page
	panel_size = size_px
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	_build()


func _residents() -> Array:
	var out: Array = []
	for i in state.animals.size():
		if catalog.animals[state.animals[i].species].building == building:
			out.append(i)
	return out


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var spec = catalog.buildings[building]
	_label(spec.name, Rect2(36, 16, 400, 44), 28)
	var residents = _residents()
	_label(
		"%d / %d · 干草 ×%d" % [residents.size(), spec.capacity, state.inventory.hay],
		Rect2(36, 58, 520, 28),
		17,
		MUTED
	)
	_button(
		"喂食全部",
		Rect2(panel_size.x - 520, 24, 220, 46),
		func(): action_requested.emit("animals_feed", {"building": building, "page": page})
	)
	_button(
		"收获",
		Rect2(panel_size.x - 280, 24, 220, 46),
		func(): action_requested.emit("animals_collect", {"building": building, "page": page})
	)
	if residents.is_empty():
		_label("这里还空着。去草溪牧场找罗西买动物吧。", Rect2(36, 130, 800, 40), 20, MUTED)
	var pages = page_count(residents.size(), PER_PAGE)
	page = clampi(page, 0, pages - 1)
	var from = page * PER_PAGE
	for k in range(from, mini(residents.size(), from + PER_PAGE)):
		var index: int = residents[k]
		var a: Dictionary = state.animals[index]
		var kind = catalog.animals[a.species]
		var y = 100.0 + float(k - from) * ROW_HEIGHT
		_frame(Rect2(30, y, panel_size.x - 60, ROW_HEIGHT - 8), "inset")
		icon(catalog.items[kind.product].icon, Rect2(46, y + 12, 56, 56), self)
		_label("%s（%s）" % [a.name, kind.name], Rect2(118, y + 6, 360, 32), 21)
		var status = "吃饱了" if a.fed else "饿着"
		if a.ready:
			status += " · 有东西可以收"
		elif int(a.age) < int(kind.adult_days):
			status += " · 还没长大"
		_label(status, Rect2(118, y + 40, 420, 30), 15, MUTED)
		for h in 5:
			ui_icon(
				"heart" if int(a.friendship) >= (h + 1) * 20 else "heart_empty",
				Rect2(560 + h * 30, y + 26, 24, 24),
				self
			)
		var pet = _button(
			"摸一摸",
			Rect2(panel_size.x - 200, y + 20, 130, 44),
			func():
				action_requested.emit(
					"animals_pet", {"index": index, "building": building, "page": page}
				)
		)
		pet.disabled = a.petted
	add_pager(self, Vector2(36, footer_y(panel_size)), panel_size.x - 300, page, pages, _turn)
	_button(
		"离开",
		Rect2(panel_size.x - 226, footer_y(panel_size), 190, 46),
		func(): action_requested.emit("close", {})
	)


func _turn(new_page: int) -> void:
	page = new_page
	_build()

class_name CookingPanel
extends GameScreen

## The stove: every recipe the cook's level allows, the ones you can make right now first.

const PER_PAGE = 5
const ROW_HEIGHT = 92

var state: FarmState
var cooking: CookingRules
var page: int = 0
var panel_size: Vector2


func open(
	content: ContentCatalog, s: FarmState, rules: CookingRules, first_page: int, size_px: Vector2
) -> void:
	catalog = content
	state = s
	cooking = rules
	page = first_page
	panel_size = size_px
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	_build()


func _sorted() -> Array:
	var ready: Array = []
	var rest: Array = []
	for recipe in cooking.known(state):
		if cooking.can_cook(state, recipe.id):
			ready.append(recipe)
		else:
			rest.append(recipe)
	return ready + rest


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_label("灶台", Rect2(36, 16, 300, 44), 28)
	_label(
		"烹饪 Lv.%d · 体力 %d / %d" % [cooking.level(state), state.stamina, FarmState.MAX_STAMINA],
		Rect2(36, 58, 520, 28),
		17,
		MUTED
	)
	var list = _sorted()
	var pages = page_count(list.size(), PER_PAGE)
	page = clampi(page, 0, pages - 1)
	var from = page * PER_PAGE
	for i in range(from, mini(list.size(), from + PER_PAGE)):
		var recipe: Dictionary = list[i]
		var y = 100.0 + float(i - from) * ROW_HEIGHT
		_frame(Rect2(30, y, panel_size.x - 60, ROW_HEIGHT - 8), "inset")
		var dish = catalog.items[recipe.id]
		icon(dish.icon, Rect2(46, y + 12, 56, 56), self)
		_label(
			"%s · 体力 +%d · 售价 %d G" % [dish.name, dish.energy, dish.sell_price],
			Rect2(118, y + 6, 640, 32),
			20
		)
		var parts: Array[String] = []
		for need in recipe.needs:
			parts.append(
				"%s %d/%d" % [catalog.items[need].name, state.inventory[need], recipe.needs[need]]
			)
		_label(
			(
				"、".join(parts)
				+ ("" if int(recipe.level) == 0 else "    需要烹饪 Lv.%d" % int(recipe.level))
			),
			Rect2(118, y + 40, 700, 30),
			15,
			MUTED
		)
		var go = _button(
			"烹饪",
			Rect2(panel_size.x - 200, y + 20, 130, 44),
			func(): action_requested.emit("cook", {"recipe": recipe.id, "page": page})
		)
		go.disabled = not cooking.can_cook(state, recipe.id)
	add_pager(self, Vector2(36, panel_size.y - 62), panel_size.x - 300, page, pages, _turn)
	_button(
		"离开灶台",
		Rect2(panel_size.x - 226, panel_size.y - 62, 190, 46),
		func(): action_requested.emit("close", {})
	)


func _turn(new_page: int) -> void:
	page = new_page
	_build()

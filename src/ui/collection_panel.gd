class_name CollectionPanel
extends GameScreen

## The collection log: every item the player has ever held, unseen ones as silhouettes.

const COLUMNS = 8
const PER_PAGE = 40
const CATEGORIES = [
	["all", "全部"],
	["seed", "种子"],
	["produce", "作物"],
	["fish", "鱼"],
	["forage", "采集"],
	["mineral", "矿物"],
	["dish", "料理"],
	["material", "材料"],
]

var state: FarmState
var category: String = "all"
var page: int = 0
var panel_size: Vector2


func open(content: ContentCatalog, s: FarmState, size_px: Vector2) -> void:
	catalog = content
	state = s
	panel_size = size_px
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	_build()


func _items() -> Array:
	var out: Array = []
	for id in catalog.items:
		if category == "all" or catalog.items[id].kind == category:
			out.append(id)
	return out


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_label("图志", Rect2(36, 16, 300, 44), 28)
	var found = 0
	for id in catalog.items:
		if state.collected.has(id):
			found += 1
	_label(
		"已收集 %d / %d" % [found, catalog.items.size()],
		Rect2(panel_size.x - 360, 20, 320, 40),
		22,
		GOLD
	)
	add_tabs(self, Vector2(36, 66), CATEGORIES, category, 92, _select)
	var items = _items()
	var pages = page_count(items.size(), PER_PAGE)
	page = clampi(page, 0, pages - 1)
	var from = page * PER_PAGE
	for i in range(from, mini(items.size(), from + PER_PAGE)):
		var id: String = items[i]
		var at = Vector2(36 + (i - from) % COLUMNS * 100, 126 + int((i - from) / COLUMNS) * 84)
		var slot = _frame(Rect2(at, Vector2(88, 76)), "slot")
		var known = state.collected.has(id)
		var picture = icon(
			catalog.items[id].icon, Rect2(at + Vector2(16, 10), Vector2(56, 56)), self
		)
		if not known:
			picture.modulate = Color(0.12, 0.09, 0.07, 0.85)
		slot.tooltip_text = catalog.items[id].name if known else "？？？"
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
	add_pager(self, Vector2(36, panel_size.y - 62), panel_size.x - 300, page, pages, _turn)
	_button(
		"关闭",
		Rect2(panel_size.x - 226, panel_size.y - 62, 190, 46),
		func(): action_requested.emit("close", {})
	)


func _select(id: String) -> void:
	category = id
	page = 0
	_build()


func _turn(new_page: int) -> void:
	page = new_page
	_build()

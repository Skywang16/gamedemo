class_name BagPanel
extends GameScreen

## The backpack and the storage chest: owned items by category, eating, and skill levels.
## In storage mode each item can be moved between the pack and the chest.

const COLUMNS = 5
const PER_PAGE = 20
const CATEGORIES = [
	["all", "全部"],
	["seed", "种子"],
	["produce", "作物"],
	["fish", "鱼"],
	["forage", "采集"],
	["mineral", "矿物"],
	["drop", "战利品"],
	["dish", "料理"],
	["material", "材料"],
]

var state: FarmState
var stories: StoryRules
var storage_mode: bool = false
var category: String = "all"
var page: int = 0
var selected: String = ""
var panel_size: Vector2


func open(
	content: ContentCatalog,
	s: FarmState,
	storage: bool,
	first_item: String,
	first_category: String,
	first_page: int,
	size_px: Vector2
) -> void:
	catalog = content
	state = s
	stories = StoryRules.new(content)
	storage_mode = storage
	selected = first_item
	category = first_category
	page = first_page
	panel_size = size_px
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	var items = _items()
	if items.has(selected):
		page = int(items.find(selected) / PER_PAGE)
	_build()


func _count(id: String) -> int:
	return int(state.inventory[id]) + (int(state.storage[id]) if storage_mode else 0)


func _items() -> Array:
	var out: Array = []
	for id in catalog.items:
		if _count(id) < 1:
			continue
		if category == "all" or catalog.items[id].kind == category:
			out.append(id)
	return out


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_label("储物箱" if storage_mode else "背包", Rect2(36, 16, 400, 44), 28)
	add_tabs(self, Vector2(36, 66), CATEGORIES, category, 92, _select_category)
	var items = _items()
	var pages = page_count(items.size(), PER_PAGE)
	page = clampi(page, 0, pages - 1)
	if not items.has(selected):
		selected = items[0] if not items.is_empty() else ""
	var from = page * PER_PAGE
	for i in range(from, mini(items.size(), from + PER_PAGE)):
		var id: String = items[i]
		var at = Vector2(36 + (i - from) % COLUMNS * 92, 128 + int((i - from) / COLUMNS) * 96)
		var button = _slot(Rect2(at, Vector2(80, 82)), func(): _pick(id))
		button.tooltip_text = catalog.items[id].name
		if selected == id:
			button.add_theme_stylebox_override("normal", _skin("selected"))
		icon(catalog.items[id].icon, Rect2(16, 10, 48, 48), button)
		var count = _label(str(state.inventory[id]), Rect2(24, 54, 48, 22), 16, INK, false, button)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if items.is_empty():
		_label("这里什么也没有。", Rect2(36, 150, 420, 40), 20, MUTED)
	add_pager(self, Vector2(36, 520), 460, page, pages, _turn)
	_build_detail()
	_button(
		"关闭",
		Rect2(panel_size.x - 226, footer_y(panel_size), 190, 46),
		func(): action_requested.emit("close", {})
	)
	if not storage_mode:
		_button(
			"图志",
			Rect2(panel_size.x - 436, footer_y(panel_size), 190, 46),
			func(): action_requested.emit("collection", {})
		)


func _build_detail() -> void:
	_frame(Rect2(520, 128, panel_size.x - 556, 318), "inset")
	if selected != "":
		var item = catalog.items[selected]
		icon(item.icon, Rect2(548, 142, 64, 64), self)
		_label(item.name, Rect2(630, 148, panel_size.x - 694, 44), 25)
		_label(item.description, Rect2(548, 214, panel_size.x - 612, 80), 19, INK, true)
		_label("持有 %d" % state.inventory[selected], Rect2(548, 302, 180, 32), 19, MUTED)
		if storage_mode:
			_label("箱内 %d" % state.storage[selected], Rect2(548, 338, 360, 32), 19, MUTED)
		if int(item.sell_price) > 0:
			_label("售价 %d G" % item.sell_price, Rect2(panel_size.x - 280, 302, 200, 32), 19, GOLD)
		if int(item.energy) > 0 and not storage_mode:
			var eat = _button(
				"食用 / +%d 体力" % item.energy,
				Rect2(548, 380, 240, 46),
				func():
					action_requested.emit(
						"eat", {"item": selected, "category": category, "page": page}
					)
			)
			eat.disabled = state.inventory[selected] < 1 or state.stamina >= FarmState.MAX_STAMINA
		if storage_mode:
			var put = _button(
				"存入",
				Rect2(548, 380, 150, 46),
				func():
					action_requested.emit(
						"transfer",
						{"id": selected, "deposit": true, "category": category, "page": page}
					)
			)
			put.disabled = state.inventory[selected] == 0
			var take = _button(
				"取出",
				Rect2(712, 380, 150, 46),
				func():
					action_requested.emit(
						"transfer",
						{"id": selected, "deposit": false, "category": category, "page": page}
					)
			)
			take.disabled = state.storage[selected] == 0
	var skills = [
		["种植", "farming_xp"],
		["采集", "foraging_xp"],
		["钓鱼", "fishing_xp"],
		["烹饪", "cooking_xp"],
		["采矿", "mining_xp"]
	]
	for i in skills.size():
		var entry = skills[i]
		ui_icon("leaf", Rect2(528 + i % 3 * 150, 462 + int(i / 3) * 34, 24, 24), self)
		_label(
			"%s Lv.%d" % [entry[0], stories.level(int(state.development[entry[1]]))],
			Rect2(558 + i % 3 * 150, 460 + int(i / 3) * 34, 110, 30),
			16
		)


func _select_category(id: String) -> void:
	category = id
	page = 0
	_build()


func _turn(new_page: int) -> void:
	page = new_page
	_build()


func _pick(id: String) -> void:
	selected = id
	_build()

class_name ShopPanel
extends GameScreen

## A shop counter: buying, selling, and whatever else the shop does (smelting, tool upgrades,
## fishing rods, healing, animals, building). Every action is emitted; the game applies it
## through ShopRules / AnimalRules and reopens this panel on the same tab and page.

const PER_PAGE = 6
const ROW_HEIGHT = 84

var state: FarmState
var rules: ShopRules
var animal_rules: AnimalRules
var shop_id: String
var tab: String
var page: int = 0
var panel_size: Vector2


func open(
	content: ContentCatalog,
	s: FarmState,
	shop_rules: ShopRules,
	animals: AnimalRules,
	id: String,
	first_tab: String,
	first_page: int,
	size_px: Vector2
) -> void:
	catalog = content
	state = s
	rules = shop_rules
	animal_rules = animals
	shop_id = id
	panel_size = size_px
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	var tabs = _tabs()
	tab = first_tab if _has_tab(tabs, first_tab) else tabs[0][0]
	page = first_page
	_build()


func _tabs() -> Array:
	var shop = catalog.shops[shop_id]
	var out: Array = []
	if not shop.goods.is_empty() or shop.get("seeds", "") == "season":
		out.append(["buy", "购买"])
	if not shop.buys.is_empty():
		out.append(["sell", "出售"])
	if shop.get("smelt", false):
		out.append(["smelt", "熔炼"])
	if shop.get("upgrade", false):
		out.append(["upgrade", "工具升级"])
	if shop.get("rods", false):
		out.append(["rod", "鱼竿"])
	if shop.get("heal", false):
		out.append(["heal", "治疗"])
	if shop.get("animals", false):
		out.append(["animals", "动物"])
	if shop.get("build", false):
		out.append(["build", "建造"])
	return out


func _has_tab(tabs: Array, id: String) -> bool:
	for entry in tabs:
		if entry[0] == id:
			return true
	return false


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var shop = catalog.shops[shop_id]
	_label(shop.name, Rect2(36, 16, 560, 44), 28)
	_label("营业 " + rules.hours_text(shop_id), Rect2(36, 56, 300, 26), 16, MUTED)
	ui_icon("coin", Rect2(panel_size.x - 250, 22, 30, 30), self)
	var gold = _label(str(state.gold), Rect2(panel_size.x - 212, 16, 170, 42), 24)
	gold.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_tabs(self, Vector2(36, 88), _tabs(), tab, 130, _select)
	var y = 142.0
	match tab:
		"buy":
			_build_buy(y)
		"sell":
			_build_sell(y)
		"smelt":
			_build_smelt(y)
		"upgrade":
			_build_upgrade(y)
		"rod":
			_build_rod(y)
		"heal":
			_build_heal(y)
		"animals":
			_build_animals(y)
		"build":
			_build_build(y)
	_button(
		"离开",
		Rect2(panel_size.x - 226, panel_size.y - 62, 190, 46),
		func(): action_requested.emit("close", {})
	)


func _select(id: String) -> void:
	tab = id
	page = 0
	_build()


func _turn(new_page: int) -> void:
	page = new_page
	_build()


func _act(action: String, extra: Dictionary = {}) -> void:
	var payload = {"shop": shop_id, "tab": tab, "page": page}
	payload.merge(extra)
	action_requested.emit(action, payload)


func _row(y: float, item_id: String, title: String, detail: String) -> void:
	_frame(Rect2(30, y, panel_size.x - 60, ROW_HEIGHT - 8), "inset")
	icon(catalog.items[item_id].icon, Rect2(46, y + 10, 56, 56), self)
	_label(title, Rect2(118, y + 6, 420, 32), 21)
	_label(detail, Rect2(118, y + 38, 470, 30), 15, MUTED)


func _paged(total: int, y: float, rows: Callable) -> void:
	var from = page * PER_PAGE
	for i in range(from, mini(total, from + PER_PAGE)):
		rows.call(i, y + float(i - from) * ROW_HEIGHT)
	add_pager(
		self,
		Vector2(36, panel_size.y - 62),
		panel_size.x - 300,
		page,
		page_count(total, PER_PAGE),
		_turn
	)


func _build_buy(y: float) -> void:
	var stock = rules.stock(shop_id, state)
	_paged(
		stock.size(),
		y,
		func(i, row_y):
			var entry = stock[i]
			var item = catalog.items[entry.item]
			_row(row_y, entry.item, "%s · %d G" % [item.name, entry.price], item.description)
			var one = _button(
				"买 1 份",
				Rect2(panel_size.x - 340, row_y + 18, 130, 44),
				func(): _act("buy", {"item": entry.item, "qty": 1})
			)
			one.disabled = state.gold < int(entry.price)
			var five = _button(
				"买 5 份",
				Rect2(panel_size.x - 200, row_y + 18, 130, 44),
				func(): _act("buy", {"item": entry.item, "qty": 5})
			)
			five.disabled = state.gold < int(entry.price) * 5
	)


func _owned_for_sale() -> Array:
	var out: Array = []
	for id in catalog.items:
		if rules.buys(shop_id, id) and int(state.inventory[id]) > 0:
			out.append(id)
	return out


func _build_sell(y: float) -> void:
	var owned = _owned_for_sale()
	var quote = rules.sell_quote(state, shop_id)
	if owned.is_empty():
		_label("这里想收的东西，你现在都没有。", Rect2(36, y + 20, 700, 40), 20, MUTED)
		return
	_paged(
		owned.size(),
		y,
		func(i, row_y):
			var id: String = owned[i]
			var item = catalog.items[id]
			_row(
				row_y, id, "%s ×%d" % [item.name, state.inventory[id]], "每份 %d G" % item.sell_price
			)
			_button(
				"卖 1 份",
				Rect2(panel_size.x - 340, row_y + 18, 130, 44),
				func(): _act("sell", {"item": id, "qty": 1})
			)
			_button(
				"全部卖出",
				Rect2(panel_size.x - 200, row_y + 18, 130, 44),
				func(): _act("sell", {"item": id, "qty": int(state.inventory[id])})
			)
	)
	_button(
		"全部出售 / +%d G" % quote.gold,
		Rect2(panel_size.x - 520, panel_size.y - 62, 280, 46),
		func(): _act("sell_all")
	)


func _build_smelt(y: float) -> void:
	var ores = catalog.smelting.keys()
	_label("5 份矿石加 1 份煤，炼成 1 块锭。煤 ×%d" % state.inventory.coal, Rect2(36, y, 800, 30), 17, MUTED)
	for i in ores.size():
		var ore: String = ores[i]
		var bar: String = catalog.smelting[ore]
		var row_y = y + 40.0 + float(i) * ROW_HEIGHT
		_row(
			row_y,
			ore,
			(
				"%s ×%d → %s"
				% [catalog.items[ore].name, state.inventory[ore], catalog.items[bar].name]
			),
			"拥有 %s ×%d" % [catalog.items[bar].name, state.inventory[bar]]
		)
		var button = _button(
			"熔炼",
			Rect2(panel_size.x - 200, row_y + 18, 130, 44),
			func(): _act("smelt", {"ore": ore})
		)
		button.disabled = state.inventory[ore] < 5 or state.inventory.coal < 1


func _build_upgrade(y: float) -> void:
	_label("每升一级，这件工具的体力消耗就少 1；长剑每升一级伤害更高。", Rect2(36, y, 800, 30), 17, MUTED)
	var names = {
		"hoe": "锄头", "axe": "斧头", "pickaxe": "镐", "scythe": "镰刀", "water": "水壶", "sword": "长剑"
	}
	var icons = {
		"hoe": "hoe",
		"axe": "axe",
		"pickaxe": "pickaxe",
		"scythe": "scythe",
		"water": "watering_can",
		"sword": "sword"
	}
	var i = 0
	for tool in FarmState.TOOLS:
		var row_y = y + 36.0 + float(i) * 72.0
		_frame(Rect2(30, row_y, panel_size.x - 60, 64), "inset")
		icon(icons[tool], Rect2(46, row_y + 4, 56, 56), self)
		var level = int(state.development.tools[tool])
		var tier = rules.tool_upgrade_cost(state, tool)
		_label(
			(
				"%s · %s"
				% [names[tool], "初始" if level == 0 else catalog.tool_tiers[level - 1].name + "级"]
			),
			Rect2(118, row_y + 2, 420, 32),
			21
		)
		var need = (
			"已是最高等级"
			if tier.is_empty()
			else (
				"需要 %s ×5 与 %d 金币（有 %d 块）"
				% [catalog.items[tier.bar].name, tier.gold, state.inventory[tier.bar]]
			)
		)
		_label(need, Rect2(118, row_y + 34, 560, 28), 15, MUTED)
		var button = _button(
			"升级",
			Rect2(panel_size.x - 200, row_y + 10, 130, 44),
			func(): _act("upgrade_tool", {"tool": tool})
		)
		button.disabled = (
			tier.is_empty() or state.inventory[tier.bar] < 5 or state.gold < int(tier.gold)
		)
		i += 1


func _build_rod(y: float) -> void:
	var level = int(state.development.rod)
	_label("现在用的是：%s" % catalog.rods[level].name, Rect2(36, y + 6, 800, 36), 22)
	if level + 1 < catalog.rods.size():
		var next = catalog.rods[level + 1]
		_label(
			"下一档：%s · %d 金币。咬钩更快，提竿的时间窗口更宽。" % [next.name, next.price],
			Rect2(36, y + 52, 900, 34),
			18,
			MUTED
		)
		var button = _button("升级鱼竿", Rect2(36, y + 110, 240, 48), func(): _act("upgrade_rod"))
		button.disabled = state.gold < int(next.price)
	else:
		_label("已经是最好的鱼竿了。", Rect2(36, y + 52, 700, 34), 18, MUTED)


func _build_heal(y: float) -> void:
	_label("体力 %d / %d" % [state.stamina, FarmState.MAX_STAMINA], Rect2(36, y + 6, 700, 36), 22)
	_label("安布罗斯医生会给你开一碗热汤，30 金币，体力立刻补满。", Rect2(36, y + 52, 900, 34), 18, MUTED)
	var button = _button("接受治疗 / 30 G", Rect2(36, y + 110, 280, 48), func(): _act("heal"))
	button.disabled = state.stamina >= FarmState.MAX_STAMINA or state.gold < 30


func _build_animals(y: float) -> void:
	var species = catalog.animals.keys()
	_paged(
		species.size(),
		y,
		func(i, row_y):
			var id: String = species[i]
			var spec = catalog.animals[id]
			_row(
				row_y,
				spec.product,
				"%s · %d G" % [spec.name, spec.price],
				"%s %s" % [spec.hint, "（需要%s）" % catalog.buildings[spec.building].name]
			)
			var button = _button(
				"买下",
				Rect2(panel_size.x - 200, row_y + 18, 130, 44),
				func(): _act("buy_animal", {"species": id})
			)
			button.disabled = (
				not animal_rules.built(state, spec.building)
				or state.gold < int(spec.price)
				or (
					animal_rules.housed(state, spec.building)
					>= int(catalog.buildings[spec.building].capacity)
				)
			)
	)


func _build_build(y: float) -> void:
	var ids = catalog.buildings.keys().filter(func(b): return catalog.buildings[b].kind == "animal")
	for i in ids.size():
		var id: String = ids[i]
		var spec = catalog.buildings[id]
		var row_y = y + float(i) * 96.0
		_frame(Rect2(30, row_y, panel_size.x - 60, 88), "inset")
		icon(id, Rect2(46, row_y + 6, 76, 76), self)
		var parts: Array[String] = []
		for material in spec.materials:
			parts.append(
				(
					"%s ×%d（有 %d）"
					% [
						catalog.items[material].name,
						spec.materials[material],
						state.inventory[material]
					]
				)
			)
		_label("%s · %d G" % [spec.name, spec.price], Rect2(138, row_y + 6, 460, 34), 22)
		_label(
			"%s  材料：%s  工期 %d 天" % [spec.hint, "、".join(parts), spec.days],
			Rect2(138, row_y + 44, 700, 34),
			15,
			MUTED
		)
		var label = "建造"
		if animal_rules.built(state, id):
			label = "已建成"
		elif animal_rules.under_construction(state, id):
			label = "施工中"
		var button = _button(
			label, Rect2(panel_size.x - 200, row_y + 22, 130, 44), func(): _act("build", {"id": id})
		)
		button.disabled = state.buildings.has(id)

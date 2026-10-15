class_name FarmRules
extends RefCounted

var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func apply_tool(
	s: FarmState, tool: String, cell: Vector2i, actor: Vector2i, crop_id: String
) -> Dictionary:
	if maxi(absi(cell.x - actor.x), absi(cell.y - actor.y)) > 1:
		return result(false, "靠近一点，只能照料身边一格的土地。")
	if s.current_map != "home_farm" or not catalog.plantable(cell):
		return result(false, "这里不能开垦。选择农场内没有树木、水面和道路的草地。")
	var debris = catalog.debris_at(cell, s)
	if tool in ["scythe", "axe", "pickaxe"]:
		if debris.is_empty():
			return result(false, "这里没有需要清理的杂物。")
		var tools = {"weeds": "scythe", "branch": "axe", "rock": "pickaxe"}
		var names = {"weeds": "镰刀（5）", "branch": "斧头（6）", "rock": "镐（7）"}
		if tool != tools[debris.kind]:
			return result(false, "请用%s清理。" % names[debris.kind])
		var cost = 1 if tool == "scythe" else 3
		if s.stamina < cost:
			return exhausted()
		s.stamina -= cost
		s.cleared.append(debris.id)
		var item = {"weeds": "fiber", "branch": "wood", "rock": "stone"}[debris.kind]
		s.inventory[item] += 1
		s.development.foraging_xp += 2
		return result(
			true, "清出一块空地，获得%s。按 1 翻土。" % catalog.items[item].name, {"cleared_id": debris.id}
		)
	if not debris.is_empty():
		return result(false, "先清理杂物：5 镰刀除草，6 斧头伐枝，7 镐碎石。")
	var key = FarmState.cell_key(cell)
	var p = s.plots.get(key)
	match tool:
		"hoe":
			if p != null:
				return result(false, "这块土地已经翻好了。")
			if s.stamina < 2:
				return exhausted()
			s.plots[key] = {"crop": "", "growth": 0, "watered": false}
			s.stamina -= 2
			s.progress.tilled = true
			return result(true, "土地翻好了。按 2 播种。")
		"seed":
			if p == null:
				return result(false, "先按 1 用锄头翻土。")
			if p.crop != "":
				return result(false, "这里已经有作物了。")
			var c = catalog.crops[crop_id]
			if int(s.inventory[c.seed_item]) < 1:
				return result(false, "种子用完了，可以去右上方小摊购买。")
			if s.stamina < 1:
				return exhausted()
			s.inventory[c.seed_item] -= 1
			p.crop = crop_id
			p.growth = 0
			s.stamina -= 1
			s.progress.planted = true
			return result(true, "种下了%s。按 3 浇水。" % c.name)
		"water":
			if p == null:
				return result(false, "先翻土，再浇水。")
			if p.watered:
				return result(false, "今天已经浇过水了。")
			if s.stamina < 1:
				return exhausted()
			p.watered = true
			if int(s.development.watering_level) > 0:
				for side in [Vector2i.LEFT, Vector2i.RIGHT]:
					var adjacent = s.plots.get(FarmState.cell_key(cell + side))
					if adjacent != null:
						adjacent.watered = true
			s.stamina -= 1
			s.progress.watered = true
			return result(true, "浇好水了，睡一觉就会生长。")
		"harvest":
			if p == null or p.crop == "":
				return result(false, "这里还没有可以收获的作物。")
			var c = catalog.crops[p.crop]
			if int(p.growth) < int(c.growth_days):
				return result(
					false, "%s还需要 %d 个浇水日。" % [c.name, int(c.growth_days) - int(p.growth)]
				)
			s.inventory[c.harvest_item] += int(c.yield)
			p.crop = ""
			p.growth = 0
			s.progress.harvested = true
			s.development.farming_xp += 10
			return result(true, "收获了%s！屋前收货箱可以出售。" % c.name, {"harvest": c.harvest_item})
	return result(false, "未知工具。")


func next_day(s: FarmState) -> Dictionary:
	var grew = 0
	var ready = 0
	for p in s.plots.values():
		if p.crop != "":
			var days = int(catalog.crops[p.crop].growth_days)
			if p.watered and int(p.growth) < days:
				p.growth += 1
				grew += 1
			if int(p.growth) >= days:
				ready += 1
		p.watered = false
	s.daily = {"talked": [], "gifted": [], "gathered": []}
	s.day += 1
	s.minute = FarmState.MORNING
	s.stamina = FarmState.MAX_STAMINA
	s.progress.slept = true
	return result(
		true, "第 %d 天 · %d 株生长，%d 株可收获。" % [s.day, grew, ready], {"grew": grew, "ready": ready}
	)


func buy_seeds(s: FarmState, crop_id: String, quantity: int = 1) -> Dictionary:
	if quantity < 1 or quantity > 99 or not catalog.crops.has(crop_id):
		return result(false, "购买数量或作物无效。")
	var c = catalog.crops[crop_id]
	var cost = int(catalog.items[c.seed_item].buy_price) * quantity
	if s.gold < cost:
		return result(false, "金币不够。先收获并出售一些作物吧。")
	s.gold -= cost
	s.inventory[c.seed_item] += quantity
	return result(true, "买到了 %d 份%s种子。" % [quantity, c.name])


func sale_quote(s: FarmState) -> Dictionary:
	var gold = 0
	var count = 0
	for id in catalog.items:
		var item = catalog.items[id]
		if item.kind == "produce":
			count += int(s.inventory[id])
			gold += int(s.inventory[id]) * int(item.sell_price)
	return {"gold": gold, "count": count}


func sell_produce(s: FarmState) -> Dictionary:
	var quote = sale_quote(s)
	if quote.count == 0:
		return result(false, "背包里还没有农产品，按 4 收获成熟作物。")
	for id in catalog.items:
		if catalog.items[id].kind == "produce":
			s.inventory[id] = 0
	s.gold += int(quote.gold)
	s.progress.sold = true
	return result(true, "出售了 %d 份农产品，获得 %d 金币。" % [quote.count, quote.gold])


func exhausted() -> Dictionary:
	return result(false, "体力不足。去左上方小屋休息，或在菜单中结束一天。")


func result(ok: bool, message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r

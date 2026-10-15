class_name FarmRules
extends RefCounted

const CLEARING = {
	"weeds": {"tool": "scythe", "cost": 1, "item": "fiber"},
	"branch": {"tool": "axe", "cost": 3, "item": "wood"},
	"rock": {"tool": "pickaxe", "cost": 3, "item": "stone"}
}
var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func apply_tool(
	s: FarmState, tool: String, cell: Vector2i, actor: Vector2i, crop_id: String
) -> Dictionary:
	if maxi(absi(cell.x - actor.x), absi(cell.y - actor.y)) > 1:
		return result(false)
	var tree_id = catalog.tree_at(cell, s)
	if not tree_id.is_empty():
		return _chop(s, tool, tree_id)
	if s.current_map != "home_farm" or not catalog.plantable(cell, s.tree_damage):
		return result(false)
	var debris = catalog.debris_at(cell, s)
	if not debris.is_empty():
		return _clear(s, tool, debris)
	var key = FarmState.cell_key(cell)
	var plot = s.plots.get(key)
	match tool:
		"hoe":
			return _till(s, key, plot)
		"seed":
			return _plant(s, plot, crop_id)
		"water":
			return _water(s, plot, cell)
		"harvest":
			return _harvest(s, plot)
	return result(false)


func _chop(s: FarmState, tool: String, id: String) -> Dictionary:
	if tool != "axe":
		return result(false)
	if s.stamina < 3:
		return exhausted()
	s.stamina -= 3
	var hits = int(s.tree_damage.get(id, 0)) + 1
	s.tree_damage[id] = hits
	var amount = 4 if hits == 3 else (1 if hits == 5 else 0)
	s.inventory.wood += amount
	s.development.foraging_xp += 2
	return result(true, "+%d 木材" % amount if amount else "", {"tree_id": id, "tree_hits": hits})


func _clear(s: FarmState, tool: String, debris: Dictionary) -> Dictionary:
	var clearing = CLEARING[debris.kind]
	if tool != clearing.tool:
		return result(false)
	if s.stamina < clearing.cost:
		return exhausted()
	s.stamina -= clearing.cost
	s.cleared.append(debris.id)
	s.inventory[clearing.item] += 1
	s.development.foraging_xp += 2
	return result(true, "+1 " + catalog.items[clearing.item].name, {"cleared_id": debris.id})


func _till(s: FarmState, key: String, plot: Variant) -> Dictionary:
	if plot != null:
		return result(false)
	if s.stamina < 2:
		return exhausted()
	s.plots[key] = {"crop": "", "growth": 0, "watered": false}
	s.stamina -= 2
	s.progress.tilled = true
	return result(true)


func _plant(s: FarmState, plot: Variant, crop_id: String) -> Dictionary:
	if plot == null or plot.crop != "":
		return result(false)
	var crop = catalog.crops[crop_id]
	if s.inventory[crop.seed_item] < 1:
		return result(false, "没有种子")
	if s.stamina < 1:
		return exhausted()
	s.inventory[crop.seed_item] -= 1
	plot.crop = crop_id
	plot.growth = 0
	s.stamina -= 1
	s.progress.planted = true
	return result(true)


func _water(s: FarmState, plot: Variant, cell: Vector2i) -> Dictionary:
	if plot == null or plot.watered:
		return result(false)
	if s.stamina < 1:
		return exhausted()
	plot.watered = true
	if s.development.watering_level > 0:
		for side in [Vector2i.LEFT, Vector2i.RIGHT]:
			var adjacent = s.plots.get(FarmState.cell_key(cell + side))
			if adjacent != null:
				adjacent.watered = true
	s.stamina -= 1
	s.progress.watered = true
	return result(true)


func _harvest(s: FarmState, plot: Variant) -> Dictionary:
	if plot == null or plot.crop == "":
		return result(false)
	var crop = catalog.crops[plot.crop]
	if plot.growth < crop.growth_days:
		return result(false)
	s.inventory[crop.harvest_item] += int(crop.yield)
	plot.crop = ""
	plot.growth = 0
	s.progress.harvested = true
	s.development.farming_xp += 10
	return result(true, "+%d %s" % [crop.yield, crop.name], {"harvest": crop.harvest_item})


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
		return result(false, "金币不足")
	s.gold -= cost
	s.inventory[c.seed_item] += quantity
	return result(true, "+%d %s种子" % [quantity, c.name])


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
		return result(false, "没有可出售的农产品")
	for id in catalog.items:
		if catalog.items[id].kind == "produce":
			s.inventory[id] = 0
	s.gold += int(quote.gold)
	s.progress.sold = true
	return result(true, "出售 %d 份农产品 · +%d G" % [quote.count, quote.gold])


func exhausted() -> Dictionary:
	return result(false, "体力不足")


func result(ok: bool, message: String = "", extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r

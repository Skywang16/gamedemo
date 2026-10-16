class_name FarmRules
extends RefCounted

const CLEARING = {
	"weeds": {"tool": "scythe", "cost": 1, "item": "fiber"},
	"branch": {"tool": "axe", "cost": 3, "item": "wood"},
	"rock": {"tool": "pickaxe", "cost": 3, "item": "stone"}
}
var catalog: ContentCatalog
var stories: StoryRules


func _init(content: ContentCatalog) -> void:
	catalog = content
	stories = StoryRules.new(content)


## Stamina a tool costs: one less per upgrade level, never below one.
func cost(s: FarmState, tool: String, base: int) -> int:
	return maxi(1, base - int(s.development.tools.get(tool, 0)))


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
	var price = cost(s, "axe", 3)
	if s.stamina < price:
		return exhausted()
	s.stamina -= price
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
	var price = cost(s, tool, int(clearing.cost))
	if s.stamina < price:
		return exhausted()
	s.stamina -= price
	s.cleared.append(debris.id)
	s.inventory[clearing.item] += 1
	s.development.foraging_xp += 2
	return result(true, "+1 " + catalog.items[clearing.item].name, {"cleared_id": debris.id})


func _till(s: FarmState, key: String, plot: Variant) -> Dictionary:
	if plot != null:
		return result(false)
	var price = cost(s, "hoe", 2)
	if s.stamina < price:
		return exhausted()
	s.plots[key] = {"crop": "", "growth": 0, "watered": false}
	s.stamina -= price
	s.progress.tilled = true
	return result(true)


func _plant(s: FarmState, plot: Variant, crop_id: String) -> Dictionary:
	if plot == null or plot.crop != "":
		return result(false)
	var crop = catalog.crops[crop_id]
	var season = catalog.calendar.date(s.day)
	if not crop.seasons.has(season.season) and not stories.greenhouse(s):
		return result(false, "%s不适合在%s天种" % [crop.name, season.season_name])
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
	var reach = int(s.development.tools.water)
	for step in range(1, reach + 1):
		for side in [Vector2i(-step, 0), Vector2i(step, 0)]:
			var neighbour = s.plots.get(FarmState.cell_key(cell + side))
			if neighbour != null:
				neighbour.watered = true
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
	if int(crop.regrow) > 0:
		plot.growth = int(crop.growth_days) - int(crop.regrow)
	else:
		plot.crop = ""
		plot.growth = 0
	s.progress.harvested = true
	s.stats.harvested += int(crop.yield)
	s.development.farming_xp += 10
	return result(true, "+%d %s" % [crop.yield, crop.name], {"harvest": crop.harvest_item})


# ---------------------------------------------------------------------------- the day


func next_day(s: FarmState) -> Dictionary:
	var grew = 0
	for p in s.plots.values():
		if p.crop != "":
			var days = int(catalog.crops[p.crop].growth_days)
			if p.watered and int(p.growth) < days:
				p.growth += 1
				grew += 1
		p.watered = false
	s.daily = {"talked": [], "gifted": [], "gathered": []}
	var old_season = catalog.calendar.season_of(s.day)
	s.day += 1
	s.minute = FarmState.MORNING
	s.stamina = FarmState.MAX_STAMINA
	s.progress.slept = true
	var season = catalog.calendar.season_of(s.day)
	var withered = 0
	if season != old_season and not stories.greenhouse(s):
		withered = _wither_out_of_season(s, season)
	var weather = catalog.weather.weather_on(s.world_seed, s.day)
	if catalog.weather.waters_crops(weather) or stories.canal_flowing(s):
		for p in s.plots.values():
			p.watered = true
	var ready = 0
	for p in s.plots.values():
		if p.crop != "" and int(p.growth) >= int(catalog.crops[p.crop].growth_days):
			ready += 1
	var summary = s.stats.duplicate()
	s.stats = FarmState.fresh_stats()
	return result(
		true,
		"第 %d 天 · %d 株生长，%d 株可收获。" % [s.day, grew, ready],
		{
			"grew": grew,
			"ready": ready,
			"weather": weather,
			"season_changed": season != old_season,
			"withered": withered,
			"summary": summary,
		}
	)


func _wither_out_of_season(s: FarmState, season: String) -> int:
	var count = 0
	for p in s.plots.values():
		if p.crop != "" and not catalog.crops[p.crop].seasons.has(season):
			p.crop = ""
			p.growth = 0
			count += 1
	return count


# ---------------------------------------------------------------------------- selling and eating


func sale_quote(s: FarmState) -> Dictionary:
	var gold = 0
	var count = 0
	for id in catalog.items:
		var item = catalog.items[id]
		if item.kind in ContentCatalog.SELLABLE:
			count += int(s.inventory[id])
			gold += int(s.inventory[id]) * int(item.sell_price)
	return {"gold": gold, "count": count}


func sell_produce(s: FarmState) -> Dictionary:
	var quote = sale_quote(s)
	if quote.count == 0:
		return result(false, "没有可出售的东西")
	for id in catalog.items:
		if catalog.items[id].kind in ContentCatalog.SELLABLE:
			s.inventory[id] = 0
	s.gold += int(quote.gold)
	s.stats.earned += int(quote.gold)
	s.progress.sold = true
	return result(true, "出售 %d 件 · +%d G" % [quote.count, quote.gold])


func eat(s: FarmState, item_id: String) -> Dictionary:
	var item = catalog.items[item_id]
	if int(item.energy) < 1 or s.inventory[item_id] < 1:
		return result(false, "这个不能吃。")
	if s.stamina >= FarmState.MAX_STAMINA:
		return result(false, "现在体力充沛，饿了再吃吧。")
	s.inventory[item_id] -= 1
	s.stamina = mini(FarmState.MAX_STAMINA, s.stamina + int(item.energy))
	return result(true, "吃下%s，恢复 %d 体力。" % [item.name, item.energy])


## Adds everything the player holds to the collection log. Returns the new entries.
func record_collection(s: FarmState) -> Array:
	var fresh: Array = []
	for id in catalog.items:
		if (int(s.inventory[id]) > 0 or int(s.storage[id]) > 0) and not s.collected.has(id):
			s.collected.append(id)
			fresh.append(id)
	return fresh


func exhausted() -> Dictionary:
	return result(false, "体力不足")


func result(ok: bool, message: String = "", extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r

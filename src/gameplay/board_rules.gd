class_name BoardRules
extends RefCounted

## The town notice board: four requests a week, the same for a given world seed and week.

const REQUESTS = 4

var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}


func week_of(day: int) -> int:
	return int((day - 1) / 7)


## Items that can plausibly be found this season, cheapest first.
func wanted_items(s: FarmState) -> Array:
	var season = catalog.calendar.season_of(s.day)
	var pool: Array = []
	for id in catalog.crops:
		if catalog.crops[id].seasons.has(season):
			pool.append(catalog.crops[id].harvest_item)
	for id in catalog.fish:
		if catalog.fish[id].seasons.has(season) and int(catalog.fish[id].difficulty) <= 3:
			pool.append(id)
	for table in ["forest", "lake"]:
		var entries = catalog.gather_tables[table].get(season, [])
		for entry in entries:
			pool.append(entry[0])
	pool.sort()
	return pool


func requests(s: FarmState) -> Array:
	var pool = wanted_items(s)
	var villagers = catalog.story.npcs.keys()
	villagers.sort()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("board:%d:%d" % [s.world_seed, week_of(s.day)])
	var out: Array = []
	for i in REQUESTS:
		var item: String = pool[rng.randi_range(0, pool.size() - 1)]
		var who: String = villagers[rng.randi_range(0, villagers.size() - 1)]
		var count = rng.randi_range(1, 3)
		var price = int(catalog.items[item].sell_price)
		(
			out
			. append(
				{
					"npc": who,
					"item": item,
					"count": count,
					"gold": int(price * count * 1.6) + 10,
					"friendship": 6,
				}
			)
		)
	return out


## Starts a new week's board when the week has changed.
func refresh(s: FarmState) -> void:
	if int(s.board.week) != week_of(s.day):
		s.board = {"week": week_of(s.day), "done": []}


func deliver(s: FarmState, index: int) -> Dictionary:
	refresh(s)
	if index < 0 or index >= REQUESTS or index in s.board.done:
		return result(false, "这份委托已经完成了。")
	var r = requests(s)[index]
	if s.inventory[r.item] < int(r.count):
		return result(false, "还需要 %s ×%d。" % [catalog.items[r.item].name, int(r.count)])
	s.inventory[r.item] -= int(r.count)
	s.gold += int(r.gold)
	s.stats.earned += int(r.gold)
	s.relationships[r.npc] = mini(100, int(s.relationships[r.npc]) + int(r.friendship))
	s.board.done.append(index)
	return result(true, "%s道了谢。+%d G" % [catalog.story.npcs[r.npc].name, int(r.gold)])

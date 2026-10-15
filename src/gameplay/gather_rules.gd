class_name GatherRules
extends RefCounted

## Which item a gather node holds today. Fixed nodes hold one item (optionally changing with
## the season); table nodes roll from data/gather_tables.json, seeded by the world seed, the
## day and the node, so the same day always shows the same item.


static func item_for(catalog: ContentCatalog, s: FarmState, node: Dictionary) -> String:
	var season = catalog.calendar.season_of(s.day)
	if node.has("item"):
		return node.get("seasonal", {}).get(season, node.item)
	var table: Dictionary = catalog.gather_tables[node.table]
	var entries: Array = table[season] if table.has(season) else table.any
	var total = 0
	for entry in entries:
		total += int(entry[1])
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("%d:%s:%d" % [s.world_seed, node.id, s.day])
	var roll = rng.randi_range(0, total - 1)
	for entry in entries:
		roll -= int(entry[1])
		if roll < 0:
			return entry[0]
	return entries[0][0]


static func is_mine(node: Dictionary) -> bool:
	return node.has("table") and str(node.table).begins_with("mine_")

class_name ContentCatalog
extends RefCounted

var items: Dictionary = {}
var crops: Dictionary = {}
var map: Dictionary = {}
var regions: Dictionary = {}
var story: Dictionary = {}
var blocked_cells: Dictionary = {}
var debris_ids: Dictionary = {}
var debris_cells: Dictionary = {}
var tree_ids: Dictionary = {}
var tree_cells: Dictionary = {}


func load_content() -> String:
	for pair in [
		["items", "res://data/items.json"],
		["crops", "res://data/crops.json"],
		["story", "res://data/story.json"]
	]:
		var value = JSON.parse_string(FileAccess.get_file_as_string(pair[1]))
		if not value is Dictionary:
			return "配置文件无法解析：" + pair[1]
		set(pair[0], value)
	for id in items:
		var item = items[id]
		if (
			not item is Dictionary
			or not item.has_all(["name", "kind", "buy_price", "sell_price", "icon", "description"])
		):
			return "物品配置不完整：" + id
		if (
			not item.name is String
			or not item.description is String
			or not item.icon is String
			or item.kind not in ["seed", "produce", "material"]
		):
			return "物品类型无效：" + id
		if (
			not natural(item.buy_price)
			or not natural(item.sell_price)
			or (item.kind == "seed" and item.buy_price < 1)
		):
			return "物品价格无效：" + id
		if not ResourceLoader.exists("res://assets/art/%s.png" % item.icon):
			return "物品图标不存在：" + id
	if crops.is_empty():
		return "至少需要一种作物"
	for id in crops:
		var c = crops[id]
		if (
			not c is Dictionary
			or not c.has_all(
				["name", "seed_item", "harvest_item", "growth_days", "yield", "stages"]
			)
		):
			return "作物配置不完整：" + id
		if not c.name is String or not items.has(c.seed_item) or not items.has(c.harvest_item):
			return "作物引用或生长配置无效：" + id
		if items[c.seed_item].kind != "seed" or items[c.harvest_item].kind != "produce":
			return "作物的种子/收获物类型错误：" + id
		if not natural(c.growth_days) or c.growth_days < 1 or not natural(c.yield) or c.yield < 1:
			return "作物生长天数或产量错误：" + id
		if not c.stages is Array or c.stages.size() < 2:
			return "作物阶段图片不足：" + id
		for texture in c.stages:
			if (
				not texture is String
				or not ResourceLoader.exists("res://assets/art/%s.png" % texture)
			):
				return "作物图片不存在：" + id
	var index = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/index.json"))
	if not index is Dictionary or not index.get("maps") is Array:
		return "地图索引无效"
	for id in index.maps:
		if not id is String or not id.is_valid_identifier():
			return "地图 ID 无效"
		var value = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % id))
		if not value is Dictionary:
			return "地图无法解析：" + id
		regions[id] = value
	if not regions.has("home_farm"):
		return "缺少农场地图"
	map = regions.home_farm
	if not map.has_all(["plantable", "starting_inventory", "starting_gold"]):
		return "农场配置不完整"
	if (
		not numeric_array(map.plantable, 4)
		or not map.starting_inventory is Dictionary
		or not natural(map.starting_gold)
	):
		return "农场配置无效"
	for item in map.starting_inventory:
		if not items.has(item) or not natural(map.starting_inventory[item]):
			return "初始物品无效"
	for id in regions:
		var area = regions[id]
		if not area.has_all(
			[
				"id",
				"name",
				"width",
				"height",
				"tile_size",
				"spawn",
				"obstacles",
				"trees",
				"props",
				"stations",
				"background"
			]
		):
			return "地图字段不完整：" + id
		if (
			area.id != id
			or not natural(area.width)
			or not natural(area.height)
			or area.width < 16
			or area.height < 16
			or area.width > 256
			or area.height > 256
			or area.tile_size != 32
		):
			return "地图尺寸无效：" + id
		if not numeric_array(area.spawn, 2):
			return "出生点无效：" + id
		if not ResourceLoader.exists("res://assets/art/%s.png" % area.background):
			return "缺少地图背景：" + id
		for field in ["obstacles", "trees", "props", "stations", "debris", "gather"]:
			if not area.get(field, []) is Array:
				return "地图列表无效：" + id + "/" + field
		var cells: Dictionary = {}
		for r in area.obstacles:
			if not numeric_array(r, 4):
				return "碰撞范围无效：" + id
			for y in range(int(r[1]), int(r[1] + r[3])):
				for x in range(int(r[0]), int(r[0] + r[2])):
					cells[Vector2i(x, y)] = true
		tree_cells[id] = {}
		for at in area.trees:
			if not numeric_array(at, 2):
				return "树木坐标无效：" + id
			var cell = Vector2i(at[0], at[1])
			var tree_id = id + ":" + FarmState.cell_key(cell)
			tree_ids[tree_id] = {"map": id, "cell": cell}
			tree_cells[id][cell] = tree_id
		blocked_cells[id] = cells
		for prop in area.props:
			if (
				not prop is Dictionary
				or not prop.has_all(["texture", "ground", "offset"])
				or not numeric_array(prop.ground, 2)
				or not numeric_array(prop.offset, 2)
			):
				return "场景物件无效：" + id
			if not ResourceLoader.exists("res://assets/art/%s.png" % prop.texture):
				return "场景物件素材缺失：" + prop.texture
		var station_ids: Array = []
		for station in area.stations:
			if (
				not station is Dictionary
				or not station.has_all(["id", "name", "kind", "cell"])
				or not numeric_array(station.cell, 2)
				or station_ids.has(station.id)
			):
				return "交互点无效：" + id
			station_ids.append(station.id)
			if (
				station.kind
				not in [
					"exit",
					"bed",
					"shop",
					"shipping",
					"bridge",
					"board",
					"lantern",
					"letter",
					"storage",
					"kitchen",
					"upgrade"
				]
			):
				return "交互类型无效：" + id
			if (
				station.kind == "exit"
				and (
					not station.has_all(["destination", "arrival"])
					or not regions.has(station.destination)
					or not numeric_array(station.arrival, 2)
				)
			):
				return "出口无效：" + id
		for node in area.get("gather", []):
			if (
				not node is Dictionary
				or not node.has_all(["id", "item", "cell"])
				or not items.has(node.item)
				or not numeric_array(node.cell, 2)
			):
				return "采集物无效：" + id
		for node in area.get("debris", []):
			if (
				not node is Dictionary
				or not node.has_all(["id", "kind", "cell", "variant"])
				or not numeric_array(node.cell, 2)
				or node.kind not in ["weeds", "branch", "rock"]
				or not natural(node.variant)
				or node.variant > 2
				or debris_ids.has(node.id)
			):
				return "荒地障碍配置无效：" + id
			debris_ids[node.id] = node
			debris_cells[Vector2i(node.cell[0], node.cell[1])] = node
	if (
		not story.has_all(["npcs", "quests", "scenes"])
		or not story.npcs is Dictionary
		or not story.quests is Array
		or not story.scenes is Dictionary
		or story.quests.size() != 7
	):
		return "剧情配置不完整"
	for quest in story.quests:
		if (
			not quest is Dictionary
			or not quest.has_all(["title", "where", "hint", "needs"])
			or not quest.needs is Dictionary
		):
			return "任务配置不完整"
		for item in quest.needs:
			if not items.has(item) or not natural(quest.needs[item]):
				return "任务物品引用无效"
	for event in story.scenes:
		if not story.scenes.get(event) is Array or story.scenes[event].is_empty():
			return "缺少剧情场景：" + event
		for page in story.scenes[event]:
			if (
				not page is Array
				or page.size() != 2
				or not page[0] is String
				or not page[1] is String
			):
				return "对白格式无效：" + event
			if page[0] not in ["letter", "narrator"] and not story.npcs.has(page[0]):
				return "对白人物不存在：" + event
	for id in story.npcs:
		var npc = story.npcs[id]
		if (
			not npc is Dictionary
			or not npc.has_all(
				[
					"name",
					"map",
					"positions",
					"favorite",
					"sprite",
					"portrait",
					"talk",
					"bio",
					"after",
					"role"
				]
			)
		):
			return "人物配置不完整：" + id
		if (
			not npc.positions is Array
			or npc.positions.size() != 2
			or not npc.talk is Array
			or npc.talk.is_empty()
		):
			return "人物日程或对白无效：" + id
		for picture in [npc.sprite, npc.portrait]:
			if not ResourceLoader.exists("res://assets/art/%s.png" % picture):
				return "人物素材不存在：" + id
		if not regions.has(npc.map) or not items.has(npc.favorite):
			return "人物引用无效：" + id
		for pos in npc.positions:
			if not numeric_array(pos, 2) or blocked(Vector2i(pos[0], pos[1]), npc.map):
				return "人物位置不可站立：" + id
	return ""


func region(id: String) -> Dictionary:
	return regions[id]


func npc_cell(id: String, minute: int) -> Vector2i:
	var points = story.npcs[id].positions
	var p = points[0 if minute < 14 * 60 else 1]
	return Vector2i(p[0], p[1])


static func avatar_path(profile: Dictionary) -> String:
	return (
		"res://assets/art/avatar_%d_%d_%d_%d.png"
		% [profile.skin, profile.hair, profile.outfit, profile.hat]
	)


func natural(value: Variant) -> bool:
	return (
		(value is int or value is float)
		and is_finite(float(value))
		and value >= 0
		and float(value) == floor(float(value))
	)


func numeric_array(value: Variant, length: int) -> bool:
	if not value is Array or value.size() != length:
		return false
	for number in value:
		if (
			not (number is int or number is float)
			or not is_finite(float(number))
			or float(number) != floor(float(number))
		):
			return false
	return true


func plantable(cell: Vector2i, tree_damage: Dictionary = {}) -> bool:
	var r = map.plantable
	if (
		not Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])).has_point(cell)
		or blocked(cell, "home_farm", tree_damage)
	):
		return false
	for path in map.no_plant:
		if Rect2i(int(path[0]), int(path[1]), int(path[2]), int(path[3])).has_point(cell):
			return false
	return true


func blocked(cell: Vector2i, map_id: String = "home_farm", tree_damage: Dictionary = {}) -> bool:
	var tree_id = tree_cells[map_id].get(cell, "")
	return static_blocked(cell, map_id) or (tree_id != "" and tree_damage.get(tree_id, 0) < 5)


func static_blocked(cell: Vector2i, map_id: String) -> bool:
	var area = regions[map_id]
	return (
		cell.x <= 0
		or cell.y <= 0
		or cell.x >= int(area.width) - 1
		or cell.y >= int(area.height) - 1
		or blocked_cells[map_id].has(cell)
	)


func tree_at(cell: Vector2i, state: FarmState) -> String:
	var id: String = tree_cells[state.current_map].get(cell, "")
	return id if state.tree_damage.get(id, 0) < 5 else ""


func debris_at(cell: Vector2i, state: FarmState) -> Dictionary:
	if state.current_map != "home_farm":
		return {}
	var node = debris_cells.get(cell, {})
	return {} if node.is_empty() or state.cleared.has(node.id) else node


func crop_texture(crop_id: String, growth: int) -> String:
	var c = crops[crop_id]
	var index = mini(
		c.stages.size() - 1, int(float(growth) / float(c.growth_days) * (c.stages.size() - 1))
	)
	return c.stages[index]

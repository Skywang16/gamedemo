class_name SaveValidator
extends RefCounted

var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func validate(data: Variant) -> String:
	# All untrusted disk values are checked here, once, before entering the domain.
	if not data is Dictionary:
		return "存档不是对象"
	if not data.has_all(
		[
			"schema_version",
			"map_id",
			"day",
			"minute",
			"stamina",
			"gold",
			"inventory",
			"plots",
			"progress",
			"player_position"
		]
	):
		return "存档字段不完整"
	if (
		not whole(data.schema_version, FarmState.SCHEMA_VERSION, FarmState.SCHEMA_VERSION)
		or not data.map_id is String
		or not catalog.regions.has(data.map_id)
	):
		return "存档版本或地图不兼容"
	if (
		not whole(data.day, 1, 999999)
		or not whole(data.minute, FarmState.MORNING, FarmState.NIGHT - 1)
	):
		return "日期或时间无效"
	if not whole(data.stamina, 0, FarmState.MAX_STAMINA) or not whole(data.gold, 0, 1000000000):
		return "体力或金币无效"
	if not data.inventory is Dictionary or data.inventory.size() != catalog.items.size():
		return "背包结构无效"
	for id in data.inventory:
		if not catalog.items.has(id) or not whole(data.inventory[id], 0, 1000000):
			return "物品数量无效"
	if (
		not data.plots is Dictionary
		or data.plots.size() > int(catalog.map.width) * int(catalog.map.height)
	):
		return "地块结构无效"
	for key in data.plots:
		if not key is String:
			return "地块坐标无效"
		var coords = key.split(",")
		if coords.size() != 2 or not coords[0].is_valid_int() or not coords[1].is_valid_int():
			return "地块坐标无效"
		var cell = FarmState.key_cell(key)
		if FarmState.cell_key(cell) != key or not catalog.plantable(cell):
			return "地块超出农田"
		var p = data.plots[key]
		if not p is Dictionary or not p.has_all(["crop", "growth", "watered"]):
			return "地块数据不完整"
		if not p.crop is String or not p.watered is bool:
			return "地块数据类型无效"
		if p.crop != "" and not catalog.crops.has(p.crop):
			return "未知作物"
		var max_growth = 0 if p.crop == "" else int(catalog.crops[p.crop].growth_days)
		if not whole(p.growth, 0, max_growth):
			return "生长天数无效"
	if not data.progress is Dictionary:
		return "引导进度无效"
	for goal in FarmState.GOALS:
		if not data.progress.has(goal) or not data.progress[goal] is bool:
			return "引导进度无效"
	if not data.get("cleared") is Array:
		return "开垦记录无效"
	var cleared_ids: Dictionary = {}
	for id in data.cleared:
		if not id is String or not catalog.debris_ids.has(id) or cleared_ids.has(id):
			return "开垦记录重复或无效"
		cleared_ids[id] = true
	for key in data.plots:
		var node = catalog.debris_cells.get(FarmState.key_cell(key), {})
		if not node.is_empty() and not cleared_ids.has(node.id):
			return "地块仍有杂物"
	var character_error = validate_character(data)
	if not character_error.is_empty():
		return character_error
	var pos = data.player_position
	if not pos is Array or pos.size() != 2 or not numeric(pos[0]) or not numeric(pos[1]):
		return "角色位置无效"
	if (
		pos[0] < 32
		or pos[1] < 32
		or pos[0] >= (int(catalog.region(data.map_id).width) - 1) * 32
		or pos[1] >= (int(catalog.region(data.map_id).height) - 1) * 32
	):
		return "角色超出地图"
	if catalog.blocked(Vector2i(int(pos[0] / 32), int(pos[1] / 32)), data.map_id):
		return "角色位于障碍物内"
	return ""


func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func whole(value: Variant, low: int, high: int) -> bool:
	return numeric(value) and value >= low and value <= high and float(value) == floor(float(value))


func validate_character(data: Dictionary) -> String:
	for field in ["profile", "narrative", "relationships", "daily", "development", "storage"]:
		if not data.get(field) is Dictionary:
			return "人物存档字段无效：" + field
	var p = data.profile
	if not p.has_all(["name", "farm", "skin", "hair", "outfit", "hat"]):
		return "人物资料不完整"
	for key in ["name", "farm"]:
		if (
			not p[key] is String
			or p[key].strip_edges().is_empty()
			or p[key].length() > (12 if key == "name" else 18)
			or p[key].contains("\n")
		):
			return "人物姓名或农场名称无效"
	if (
		not whole(p.skin, 0, 2)
		or not whole(p.hair, 0, 2)
		or not whole(p.outfit, 0, 3)
		or not whole(p.hat, 0, 1)
	):
		return "人物外观无效"
	var n = data.narrative
	if not n.has_all(["stage", "intro_seen", "intent", "wish", "active_scene", "page"]):
		return "剧情状态不完整"
	if (
		not whole(n.stage, 0, 6)
		or not n.intro_seen is bool
		or n.intent not in ["", "grow", "restart"]
		or n.wish not in ["", "stay", "explore", "together"]
	):
		return "剧情状态无效"
	var scene_ids = catalog.story.scenes.keys()
	if (
		not n.active_scene is String
		or (n.active_scene != "" and not scene_ids.has(n.active_scene))
		or not whole(n.page, 0, 20)
	):
		return "对话记录无效"
	if n.stage == 6 and n.wish == "":
		return "缺少结局选择"
	if data.map_id == "lake" and n.stage < 3:
		return "湖畔尚未解锁"
	for id in catalog.story.npcs:
		if not data.relationships.has(id) or not whole(data.relationships[id], 0, 100):
			return "人物关系无效"
	for field in ["talked", "gifted", "gathered"]:
		if not data.daily.get(field) is Array:
			return "每日记录无效"
		var seen: Array = []
		for id in data.daily[field]:
			if not id is String or seen.has(id):
				return "每日记录重复或无效"
			seen.append(id)
			if field != "gathered" and not catalog.story.npcs.has(id):
				return "未知人物"
			if field == "gathered":
				var found = false
				for node in catalog.regions.forest.gather:
					if node.id == id:
						found = true
				if not found:
					return "未知采集点"
	var d = data.development
	if not d.has_all(["farming_xp", "foraging_xp", "watering_level", "memories"]):
		return "成长字段不完整"
	if (
		not whole(d.farming_xp, 0, 1000000000)
		or not whole(d.foraging_xp, 0, 1000000000)
		or not whole(d.watering_level, 0, 1)
		or not d.memories is Array
	):
		return "成长数据无效"
	var memories: Array = []
	for id in d.memories:
		if not catalog.story.npcs.has(id) or memories.has(id):
			return "人物回忆无效"
		memories.append(id)
	if data.storage.size() != catalog.items.size():
		return "储物字段不完整"
	for id in data.storage:
		if not catalog.items.has(id) or not whole(data.storage[id], 0, 1000000):
			return "储物数量无效"
	return ""

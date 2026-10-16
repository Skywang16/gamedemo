class_name ContentCatalog
extends RefCounted

## Loads and strictly validates every data file. Anything malformed is an error string; the
## game refuses to start rather than guessing.

const ITEM_KINDS = ["seed", "produce", "material", "fish", "forage", "mineral", "dish", "drop"]
const SELLABLE = ["produce", "fish", "forage", "mineral", "dish", "drop"]
const STATION_KINDS = [
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
	"ferry",
	"story",
	"inspect"
]
const BACKDROPS = [
	"farm",
	"town",
	"market",
	"ranch",
	"seaside",
	"forest",
	"lake",
	"greenhouse",
	"river",
	"shore",
	"canal",
	"stage",
	"hall",
	"clock",
	"quarry",
	"vault",
	"inn",
	"shop",
	"cottage",
	"train",
	"feast"
]
const MOODS = ["day", "dusk", "night", "dawn", "rain", "snow"]
const ENEMY_FIELDS = ["name", "hp", "damage", "speed", "aggro", "xp", "size", "boss", "drops"]
const NPC_FIELDS = [
	"name",
	"en",
	"age",
	"gender",
	"role",
	"household",
	"birthday",
	"favorite",
	"likes",
	"dislikes",
	"sprite",
	"portrait",
	"bio",
	"talk",
	"rain",
	"birthday_line",
	"after",
	"romance",
	"events",
	"married_talk",
	"married_events",
	"schedule"
]
const SCHEDULE_CONDITIONS = [
	"birthday",
	"festival",
	"weekdays",
	"week",
	"seasons",
	"weather",
	"days",
	"year_min",
	"year_max",
	"stage_min",
	"stage_max",
	"spouse"
]

var items: Dictionary = {}
var crops: Dictionary = {}
var fish: Dictionary = {}
var fish_spots: Dictionary = {}
var recipes: Dictionary = {}
var gather_tables: Dictionary = {}
var events: Array = []
var shops: Dictionary = {}
var rods: Array = []
var tool_tiers: Array = []
var smelting: Dictionary = {}
var animals: Dictionary = {}
var buildings: Dictionary = {}
var enemies: Dictionary = {}
var spawns: Dictionary = {}
var weapon: Dictionary = {}
var spouses: Dictionary = {}
var places: Dictionary = {}
var map: Dictionary = {}
var regions: Dictionary = {}
var story: Dictionary = {}
var calendar: GameCalendar = GameCalendar.new()
var weather: WeatherRules = WeatherRules.new(calendar)
var blocked_cells: Dictionary = {}
var water_cells: Dictionary = {}
var exits: Dictionary = {}
var debris_ids: Dictionary = {}
var debris_cells: Dictionary = {}
var tree_ids: Dictionary = {}
var tree_cells: Dictionary = {}


func load_content() -> String:
	var files = {
		"items": "res://data/items.json",
		"crops": "res://data/crops.json",
		"fish_data": "res://data/fish.json",
		"recipes_data": "res://data/recipes.json",
		"gather_tables": "res://data/gather_tables.json",
		"shop_data": "res://data/shops.json",
		"animals": "res://data/animals.json",
		"buildings": "res://data/buildings.json",
		"enemy_data": "res://data/enemies.json",
		"spouses": "res://data/spouses.json",
		"places": "res://data/places.json",
		"events_data": "res://data/events.json",
		"story": "res://data/story.json",
		"calendar_data": "res://data/calendar.json",
	}
	var raw: Dictionary = {}
	for key in files:
		var value = JSON.parse_string(FileAccess.get_file_as_string(files[key]))
		if (
			not value is Dictionary
			and not (key in ["recipes_data", "events_data"] and value is Array)
		):
			return "配置文件无法解析：" + files[key]
		raw[key] = value
	items = raw.items
	crops = raw.crops
	gather_tables = raw.gather_tables
	if not raw.shop_data.has_all(["shops", "rods", "tool_tiers", "smelting"]):
		return "商店配置不完整"
	shops = raw.shop_data.shops
	rods = raw.shop_data.rods
	tool_tiers = raw.shop_data.tool_tiers
	smelting = raw.shop_data.smelting
	animals = raw.animals
	buildings = raw.buildings
	spouses = raw.spouses
	if not raw.enemy_data.has_all(["enemies", "spawns", "weapon"]):
		return "怪物配置不完整"
	enemies = raw.enemy_data.enemies
	spawns = raw.enemy_data.spawns
	weapon = raw.enemy_data.weapon
	places = raw.places
	story = raw.story
	var steps = [
		func(): return calendar.load_data(raw.calendar_data),
		_validate_items,
		_validate_crops,
		func(): return _load_fish(raw.fish_data),
		func(): return _load_recipes(raw.recipes_data),
		_validate_tables,
		_validate_regions,
		_validate_shops,
		_validate_animals,
		_validate_places,
		_validate_story,
		func(): return _load_events(raw.events_data),
		_validate_enemies
	]
	for step in steps:
		var error: String = step.call()
		if not error.is_empty():
			return error
	return ""


# ---------------------------------------------------------------------------- items


func _validate_items() -> String:
	if items.is_empty():
		return "没有物品"
	for id in items:
		var item = items[id]
		if (
			not item is Dictionary
			or not item.has_all(
				["name", "kind", "buy_price", "sell_price", "icon", "description", "energy"]
			)
		):
			return "物品配置不完整：" + id
		if not item.name is String or not item.description is String or not item.icon is String:
			return "物品文字无效：" + id
		if item.kind not in ITEM_KINDS:
			return "物品类型无效：" + id
		if not natural(item.buy_price) or not natural(item.sell_price) or not natural(item.energy):
			return "物品数值无效：" + id
		if item.kind == "seed" and item.buy_price < 1:
			return "种子必须有价格：" + id
		if not ResourceLoader.exists("res://assets/art/%s.png" % item.icon):
			return "物品图标不存在：" + id
	return ""


func _validate_crops() -> String:
	if crops.is_empty():
		return "至少需要一种作物"
	for id in crops:
		var c = crops[id]
		if (
			not c is Dictionary
			or not c.has_all(
				[
					"name",
					"seed_item",
					"harvest_item",
					"growth_days",
					"regrow",
					"yield",
					"stages",
					"seasons"
				]
			)
		):
			return "作物配置不完整：" + id
		if not c.name is String or not items.has(c.seed_item) or not items.has(c.harvest_item):
			return "作物引用无效：" + id
		if items[c.seed_item].kind != "seed" or items[c.harvest_item].kind != "produce":
			return "作物的种子/收获物类型错误：" + id
		if not natural(c.growth_days) or c.growth_days < 1 or not natural(c.yield) or c.yield < 1:
			return "作物生长天数或产量错误：" + id
		if not natural(c.regrow) or c.regrow >= c.growth_days:
			return "作物再生天数错误：" + id
		if not c.seasons is Array or c.seasons.is_empty():
			return "作物没有可种植季节：" + id
		for season_id in c.seasons:
			if not season_id is String or calendar.season_index(season_id) < 0:
				return "作物季节无效：" + id
		if not c.stages is Array or c.stages.size() < 2:
			return "作物阶段图片不足：" + id
		for texture in c.stages:
			if (
				not texture is String
				or not ResourceLoader.exists("res://assets/art/%s.png" % texture)
			):
				return "作物图片不存在：" + id
	return ""


func _load_fish(data: Dictionary) -> String:
	if (
		not data.has_all(["spots", "fish"])
		or not data.spots is Dictionary
		or not data.fish is Array
	):
		return "钓鱼配置不完整"
	fish_spots = data.spots
	for entry in data.fish:
		if (
			not entry is Dictionary
			or not entry.has_all(
				["id", "spots", "seasons", "weather", "hours", "weight", "difficulty"]
			)
		):
			return "鱼的配置不完整"
		if not items.has(entry.id) or items[entry.id].kind != "fish":
			return "鱼没有对应物品：" + str(entry.id)
		if not numeric_array(entry.hours, 2) or entry.hours[0] >= entry.hours[1]:
			return "鱼的时段无效：" + entry.id
		if not natural(entry.weight) or entry.weight < 1 or not natural(entry.difficulty):
			return "鱼的权重或难度无效：" + entry.id
		for season_id in entry.seasons:
			if calendar.season_index(season_id) < 0:
				return "鱼的季节无效：" + entry.id
		for w in entry.weather:
			if w not in ["any", "any_clear"] and not calendar.weather_names.has(w):
				return "鱼的天气无效：" + entry.id
		fish[entry.id] = entry
	for map_id in fish_spots:
		if not fish_spots[map_id] is String:
			return "水域类型无效：" + map_id
	return ""


func _load_recipes(data: Array) -> String:
	for entry in data:
		if not entry is Dictionary or not entry.has_all(["id", "needs", "level"]):
			return "食谱配置不完整"
		if not items.has(entry.id) or items[entry.id].kind != "dish":
			return "食谱产物不是料理：" + str(entry.id)
		if not entry.needs is Dictionary or entry.needs.is_empty() or not natural(entry.level):
			return "食谱材料无效：" + entry.id
		for need in entry.needs:
			if not items.has(need) or not natural(entry.needs[need]) or entry.needs[need] < 1:
				return "食谱材料不存在：" + entry.id
		recipes[entry.id] = entry
	return ""


func _validate_tables() -> String:
	for table in gather_tables:
		var by_season = gather_tables[table]
		if not by_season is Dictionary or by_season.is_empty():
			return "采集表无效：" + table
		for season_key in by_season:
			if season_key != "any" and calendar.season_index(season_key) < 0:
				return "采集表季节无效：" + table
			if not by_season[season_key] is Array or by_season[season_key].is_empty():
				return "采集表为空：" + table
			for entry in by_season[season_key]:
				if (
					not entry is Array
					or entry.size() != 2
					or not items.has(entry[0])
					or not natural(entry[1])
					or entry[1] < 1
				):
					return "采集表条目无效：" + table
	return ""


func _load_events(data: Array) -> String:
	for e in data:
		if not e is Dictionary or not e.has_all(["id", "name", "when", "effect", "text"]):
			return "事件配置不完整"
		if not e.when is Dictionary or not e.when.has("chance"):
			return "事件概率缺失：" + str(e.id)
		if not natural(e.when.chance) or e.when.chance < 1 or e.when.chance > 100:
			return "事件概率无效：" + str(e.id)
		for season_id in e.when.get("seasons", []):
			if calendar.season_index(season_id) < 0:
				return "事件季节无效：" + str(e.id)
		for key in ["weather", "prev_weather"]:
			for w in e.when.get(key, []):
				if not calendar.weather_names.has(w):
					return "事件天气无效：" + str(e.id)
		for item in e.effect.get("items", {}):
			if not items.has(item):
				return "事件物品不存在：" + str(e.id)
	events = data
	return ""


# ---------------------------------------------------------------------------- shops


func _validate_shops() -> String:
	for id in shops:
		var shop = shops[id]
		if (
			not shop is Dictionary
			or not shop.has_all(["name", "open", "close", "closed_weekdays"])
			or not natural(shop.open)
			or not natural(shop.close)
			or shop.open >= shop.close
			or not shop.closed_weekdays is Array
		):
			return "商店配置无效：" + id
		if not shop.get("goods") is Dictionary or not shop.get("buys") is Array:
			return "商店商品配置无效：" + id
		for good in shop.goods:
			if not items.has(good) or not natural(shop.goods[good]) or shop.goods[good] < 1:
				return "商品不存在或价格无效：" + id
		for kind in shop.buys:
			if kind not in SELLABLE:
				return "商店收购类型无效：" + id
	for rod in rods:
		if not rod is Dictionary or not rod.has_all(["name", "price", "speed", "window"]):
			return "鱼竿配置无效"
	for tier in tool_tiers:
		if (
			not tier is Dictionary
			or not items.has(tier.get("bar"))
			or not natural(tier.get("gold"))
		):
			return "工具升级配置无效"
	for ore in smelting:
		if not items.has(ore) or not items.has(smelting[ore]):
			return "熔炼配置无效"
	var found: Dictionary = {}
	for map_id in regions:
		for station in regions[map_id].stations:
			if station.kind == "shop":
				if not station.has("shop_id") or not shops.has(station.shop_id):
					return "柜台没有对应商店：" + station.id
				found[station.shop_id] = true
	for id in shops:
		if not found.has(id):
			return "商店没有柜台：" + id
	return ""


func _validate_animals() -> String:
	for id in animals:
		var a = animals[id]
		if (
			not a is Dictionary
			or not a.has_all(
				["name", "building", "price", "product", "special", "interval", "adult_days"]
			)
			or not buildings.has(a.building)
			or not items.has(a.product)
			or not items.has(a.special)
			or not natural(a.price)
			or not natural(a.interval)
			or a.interval < 1
			or not natural(a.adult_days)
		):
			return "动物配置无效：" + id
	for id in buildings:
		var b = buildings[id]
		if not b is Dictionary or not b.has_all(["name", "kind", "hint"]):
			return "建筑配置无效：" + id
		if b.kind not in ["animal", "story"]:
			return "建筑类型无效：" + id
		if b.kind == "animal":
			if not b.has_all(["price", "materials", "days", "capacity"]):
				return "建筑配置无效：" + id
			for material in b.materials:
				if not items.has(material):
					return "建筑材料不存在：" + id
		if not map.building_sites.has(id):
			return "农场没有建筑地块：" + id
	return ""


func _validate_enemies() -> String:
	for id in enemies:
		var e = enemies[id]
		if not e is Dictionary or not e.has_all(ENEMY_FIELDS):
			return "怪物配置无效：" + id
		for key in ["hp", "damage", "speed", "aggro", "xp", "size"]:
			if not natural(e[key]) or e[key] < 1:
				return "怪物数值无效：" + id
		for drop in e.drops:
			if (
				not drop is Array
				or drop.size() != 4
				or not items.has(drop[0])
				or not natural(drop[1])
				or drop[1] > 100
				or not natural(drop[2])
				or not natural(drop[3])
				or drop[2] > drop[3]
			):
				return "怪物掉落无效：" + id
	for map_id in spawns:
		if not regions.has(map_id):
			return "怪物出没的地图不存在：" + map_id
		for kind in spawns[map_id]:
			if not enemies.has(kind) or not natural(spawns[map_id][kind]):
				return "怪物出没配置无效：" + map_id
	if (
		not weapon.has_all(["damage", "cost", "hp", "knockback"])
		or weapon.damage.size() != tool_tiers.size() + 1
		or weapon.cost.size() != tool_tiers.size() + 1
		or not natural(weapon.hp)
	):
		return "武器配置无效"
	for id in spouses:
		var sp = spouses[id]
		if not story.npcs.has(id) or not story.npcs[id].romance or not sp is Dictionary:
			return "配偶配置无效：" + id
		for item in sp.get("items", {}):
			if not items.has(item):
				return "配偶带回的物品不存在：" + id
	for id in story.npcs:
		if story.npcs[id].romance and not spouses.has(id):
			return "缺少配偶的日常：" + id
	return ""


# ---------------------------------------------------------------------------- places and people


func _validate_places() -> String:
	for key in places:
		var parts = key.split("/")
		if parts.size() != 2 or not regions.has(parts[0]):
			return "地点所在地图无效：" + key
		var p = places[key]
		if (
			not p is Array
			or p.size() != 3
			or not numeric_array([p[0], p[1]], 2)
			or not p[2] is bool
		):
			return "地点格式无效：" + key
		if blocked(Vector2i(int(p[0]), int(p[1])), parts[0]):
			return "地点不可站立：" + key
	return ""


const QUEST_FIELDS = [
	"id",
	"title",
	"where",
	"hint",
	"needs",
	"npc",
	"event",
	"chapter",
	"available_day",
	"friendship",
	"reward",
	"choice",
	"flag",
	"lamp",
	"station",
	"build"
]
const STORY_STATIONS = ["bridge", "lantern", "shrine"]
const SLOTS = ["far_left", "left", "center_left", "center", "center_right", "right", "far_right"]
const EFFECTS = [
	"fireflies",
	"lanterns",
	"petals",
	"rain",
	"snow",
	"leaves",
	"dust",
	"confetti",
	"sparks",
	"steam",
	"bells",
	"water"
]
const SOUNDS = ["bell", "chime", "lantern", "water", "cheer", "wedding", "hit", "rumble", "tick"]
const ACTIONS = ["hop", "nod", "shake", "bow", "step"]
const CAMERAS = ["zoom_in", "zoom_out", "pan_left", "pan_right", "still"]
const FLASHES = ["white", "gold", "black"]


func _validate_story() -> String:
	if (
		not story.has_all(["npcs", "quests", "scenes", "flags", "guests", "prologue_choices"])
		or not story.npcs is Dictionary
		or not story.quests is Array
		or not story.scenes is Dictionary
		or not story.flags is Dictionary
		or not story.guests is Dictionary
		or not story.prologue_choices is Array
		or story.quests.size() < 7
	):
		return "剧情配置不完整"
	var lamps: Array = []
	for index in story.quests.size():
		var quest = story.quests[index]
		var error = _validate_quest(quest, index == story.quests.size() - 1)
		if not error.is_empty():
			return error
		if int(quest.lamp) > 0:
			lamps.append(int(quest.lamp))
	if lamps != [1, 2, 3, 4, 5, 6]:
		return "六盏灯必须按顺序各亮一次"
	for guest in story.guests:
		var g = story.guests[guest]
		if (
			not g is Dictionary
			or not g.has_all(["name", "en", "age", "sprite", "portrait"])
			or not ResourceLoader.exists("res://assets/art/%s.png" % g.portrait)
			or not ResourceLoader.exists("res://assets/art/%s.png" % g.sprite)
		):
			return "来宾配置无效：" + guest
	for event in story.scenes:
		var error = _validate_scene(event, story.scenes[event])
		if not error.is_empty():
			return error
	for id in story.npcs:
		var error = _validate_npc(id, story.npcs[id])
		if not error.is_empty():
			return error
	return ""


func _validate_quest(quest: Variant, terminal: bool) -> String:
	if not quest is Dictionary or not quest.has_all(QUEST_FIELDS):
		return "任务配置不完整"
	var name = str(quest.id)
	if not quest.needs is Dictionary or not quest.friendship is Dictionary:
		return "任务需求无效：" + name
	for item in quest.needs:
		if not items.has(item) or not natural(quest.needs[item]):
			return "任务物品引用无效：" + name
	for who in quest.friendship:
		if not story.npcs.has(who) or not natural(quest.friendship[who]):
			return "任务好感要求无效：" + name
	if quest.npc != "" and not story.npcs.has(quest.npc):
		return "任务人物不存在：" + name
	if terminal != (quest.event == ""):
		return "只有最后一个任务没有事件：" + name
	if quest.event != "" and not story.scenes.has(quest.event):
		return "任务场景不存在：" + name
	if quest.event != "" and quest.npc == "" and quest.station not in STORY_STATIONS:
		return "任务没有人物也没有地点：" + name
	if not natural(quest.available_day) or not natural(quest.lamp) or quest.lamp > 6:
		return "任务数值无效：" + name
	if not quest.reward is Dictionary or not quest.reward.has_all(["gold", "items"]):
		return "任务奖励无效：" + name
	for item in quest.reward.items:
		if not items.has(item):
			return "任务奖励物品不存在：" + name
	if not quest.choice is Array or (not quest.choice.is_empty() and quest.flag == ""):
		return "任务选项无效：" + name
	for c in quest.choice:
		if not c is Dictionary or not c.has_all(["id", "label"]):
			return "任务选项无效：" + name
		if not story.flags.has(quest.flag) or c.id not in story.flags[quest.flag]:
			return "任务选项未登记：" + name
	if quest.build != "" and not buildings.has(quest.build):
		return "任务建筑不存在：" + name
	return ""


func _validate_scene(event: String, scene: Variant) -> String:
	if (
		not scene is Dictionary
		or not scene.has_all(["pages", "bg", "mood", "card", "fx"])
		or not scene.pages is Array
		or scene.pages.is_empty()
		or scene.bg not in BACKDROPS
		or scene.mood not in MOODS
		or not scene.card is Array
		or not scene.fx is Array
	):
		return "缺少剧情场景：" + event
	for page in scene.pages:
		if (
			not page is Array
			or page.size() != 3
			or not page[0] is String
			or not page[1] is String
			or not page[2] is Dictionary
		):
			return "对白格式无效：" + event
		if (
			page[0] not in ["letter", "narrator"]
			and not story.npcs.has(page[0])
			and not story.guests.has(page[0])
		):
			return "对白人物不存在：" + event
		var error = _validate_notes(event, page[2])
		if not error.is_empty():
			return error
	return ""


func _validate_notes(event: String, notes: Dictionary) -> String:
	for key in notes:
		var value = notes[key]
		var ok = true
		match key:
			"bg":
				ok = value in BACKDROPS
			"mood":
				ok = value in MOODS
			"fx":
				ok = value is Array and value.all(func(e): return e in EFFECTS)
			"sfx":
				ok = value in SOUNDS
			"flash":
				ok = value in FLASHES
			"cam":
				ok = value in CAMERAS
			"shake":
				ok = value is float or value is int
			"title":
				ok = value is String
			"actors":
				ok = value is Array and value.all(func(a): return _actor_ok(a))
			"act":
				ok = value is Dictionary and value.values().all(func(a): return a in ACTIONS)
			"when":
				ok = (
					value is Dictionary
					and value.keys().all(func(f): return _condition_ok(f, value[f]))
				)
			_:
				ok = false
		if not ok:
			return "导演提示无效：%s %s" % [event, key]
	return ""


func _actor_ok(entry: Variant) -> bool:
	if not entry is String:
		return false
	var parts = entry.split("@")
	if parts.size() != 2 or parts[1] not in SLOTS:
		return false
	return parts[0] == "player" or story.npcs.has(parts[0]) or story.guests.has(parts[0])


func _condition_ok(flag: String, wanted: Variant) -> bool:
	if flag == "partner":
		return story.npcs.has(wanted) and story.npcs[wanted].romance
	return story.flags.has(flag) and wanted in story.flags[flag]


func _validate_npc(id: String, npc: Variant) -> String:
	if not npc is Dictionary or not npc.has_all(NPC_FIELDS):
		return "人物配置不完整：" + id
	if not npc.talk is Array or npc.talk.is_empty() or not npc.events is Array:
		return "人物对白或事件无效：" + id
	for picture in [npc.sprite, npc.portrait]:
		if not ResourceLoader.exists("res://assets/art/%s.png" % picture):
			return "人物素材不存在：" + id
	var b = npc.birthday
	if (
		not b is Dictionary
		or calendar.season_index(b.season) < 0
		or int(b.day) < 1
		or int(b.day) > 28
	):
		return "人物生日无效：" + id
	for taste in [npc.favorite] + npc.likes + npc.dislikes:
		if not items.has(taste) or items[taste].kind == "seed":
			return "人物喜好无效：" + id
	var previous = 0
	for event in npc.events:
		if (
			not event is Dictionary
			or not event.has_all(["id", "at", "reward"])
			or not story.scenes.has(event.id)
			or not natural(event.at)
			or event.at <= previous
			or event.at > 100
		):
			return "人物事件无效：" + id
		previous = int(event.at)
		for item in event.reward.items:
			if not items.has(item):
				return "事件奖励不存在：" + event.id
	if not npc.married_talk is Array or not npc.married_events is Array:
		return "婚后内容无效：" + id
	if npc.romance and (npc.married_talk.size() != 3 or npc.married_events.size() != 2):
		return "婚后内容不完整：" + id
	for event in npc.married_events:
		if (
			not event is Dictionary
			or not event.has_all(["id", "after", "reward"])
			or not story.scenes.has(event.id)
			or not natural(event.after)
		):
			return "婚后事件无效：" + id
		for item in event.reward.items:
			if not items.has(item):
				return "事件奖励不存在：" + event.id
	return _validate_schedule(id, npc.schedule)


func _validate_schedule(id: String, schedule: Variant) -> String:
	if (
		not schedule is Dictionary
		or not schedule.get("rules") is Array
		or schedule.rules.is_empty()
	):
		return "日程缺失：" + id
	for i in schedule.rules.size():
		var rule = schedule.rules[i]
		if not rule is Dictionary or not rule.has_all(["when", "stops"]) or rule.stops.is_empty():
			return "日程规则无效：" + id
		for key in rule.when:
			if key not in SCHEDULE_CONDITIONS:
				return "日程条件无效：" + id
		if (i == schedule.rules.size() - 1) != rule.when.is_empty():
			return "日程最后一条规则必须是无条件规则：" + id
		var last = -1
		for stop in rule.stops:
			if (
				not stop is Array
				or stop.size() != 3
				or not natural(stop[0])
				or int(stop[0]) <= last
			):
				return "日程时刻无效：" + id
			last = int(stop[0])
			if stop[1] not in ["festival", "away"] and not places.has(stop[1]):
				return "日程地点不存在：" + id + " " + str(stop[1])
	return ""


# ---------------------------------------------------------------------------- maps


func _validate_regions() -> String:
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
	if not map.has_all(["plantable", "starting_inventory", "starting_gold", "building_sites"]):
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
		var error = _validate_region(id, regions[id])
		if not error.is_empty():
			return error
	for id in regions:
		for station in regions[id].stations:
			if station.kind == "ferry":
				if not regions.has(station.destination) or not numeric_array(station.arrival, 2):
					return "渡口无效：" + id
			if station.kind == "story":
				if not station.get("event") is String or not station.get("idle") is String:
					return "剧情地点无效：" + id
			if station.kind == "exit":
				if not regions.has(station.destination) or not numeric_array(station.arrival, 2):
					return "出口无效：" + id
				exits[id] = exits.get(id, [])
				exits[id].append(
					{
						"cell": Vector2i(station.cell[0], station.cell[1]),
						"to": station.destination,
						"arrival":
						Vector2i(int(station.arrival[0] / 32), int(station.arrival[1] / 32))
					}
				)
	return ""


func _validate_region(id: String, area: Dictionary) -> String:
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
	if area.get("environment", "") not in ["interior", "exterior", "cave"]:
		return "地图环境无效：" + id
	if not numeric_array(area.spawn, 2):
		return "出生点无效：" + id
	if not ResourceLoader.exists("res://assets/art/%s.png" % area.background):
		return "缺少地图背景：" + id
	if area.has("tile_layers"):
		if not ResourceLoader.exists("res://assets/art/%s.png" % area.get("tile_atlas", "")):
			return "缺少地图图块集：" + id
		if not area.tile_layers is Array:
			return "地图图层无效：" + id
		for layer in area.tile_layers:
			if not layer is Dictionary or not layer.has_all(["name", "cells"]):
				return "地图图层字段无效：" + id
			if not layer.cells is Array or layer.cells.size() != int(area.width * area.height):
				return "地图图层尺寸无效：" + id
			for gid in layer.cells:
				if not natural(gid) or gid > 528 or gid in [10, 11, 12]:
					return "地图图块编号无效：" + id
	if (
		area.has("tree_texture")
		and not ResourceLoader.exists("res://assets/art/%s.png" % area.tree_texture)
	):
		return "缺少地图树木素材：" + id
	for field in ["obstacles", "trees", "props", "stations", "debris", "gather", "water_rects"]:
		if not area.get(field, []) is Array:
			return "地图列表无效：" + id + "/" + field
	var cells: Dictionary = {}
	for r in area.obstacles:
		if not numeric_array(r, 4):
			return "碰撞范围无效：" + id
		for y in range(int(r[1]), int(r[1] + r[3])):
			for x in range(int(r[0]), int(r[0] + r[2])):
				cells[Vector2i(x, y)] = true
	var water: Dictionary = {}
	for r in area.get("water_rects", []):
		if not numeric_array(r, 4):
			return "水域范围无效：" + id
		for y in range(int(r[1]), int(r[1] + r[3])):
			for x in range(int(r[0]), int(r[0] + r[2])):
				water[Vector2i(x, y)] = true
	water_cells[id] = water
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
			or station.kind not in STATION_KINDS
		):
			return "交互点无效：" + id
		if station.kind == "inspect" and not station.get("description") is String:
			return "物件说明缺失：" + id
		station_ids.append(station.id)
	for node in area.get("gather", []):
		if (
			not node is Dictionary
			or not node.has_all(["id", "cell"])
			or not numeric_array(node.cell, 2)
			or (node.has("item") == node.has("table"))
		):
			return "采集点无效：" + id
		if node.has("item") and not items.has(node.item):
			return "采集物不存在：" + id
		if node.has("table") and not gather_tables.has(node.table):
			return "采集表不存在：" + id
		for season_item in node.get("seasonal", {}).values():
			if not items.has(season_item):
				return "季节采集物不存在：" + id
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
	return ""


# ---------------------------------------------------------------------------- queries


## Index of the quest whose completion lights lamp `number` (1-6).
func lamp_quest_index(number: int) -> int:
	for i in story.quests.size():
		if int(story.quests[i].lamp) == number:
			return i
	return -1


func quest_index(event: String) -> int:
	for i in story.quests.size():
		if story.quests[i].event == event:
			return i
	return -1


func region(id: String) -> Dictionary:
	return regions[id]


func place(key: String) -> Dictionary:
	var p = places[key]
	return {"map": key.split("/")[0], "cell": Vector2i(int(p[0]), int(p[1])), "hidden": p[2]}


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


func is_water(cell: Vector2i, map_id: String) -> bool:
	return water_cells[map_id].has(cell)


func tree_at(cell: Vector2i, state: FarmState) -> String:
	var id: String = tree_cells[state.current_map].get(cell, "")
	return id if state.tree_damage.get(id, 0) < 5 else ""


func debris_at(cell: Vector2i, state: FarmState) -> Dictionary:
	var node = debris_cells.get(cell, {})
	return {} if node.is_empty() or state.cleared.has(node.id) else node


func crop_texture(crop_id: String, growth: int) -> String:
	var c = crops[crop_id]
	var index = mini(
		c.stages.size() - 1, int(float(growth) / float(c.growth_days) * (c.stages.size() - 1))
	)
	return c.stages[index]

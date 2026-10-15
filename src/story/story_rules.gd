class_name StoryRules
extends RefCounted

var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}


func level(xp: int) -> int:
	return mini(10, 1 + int(xp / 40))


func quest(s: FarmState) -> Dictionary:
	return catalog.story.quests[int(s.narrative.stage)]


func missing(s: FarmState, requirements: Dictionary) -> String:
	var parts: Array[String] = []
	for id in requirements:
		if s.inventory[id] < requirements[id]:
			parts.append("%s %d/%d" % [catalog.items[id].name, s.inventory[id], requirements[id]])
	return "还需要：" + "，".join(parts) if not parts.is_empty() else ""


func can_complete(s: FarmState, event: String) -> String:
	var expected = {
		"welcome": 0, "first_meal": 1, "bridge": 2, "notebook": 3, "feast": 4, "festival": 5
	}
	if not expected.has(event) or int(s.narrative.stage) != expected[event]:
		return "这段故事已经完成，或还没到时候。"
	return missing(s, quest(s).needs)


func complete(s: FarmState, event: String, choice: String = "") -> Dictionary:
	if event == "prologue":
		if s.narrative.intro_seen or choice not in ["grow", "restart"]:
			return result(false, "这封信已经读过了。")
		s.narrative.intro_seen = true
		s.narrative.intent = choice
		return result(true, "")
	var error = can_complete(s, event)
	if not error.is_empty():
		return result(false, error)
	if event == "festival" and choice not in ["stay", "explore", "together"]:
		return result(false, "先在灯上写下你的心愿。")
	for id in quest(s).needs:
		s.inventory[id] -= int(quest(s).needs[id])
	s.narrative.stage += 1
	if event == "first_meal":
		s.gold += 20
	if event == "festival":
		s.gold += 50
		s.narrative.wish = choice
	return result(
		true, "+50 G" if event == "festival" else ("+20 G" if event == "first_meal" else "")
	)


func talk(s: FarmState, id: String) -> String:
	if not s.daily.talked.has(id):
		s.relationships[id] = mini(100, int(s.relationships[id]) + 4)
		s.daily.talked.append(id)
	var npc = catalog.story.npcs[id]
	return npc.after if int(s.narrative.stage) == 6 else npc.talk[(s.day - 1) % npc.talk.size()]


func gift(s: FarmState, npc_id: String, item_id: String) -> Dictionary:
	if not catalog.story.npcs.has(npc_id) or not catalog.items.has(item_id):
		return result(false, "无法赠送这个物品。")
	if s.daily.gifted.has(npc_id):
		return result(false, "今天已经送过礼物了，明天再来吧。")
	if s.inventory[item_id] < 1 or catalog.items[item_id].kind == "seed":
		return result(false, "口袋里没有这份礼物。")
	var favorite = catalog.story.npcs[npc_id].favorite == item_id
	s.inventory[item_id] -= 1
	s.relationships[npc_id] = mini(100, int(s.relationships[npc_id]) + (10 if favorite else 4))
	s.daily.gifted.append(npc_id)
	return result(true, "正是我喜欢的，谢谢你！关系 +10" if favorite else "谢谢你的心意。关系 +4")


func memory(s: FarmState, id: String) -> Dictionary:
	if (
		not catalog.story.npcs.has(id)
		or int(s.relationships[id]) < 40
		or s.development.memories.has(id)
	):
		return result(false, "这段回忆尚未解锁，或已经读过。")
	s.development.memories.append(id)
	s.gold += 30
	s.inventory.turnip_seed += 3
	return result(true, "收到友人的回礼：30 金币、3 份萝卜种子。")


func gather(s: FarmState, node_id: String) -> Dictionary:
	var area = catalog.region(s.current_map)
	var node: Dictionary = {}
	for entry in area.get("gather", []):
		if entry.id == node_id:
			node = entry
	if node.is_empty() or s.daily.gathered.has(node_id):
		return result(false, "")
	if s.stamina < 2:
		return result(false, "体力不足")
	var amount = 2 if level(int(s.development.foraging_xp)) >= 3 else 1
	s.inventory[node.item] += amount
	s.stamina -= 2
	s.development.foraging_xp += 3
	s.daily.gathered.append(node_id)
	return result(true, "%s +%d" % [catalog.items[node.item].name, amount])


func enter(s: FarmState, destination: String, arrival: Vector2) -> Dictionary:
	if (
		not catalog.regions.has(destination)
		or (destination == "lake" and int(s.narrative.stage) < 3)
	):
		return result(false, "木桥还没修好。")
	if catalog.blocked(
		Vector2i(int(arrival.x / 32), int(arrival.y / 32)), destination, s.tree_damage
	):
		return result(false, "入口不可通行。")
	s.current_map = destination
	s.player_position = arrival
	return result(true, "")


func upgrade(s: FarmState) -> Dictionary:
	if int(s.development.watering_level) > 0:
		return result(false, "水壶已经升级过了。")
	if level(int(s.development.farming_xp)) < 2:
		return result(false, "需要种植 Lv.2")
	var error = missing(s, {"wood": 3, "stone": 2})
	if not error.is_empty():
		return result(false, error)
	if s.gold < 40:
		return result(false, "还需要 40 金币。")
	s.gold -= 40
	s.inventory.wood -= 3
	s.inventory.stone -= 2
	s.development.watering_level = 1
	return result(true, "获得铜水壶")


func cook(s: FarmState) -> Dictionary:
	if s.inventory.berry < 2:
		return result(false, "野莓粥需要 2 份野莓。")
	if s.stamina >= FarmState.MAX_STAMINA:
		return result(false, "现在体力充沛，饿了再吃吧。")
	s.inventory.berry -= 2
	s.stamina = mini(FarmState.MAX_STAMINA, s.stamina + 30)
	return result(true, "吃下温热的野莓粥，恢复 30 体力。")


func transfer(s: FarmState, id: String, deposit: bool) -> Dictionary:
	if not catalog.items.has(id):
		return result(false, "未知物品。")
	var source = s.inventory if deposit else s.storage
	var destination = s.storage if deposit else s.inventory
	if source[id] < 1:
		return result(false, "这里没有这个物品。")
	source[id] -= 1
	destination[id] += 1
	return result(true, "")

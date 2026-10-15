class_name StoryRules
extends RefCounted

var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func result(ok: bool, message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r


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


# ---------------------------------------------------------------------------- the main story


func can_complete(s: FarmState, event: String) -> String:
	var q = quest(s)
	if q.event != event or event == "":
		return "这段故事已经完成，或还没到时候。"
	return missing(s, q.needs)


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
	var message = ""
	if event == "first_meal":
		s.gold += 20
		message = "+20 G"
	if event == "festival":
		s.gold += 50
		s.narrative.wish = choice
		message = "+50 G"
	return result(true, message)


# ---------------------------------------------------------------------------- people


func birthday_today(s: FarmState, id: String) -> bool:
	return id in catalog.calendar.birthdays_on(s.day, catalog.story.npcs)


func talk(s: FarmState, id: String) -> String:
	if not s.daily.talked.has(id):
		s.relationships[id] = mini(100, int(s.relationships[id]) + 4)
		s.daily.talked.append(id)
	var npc = catalog.story.npcs[id]
	if birthday_today(s, id):
		return npc.birthday_line
	if int(s.narrative.stage) == 6:
		return npc.after
	var weather = catalog.weather.weather_on(s.world_seed, s.day)
	if catalog.weather.waters_crops(weather) and s.day % 2 == 0:
		return npc.rain
	return npc.talk[(s.day + id.length()) % npc.talk.size()]


## How a villager feels about an item: "love" (favourite), "like", "dislike" or "neutral".
func taste(id: String, item_id: String) -> String:
	var npc = catalog.story.npcs[id]
	if npc.favorite == item_id:
		return "love"
	if item_id in npc.likes:
		return "like"
	if item_id in npc.dislikes:
		return "dislike"
	return "neutral"


func gift(s: FarmState, npc_id: String, item_id: String) -> Dictionary:
	if not catalog.story.npcs.has(npc_id) or not catalog.items.has(item_id):
		return result(false, "无法赠送这个物品。")
	if s.daily.gifted.has(npc_id):
		return result(false, "今天已经送过礼物了，明天再来吧。")
	if s.inventory[item_id] < 1 or catalog.items[item_id].kind == "seed":
		return result(false, "口袋里没有这份礼物。")
	var feeling = taste(npc_id, item_id)
	var change = {"love": 12, "like": 8, "neutral": 4, "dislike": -4}[feeling]
	if change > 0 and birthday_today(s, npc_id):
		change *= 2
	s.inventory[item_id] -= 1
	s.relationships[npc_id] = clampi(int(s.relationships[npc_id]) + change, 0, 100)
	s.daily.gifted.append(npc_id)
	var message = {
		"love": "正是我最喜欢的，谢谢你！关系 %+d",
		"like": "我很喜欢，谢谢。关系 %+d",
		"neutral": "谢谢你的心意。关系 %+d",
		"dislike": "呃……谢谢，不过这个我不太喜欢。关系 %+d",
	}[feeling]
	return result(true, message % change)


## The next unseen event this villager's friendship has unlocked, or {}.
func available_event(s: FarmState, id: String) -> Dictionary:
	for event in catalog.story.npcs[id].events:
		if int(s.relationships[id]) >= int(event.at) and not s.development.events.has(event.id):
			return event
	return {}


func is_heart_event(event_id: String) -> bool:
	for id in catalog.story.npcs:
		for event in catalog.story.npcs[id].events:
			if event.id == event_id:
				return true
	return false


## Joining a festival on the plaza between 09:00 and 14:00, once per year and festival.
func attend_festival(s: FarmState) -> Dictionary:
	var festival = catalog.calendar.festival_on(s.day)
	if festival.is_empty() or s.current_map != catalog.calendar.plaza_map:
		return result(false, "")
	if s.minute < 9 * 60 or s.minute >= 14 * 60:
		return result(false, "")
	var key = "%d:%s" % [catalog.calendar.date(s.day).year, festival.id]
	if s.festival_done.has(key):
		return result(false, "")
	s.festival_done.append(key)
	s.gold += 30
	for id in s.relationships:
		s.relationships[id] = mini(100, int(s.relationships[id]) + 2)
	return result(true, "参加了「%s」：%s 金币 +30，大家都近了一点。" % [festival.name, festival.text])


func claim_event(s: FarmState, event_id: String) -> Dictionary:
	for id in catalog.story.npcs:
		for event in catalog.story.npcs[id].events:
			if event.id != event_id:
				continue
			if int(s.relationships[id]) < int(event.at) or s.development.events.has(event_id):
				return result(false, "这段回忆尚未解锁，或已经读过。")
			s.development.events.append(event_id)
			var parts: Array[String] = []
			if int(event.reward.gold) > 0:
				s.gold += int(event.reward.gold)
				parts.append("%d 金币" % int(event.reward.gold))
			for item in event.reward.items:
				s.inventory[item] += int(event.reward.items[item])
				parts.append("%s ×%d" % [catalog.items[item].name, int(event.reward.items[item])])
			return result(true, "收到友人的回礼：" + "、".join(parts))
	return result(false, "没有这段事件。")


# ---------------------------------------------------------------------------- the land


func gather(s: FarmState, node_id: String) -> Dictionary:
	var area = catalog.region(s.current_map)
	var node: Dictionary = {}
	for entry in area.get("gather", []):
		if entry.id == node_id:
			node = entry
	if node.is_empty() or s.daily.gathered.has(node_id):
		return result(false, "")
	var mine = GatherRules.is_mine(node)
	var cost = 3 if mine else 2
	if s.stamina < cost:
		return result(false, "体力不足")
	var item = GatherRules.item_for(catalog, s, node)
	var amount = 1
	if not mine and level(int(s.development.foraging_xp)) >= 3:
		amount = 2
	s.inventory[item] += amount
	s.stamina -= cost
	if mine:
		s.development.mining_xp += 4
	else:
		s.development.foraging_xp += 3
	s.daily.gathered.append(node_id)
	return result(true, "%s +%d" % [catalog.items[item].name, amount], {"item": item})


func enter(s: FarmState, destination: String, arrival: Vector2) -> Dictionary:
	if not catalog.regions.has(destination):
		return result(false, "那里没有路。")
	if destination == "lake" and int(s.narrative.stage) < 3:
		return result(false, "木桥还没修好。")
	if catalog.blocked(
		Vector2i(int(arrival.x / 32), int(arrival.y / 32)), destination, s.tree_damage
	):
		return result(false, "入口不可通行。")
	s.current_map = destination
	s.player_position = arrival
	return result(true, "")


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

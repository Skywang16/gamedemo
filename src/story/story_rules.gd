class_name StoryRules
extends RefCounted

## The main story, the people, courtship and the land. Every rule is a pure change to FarmState.

const COURTSHIP_FRIENDSHIP = 80
const WEDDING_FRIENDSHIP = 100
const WEDDING_DELAY = 3
const FIRST_ROMANCE_STAGE = 6

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


func flag(s: FarmState, id: String) -> String:
	return str(s.narrative.flags.get(id, ""))


# ---------------------------------------------------------------------------- lamps


## How many of the six lamps are lit.
func lamps(s: FarmState) -> int:
	var count = 0
	for i in int(s.narrative.stage):
		if int(catalog.story.quests[i].lamp) > 0:
			count += 1
	return count


func lamp_lit(s: FarmState, number: int) -> bool:
	return int(s.narrative.stage) > catalog.lamp_quest_index(number)


func bridge_open(s: FarmState) -> bool:
	return lamp_lit(s, 1)


func ferry_open(s: FarmState) -> bool:
	return lamp_lit(s, 4)


## Seeds of every season on the rack, and no withering at the turn of the season.
func greenhouse(s: FarmState) -> bool:
	return lamp_lit(s, 3)


func canal_flowing(s: FarmState) -> bool:
	return lamp_lit(s, 5)


func clock_ringing(s: FarmState) -> bool:
	return lamp_lit(s, 2)


# ---------------------------------------------------------------------------- the main story


func missing(s: FarmState, requirements: Dictionary) -> String:
	var parts: Array[String] = []
	for id in requirements:
		if s.inventory[id] < requirements[id]:
			parts.append("%s %d/%d" % [catalog.items[id].name, s.inventory[id], requirements[id]])
	return "还需要：" + "，".join(parts) if not parts.is_empty() else ""


## Why the current step cannot be finished yet, or "".
func can_complete(s: FarmState, event: String) -> String:
	var q = quest(s)
	if q.event != event or event == "":
		return "这段故事已经完成，或还没到时候。"
	if s.day < int(q.available_day):
		return "还没到时候。%s" % available_text(q)
	for id in q.friendship:
		if int(s.relationships[id]) < int(q.friendship[id]):
			return "需要和%s再熟悉一些（好感 %d）。" % [catalog.story.npcs[id].name, int(q.friendship[id])]
	return missing(s, q.needs)


## "夏 1 日起" for a step that waits for the season.
func available_text(q: Dictionary) -> String:
	if int(q.available_day) <= 0:
		return ""
	var d = catalog.calendar.date(int(q.available_day))
	return "%s %d 日起。" % [d.season_name, d.day]


func complete(s: FarmState, event: String, choice: String = "") -> Dictionary:
	if event == "prologue":
		var allowed = catalog.story.prologue_choices.map(func(c): return c.id)
		if s.narrative.intro_seen or choice not in allowed:
			return result(false, "这封信已经读过了。")
		s.narrative.intro_seen = true
		s.narrative.intent = choice
		return result(true, "")
	var error = can_complete(s, event)
	if not error.is_empty():
		return result(false, error)
	var q = quest(s)
	if not q.choice.is_empty() and not q.choice.any(func(c): return c.id == choice):
		return result(false, "先做出你的选择。")
	for id in q.needs:
		s.inventory[id] -= int(q.needs[id])
	var parts: Array[String] = []
	if int(q.reward.gold) > 0:
		s.gold += int(q.reward.gold)
		s.stats.earned += int(q.reward.gold)
		parts.append("+%d G" % int(q.reward.gold))
	for id in q.reward.items:
		s.inventory[id] += int(q.reward.items[id])
		parts.append("%s ×%d" % [catalog.items[id].name, int(q.reward.items[id])])
	if q.flag != "":
		s.narrative.flags[q.flag] = choice
	if q.build != "":
		s.buildings[q.build] = {"ready_day": s.day}
	s.narrative.stage += 1
	if q.id == "town_meeting":
		s.narrative.flags["ending"] = compute_ending(s)
	return result(true, " ".join(parts), {"follow": follow_ups(s, q, choice)})


## Scenes that play right after a step: the answer to the choice, then the ending's epilogue.
func follow_ups(s: FarmState, q: Dictionary, choice: String) -> Array:
	var out: Array = []
	var reply = "%s_%s" % [q.event, choice]
	if choice != "" and catalog.story.scenes.has(reply):
		out.append(reply)
	if q.id == "new_lantern":
		out.append("new_lantern_end_" + flag(s, "ending"))
	return out


## The scene's pages for this player: pages with a `when` note show only if it holds.
func scene_pages(s: FarmState, event: String) -> Array:
	var out: Array = []
	for page in catalog.story.scenes[event].pages:
		var when: Dictionary = page[2].get("when", {})
		var show = true
		for key in when:
			if key == "partner":
				show = show and partner(s) == when[key]
			else:
				show = show and flag(s, key) == when[key]
		if show:
			out.append(page)
	return out


## What the town has become: lit lamps, friendships made, festivals shared and the answers given.
func town_heart(s: FarmState) -> int:
	var score = lamps(s) * 10 + s.development.events.size() + s.festival_done.size() * 3
	match flag(s, "reservoir"):
		"third":
			score += 10
		"oppose":
			score += 5
	return score


func compute_ending(s: FarmState) -> String:
	var meeting = flag(s, "meeting")
	if meeting == "move":
		return "stream"
	if meeting == "stay" and flag(s, "reservoir") != "cooperate" and town_heart(s) >= 70:
		return "root"
	return "shore"


## The statue wakes with the winter chapter and keeps coming back until the story has its core.
func boss_active(s: FarmState) -> bool:
	var stage = int(s.narrative.stage)
	return (
		stage >= catalog.quest_index("first_snow")
		and stage <= catalog.quest_index("statue")
		and s.inventory.statue_core < 1
	)


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
	var weather = catalog.weather.weather_on(s.world_seed, s.day)
	if catalog.weather.waters_crops(weather) and s.day % 2 == 0:
		return npc.rain
	if stage_of(s, id) == "married":
		return npc.married_talk[s.day % npc.married_talk.size()]
	if int(s.narrative.stage) >= FIRST_ROMANCE_STAGE and s.day % 3 == 0:
		return npc.after
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


## The next unseen event this villager's friendship has unlocked, or {}. Married life adds two
## more that arrive a week and four weeks after the wedding.
func available_event(s: FarmState, id: String) -> Dictionary:
	var npc = catalog.story.npcs[id]
	for event in npc.events:
		if int(s.relationships[id]) >= int(event.at) and not s.development.events.has(event.id):
			return event
	if stage_of(s, id) == "married":
		for event in npc.married_events:
			var since = s.day - int(s.romance[id].day)
			if since >= int(event.after) and not s.development.events.has(event.id):
				return event
	return {}


func is_heart_event(event_id: String) -> bool:
	for id in catalog.story.npcs:
		for event in catalog.story.npcs[id].events + catalog.story.npcs[id].married_events:
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
	var pay = 60 if lamp_lit(s, 6) else 30
	s.gold += pay
	s.stats.earned += pay
	for id in s.relationships:
		s.relationships[id] = mini(100, int(s.relationships[id]) + 2)
	return result(true, "参加了「%s」：%s 金币 +%d，大家都近了一点。" % [festival.name, festival.text, pay])


func claim_event(s: FarmState, event_id: String) -> Dictionary:
	for id in catalog.story.npcs:
		for event in catalog.story.npcs[id].events + catalog.story.npcs[id].married_events:
			if event.id != event_id:
				continue
			var open = available_event(s, id)
			if open.is_empty() or open.id != event_id:
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


# ---------------------------------------------------------------------------- courtship


## "", "dating", "engaged" or "married".
func stage_of(s: FarmState, id: String) -> String:
	return str(s.romance[id].stage) if s.romance.has(id) else ""


## The villager the player is courting, engaged to or married to, or "".
func partner(s: FarmState) -> String:
	for id in s.romance:
		return id
	return ""


func spouse(s: FarmState) -> String:
	var id = partner(s)
	return id if id != "" and stage_of(s, id) == "married" else ""


func romanceable(id: String) -> bool:
	return catalog.story.npcs.has(id) and catalog.story.npcs[id].romance


func heart_event_seen(s: FarmState, id: String, at: int) -> bool:
	return s.development.events.has("%s_%d" % [id, at])


## "" when the villager can be given a heart lantern, otherwise the reason.
func confess_blocker(s: FarmState, id: String) -> String:
	if not romanceable(id):
		return "他们只想做朋友。"
	if int(s.narrative.stage) < FIRST_ROMANCE_STAGE:
		return "灯夜还没有重燃，再等一等。"
	if partner(s) == id:
		return "你们已经在一起了。"
	if partner(s) != "":
		return "你已经有重要的人了。"
	if (
		int(s.relationships[id]) < COURTSHIP_FRIENDSHIP
		or not heart_event_seen(s, id, COURTSHIP_FRIENDSHIP)
	):
		return "还需要更了解彼此（好感 %d，并听完前几段心里话）。" % COURTSHIP_FRIENDSHIP
	if s.inventory.heart_lantern < 1:
		return "需要一盏心意灯（杂货店有卖）。"
	return ""


func confess(s: FarmState, id: String) -> Dictionary:
	var reason = confess_blocker(s, id)
	if not reason.is_empty():
		return result(false, reason)
	s.inventory.heart_lantern -= 1
	s.romance[id] = {"stage": "dating", "day": s.day}
	return result(true, "%s收下了你的心意灯。" % catalog.story.npcs[id].name, {"scene": "dating_" + id})


func propose_blocker(s: FarmState, id: String) -> String:
	if stage_of(s, id) != "dating":
		return "还没有走到这一步。"
	if (
		int(s.relationships[id]) < WEDDING_FRIENDSHIP
		or not heart_event_seen(s, id, WEDDING_FRIENDSHIP)
	):
		return "还需要更了解彼此（好感 %d，并听完所有心里话）。" % WEDDING_FRIENDSHIP
	if s.inventory.union_ring < 1:
		return "需要一枚同心环（铁匠铺有卖）。"
	return ""


func propose(s: FarmState, id: String) -> Dictionary:
	var reason = propose_blocker(s, id)
	if not reason.is_empty():
		return result(false, reason)
	s.inventory.union_ring -= 1
	s.romance[id] = {"stage": "engaged", "day": s.day}
	return result(
		true,
		"%s答应了。婚礼在 %d 天后。" % [catalog.story.npcs[id].name, WEDDING_DELAY],
		{"scene": "engage_" + id}
	)


func wedding_day(s: FarmState) -> int:
	var id = partner(s)
	if id == "" or stage_of(s, id) != "engaged":
		return 0
	return int(s.romance[id].day) + WEDDING_DELAY


## The villager whose wedding is today (or overdue), or "".
func wedding_due(s: FarmState) -> String:
	var day = wedding_day(s)
	return partner(s) if day > 0 and s.day >= day else ""


func wed(s: FarmState, id: String) -> Dictionary:
	if stage_of(s, id) != "engaged":
		return result(false, "")
	s.romance[id] = {"stage": "married", "day": s.day}
	return result(true, "你和%s结婚了。" % catalog.story.npcs[id].name)


## What the spouse did for the household this morning, applied to the state. {} when single.
func spouse_morning(s: FarmState) -> Dictionary:
	var id = spouse(s)
	if id == "":
		return {}
	var chore: Dictionary = catalog.spouses[id]
	if chore.get("water", false):
		for plot in s.plots.values():
			plot.watered = true
	s.gold += int(chore.get("gold", 0))
	s.stats.earned += int(chore.get("gold", 0))
	for item in chore.get("items", {}):
		s.inventory[item] += int(chore.items[item])
	return {"text": chore.text, "id": id}


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
	if destination == "lake" and not bridge_open(s):
		return result(false, "木桥还没修好。")
	if destination == "far_shore" and not ferry_open(s):
		return result(false, "渡口的船还不能下水。")
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

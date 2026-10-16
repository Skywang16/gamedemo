class_name ShopRules
extends RefCounted

var catalog: ContentCatalog
var stories: StoryRules


func _init(content: ContentCatalog) -> void:
	catalog = content
	stories = StoryRules.new(content)


func result(ok: bool, message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r


func hours_text(shop_id: String) -> String:
	var shop = catalog.shops[shop_id]
	return "%02d:00–%02d:00" % [shop.open, shop.close]


## "" when the shop is open, otherwise why it is not.
func closed_reason(shop_id: String, s: FarmState) -> String:
	var shop = catalog.shops[shop_id]
	var date = catalog.calendar.date(s.day)
	if int(date.weekday) in shop.closed_weekdays.map(func(d): return int(d)):
		return "%s今天休息（%s）。" % [shop.name, date.weekday_name]
	if catalog.calendar.is_festival(s.day) and s.minute >= 9 * 60 and s.minute < 14 * 60:
		return "%s去参加节日了，下午再来吧。" % shop.name
	if s.minute < int(shop.open) * 60 or s.minute >= int(shop.close) * 60:
		return "%s已经打烊。营业时间 %s。" % [shop.name, hours_text(shop_id)]
	return ""


## Everything a counter sells right now: [{item, price}].
func stock(shop_id: String, s: FarmState) -> Array:
	var shop = catalog.shops[shop_id]
	var out: Array = []
	if shop.get("seeds", "") == "season":
		var season = catalog.calendar.season_of(s.day)
		for crop_id in catalog.crops:
			var crop = catalog.crops[crop_id]
			if crop.seasons.has(season) or stories.greenhouse(s):
				out.append(
					{"item": crop.seed_item, "price": int(catalog.items[crop.seed_item].buy_price)}
				)
	for item in shop.goods:
		out.append({"item": item, "price": int(shop.goods[item])})
	return out


func buy(s: FarmState, shop_id: String, item: String, quantity: int) -> Dictionary:
	var reason = closed_reason(shop_id, s)
	if not reason.is_empty():
		return result(false, reason)
	if quantity < 1 or quantity > 99:
		return result(false, "购买数量无效。")
	var price = -1
	for entry in stock(shop_id, s):
		if entry.item == item:
			price = int(entry.price)
	if price < 0:
		return result(false, "这里不卖这个。")
	if s.gold < price * quantity:
		return result(false, "金币不足")
	s.gold -= price * quantity
	s.inventory[item] += quantity
	return result(true, "+%d %s" % [quantity, catalog.items[item].name])


func buys(shop_id: String, item: String) -> bool:
	return (
		catalog.items[item].kind in catalog.shops[shop_id].buys
		and int(catalog.items[item].sell_price) > 0
	)


func sell_item(s: FarmState, shop_id: String, item: String, quantity: int) -> Dictionary:
	var reason = closed_reason(shop_id, s)
	if not reason.is_empty():
		return result(false, reason)
	if not buys(shop_id, item) or quantity < 1 or s.inventory[item] < quantity:
		return result(false, "这里不收这个，或者数量不够。")
	var gold = int(catalog.items[item].sell_price) * quantity
	s.inventory[item] -= quantity
	s.gold += gold
	s.stats.earned += gold
	s.progress.sold = true
	return result(true, "卖出 %s ×%d · +%d G" % [catalog.items[item].name, quantity, gold])


func sell_all(s: FarmState, shop_id: String) -> Dictionary:
	var reason = closed_reason(shop_id, s)
	if not reason.is_empty():
		return result(false, reason)
	var gold = 0
	var count = 0
	for id in catalog.items:
		if buys(shop_id, id) and int(s.inventory[id]) > 0:
			gold += int(s.inventory[id]) * int(catalog.items[id].sell_price)
			count += int(s.inventory[id])
			s.inventory[id] = 0
	if count == 0:
		return result(false, "没有可出售的东西")
	s.gold += gold
	s.stats.earned += gold
	s.progress.sold = true
	return result(true, "出售 %d 件 · +%d G" % [count, gold])


func sell_quote(s: FarmState, shop_id: String) -> Dictionary:
	var gold = 0
	var count = 0
	for id in catalog.items:
		if buys(shop_id, id):
			gold += int(s.inventory[id]) * int(catalog.items[id].sell_price)
			count += int(s.inventory[id])
	return {"gold": gold, "count": count}


# ---------------------------------------------------------------------------- the forge


func smelt(s: FarmState, ore: String) -> Dictionary:
	var reason = closed_reason("smith", s)
	if not reason.is_empty():
		return result(false, reason)
	if not catalog.smelting.has(ore):
		return result(false, "这不是矿石。")
	if s.inventory[ore] < 5 or s.inventory.coal < 1:
		return result(false, "需要 5 份%s和 1 份煤。" % catalog.items[ore].name)
	s.inventory[ore] -= 5
	s.inventory.coal -= 1
	var bar: String = catalog.smelting[ore]
	s.inventory[bar] += 1
	s.development.mining_xp += 5
	return result(true, "炼出了 1 块%s。" % catalog.items[bar].name)


func tool_upgrade_cost(s: FarmState, tool: String) -> Dictionary:
	var level = int(s.development.tools[tool])
	if level >= catalog.tool_tiers.size():
		return {}
	return catalog.tool_tiers[level]


func upgrade_tool(s: FarmState, tool: String) -> Dictionary:
	var reason = closed_reason("smith", s)
	if not reason.is_empty():
		return result(false, reason)
	var tier = tool_upgrade_cost(s, tool)
	if tier.is_empty():
		return result(false, "已经是最高等级了。")
	if s.inventory[tier.bar] < 5:
		return result(false, "需要 5 块%s。" % catalog.items[tier.bar].name)
	if s.gold < int(tier.gold):
		return result(false, "需要 %d 金币。" % int(tier.gold))
	s.inventory[tier.bar] -= 5
	s.gold -= int(tier.gold)
	s.development.tools[tool] += 1
	return result(true, "升级完成：%s级。" % tier.name)


# ---------------------------------------------------------------------------- the tackle shop


func upgrade_rod(s: FarmState) -> Dictionary:
	var reason = closed_reason("tackle", s)
	if not reason.is_empty():
		return result(false, reason)
	var next = int(s.development.rod) + 1
	if next >= catalog.rods.size():
		return result(false, "已经是最好的鱼竿了。")
	var rod = catalog.rods[next]
	if s.gold < int(rod.price):
		return result(false, "需要 %d 金币。" % int(rod.price))
	s.gold -= int(rod.price)
	s.development.rod = next
	return result(true, "换上了%s。" % rod.name)


# ---------------------------------------------------------------------------- the clinic


func heal(s: FarmState) -> Dictionary:
	var reason = closed_reason("clinic", s)
	if not reason.is_empty():
		return result(false, reason)
	if s.stamina >= FarmState.MAX_STAMINA:
		return result(false, "你看起来精神很好。")
	var price = 30
	if s.gold < price:
		return result(false, "需要 %d 金币。" % price)
	s.gold -= price
	s.stamina = FarmState.MAX_STAMINA
	return result(true, "安布罗斯医生给你开了一碗热汤，体力恢复了。")

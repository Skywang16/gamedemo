class_name AnimalRules
extends RefCounted

var catalog: ContentCatalog


func _init(content: ContentCatalog) -> void:
	catalog = content


func result(ok: bool, message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r


func built(s: FarmState, id: String) -> bool:
	return s.buildings.has(id) and s.day >= int(s.buildings[id].ready_day)


func under_construction(s: FarmState, id: String) -> bool:
	return s.buildings.has(id) and s.day < int(s.buildings[id].ready_day)


func build(s: FarmState, id: String) -> Dictionary:
	var spec = catalog.buildings[id]
	if spec.kind != "animal":
		return result(false, "这座建筑不能在这里订做。")
	if s.buildings.has(id):
		return result(false, "已经有%s了。" % spec.name)
	if s.gold < int(spec.price):
		return result(false, "需要 %d 金币。" % int(spec.price))
	for material in spec.materials:
		if s.inventory[material] < int(spec.materials[material]):
			return result(false, "材料不够：%s。" % catalog.items[material].name)
	s.gold -= int(spec.price)
	for material in spec.materials:
		s.inventory[material] -= int(spec.materials[material])
	s.buildings[id] = {"ready_day": s.day + int(spec.days)}
	return result(true, "赛拉斯接下了活，%d 天后完工。" % int(spec.days))


const NAMES = ["花花", "豆豆", "团团", "奶糖", "阿黄", "小白", "点点", "圆圆", "毛毛", "糯米", "年糕", "汤圆"]


## The first name from the pool that no animal on the farm already has.
func default_name(s: FarmState, species: String) -> String:
	var taken: Array = []
	for a in s.animals:
		taken.append(a.name)
	for candidate in NAMES:
		if candidate not in taken:
			return candidate
	return "%s%d" % [catalog.animals[species].name, s.animals.size() + 1]


func housed(s: FarmState, building: String) -> int:
	var count = 0
	for a in s.animals:
		if catalog.animals[a.species].building == building:
			count += 1
	return count


func buy(s: FarmState, species: String, animal_name: String) -> Dictionary:
	var spec = catalog.animals[species]
	if not built(s, spec.building):
		return result(false, "还没有%s。" % catalog.buildings[spec.building].name)
	if housed(s, spec.building) >= int(catalog.buildings[spec.building].capacity):
		return result(false, "%s住满了。" % catalog.buildings[spec.building].name)
	if s.gold < int(spec.price):
		return result(false, "需要 %d 金币。" % int(spec.price))
	var clean = animal_name.strip_edges()
	if clean.is_empty() or clean.length() > 10:
		return result(false, "名字不能为空，也不能超过 10 个字。")
	s.gold -= int(spec.price)
	(
		s
		. animals
		. append(
			{
				"species": species,
				"name": clean,
				"friendship": 0,
				"fed": false,
				"petted": false,
				"age": 0,
				"wait": int(spec.interval),
				"ready": false,
			}
		)
	)
	return result(true, "%s搬进了新家。" % clean)


func feed_all(s: FarmState, building: String) -> Dictionary:
	var hungry = 0
	for a in s.animals:
		if catalog.animals[a.species].building == building and not a.fed:
			hungry += 1
	if hungry == 0:
		return result(false, "都已经吃饱了。")
	if s.inventory.hay < hungry:
		return result(false, "需要 %d 份干草。" % hungry)
	s.inventory.hay -= hungry
	for a in s.animals:
		if catalog.animals[a.species].building == building:
			a.fed = true
	return result(true, "喂好了 %d 只。" % hungry)


func pet(s: FarmState, index: int) -> Dictionary:
	var a = s.animals[index]
	if a.petted:
		return result(false, "今天已经摸过了。")
	a.petted = true
	a.friendship = mini(100, int(a.friendship) + 3)
	return result(true, "%s蹭了蹭你。" % a.name)


func collect(s: FarmState, building: String) -> Dictionary:
	var parts: Array[String] = []
	for i in s.animals.size():
		var a = s.animals[i]
		var spec = catalog.animals[a.species]
		if spec.building != building or not a.ready:
			continue
		var special = (hash("%d:%d:%d" % [s.world_seed, s.day, i]) % 100) < int(a.friendship) / 2
		var item: String = spec.special if special else spec.product
		s.inventory[item] += 1
		a.ready = false
		parts.append(catalog.items[item].name)
	if parts.is_empty():
		return result(false, "现在没有可以收的东西。")
	return result(true, "收获：" + "、".join(parts))


## Morning: fed animals age, grow fonder and produce on schedule; hungry ones sulk.
func next_day(s: FarmState, weather: String) -> void:
	for a in s.animals:
		var spec = catalog.animals[a.species]
		if a.fed:
			a.age += 1
			if a.petted:
				a.friendship = mini(100, int(a.friendship) + 2)
			var adult = int(a.age) >= int(spec.adult_days)
			var can_work = a.species != "pig" or weather == "sunny"
			if adult and can_work and not a.ready:
				a.wait = maxi(0, int(a.wait) - 1)
				if int(a.wait) == 0:
					a.ready = true
					a.wait = int(spec.interval)
		else:
			a.friendship = maxi(0, int(a.friendship) - 1)
		a.fed = false
		a.petted = false

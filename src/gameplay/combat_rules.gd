class_name CombatRules
extends RefCounted

## The mine fights: the sword, who lives on which floor, what they drop. Positions and AI belong
## to the world; everything that changes the save is decided here.

const SAFE_RADIUS = 10  # cells around the spawn point that stay free of monsters

var catalog: ContentCatalog
var stories: StoryRules


func _init(content: ContentCatalog) -> void:
	catalog = content
	stories = StoryRules.new(content)


func result(ok: bool, message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r


func sword_level(s: FarmState) -> int:
	return int(s.development.tools.sword)


## Damage of one sword stroke.
func damage(s: FarmState) -> int:
	return int(catalog.weapon.damage[sword_level(s)])


func swing_cost(s: FarmState) -> int:
	return int(catalog.weapon.cost[sword_level(s)])


func hero_hp() -> int:
	return int(catalog.weapon.hp)


func knockback() -> float:
	return float(catalog.weapon.knockback)


## The monsters of a floor today: [{kind, cell}]. `open` lists the cells they may stand on and
## `boss_cell` is where the boss waits. The same world seed and day always give the same floor.
func spawn_plan(s: FarmState, map_id: String, open: Array, boss_cell: Vector2i) -> Array:
	var out: Array = []
	if not catalog.spawns.has(map_id):
		return out
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("spawn:%d:%d:%s" % [s.world_seed, s.day, map_id])
	var region = catalog.region(map_id)
	var start = Vector2i(int(region.spawn[0] / 32), int(region.spawn[1] / 32))
	var cells: Array = open.filter(
		func(c): return absi(c.x - start.x) + absi(c.y - start.y) > SAFE_RADIUS
	)
	for i in range(cells.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var swap = cells[i]
		cells[i] = cells[j]
		cells[j] = swap
	var kinds = catalog.spawns[map_id].keys()
	kinds.sort()
	for kind in kinds:
		var spec = catalog.enemies[kind]
		if spec.boss:
			if stories.boss_active(s):
				out.append({"kind": kind, "cell": boss_cell})
			continue
		for n in int(catalog.spawns[map_id][kind]):
			if cells.is_empty():
				break
			out.append({"kind": kind, "cell": cells.pop_back()})
	return out


## What a defeated monster leaves behind, rolled from `rng`: {item: count}.
func roll_drops(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var out: Dictionary = {}
	for drop in catalog.enemies[kind].drops:
		if rng.randi_range(1, 100) <= int(drop[1]):
			out[drop[0]] = int(out.get(drop[0], 0)) + rng.randi_range(int(drop[2]), int(drop[3]))
	return out


## Pays out a kill: drops go to the bag, experience to mining.
func defeat(s: FarmState, kind: String, rng: RandomNumberGenerator) -> Dictionary:
	var spec = catalog.enemies[kind]
	var drops = roll_drops(kind, rng)
	var parts: Array[String] = []
	for item in drops:
		s.inventory[item] += drops[item]
		parts.append("%s ×%d" % [catalog.items[item].name, drops[item]])
	s.development.mining_xp += int(spec.xp)
	s.stats.defeated += 1
	var text = "击败了%s" % spec.name
	if not parts.is_empty():
		text += "：" + "、".join(parts)
	return result(true, text, {"drops": drops})


## One swing: costs stamina, or says why not.
func swing(s: FarmState) -> Dictionary:
	var cost = swing_cost(s)
	if s.stamina < cost:
		return result(false, "体力不足")
	s.stamina -= cost
	return result(true, "")

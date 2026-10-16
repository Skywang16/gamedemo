extends SceneTree

## The mine: the sword, who lives where, what falls when they do.

var failures: Array[String] = []
var checks: int = 0
var catalog: ContentCatalog
var combat: CombatRules
var story: StoryRules


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)


func run() -> void:
	catalog = ContentCatalog.new()
	var error = catalog.load_content()
	check(error.is_empty(), "content loads: " + error)
	if error.is_empty():
		combat = CombatRules.new(catalog)
		story = StoryRules.new(catalog)
		test_sword()
		test_spawns()
		test_drops()
		test_boss()
		test_upgrades()
		test_data()
	print("COMBAT_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func open_cells(map_id: String) -> Array:
	var region = catalog.region(map_id)
	var out: Array = []
	for y in range(int(region.height)):
		for x in range(int(region.width)):
			var cell = Vector2i(x, y)
			if not catalog.blocked(cell, map_id) and not catalog.is_water(cell, map_id):
				out.append(cell)
	return out


func test_sword() -> void:
	var s = FarmState.new_game(catalog)
	check(combat.sword_level(s) == 0 and combat.damage(s) == 8, "the first sword hits for eight")
	check(combat.hero_hp() == 40, "the hero has forty hit points")
	var stamina = s.stamina
	check(
		combat.swing(s).ok and s.stamina == stamina - combat.swing_cost(s), "a swing costs stamina"
	)
	s.stamina = 1
	var before = s.snapshot(catalog)
	check(not combat.swing(s).ok and before == s.snapshot(catalog), "a tired arm cannot swing")
	for level in range(5):
		s.development.tools.sword = level
		check(combat.damage(s) == int(catalog.weapon.damage[level]), "damage at level %d" % level)
	check(combat.damage(s) > 3 * 8, "the best sword is far stronger")
	check(combat.knockback() > 0.0, "blows push back")


func test_spawns() -> void:
	var s = FarmState.new_game(catalog, 77)
	s.day = 5
	var plan1 = combat.spawn_plan(s, "mine_1", open_cells("mine_1"), Vector2i(32, 8))
	var plan2 = combat.spawn_plan(s, "mine_1", open_cells("mine_1"), Vector2i(32, 8))
	check(plan1 == plan2, "a floor looks the same all day")
	check(
		plan1.size() == 7 and plan1.all(func(e): return e.kind == "slime"),
		"seven slimes on the first floor"
	)
	s.day = 6
	check(
		combat.spawn_plan(s, "mine_1", open_cells("mine_1"), Vector2i(32, 8)) != plan1,
		"and different tomorrow"
	)
	var region = catalog.region("mine_1")
	var start = Vector2i(int(region.spawn[0] / 32), int(region.spawn[1] / 32))
	for e in plan1:
		check(
			absi(e.cell.x - start.x) + absi(e.cell.y - start.y) > CombatRules.SAFE_RADIUS,
			"monsters keep away from the stairs"
		)
		check(not catalog.blocked(e.cell, "mine_1"), "and stand on open ground")
	var second = combat.spawn_plan(s, "mine_2", open_cells("mine_2"), Vector2i(32, 8))
	var kinds = {}
	for e in second:
		kinds[e.kind] = int(kinds.get(e.kind, 0)) + 1
	check(kinds == {"slime": 4, "bat": 5}, "slimes and bats on the second floor %s" % str(kinds))
	check(
		combat.spawn_plan(s, "forest", open_cells("forest"), Vector2i(1, 1)).is_empty(),
		"no monsters in the forest"
	)
	var cells = {}
	for e in plan1:
		check(not cells.has(e.cell), "no two monsters share a cell")
		cells[e.cell] = true


func test_boss() -> void:
	var s = FarmState.new_game(catalog)
	var open = open_cells("mine_3")
	var plan = combat.spawn_plan(s, "mine_3", open, Vector2i(32, 8))
	check(not plan.any(func(e): return e.kind == "statue"), "the statue sleeps before its time")
	s.narrative.stage = catalog.quest_index("statue")
	check(story.boss_active(s), "it wakes when the story needs it")
	plan = combat.spawn_plan(s, "mine_3", open, Vector2i(32, 8))
	var statues = plan.filter(func(e): return e.kind == "statue")
	check(
		statues.size() == 1 and statues[0].cell == Vector2i(32, 8), "one statue waits in the deep"
	)
	check(plan.filter(func(e): return e.kind == "golem").size() == 5, "five golems guard it")
	s.inventory.statue_core = 1
	check(not story.boss_active(s), "it stays down once beaten")
	s.inventory.statue_core = 0
	s.narrative.stage = catalog.quest_index("statue") + 1
	check(not story.boss_active(s), "and never returns after the quest")
	s.narrative.stage = catalog.quest_index("first_snow")
	check(story.boss_active(s), "it is already there once the winter chapter opens")


func test_drops() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 9
	var s = FarmState.new_game(catalog)
	var slimes = 0
	for i in 200:
		var drops = combat.roll_drops("slime", rng)
		for item in drops:
			check(item == "slime_goo" and drops[item] >= 1 and drops[item] <= 2, "slimes leave goo")
		slimes += int(drops.get("slime_goo", 0))
	check(slimes > 120 and slimes < 340, "about seventy percent of slimes drop goo (%d)" % slimes)
	check(combat.roll_drops("statue", rng).has("statue_core"), "the statue always drops its core")
	var xp = s.development.mining_xp
	rng.seed = 1
	var reward = combat.defeat(s, "statue", rng)
	check(reward.ok and s.inventory.statue_core == 1, "defeating the boss pays the core")
	check(s.inventory.gold_ore >= 3 and s.inventory.gold_ore <= 5, "and gold ore")
	check(s.development.mining_xp == xp + 60 and s.stats.defeated == 1, "experience and the tally")
	var again = FarmState.new_game(catalog)
	var a = RandomNumberGenerator.new()
	var b = RandomNumberGenerator.new()
	a.seed = 5
	b.seed = 5
	check(
		combat.roll_drops("golem", a) == combat.roll_drops("golem", b), "drops replay from the seed"
	)
	check(again.stats.defeated == 0, "a new hero has beaten no one")


func test_upgrades() -> void:
	var shops = ShopRules.new(catalog)
	var s = FarmState.new_game(catalog)
	s.day = 2
	s.minute = 10 * 60
	s.gold = 10000
	s.inventory.copper_bar = 5
	check(
		shops.upgrade_tool(s, "sword").ok and s.development.tools.sword == 1,
		"the smith upgrades the sword"
	)
	check(combat.damage(s) == 13, "and it hits harder")
	var spent = FarmState.new_game(catalog)
	check(spent.development.tools.has("sword"), "every new game has a sword")
	check(
		SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(), "the upgraded sword saves"
	)
	var broken = s.snapshot(catalog)
	broken.development.tools.sword = 9
	check(not SaveStore.new(catalog).validate(broken).is_empty(), "a sword beyond gold is rejected")


func test_data() -> void:
	for kind in catalog.enemies:
		var spec = catalog.enemies[kind]
		check(ResourceLoader.exists("res://assets/art/enemy_%s.png" % kind), "art for " + kind)
		check(int(spec.hp) > 0 and int(spec.damage) > 0, "stats for " + kind)
		for drop in spec.drops:
			check(catalog.items.has(drop[0]), "drop exists: " + str(drop[0]))
	for map_id in catalog.spawns:
		check(
			catalog.regions.has(map_id) and map_id.begins_with("mine_"),
			"monsters live in the mine: " + map_id
		)
	check(catalog.items.statue_core.kind == "drop", "the core is a trophy")
	check(
		catalog.items.heart_lantern.buy_price > 0 and catalog.items.union_ring.buy_price > 0,
		"love has a price"
	)
	for shop in ["smith"]:
		check(catalog.shops[shop].goods.has("union_ring"), "the ring is sold at the forge")
	check(
		catalog.shops.general.goods.has("heart_lantern"),
		"heart lanterns are sold in the general store"
	)

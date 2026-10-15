extends SceneTree
var checks = 0
var failures: Array[String] = []
var catalog: ContentCatalog
var rules: FarmRules
var story: StoryRules


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error("FAIL: " + message)


func run() -> void:
	catalog = ContentCatalog.new()
	var error = catalog.load_content()
	check(error.is_empty(), "chapter content: " + error)
	if not error.is_empty():
		finish()
		return
	rules = FarmRules.new(catalog)
	story = StoryRules.new(catalog)
	test_chapter()
	test_growth()
	test_persistence()
	test_maps()
	finish()


func finish() -> void:
	print("CHAPTER_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func test_chapter() -> void:
	var s = FarmState.new_game(catalog)
	check(story.complete(s, "prologue", "grow").ok, "prologue choice saved")
	check(not story.complete(s, "prologue", "restart").ok, "intro cannot repeat")
	check(story.complete(s, "welcome").ok, "meet neighbor")
	var before = s.snapshot(catalog)
	check(not story.complete(s, "first_meal").ok, "tutorial and produce required")
	check(before == s.snapshot(catalog), "failed delivery atomic")
	check(not story.enter(s, "lake", Vector2(144, 944)).ok, "lake locked")
	for x in range(34, 38):
		var cell = Vector2i(x, 20)
		check(rules.apply_tool(s, "scythe", cell, cell, "turnip").ok, "reclaim wild land")
		check(rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "prepare plot")
		check(rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "seed plot")
	for day in range(3):
		for x in range(34, 38):
			rules.apply_tool(s, "water", Vector2i(x, 20), Vector2i(x, 20), "turnip")
		rules.next_day(s)
	for x in range(34, 38):
		check(
			rules.apply_tool(s, "harvest", Vector2i(x, 20), Vector2i(x, 20), "turnip").ok,
			"real crop harvest"
		)
	check(s.inventory.turnip == 4 and s.development.farming_xp == 40, "harvest experience")
	check(story.complete(s, "first_meal").ok, "meal delivery")
	check(
		s.inventory.turnip == 2 and s.gold == 60 and s.narrative.stage == 2, "meal costs and reward"
	)
	before = s.snapshot(catalog)
	check(
		not story.complete(s, "first_meal").ok and before == s.snapshot(catalog),
		"no repeated reward"
	)
	check(story.enter(s, "forest", Vector2(1232, 1904)).ok, "enter forest")
	for node in catalog.regions.forest.gather:
		check(story.gather(s, node.id).ok, "gather " + node.id)
		before = s.snapshot(catalog)
		check(
			not story.gather(s, node.id).ok and before == s.snapshot(catalog),
			"daily resource only once"
		)
	check(
		s.inventory.wood == 4 and s.inventory.stone == 3 and s.inventory.berry == 3,
		"forest supplies chapter resources"
	)
	check(story.complete(s, "bridge").ok, "bridge repaired")
	check(s.inventory.wood == 0 and s.inventory.stone == 0, "bridge payment once")
	check(story.enter(s, "lake", Vector2(144, 944)).ok, "lake unlocked")
	check(story.complete(s, "notebook").ok, "notebook read")
	check(story.complete(s, "feast").ok, "feast delivery")
	check(s.inventory.turnip == 0 and s.inventory.berry == 0, "feast payment")
	before = s.snapshot(catalog)
	check(
		not story.complete(s, "festival", "bad").ok and before == s.snapshot(catalog),
		"invalid ending atomic"
	)
	check(story.complete(s, "festival", "together").ok, "finish chapter from farm and forest")
	check(
		s.narrative.stage == 6 and s.narrative.wish == "together" and s.gold == 110,
		"choice and reward persisted"
	)
	before = s.snapshot(catalog)
	check(
		not story.complete(s, "festival", "stay").ok and before == s.snapshot(catalog),
		"ending cannot repeat"
	)
	check(
		SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(),
		"completed chapter save valid"
	)


func test_growth() -> void:
	var s = FarmState.new_game(catalog)
	story.talk(s, "ahe")
	story.talk(s, "ahe")
	check(s.relationships.ahe == 4, "daily chat only once")
	s.inventory.turnip = 3
	check(story.gift(s, "ahe", "turnip").ok and s.relationships.ahe == 14, "favorite gift bonus")
	var before = s.snapshot(catalog)
	check(
		not story.gift(s, "ahe", "turnip").ok and before == s.snapshot(catalog),
		"daily gift limit atomic"
	)
	check(not story.memory(s, "ahe").ok, "memory requires relationship")
	for day in range(2):
		rules.next_day(s)
		story.talk(s, "ahe")
		story.gift(s, "ahe", "turnip")
	check(s.relationships.ahe == 42, "relationship accumulates")
	check(story.memory(s, "ahe").ok and s.development.memories.has("ahe"), "memory unlocked")
	before = s.snapshot(catalog)
	check(not story.memory(s, "ahe").ok and before == s.snapshot(catalog), "memory reward once")
	s.inventory.wood = 3
	s.inventory.stone = 2
	check(not story.upgrade(s).ok, "upgrade requires level")
	s.development.farming_xp = 40
	check(story.upgrade(s).ok and s.gold == 30, "upgrade payment")
	for x in range(34, 37):
		rules.apply_tool(s, "scythe", Vector2i(x, 20), Vector2i(x, 20), "turnip")
		rules.apply_tool(s, "hoe", Vector2i(x, 20), Vector2i(x, 20), "turnip")
	var stamina = s.stamina
	rules.apply_tool(s, "water", Vector2i(35, 20), Vector2i(35, 20), "turnip")
	check(
		s.plots["34,20"].watered and s.plots["35,20"].watered and s.plots["36,20"].watered,
		"copper can covers three tiles"
	)
	check(s.stamina == stamina - 1, "copper can charges once")
	s.inventory.berry = 2
	s.stamina = 80
	check(
		story.cook(s).ok and s.stamina == 100 and s.inventory.berry == 0, "cooking payment and cap"
	)
	check(story.transfer(s, "turnip_seed", true).ok and s.storage.turnip_seed == 1, "deposit")
	check(story.transfer(s, "turnip_seed", false).ok and s.storage.turnip_seed == 0, "withdraw")
	story.enter(s, "forest", Vector2(1232, 1904))
	s.development.foraging_xp = 80
	check(story.gather(s, "wood0").ok and s.inventory.wood == 2, "foraging skill raises yield")
	check(not story.gather(s, "wood0").ok, "resource cooldown")
	rules.next_day(s)
	check(story.gather(s, "wood0").ok, "resource refresh after sleep")


func test_persistence() -> void:
	var folder = "user://chapter-domain-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var store = SaveStore.new(catalog, folder)
	var s = FarmState.new_game(catalog)
	s.profile = {"name": "小雨", "farm": "青苇小院", "skin": 2, "hair": 1, "outfit": 3, "hat": 0}
	s.narrative.active_scene = "welcome"
	s.narrative.page = 1
	s.storage.wood = 7
	s.development.farming_xp = 60
	s.relationships.ahe = 42
	story.enter(s, "cottage", Vector2(464, 464))
	check(store.save_game(s).is_empty(), "current save written")
	var copy = SaveStore.new(catalog, folder).load_game().state
	check(
		copy != null and copy.snapshot(catalog) == s.snapshot(catalog),
		"all character, story and progression fields roundtrip"
	)
	for key in ["profile", "narrative", "daily", "development", "storage"]:
		var invalid = s.snapshot(catalog)
		invalid[key] = []
		check(not store.validate(invalid).is_empty(), "reject malformed " + key)
	var invalid = s.snapshot(catalog)
	invalid.profile.skin = 99
	check(not store.validate(invalid).is_empty(), "reject absent avatar")
	invalid = s.snapshot(catalog)
	invalid.map_id = "lake"
	invalid.player_position = [144, 944]
	check(not store.validate(invalid).is_empty(), "save respects lake lock")
	var dir = DirAccess.open(folder)
	for name in dir.get_files():
		dir.remove(name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))


func test_maps() -> void:
	for id in catalog.regions:
		var area = catalog.region(id)
		var start = Vector2i(int(area.spawn[0] / 32), int(area.spawn[1] / 32))
		check(not catalog.blocked(start, id), "spawn free: " + id)
		var visited = {start: true}
		var queue = [start]
		while not queue.is_empty():
			var current = queue.pop_front()
			for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var n: Vector2i = current + offset
				if not catalog.blocked(n, id) and not visited.has(n):
					visited[n] = true
					queue.append(n)
		for station in area.stations:
			check(
				visited.has(Vector2i(station.cell[0], station.cell[1])),
				"reachable " + id + "/" + station.id
			)
			if station.kind == "exit":
				check(
					not catalog.blocked(
						Vector2i(int(station.arrival[0] / 32), int(station.arrival[1] / 32)),
						station.destination
					),
					"arrival free " + id + "/" + station.id
				)
		for node in area.get("gather", []):
			check(visited.has(Vector2i(node.cell[0], node.cell[1])), "gather reachable " + node.id)
		for npc in catalog.story.npcs.values():
			if npc.map != id:
				continue
			for pos in npc.positions:
				check(visited.has(Vector2i(pos[0], pos[1])), "NPC reachable " + npc.name)

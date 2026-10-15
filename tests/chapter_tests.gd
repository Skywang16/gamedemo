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
	test_cast()
	test_optional_intro()
	test_chapter()
	test_growth()
	test_heart_events()
	test_festival()
	test_gathering()
	test_persistence()
	test_maps()
	finish()


func finish() -> void:
	print("CHAPTER_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func free_cells(s: FarmState, count: int) -> Array:
	var out: Array = []
	for y in range(18, 66):
		for x in range(4, 90):
			var cell = Vector2i(x, y)
			if (
				catalog.plantable(cell, s.tree_damage)
				and catalog.tree_at(cell, s).is_empty()
				and catalog.debris_at(cell, s).is_empty()
			):
				out.append(cell)
				if out.size() == count:
					return out
	return out


func test_cast() -> void:
	var npcs = catalog.story.npcs
	check(npcs.size() == 30, "thirty villagers plus the grandmother's letter")
	var romances = 0
	var genders = {}
	var families = {}
	for id in npcs:
		var npc = npcs[id]
		genders[npc.gender] = true
		families[npc.household] = true
		check(not npc.en.is_empty(), "every villager has an English name: " + id)
		check(npc.schedule.rules.size() >= 3, "every villager has a real routine: " + id)
		var last = npc.schedule.rules[npc.schedule.rules.size() - 1]
		check(last.when.is_empty(), "the last rule is unconditional: " + id)
		check(npc.events.size() == (5 if npc.romance else 3), "heart events: " + id)
		if npc.romance:
			romances += 1
		var seen = 0
		for event in npc.events:
			check(int(event.at) > seen, "events are ordered: " + id)
			seen = int(event.at)
		for item in npc.likes + npc.dislikes + [npc.favorite]:
			check(catalog.items.has(item), "taste names a real item: %s %s" % [id, item])
	check(romances == 12, "twelve villagers can be courted")
	check(genders.has("F") and genders.has("M"), "both genders live in town")
	check(families.size() >= 12, "households differ")


func test_chapter() -> void:
	var s = FarmState.new_game(catalog)
	s.minute = 10 * 60
	check(story.complete(s, "prologue", "grow").ok, "prologue choice saved")
	check(not story.complete(s, "prologue", "restart").ok, "the intro cannot repeat")
	check(story.complete(s, "welcome").ok, "meet the neighbor")
	var before = s.snapshot(catalog)
	check(not story.complete(s, "first_meal").ok, "delivery requires produce")
	check(before == s.snapshot(catalog), "a failed delivery is atomic")
	var lake = Vector2(catalog.region("lake").spawn[0], catalog.region("lake").spawn[1])
	check(not story.enter(s, "lake", lake).ok, "the lake is locked")
	var cells = free_cells(s, 4)
	for cell in cells:
		check(rules.apply_tool(s, "hoe", cell, cell, "turnip").ok, "prepare plot")
		check(rules.apply_tool(s, "seed", cell, cell, "turnip").ok, "seed plot")
	for day in range(3):
		for cell in cells:
			rules.apply_tool(s, "water", cell, cell, "turnip")
		rules.next_day(s)
	for cell in cells:
		check(rules.apply_tool(s, "harvest", cell, cell, "turnip").ok, "real crop harvest")
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
	check(
		(
			story
			. enter(
				s,
				"forest",
				Vector2(catalog.region("forest").spawn[0], catalog.region("forest").spawn[1])
			)
			. ok
		),
		"enter the forest"
	)
	s.inventory.wood = 4
	s.inventory.stone = 3
	check(story.complete(s, "bridge").ok, "bridge repaired")
	check(s.inventory.wood == 0 and s.inventory.stone == 0, "bridge payment once")
	check(story.enter(s, "lake", lake).ok, "the lake is unlocked")
	check(story.complete(s, "notebook").ok, "notebook read")
	s.inventory.berry = 3
	check(story.complete(s, "feast").ok, "feast delivery")
	check(s.inventory.turnip == 0 and s.inventory.berry == 0, "feast payment")
	before = s.snapshot(catalog)
	check(
		not story.complete(s, "festival", "bad").ok and before == s.snapshot(catalog),
		"an invalid ending is atomic"
	)
	check(story.complete(s, "festival", "together").ok, "finish the chapter")
	check(
		s.narrative.stage == 6 and s.narrative.wish == "together" and s.gold == 110,
		"choice and reward persisted"
	)
	before = s.snapshot(catalog)
	check(
		not story.complete(s, "festival", "stay").ok and before == s.snapshot(catalog),
		"the ending cannot repeat"
	)
	check(
		SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(),
		"the completed chapter saves validly"
	)
	check(
		story.talk(s, "hazel") == catalog.story.npcs.hazel.after,
		"villagers talk about the lamps afterwards"
	)


func test_optional_intro() -> void:
	var s = FarmState.new_game(catalog)
	check(
		story.complete(s, "welcome").ok and not s.narrative.intro_seen,
		"the main story does not require the letter"
	)
	s.inventory.turnip = 2
	check(
		story.complete(s, "first_meal").ok and not s.progress.planted,
		"delivery does not require hidden tutorial flags"
	)


func test_growth() -> void:
	var s = FarmState.new_game(catalog)
	story.talk(s, "hazel")
	story.talk(s, "hazel")
	check(s.relationships.hazel == 4, "daily chat only once")
	check(story.taste("hazel", "turnip") == "love", "a favourite is loved")
	check(story.taste("hazel", "honey") == "like", "a liked item")
	check(story.taste("hazel", "fiber") == "dislike", "a disliked item")
	check(story.taste("hazel", "wood") == "neutral", "everything else is neutral")
	s.inventory.turnip = 3
	check(
		story.gift(s, "hazel", "turnip").ok and s.relationships.hazel == 16, "favourite gift bonus"
	)
	var before = s.snapshot(catalog)
	check(
		not story.gift(s, "hazel", "turnip").ok and before == s.snapshot(catalog),
		"the daily gift limit is atomic"
	)
	check(not story.gift(s, "hazel", "turnip_seed").ok, "seeds are not gifts")
	rules.next_day(s)
	s.inventory.fiber = 1
	check(
		story.gift(s, "hazel", "fiber").ok and s.relationships.hazel == 12,
		"a disliked gift costs friendship"
	)
	# Hazel's birthday is spring 3: positive gifts count double.
	rules.next_day(s)
	check(story.birthday_today(s, "hazel"), "birthday on spring 3")
	check(story.talk(s, "hazel") == catalog.story.npcs.hazel.birthday_line, "birthday greeting")
	var friendship = s.relationships.hazel
	check(
		story.gift(s, "hazel", "turnip").ok and s.relationships.hazel == friendship + 24,
		"birthday doubles gifts"
	)
	s.inventory.wood = 3
	s.inventory.stone = 2
	rules.next_day(s)
	check(s.daily.gifted.is_empty() and s.daily.talked.is_empty(), "a new day resets social limits")
	check(story.transfer(s, "turnip", true).ok and s.storage.turnip == 1, "deposit")
	check(story.transfer(s, "turnip", false).ok and s.storage.turnip == 0, "withdraw")
	check(not story.transfer(s, "diamond", true).ok, "cannot store what you lack")


func test_heart_events() -> void:
	var s = FarmState.new_game(catalog)
	check(story.available_event(s, "hazel").is_empty(), "no event at zero friendship")
	check(not story.claim_event(s, "hazel_20").ok, "events need friendship")
	s.relationships.hazel = 20
	var event = story.available_event(s, "hazel")
	check(event.id == "hazel_20", "the first event unlocks at 20")
	check(
		story.is_heart_event("hazel_20") and not story.is_heart_event("welcome"),
		"heart events are recognised"
	)
	var gold = s.gold
	check(
		story.claim_event(s, "hazel_20").ok and s.gold == gold + int(event.reward.gold),
		"claiming pays out"
	)
	check(s.inventory.turnip_seed == 11, "reward items arrive")
	var before = s.snapshot(catalog)
	check(
		not story.claim_event(s, "hazel_20").ok and before == s.snapshot(catalog),
		"an event pays once"
	)
	check(story.available_event(s, "hazel").is_empty(), "the next event waits for 40")
	check(not story.claim_event(s, "no_such_event").ok, "unknown events are refused")


func test_festival() -> void:
	var s = FarmState.new_game(catalog)
	var festival = catalog.calendar.festivals[0]
	s.day = catalog.calendar.day_number(1, festival.season, int(festival.day))
	s.current_map = catalog.calendar.plaza_map
	s.minute = 8 * 60
	check(not story.attend_festival(s).ok, "too early for the festival")
	s.minute = 10 * 60
	var gold = s.gold
	check(story.attend_festival(s).ok and s.gold == gold + 30, "joining pays a little")
	check(s.relationships.hazel == 2, "everyone grows closer")
	check(not story.attend_festival(s).ok, "once per festival")
	s.day = catalog.calendar.day_number(2, festival.season, int(festival.day))
	check(story.attend_festival(s).ok, "the same festival counts again next year")
	s.day += 1
	check(not story.attend_festival(s).ok, "ordinary days have no festival")
	check(s.festival_done.size() == 2, "attendance is remembered")


func test_gathering() -> void:
	var s = FarmState.new_game(catalog)
	s.current_map = "forest"
	var nodes: Array = catalog.region("forest").gather
	check(not nodes.is_empty(), "the forest has things to gather")
	var node = nodes[0]
	var stamina = s.stamina
	var response = story.gather(s, node.id)
	check(response.ok and s.stamina == stamina - 2, "gathering costs stamina")
	check(s.inventory[response.item] == 1, "gathering yields the item")
	var before = s.snapshot(catalog)
	check(
		not story.gather(s, node.id).ok and before == s.snapshot(catalog), "a node gives once a day"
	)
	rules.next_day(s)
	check(story.gather(s, node.id).ok, "nodes refresh after sleep")
	s.development.foraging_xp = 200
	rules.next_day(s)
	var amount = s.inventory[GatherRules.item_for(catalog, s, node)]
	story.gather(s, node.id)
	check(
		s.inventory[GatherRules.item_for(catalog, s, node)] == amount + 2,
		"foraging skill doubles the yield"
	)
	var again = GatherRules.item_for(catalog, s, node)
	check(
		again == GatherRules.item_for(catalog, s, node), "the same day always shows the same item"
	)
	check(not story.gather(s, "no_such_node").ok, "unknown nodes are refused")
	s.stamina = 0
	rules.next_day(s)
	check(s.stamina == FarmState.MAX_STAMINA, "sleep restores stamina")


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
	s.development.fishing_xp = 12
	s.development.rod = 1
	s.development.tools.hoe = 2
	s.relationships.hazel = 42
	s.buildings = {"coop": {"ready_day": 3}}
	s.animals = [
		{
			"species": "chicken",
			"name": "花花",
			"friendship": 6,
			"fed": true,
			"petted": false,
			"age": 2,
			"wait": 1,
			"ready": false,
		}
	]
	s.collected = ["turnip", "wood"]
	s.festival_done = ["1:plow_rite"]
	s.stats.earned = 120
	s.board = {"week": 1, "done": [0, 2]}
	story.enter(s, "cottage", Vector2(464, 464))
	check(store.save_game(s, 1).is_empty(), "the current save is written")
	var copy = SaveStore.new(catalog, folder).load_slot(1).state
	check(
		copy != null and copy.snapshot(catalog) == s.snapshot(catalog),
		"all character, story and progression fields roundtrip"
	)
	for key in ["profile", "narrative", "daily", "development", "storage", "stats", "board"]:
		var invalid = s.snapshot(catalog)
		invalid[key] = []
		check(not store.validate(invalid).is_empty(), "reject malformed " + key)
	var invalid = s.snapshot(catalog)
	invalid.profile.skin = 99
	check(not store.validate(invalid).is_empty(), "reject an absent avatar")
	invalid = s.snapshot(catalog)
	invalid.map_id = "lake"
	invalid.player_position = [catalog.region("lake").spawn[0], catalog.region("lake").spawn[1]]
	check(not store.validate(invalid).is_empty(), "a save respects the lake lock")
	invalid = s.snapshot(catalog)
	invalid.relationships.stranger = 5
	check(not store.validate(invalid).is_empty(), "reject an unknown villager")
	invalid = s.snapshot(catalog)
	invalid.development.events = ["no_such_event"]
	check(not store.validate(invalid).is_empty(), "reject an unknown heart event")
	var dir = DirAccess.open(folder)
	for name in dir.get_files():
		dir.remove(name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))


func reach(id: String, start: Vector2i) -> Dictionary:
	var visited = {start: true}
	var queue = [start]
	while not queue.is_empty():
		var current = queue.pop_front()
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = current + offset
			if not catalog.blocked(n, id) and not visited.has(n):
				visited[n] = true
				queue.append(n)
	return visited


func test_maps() -> void:
	check(catalog.regions.size() == 18, "eighteen maps")
	for id in catalog.regions:
		var area = catalog.region(id)
		var start = Vector2i(int(area.spawn[0] / 32), int(area.spawn[1] / 32))
		check(not catalog.blocked(start, id), "spawn free: " + id)
		var visited = reach(id, start)
		for station in area.stations:
			check(
				visited.has(Vector2i(station.cell[0], station.cell[1])),
				"reachable " + id + "/" + station.id
			)
			if station.kind == "exit":
				var arrival = Vector2i(int(station.arrival[0] / 32), int(station.arrival[1] / 32))
				check(
					not catalog.blocked(arrival, station.destination),
					"arrival free " + id + "/" + station.id
				)
				check(
					reach(station.destination, arrival).has(
						Vector2i(
							catalog.region(station.destination).spawn[0] / 32,
							catalog.region(station.destination).spawn[1] / 32
						)
					),
					"arrival joins the destination " + id + "/" + station.id
				)
		for node in area.get("gather", []):
			check(visited.has(Vector2i(node.cell[0], node.cell[1])), "gather reachable " + node.id)
	for key in catalog.places:
		var place = catalog.place(key)
		var start = Vector2i(
			int(catalog.region(place.map).spawn[0] / 32),
			int(catalog.region(place.map).spawn[1] / 32)
		)
		check(reach(place.map, start).has(place.cell), "place reachable: " + key)

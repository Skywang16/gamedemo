extends SceneTree

## The whole story from the prologue to the finale, the six lamps and what they do, the three
## endings, courtship and marriage.

var failures: Array[String] = []
var checks: int = 0
var catalog: ContentCatalog
var story: StoryRules
var rules: FarmRules
var shops: ShopRules


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
		story = StoryRules.new(catalog)
		rules = FarmRules.new(catalog)
		shops = ShopRules.new(catalog)
		test_shape()
		test_gates()
		test_full_story()
		test_endings()
		test_lamp_effects()
		test_scene_pages()
		test_courtship()
		test_married_life()
	print("STORY_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


## Plays one step of the story the way a player would: waits for the day, makes the friends,
## brings the goods, and answers the first (or the named) choice.
func play_step(s: FarmState, choice: String = "") -> Dictionary:
	var q = story.quest(s)
	s.day = maxi(s.day, int(q.available_day))
	for id in q.friendship:
		s.relationships[id] = maxi(int(s.relationships[id]), int(q.friendship[id]))
	for id in q.needs:
		s.inventory[id] += int(q.needs[id])
	var answer = choice
	if answer == "" and not q.choice.is_empty():
		answer = q.choice[0].id
	return story.complete(s, q.event, answer)


func test_shape() -> void:
	var quests: Array = catalog.story.quests
	check(quests.size() == 36, "thirty-six steps (%d)" % quests.size())
	var chapters = {}
	for q in quests:
		chapters[int(q.chapter)] = int(chapters.get(int(q.chapter), 0)) + 1
	check(chapters == {1: 6, 2: 8, 3: 10, 4: 9, 5: 3}, "the chapters hold %s" % str(chapters))
	var last = quests[quests.size() - 1]
	check(last.event == "" and last.id == "new_year", "the story ends in free life")
	var order: Array = []
	for q in quests:
		if int(q.lamp) > 0:
			order.append(int(q.lamp))
	check(order == [1, 2, 3, 4, 5, 6], "lamps light in order")
	check(catalog.lamp_quest_index(1) == 2, "the bridge is the first lamp")
	for q in quests:
		if q.event != "":
			check(catalog.story.scenes.has(q.event), "every step has a scene: " + q.id)
			var pages: Array = catalog.story.scenes[q.event].pages
			check(pages.size() >= 3, "scenes have substance: %s (%d)" % [q.id, pages.size()])
	var total_pages = 0
	for event in catalog.story.scenes:
		total_pages += catalog.story.scenes[event].pages.size()
	check(
		catalog.story.scenes.size() >= 230 and total_pages >= 600,
		"a long story (%d scenes, %d pages)" % [catalog.story.scenes.size(), total_pages]
	)


func test_gates() -> void:
	var s = FarmState.new_game(catalog)
	for i in 6:
		check(play_step(s).ok, "chapter one step %d" % i)
	check(s.narrative.stage == 6, "chapter one is done")
	var wait = story.complete(s, "ledger")
	check(not wait.ok and wait.message.contains("还没到时候"), "chapter two waits for summer")
	check(s.day < 29, "it is still spring")
	s.day = catalog.calendar.day_number(1, "summer", 1)
	check(story.can_complete(s, "ledger").is_empty(), "and opens on the first day of summer")
	check(not story.complete(s, "gears").ok, "steps must come in order")
	while story.quest(s).id != "three_voices":
		check(play_step(s).ok, "on the way to the three voices: " + story.quest(s).id)
	var friends = story.can_complete(s, "three_voices")
	s.relationships.maeve = 0
	var blocked = story.complete(s, "three_voices")
	check(not blocked.ok and blocked.message.contains("梅芙"), "a step can ask for a friendship")
	s.relationships.maeve = 30
	check(story.complete(s, "three_voices").ok, "and gets it")
	check(friends.is_empty() or friends.contains("梅芙"), "the reason names the friend")
	var needy = FarmState.new_game(catalog)
	needy.narrative.stage = catalog.quest_index("glasshouse")
	var before = needy.snapshot(catalog)
	check(
		not story.complete(needy, "glasshouse").ok and before == needy.snapshot(catalog),
		"missing goods change nothing"
	)
	var choosy = FarmState.new_game(catalog)
	choosy.narrative.stage = catalog.quest_index("leo_guest")
	check(not story.complete(choosy, "leo_guest").ok, "a choice step needs an answer")
	check(not story.complete(choosy, "leo_guest", "nonsense").ok, "and a real one")


func test_full_story() -> void:
	var s = FarmState.new_game(catalog)
	check(story.complete(s, "prologue", "grow").ok, "the letter")
	var lit = 0
	for index in range(catalog.story.quests.size() - 1):
		var q = story.quest(s)
		var response = play_step(s)
		check(response.ok, "complete " + str(q.id) + ": " + str(response.message))
		check(s.narrative.stage == index + 1, "the story advances: " + str(q.id))
		if int(q.lamp) > 0:
			lit += 1
			check(
				story.lamps(s) == lit and story.lamp_lit(s, int(q.lamp)),
				"lamp %d is lit" % int(q.lamp)
			)
		if q.flag != "":
			check(s.narrative.flags.has(q.flag), "the answer is remembered: " + q.flag)
		if not q.reward.items.is_empty():
			check(response.message.contains("×"), "rewards are announced")
	check(story.lamps(s) == 6, "all six lamps burn")
	check(story.quest(s).event == "", "free life follows")
	check(story.flag(s, "ending") in ["root", "shore", "stream"], "an ending was chosen")
	check(
		(
			story.greenhouse(s)
			and story.canal_flowing(s)
			and story.clock_ringing(s)
			and story.ferry_open(s)
		),
		"every lamp's gift is open"
	)
	check(
		SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(), "the finished story saves"
	)
	var rounds = FarmState.from_validated(s.snapshot(catalog))
	check(rounds.narrative.flags == s.narrative.flags, "answers survive a save")
	for choice in catalog.story.quests[catalog.quest_index("new_lantern")].choice:
		var reply = "new_lantern_" + choice.id
		check(catalog.story.scenes.has(reply), "the heir has an answer: " + choice.id)


func finish_until(s: FarmState, event: String, answers: Dictionary) -> void:
	while story.quest(s).event != event:
		var q = story.quest(s)
		check(play_step(s, answers.get(q.flag, "")).ok, "play to " + event + ": " + str(q.id))
	s.day = maxi(s.day, int(story.quest(s).available_day))


func test_endings() -> void:
	var seen = {}
	var variants = [
		{"reservoir": "third", "meeting": "stay", "festivals": 5, "want": "root"},
		{"reservoir": "cooperate", "meeting": "stay", "festivals": 5, "want": "shore"},
		{"reservoir": "oppose", "meeting": "stay", "festivals": 0, "want": "shore"},
		{"reservoir": "oppose", "meeting": "compromise", "festivals": 5, "want": "shore"},
		{"reservoir": "cooperate", "meeting": "move", "festivals": 0, "want": "stream"},
		{"reservoir": "third", "meeting": "move", "festivals": 5, "want": "stream"},
	]
	for v in variants:
		var s = FarmState.new_game(catalog)
		s.narrative.stage = 0
		for i in int(v.festivals):
			s.festival_done.append("%d:plow_rite" % (i + 1))
		finish_until(s, "town_meeting", {"reservoir": v.reservoir})
		check(story.complete(s, "town_meeting", v.meeting).ok, "the meeting")
		var ending = story.flag(s, "ending")
		seen[ending] = true
		check(
			ending == v.want,
			(
				"%s / %s / %d festivals ends in %s (got %s)"
				% [v.reservoir, v.meeting, v.festivals, v.want, ending]
			)
		)
	check(seen.size() == 3, "all three endings can be reached")
	var s2 = FarmState.new_game(catalog)
	finish_until(s2, "town_meeting", {"reservoir": "third"})
	var meeting = story.complete(s2, "town_meeting", "stay")
	check(meeting.follow == ["town_meeting_stay"], "the meeting is answered")
	finish_until(s2, "new_lantern", {})
	var last = story.complete(s2, "new_lantern", "poppy")
	check(
		last.follow.size() == 2 and last.follow[0] == "new_lantern_poppy",
		"the heir is answered first"
	)
	check(last.follow[1] == "new_lantern_end_" + story.flag(s2, "ending"), "then the ending plays")
	check(catalog.story.scenes.has(last.follow[1]), "and it exists")
	check(story.town_heart(s2) >= 60, "six lamps are most of the town's heart")


func test_lamp_effects() -> void:
	var s = FarmState.new_game(catalog)
	s.narrative.stage = 3
	check(story.bridge_open(s) and not story.ferry_open(s), "the bridge, not the ferry")
	var lake = catalog.region("lake").spawn
	var shore = catalog.region("far_shore").spawn
	check(story.enter(s, "lake", Vector2(lake[0], lake[1])).ok, "the lake opens")
	check(
		not story.enter(s, "far_shore", Vector2(shore[0], shore[1])).ok, "the far shore is closed"
	)
	s.narrative.stage = catalog.lamp_quest_index(4) + 1
	check(
		story.ferry_open(s) and story.enter(s, "far_shore", Vector2(shore[0], shore[1])).ok,
		"the ferry opens the far shore"
	)
	# Greenhouse: any crop can be planted, nothing withers at the turn of the season.
	var g = FarmState.new_game(catalog)
	g.minute = 10 * 60
	var winter = catalog.calendar.day_number(1, "winter", 3)
	g.day = winter
	g.inventory.corn_seed = 1
	g.gold = 1000
	check(
		not shops.stock("seeds", g).any(func(e): return e.item == "corn_seed"),
		"no summer seeds in winter"
	)
	var cell = free_cell(g)
	rules.apply_tool(g, "hoe", cell, cell, "corn")
	check(not rules.apply_tool(g, "seed", cell, cell, "corn").ok, "corn does not grow in winter")
	g.narrative.stage = catalog.lamp_quest_index(3) + 1
	check(
		shops.stock("seeds", g).any(func(e): return e.item == "corn_seed"),
		"the greenhouse stocks every seed"
	)
	check(rules.apply_tool(g, "seed", cell, cell, "corn").ok, "and lets it grow")
	g.day = catalog.calendar.day_number(1, "autumn", 28)
	g.inventory.pea_seed = 1
	var other = free_cell(g, 1)
	rules.apply_tool(g, "hoe", other, other, "pea")
	rules.apply_tool(g, "seed", other, other, "pea")
	var morning = rules.next_day(g)
	check(morning.season_changed and morning.withered == 0, "nothing withers when the seasons turn")
	# Canal: every plot is watered each morning.
	var c = FarmState.new_game(catalog)
	var plot = free_cell(c)
	rules.apply_tool(c, "hoe", plot, plot, "turnip")
	rules.next_day(c)
	check(not c.plots[FarmState.cell_key(plot)].watered, "dry mornings leave the soil dry")
	c.narrative.stage = catalog.lamp_quest_index(5) + 1
	rules.next_day(c)
	check(c.plots[FarmState.cell_key(plot)].watered, "the canal waters the field")
	# Playhouse: festivals pay double.
	var f = FarmState.new_game(catalog)
	var festival = catalog.calendar.festivals[0]
	f.day = catalog.calendar.day_number(1, festival.season, int(festival.day))
	f.current_map = catalog.calendar.plaza_map
	f.minute = 10 * 60
	var gold = f.gold
	story.attend_festival(f)
	check(f.gold == gold + 30, "a festival pays thirty at first")
	var g2 = FarmState.new_game(catalog)
	g2.narrative.stage = catalog.lamp_quest_index(6) + 1
	g2.day = f.day
	g2.current_map = catalog.calendar.plaza_map
	g2.minute = 10 * 60
	gold = g2.gold
	story.attend_festival(g2)
	check(g2.gold == gold + 60, "and sixty once the playhouse lamp burns")
	check(
		not story.clock_ringing(FarmState.new_game(catalog)), "no bell before the clock is mended"
	)


func free_cell(s: FarmState, skip: int = 0) -> Vector2i:
	var seen = 0
	for y in range(18, 66):
		for x in range(4, 90):
			var cell = Vector2i(x, y)
			if (
				catalog.plantable(cell, s.tree_damage)
				and catalog.tree_at(cell, s).is_empty()
				and catalog.debris_at(cell, s).is_empty()
			):
				if seen == skip:
					return cell
				seen += 1
	return Vector2i(-1, -1)


func test_scene_pages() -> void:
	var s = FarmState.new_game(catalog)
	for ending in ["root", "shore", "stream"]:
		s.narrative.flags = {"ending": ending}
		var pages = story.scene_pages(s, "last_report")
		var texts = pages.map(func(p): return p[1])
		check(texts.size() >= 3, "the report reads for the %s ending" % ending)
		var mine = pages.filter(
			func(p): return p[2].get("when", {}).get("ending", ending) != ending
		)
		check(mine.is_empty(), "only this ending's pages show: " + ending)
	var all = catalog.story.scenes["last_report"].pages.size()
	s.narrative.flags = {"ending": "root"}
	check(story.scene_pages(s, "last_report").size() < all, "pages for other endings are hidden")
	for event in catalog.story.scenes:
		for ending in ["root", "shore", "stream"]:
			s.narrative.flags = {"ending": ending}
			check(
				not story.scene_pages(s, event).is_empty(),
				"%s always has pages (%s)" % [event, ending]
			)
	var wedding = FarmState.new_game(catalog)
	wedding.romance = {"hazel": {"stage": "married", "day": 1}}
	check(story.partner(wedding) == "hazel", "the partner is known to the scenes")


func test_courtship() -> void:
	var s = FarmState.new_game(catalog)
	check(story.confess_blocker(s, "hazel").contains("灯夜"), "courtship waits for chapter one")
	s.narrative.stage = 6
	s.narrative.flags = {"wish": "stay"}
	check(not story.confess_blocker(s, "milo").is_empty(), "children are only friends")
	check(not story.confess_blocker(s, "augustus").is_empty(), "and so are most grown-ups")
	check(story.confess_blocker(s, "hazel").contains("好感"), "friendship comes first")
	s.relationships.hazel = 80
	for at in [20, 40, 60, 80]:
		check(story.claim_event(s, "hazel_%d" % at).ok, "hear hazel's story %d" % at)
	check(story.confess_blocker(s, "hazel").contains("心意灯"), "the lantern is needed")
	s.inventory.heart_lantern = 2
	var before = s.snapshot(catalog)
	check(
		not story.confess(s, "silas").ok and before == s.snapshot(catalog),
		"silas has not heard enough"
	)
	var dating = story.confess(s, "hazel")
	check(dating.ok and dating.scene == "dating_hazel", "a heart lantern is accepted")
	check(
		story.stage_of(s, "hazel") == "dating" and s.inventory.heart_lantern == 1,
		"they are courting"
	)
	check(story.partner(s) == "hazel" and story.spouse(s) == "", "not married yet")
	s.relationships.silas = 80
	for at in [20, 40, 60, 80]:
		story.claim_event(s, "silas_%d" % at)
	check(story.confess_blocker(s, "silas").contains("重要的人"), "only one heart at a time")
	check(story.propose_blocker(s, "hazel").contains("好感"), "marriage needs full friendship")
	s.relationships.hazel = 100
	check(story.propose_blocker(s, "hazel").contains("心里话"), "and every story")
	story.claim_event(s, "hazel_100")
	check(story.propose_blocker(s, "hazel").contains("同心环"), "and a ring")
	s.inventory.union_ring = 1
	var proposal = story.propose(s, "hazel")
	check(proposal.ok and proposal.scene == "engage_hazel", "the ring is accepted")
	check(
		story.stage_of(s, "hazel") == "engaged" and s.inventory.union_ring == 0, "they are engaged"
	)
	check(
		story.wedding_day(s) == s.day + 3 and story.wedding_due(s) == "",
		"the wedding is three days away"
	)
	check(SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(), "an engagement saves")
	s.day += 2
	check(story.wedding_due(s) == "", "not yet")
	s.day += 1
	check(story.wedding_due(s) == "hazel", "the wedding morning")
	check(story.wed(s, "hazel").ok and story.spouse(s) == "hazel", "married")
	check(not story.wed(s, "hazel").ok, "only once")


func test_married_life() -> void:
	for id in [
		"hazel",
		"silas",
		"margot",
		"wren",
		"juniper",
		"leo",
		"felix",
		"colette",
		"jonas",
		"nora",
		"theo",
		"declan"
	]:
		var s = FarmState.new_game(catalog)
		s.narrative.stage = 6
		s.narrative.flags = {"wish": "stay"}
		s.day = 40
		s.romance = {id: {"stage": "married", "day": 40}}
		var chore = story.spouse_morning(s)
		check(
			not chore.is_empty() and not str(chore.text).is_empty(),
			"%s does something for the household" % id
		)
		check(story.talk(s, id) != "", "%s talks" % id)
		var spec = catalog.spouses[id]
		check(s.gold >= 40 + int(spec.get("gold", 0)), "the chore pays: " + id)
		for item in spec.get("items", {}):
			check(s.inventory[item] >= int(spec.items[item]), "the chore brings %s" % item)
		check(
			story.available_event(s, id).is_empty() or catalog.story.npcs[id].events.size() > 0,
			"events open in order"
		)
		s.relationships[id] = 100
		for event in catalog.story.npcs[id].events:
			s.development.events.append(event.id)
		check(story.available_event(s, id).is_empty(), "nothing opens on the wedding day")
		s.day = 47
		var first = story.available_event(s, id)
		check(first.id == id + "_m1", "the first married story comes after a week: " + id)
		check(story.claim_event(s, id + "_m1").ok, "read it")
		check(story.available_event(s, id).is_empty(), "the second waits")
		s.day = 68
		check(
			story.available_event(s, id).id == id + "_m2", "and the second after four weeks: " + id
		)
		check(
			story.claim_event(s, id + "_m2").ok and story.available_event(s, id).is_empty(),
			"married stories are told once"
		)
		check(
			SaveStore.new(catalog).validate(s.snapshot(catalog)).is_empty(),
			"married life saves: " + id
		)
	var water = FarmState.new_game(catalog)
	water.narrative.stage = 6
	water.romance = {"hazel": {"stage": "married", "day": 1}}
	water.plots["30,30"] = {"crop": "", "growth": 0, "watered": false}
	story.spouse_morning(water)
	check(water.plots["30,30"].watered, "hazel waters the field")
	var single = FarmState.new_game(catalog)
	check(story.spouse_morning(single).is_empty(), "no spouse, no chore")

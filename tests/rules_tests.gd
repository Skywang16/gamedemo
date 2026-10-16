extends SceneTree

## Shops, smithing, fishing, cooking, animals, happenings, the notice board and content shape.

var failures: Array[String] = []
var checks: int = 0
var catalog: ContentCatalog
var shops: ShopRules
var cooking: CookingRules
var fishing: FishingRules
var animals: AnimalRules
var happenings: EventRules
var board: BoardRules
var farm: FarmRules


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
		shops = ShopRules.new(catalog)
		cooking = CookingRules.new(catalog)
		fishing = FishingRules.new(catalog)
		animals = AnimalRules.new(catalog)
		happenings = EventRules.new(catalog)
		board = BoardRules.new(catalog)
		farm = FarmRules.new(catalog)
		test_content_shape()
		test_shop_hours()
		test_shop_stock()
		test_smithing()
		test_clinic_and_rods()
		test_cooking()
		test_fishing()
		test_fish_coverage()
		test_animals()
		test_happenings()
		test_board()
		test_gathering_tables()
	print("RULES_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func at(day: int, minute: int) -> FarmState:
	var s = FarmState.new_game(catalog)
	s.day = day
	s.minute = minute
	return s


func kinds() -> Dictionary:
	var out = {}
	for id in catalog.items:
		var kind = catalog.items[id].kind
		out[kind] = int(out.get(kind, 0)) + 1
	return out


func test_content_shape() -> void:
	var count = kinds()
	check(catalog.items.size() >= 600, "hundreds of items (%d)" % catalog.items.size())
	check(count.seed >= 60 and count.produce >= 60, "sixty-odd crops")
	check(count.fish >= 60, "sixty-odd fish (%d)" % count.fish)
	check(count.forage >= 40, "forty-odd wild foods (%d)" % count.forage)
	check(count.mineral >= 20, "twenty-odd minerals (%d)" % count.mineral)
	check(count.dish >= 400, "four hundred dishes (%d)" % count.dish)
	check(catalog.recipes.size() >= 400, "four hundred recipes (%d)" % catalog.recipes.size())
	for id in catalog.recipes:
		check(catalog.items[id].kind == "dish", "every recipe makes a dish: " + id)
	check(count.dish - catalog.recipes.size() <= 6, "only a few ready-made foods lack recipes")
	for season in ["spring", "summer", "autumn", "winter"]:
		var crops = 0
		var fish = 0
		for id in catalog.crops:
			if catalog.crops[id].seasons.has(season):
				crops += 1
		for id in catalog.fish:
			if catalog.fish[id].seasons.has(season):
				fish += 1
		check(crops >= 15, "%s has crops (%d)" % [season, crops])
		check(fish >= 20, "%s has fish (%d)" % [season, fish])
	for id in catalog.items:
		var item = catalog.items[id]
		check(ResourceLoader.exists("res://assets/art/%s.png" % item.icon), "icon exists: " + id)
	for id in catalog.crops:
		for stage in catalog.crops[id].stages:
			check(
				ResourceLoader.exists("res://assets/art/%s.png" % stage), "crop stage art: " + stage
			)
	for id in catalog.story.npcs:
		var npc = catalog.story.npcs[id]
		check(ResourceLoader.exists("res://assets/art/%s.png" % npc.sprite), "sprite sheet: " + id)
		check(ResourceLoader.exists("res://assets/art/%s.png" % npc.portrait), "portrait: " + id)
	for id in catalog.regions:
		check(
			ResourceLoader.exists("res://assets/art/%s.png" % catalog.regions[id].background),
			"map art: " + id
		)
	for id in catalog.recipes:
		for need in catalog.recipes[id].needs:
			check(catalog.items.has(need), "recipe ingredient exists: %s %s" % [id, need])
	for id in catalog.items:
		if catalog.items[id].kind == "dish":
			check(int(catalog.items[id].energy) > 0, "dishes restore stamina: " + id)
			check(int(catalog.items[id].sell_price) > 0, "dishes can be sold: " + id)


func test_shop_hours() -> void:
	var spring_monday = 1
	check(
		shops.closed_reason("general", at(spring_monday, 10 * 60)).is_empty(),
		"open on a weekday morning"
	)
	check(
		not shops.closed_reason("general", at(spring_monday, 8 * 60)).is_empty(),
		"closed before opening"
	)
	check(
		not shops.closed_reason("general", at(spring_monday, 17 * 60)).is_empty(),
		"closed at closing time"
	)
	check(
		shops.closed_reason("tackle", at(spring_monday, 6 * 60)).is_empty(),
		"the tackle shop opens at dawn"
	)
	check(
		not shops.closed_reason("tea", at(spring_monday, 9 * 60)).is_empty(),
		"the tea room sleeps in"
	)
	check(
		shops.closed_reason("tea", at(spring_monday, 21 * 60)).is_empty(),
		"the tea room stays open late"
	)
	var sunday = at(7, 10 * 60)
	check(catalog.calendar.date(7).weekday_name == "周日", "day 7 is a Sunday")
	check(shops.closed_reason("smith", sunday).contains("休息"), "the smithy rests on Sunday")
	check(shops.closed_reason("seeds", sunday).is_empty(), "the seed stall does not")
	var festival = at(8, 10 * 60)
	check(shops.closed_reason("seeds", festival).contains("节日"), "shops close for the festival")
	festival.minute = 15 * 60
	check(shops.closed_reason("seeds", festival).is_empty(), "and reopen in the afternoon")
	var s = at(7, 10 * 60)
	s.gold = 1000
	var before = s.snapshot(catalog)
	check(
		not shops.buy(s, "smith", "coal", 1).ok and s.snapshot(catalog) == before,
		"a closed shop sells nothing"
	)
	check(shops.hours_text("tea") == "10:00–22:00", "hours read well")


func test_shop_stock() -> void:
	var spring = at(1, 10 * 60)
	var summer = at(catalog.calendar.day_number(1, "summer", 3), 10 * 60)
	var stock = shops.stock("seeds", spring).map(func(e): return e.item)
	check(stock.has("pea_seed") and not stock.has("corn_seed"), "spring seeds only in spring")
	stock = shops.stock("seeds", summer).map(func(e): return e.item)
	check(stock.has("corn_seed") and not stock.has("pea_seed"), "summer seeds only in summer")
	check(shops.stock("seeds", spring).size() >= 20, "a seed rack worth browsing")
	var s = at(1, 10 * 60)
	s.gold = 100
	check(
		shops.buy(s, "seeds", "turnip_seed", 3).ok and s.inventory.turnip_seed == 11,
		"buying adds seeds"
	)
	check(not shops.buy(s, "seeds", "turnip_seed", 100).ok, "quantity is capped")
	check(not shops.buy(s, "seeds", "diamond", 1).ok, "a counter sells only its goods")
	check(
		shops.buys("smith", "copper_ore") and not shops.buys("smith", "turnip"), "buyers are picky"
	)
	s.inventory.copper_ore = 2
	var worth = 2 * int(catalog.items.copper_ore.sell_price)
	check(shops.sell_quote(s, "smith") == {"gold": worth, "count": 2}, "the smith quotes ore")
	s.minute = 10 * 60
	s.day = 2
	var gold = s.gold
	check(
		shops.sell_item(s, "smith", "copper_ore", 1).ok and s.inventory.copper_ore == 1, "sell one"
	)
	check(not shops.sell_item(s, "smith", "copper_ore", 5).ok, "cannot sell what you lack")
	check(shops.sell_all(s, "smith").ok and s.gold > gold, "sell the rest")
	check(not shops.sell_all(s, "smith").ok, "nothing left to sell")


func test_smithing() -> void:
	var s = at(2, 10 * 60)
	s.inventory.copper_ore = 5
	check(not shops.smelt(s, "copper_ore").ok, "smelting needs coal")
	s.inventory.coal = 1
	check(shops.smelt(s, "copper_ore").ok, "smelt")
	check(
		s.inventory.copper_bar == 1 and s.inventory.copper_ore == 0 and s.inventory.coal == 0,
		"ore and coal become a bar"
	)
	check(not shops.smelt(s, "turnip").ok, "only ore smelts")
	check(shops.tool_upgrade_cost(s, "hoe").bar == "copper_bar", "the first tier is copper")
	s.inventory.copper_bar = 5
	var before = s.snapshot(catalog)
	check(
		not shops.upgrade_tool(s, "hoe").ok and s.snapshot(catalog) == before,
		"upgrades cost gold too"
	)
	s.gold = 1000
	check(shops.upgrade_tool(s, "hoe").ok, "upgrade the hoe")
	check(
		s.development.tools.hoe == 1 and s.inventory.copper_bar == 0 and s.gold == 800,
		"tier paid in bars and gold"
	)
	check(farm.cost(s, "hoe", 2) == 1, "the upgraded hoe is easier")
	s.development.tools.hoe = 4
	check(shops.tool_upgrade_cost(s, "hoe").is_empty(), "no tier beyond gold")
	check(not shops.upgrade_tool(s, "hoe").ok, "a maxed tool cannot be upgraded")
	for tool in FarmState.TOOLS:
		check(["hoe", "axe", "pickaxe", "scythe", "water", "sword"].has(tool), "tool list: " + tool)
	var watering = at(2, 10 * 60)
	watering.development.tools.water = 2
	var center = Vector2i(-1, -1)
	for y in range(30, 40):
		for x in range(20, 80):
			var cell = Vector2i(x, y)
			if (
				center.x < 0
				and catalog.plantable(cell)
				and catalog.tree_at(cell, watering).is_empty()
				and catalog.debris_at(cell, watering).is_empty()
			):
				center = cell
	check(center.x >= 0, "a spot to water")
	for dx in range(-3, 4):
		watering.plots[FarmState.cell_key(center + Vector2i(dx, 0))] = {
			"crop": "", "growth": 0, "watered": false
		}
	check(farm.apply_tool(watering, "water", center, center, "turnip").ok, "water the middle plot")
	var wet = 0
	for dx in range(-3, 4):
		if watering.plots[FarmState.cell_key(center + Vector2i(dx, 0))].watered:
			wet += 1
	check(wet == 5, "a level-two can waters five in a row (%d)" % wet)


func test_clinic_and_rods() -> void:
	var s = at(2, 10 * 60)
	s.stamina = 100
	check(not shops.heal(s).ok, "healthy visitors are sent home")
	s.stamina = 20
	s.gold = 10
	check(not shops.heal(s).ok, "treatment costs money")
	s.gold = 100
	check(shops.heal(s).ok and s.stamina == 100 and s.gold == 70, "a hot bowl of soup")
	s.gold = 0
	check(not shops.upgrade_rod(s).ok, "rods cost money")
	s.gold = 20000
	check(shops.upgrade_rod(s).ok and s.development.rod == 1, "a better rod")
	check(shops.upgrade_rod(s).ok and shops.upgrade_rod(s).ok, "up to the best rod")
	check(
		not shops.upgrade_rod(s).ok and s.development.rod == catalog.rods.size() - 1,
		"the top rod is final"
	)


func test_cooking() -> void:
	var s = at(2, 10 * 60)
	check(cooking.level(s) == 1, "new cooks are level one")
	var easy = cooking.known(s)
	check(not easy.is_empty(), "a beginner knows some recipes")
	for recipe in easy:
		check(int(recipe.level) <= 1, "beginner recipes are easy: " + recipe.id)
	var recipe = easy[0]
	check(not cooking.can_cook(s, recipe.id), "no ingredients, no meal")
	var before = s.snapshot(catalog)
	check(
		not cooking.cook(s, recipe.id).ok and s.snapshot(catalog) == before,
		"failed cooking is atomic"
	)
	for need in recipe.needs:
		s.inventory[need] = int(recipe.needs[need])
	check(cooking.can_cook(s, recipe.id), "with ingredients")
	check(cooking.cook(s, recipe.id).ok, "cook")
	check(
		s.inventory[recipe.id] == 1 and s.development.cooking_xp == 5 and s.stats.cooked == 1,
		"dish, experience, tally"
	)
	for need in recipe.needs:
		check(s.inventory[need] == 0, "ingredients are used up: " + need)
	var hard = ""
	for id in catalog.recipes:
		if int(catalog.recipes[id].level) >= 3:
			hard = id
			break
	check(not hard.is_empty(), "there are advanced recipes")
	for need in catalog.recipes[hard].needs:
		s.inventory[need] = 9
	check(
		not cooking.cook(s, hard).ok and not cooking.can_cook(s, hard),
		"advanced recipes wait for skill"
	)
	var wanted = int(catalog.recipes[hard].level)
	s.development.cooking_xp = (wanted - 1) * 40
	check(cooking.level(s) == wanted and cooking.cook(s, hard).ok, "skill unlocks them")
	check(not cooking.cook(s, "no_such_dish").ok, "unknown recipes are refused")
	check(cooking.known(s).size() > easy.size(), "more recipes with more skill")


func test_fishing() -> void:
	var s = at(1, 10 * 60)
	s.current_map = "town"
	check(fishing.spot(s) == "river", "the town has a river")
	var list = fishing.candidates(s)
	check(list.size() >= 3, "the river has fish in spring (%d)" % list.size())
	var allowed = list.map(func(e): return e.id)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	var junk = 0
	var caught = {}
	for i in 400:
		var id = fishing.pick(s, rng)
		if id == FishingRules.JUNK:
			junk += 1
		else:
			check(allowed.has(id), "only catchable fish bite: " + id)
			caught[id] = true
	check(junk > 20 and junk < 120, "junk turns up now and then (%d)" % junk)
	check(caught.size() >= 3, "variety on the line (%d)" % caught.size())
	check(fishing.zone_size(s, allowed[0]) >= 0.12, "the catch zone has a size")
	var easy = fishing.zone_size(s, allowed[0])
	s.development.rod = 3
	check(fishing.zone_size(s, allowed[0]) > easy, "better rods widen the zone")
	var first = RandomNumberGenerator.new()
	var second = RandomNumberGenerator.new()
	first.seed = 3
	second.seed = 3
	check(
		fishing.wait_seconds(s, first, true) <= fishing.wait_seconds(s, second, false),
		"bait shortens the wait"
	)
	check(fishing.wait_seconds(s, first, true) >= 1.0, "the wait never vanishes")
	s.current_map = "cottage"
	check(fishing.spot(s).is_empty() and fishing.candidates(s).is_empty(), "no fishing indoors")
	s.current_map = "home_farm"
	var before = s.snapshot(catalog)
	s.stamina = 3
	check(not fishing.cast(s, false).ok, "casting costs stamina")
	s.stamina = 50
	check(not fishing.cast(s, true).ok, "bait must be in the bag")
	s.inventory.bait = 2
	check(fishing.cast(s, true).ok and s.stamina == 46 and s.inventory.bait == 1, "a baited cast")
	var fish_id = allowed[0]
	check(fishing.land(s, fish_id).ok, "land a fish")
	check(
		s.inventory[fish_id] == 1 and s.stats.caught == 1 and s.development.fishing_xp > 0,
		"the catch is kept and counted"
	)
	var xp = s.development.fishing_xp
	check(
		fishing.land(s, FishingRules.JUNK).ok and s.development.fishing_xp == xp + 1,
		"junk is worth a little"
	)
	check(s.stats.caught == 1, "junk is not a fish")
	check(before != s.snapshot(catalog), "fishing changes the world")
	var water = Vector2i(-1, -1)
	var stand = Vector2i.ZERO
	var face = Vector2i.ZERO
	for cell in catalog.water_cells["home_farm"]:
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if (
				not catalog.static_blocked(cell - dir, "home_farm")
				and not catalog.is_water(cell - dir, "home_farm")
			):
				water = cell
				stand = cell - dir
				face = dir
				break
		if water.x >= 0:
			break
	check(water.x >= 0, "the farm has a pond")
	check(fishing.water_ahead(s, stand, face) == water, "the shore points to the water")


func test_fish_coverage() -> void:
	var spots = {}
	for map_id in catalog.fish_spots:
		spots[catalog.fish_spots[map_id]] = true
	for id in catalog.fish:
		var entry = catalog.fish[id]
		for spot in entry.spots:
			check(spots.has(spot), "fish spot exists: %s %s" % [id, spot])
		check(catalog.items[id].kind == "fish", "fish items are fish: " + id)
	for spot in spots:
		for season in ["spring", "summer", "autumn", "winter"]:
			var n = 0
			for id in catalog.fish:
				if catalog.fish[id].spots.has(spot) and catalog.fish[id].seasons.has(season):
					n += 1
			check(n >= 1, "%s has fish in %s (%d)" % [spot, season, n])


func test_animals() -> void:
	var s = at(1, 10 * 60)
	check(
		not animals.built(s, "coop") and not animals.buy(s, "chicken", "花花").ok,
		"no coop, no chickens"
	)
	check(not animals.build(s, "coop").ok, "building needs money and materials")
	s.gold = 2000
	s.inventory.wood = 20
	s.inventory.stone = 10
	check(
		animals.build(s, "coop").ok and animals.under_construction(s, "coop"),
		"the carpenter starts work"
	)
	check(s.gold == 1400 and s.inventory.wood == 0, "materials and gold are paid")
	check(not animals.build(s, "coop").ok, "one coop is enough")
	check(not animals.buy(s, "chicken", "花花").ok, "no chickens before it is finished")
	s.day += 2
	check(
		animals.built(s, "coop") and not animals.under_construction(s, "coop"),
		"finished after two days"
	)
	check(not animals.buy(s, "chicken", "").ok, "animals need names")
	check(not animals.buy(s, "chicken", "名字实在是太长太长了呀呀呀").ok, "and short ones")
	check(animals.default_name(s, "chicken") == "花花", "the first default name")
	check(animals.buy(s, "chicken", "花花").ok and s.gold == 1100, "welcome home")
	check(animals.default_name(s, "chicken") == "豆豆", "default names do not repeat")
	s.gold = 5000
	for i in range(5):
		animals.buy(s, "chicken", animals.default_name(s, "chicken"))
	check(animals.housed(s, "coop") == 6, "six birds fill the coop")
	check(not animals.buy(s, "chicken", "多余").ok, "a full coop is full")
	check(not animals.buy(s, "cow", "牛牛").ok, "a cow needs a barn")
	check(not animals.feed_all(s, "coop").ok, "feeding needs hay")
	s.inventory.hay = 6
	check(animals.feed_all(s, "coop").ok and s.inventory.hay == 0, "feed them")
	check(not animals.feed_all(s, "coop").ok, "already fed")
	check(animals.pet(s, 0).ok and not animals.pet(s, 0).ok, "one pat a day")
	var first = s.animals[0]
	first.age = 3
	first.wait = 1
	animals.next_day(s, "sunny")
	check(first.ready and first.age == 4 and first.friendship == 5, "an adult hen lays")
	check(s.animals[1].age == 1 and not s.animals[1].ready, "young hens grow first")
	check(not first.fed and not first.petted, "each day starts hungry")
	var eggs = s.inventory.egg + s.inventory.large_egg
	check(animals.collect(s, "coop").ok, "collect")
	check(s.inventory.egg + s.inventory.large_egg == eggs + 1 and not first.ready, "one egg, once")
	check(not animals.collect(s, "coop").ok, "nothing more to collect")
	animals.next_day(s, "sunny")
	check(first.friendship == 4, "neglected animals sulk")
	var barn = at(1, 10 * 60)
	barn.buildings = {"barn": {"ready_day": 1}}
	barn.gold = 5000
	check(animals.buy(barn, "cow", "奶糖").ok, "cows live in the barn")
	for key in catalog.animals:
		var spec = catalog.animals[key]
		check(catalog.buildings.has(spec.building), "animal home exists: " + key)
		check(
			catalog.items.has(spec.product) and catalog.items.has(spec.special),
			"animal goods exist: " + key
		)
	check(catalog.animals.size() >= 9, "a real menagerie")


func test_happenings() -> void:
	var seen = {}
	var total = 0
	for world_seed in [1, 2, 3, 4, 5]:
		for day in range(8, 113):
			var s = FarmState.new_game(catalog, world_seed)
			s.day = day
			var e = happenings.roll(s)
			check(e == happenings.roll(s), "happenings replay exactly")
			if not e.is_empty():
				seen[e.id] = true
				total += 1
				check(not catalog.calendar.is_festival(day), "festival mornings are left alone")
	for day in range(1, 8):
		var s = FarmState.new_game(catalog, 3)
		s.day = day
		check(happenings.roll(s).is_empty(), "the first week is calm")
	check(
		total > 30 and seen.size() >= 6,
		"mornings bring variety (%d, %d kinds)" % [total, seen.size()]
	)
	var s = FarmState.new_game(catalog)
	var gold = s.gold
	var plain = {
		"id": "x",
		"name": "x",
		"text": "x",
		"when": {"chance": 1},
		"effect": {"gold": 25, "items": {"honey": 2}, "friends": 3}
	}
	happenings.apply(s, plain)
	check(
		s.gold == gold + 25 and s.inventory.honey == 2 and s.relationships.hazel == 3,
		"effects apply"
	)
	s.plots["5,5"] = {"crop": "turnip", "growth": 0, "watered": false}
	happenings.apply(
		s, {"id": "y", "name": "y", "text": "y", "when": {"chance": 1}, "effect": {"boost": 1}}
	)
	check(s.plots["5,5"].growth == 1, "growth boosts help the crops")


func test_board() -> void:
	var s = at(1, 10 * 60)
	s.world_seed = 9
	var requests = board.requests(s)
	check(requests.size() == BoardRules.REQUESTS, "four requests")
	check(requests == board.requests(s), "the board is stable")
	var other = at(8, 10 * 60)
	other.world_seed = 9
	check(requests != board.requests(other), "a new week, a new board")
	var elsewhere = at(1, 10 * 60)
	elsewhere.world_seed = 10
	check(requests != board.requests(elsewhere), "other worlds, other boards")
	for r in requests:
		check(
			catalog.items.has(r.item) and catalog.story.npcs.has(r.npc), "requests name real things"
		)
		check(
			int(r.gold) > int(catalog.items[r.item].sell_price) * int(r.count),
			"helping out pays better than selling"
		)
	var first = requests[0]
	var before = s.snapshot(catalog)
	check(not board.deliver(s, 0).ok and s.snapshot(catalog) == before, "no goods, no delivery")
	s.inventory[first.item] = int(first.count)
	var gold = s.gold
	check(board.deliver(s, 0).ok and s.gold == gold + int(first.gold), "deliver")
	check(
		s.relationships[first.npc] >= 6 and s.inventory[first.item] == 0, "thanks, and friendship"
	)
	check(not board.deliver(s, 0).ok, "each request once")
	check(
		not board.deliver(s, 7).ok and not board.deliver(s, -1).ok, "unknown requests are refused"
	)
	s.day = 9
	board.refresh(s)
	check(s.board.week == 1 and s.board.done.is_empty(), "the board resets weekly")
	check(board.wanted_items(s).size() > 20, "plenty to ask for")


func test_gathering_tables() -> void:
	var s = at(1, 10 * 60)
	for table in catalog.gather_tables:
		for season in ["spring", "summer", "autumn", "winter"]:
			s.day = catalog.calendar.day_number(1, season, 5)
			var node = {"id": "test_" + table, "table": table}
			var item = GatherRules.item_for(catalog, s, node)
			check(catalog.items.has(item), "table %s gives a real item in %s" % [table, season])
			check(item == GatherRules.item_for(catalog, s, node), "a day shows one item")
	var node = {"id": "fixed", "item": "wood", "seasonal": {"winter": "stone"}}
	s.day = 1
	check(GatherRules.item_for(catalog, s, node) == "wood", "fixed nodes hold one thing")
	s.day = catalog.calendar.day_number(1, "winter", 1)
	check(GatherRules.item_for(catalog, s, node) == "stone", "and may change with the season")
	check(
		GatherRules.is_mine({"table": "mine_2"}) and not GatherRules.is_mine({"table": "forest"}),
		"mines are rocks"
	)
	var variety = {}
	for day in range(1, 60):
		s.day = day
		variety[GatherRules.item_for(catalog, s, {"id": "wild", "table": "forest"})] = true
	check(variety.size() >= 4, "the forest floor changes from day to day (%d)" % variety.size())

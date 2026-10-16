class_name FarmWorld
extends Node2D

signal player_hit(damage: int, push: Vector2)
signal enemy_defeated(kind: String, at: Vector2)

var catalog: ContentCatalog
var stories: StoryRules
var enemies: Array = []
var state: FarmState
var player: Farmer
var actors: Node2D
var textures: Dictionary = {}
var target: Vector2i = Vector2i(-1, -1)
var target_visible: bool = false
var effects: WorldEffects
var ambient: WorldAmbient
var tree_nodes: Dictionary = {}
var ambient_time: float = 0.0
var weather_layer: WeatherLayer
var season_material: ShaderMaterial
var season: String = "spring"
var weather: String = "sunny"
var outdoors: bool = false
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if ambient != null:
			ambient.calm = value
		for id in tree_nodes:
			tree_nodes[id].calm = value
		if weather_layer != null:
			refresh_atmosphere()
var background: Texture2D
var region: Dictionary
var npc_nodes: Dictionary = {}
var map_font: Font
var planner: NpcPlanner
var clock_fraction: float = 0.0
var camera: Camera2D
var debris_nodes: Dictionary = {}


func configure(content: ContentCatalog, initial_state: FarmState, day_planner: NpcPlanner) -> void:
	catalog = content
	stories = StoryRules.new(content)
	state = initial_state
	planner = day_planner
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	region = catalog.region(state.current_map)
	background = tex(region.background)
	var variation = FontVariation.new()
	variation.base_font = load("res://assets/fonts/NotoSansSC.ttf")
	variation.variation_opentype = {2003265652: 600.0}
	map_font = variation
	season_material = ShaderMaterial.new()
	season_material.shader = load("res://assets/shaders/season.gdshader")
	material = season_material
	ambient = WorldAmbient.new()
	add_child(ambient)
	ambient.configure(region)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	actors.use_parent_material = true
	add_child(actors)
	for prop in region.props:
		add_prop(
			prop.texture,
			Vector2(prop.ground[0], prop.ground[1]),
			Vector2(prop.offset[0], prop.offset[1])
		)
	for p in region.trees:
		var cell = Vector2i(p[0], p[1])
		var id = catalog.tree_cells[state.current_map][cell]
		var tree = TreeProp.new()
		tree.position = Vector2(cell) * 32 + Vector2(16, 16)
		tree.use_parent_material = true
		actors.add_child(tree)
		tree.configure(
			tex("tree_moving_%d" % ((cell.x + cell.y) % 4)), int(state.tree_damage.get(id, 0))
		)
		tree.landed.connect(
			func(at):
				effects.burst("axe", at, 24)
				effects.burst("scythe", at + Vector2(0, -20), 16)
		)
		tree_nodes[id] = tree
	var body = StaticBody2D.new()
	add_child(body)
	# Merge contiguous occupied cells into row rectangles rather than one body per tile.
	for y in range(int(region.height)):
		var x = 0
		while x < int(region.width):
			if not catalog.static_blocked(Vector2i(x, y), state.current_map):
				x += 1
				continue
			var start = x
			while (
				x < int(region.width) and catalog.static_blocked(Vector2i(x, y), state.current_map)
			):
				x += 1
			add_collider(
				body, Vector2((start + x) * 16, y * 32 + 16), Vector2((x - start) * 32, 32)
			)
	for node in region.get("debris", []):
		if state.cleared.has(node.id):
			continue
		var anchor = add_prop(
			"%s_%d" % [node.kind, node.variant],
			Vector2(node.cell[0] * 32 + 16, node.cell[1] * 32 + 24),
			Vector2(-16, -32)
		)
		if node.kind != "weeds":
			var obstacle = StaticBody2D.new()
			anchor.add_child(obstacle)
			add_collider(obstacle, Vector2(0, -6), Vector2(24, 20))
		debris_nodes[node.id] = anchor
	for id in planner.visitors(state.current_map):
		var node = Node2D.new()
		var sprite = Sprite2D.new()
		sprite.texture = tex(catalog.story.npcs[id].sprite)
		sprite.centered = false
		sprite.scale = Vector2.ONE * ActorVisual.SCALE
		sprite.position = ActorVisual.ORIGIN * ActorVisual.SCALE
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, 32, 48)
		node.add_child(sprite)
		node.visible = false
		actors.add_child(node)
		npc_nodes[id] = node
	if state.current_map == "home_farm":
		_place_building_sites()
	effects = WorldEffects.new()
	effects.z_index = 2
	add_child(effects)
	player = Farmer.new()
	player.appearance = state.profile
	player.position = state.player_position
	actors.add_child(player)
	camera = Camera2D.new()
	var interior: bool = region.environment == "interior"
	camera.zoom = Vector2(1.5, 1.5)
	camera.offset = Vector2.ZERO if interior else Vector2(0, -48)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(region.width) * 32
	camera.limit_bottom = int(region.height) * 32
	camera.position_smoothing_enabled = false
	if region.width * 32 <= 1280 / camera.zoom.x and region.height * 32 <= 800 / camera.zoom.y:
		camera.position = Vector2(region.width * 16, region.height * 16)
		add_child(camera)
	else:
		player.add_child(camera)
	camera.make_current()
	camera.force_update_scroll()
	var sky = CanvasLayer.new()
	sky.layer = 4
	add_child(sky)
	weather_layer = WeatherLayer.new()
	sky.add_child(weather_layer)
	refresh_atmosphere()
	queue_redraw()


## Re-reads the season and weather for the current day and restarts the weather layer.
func refresh_atmosphere() -> void:
	season = catalog.calendar.season_of(state.day)
	weather = catalog.weather.weather_on(state.world_seed, state.day)
	outdoors = region.environment == "exterior"
	weather_layer.visible = outdoors
	if outdoors:
		weather_layer.configure(season, weather, reduce_motion)
	var date = catalog.calendar.date(state.day)
	set_season_look(
		WorldAtmosphere.season_weights(
			date.season_index, date.day, catalog.calendar.days_per_season
		)
	)


func set_season_look(weights: Dictionary) -> void:
	for key in ["summer", "autumn", "winter"]:
		season_material.set_shader_parameter(key, float(weights.get(key, 0.0)) if outdoors else 0.0)


## The colour the whole world is multiplied by: season, weather and evening dusk.
func light_color() -> Color:
	var minute = int(float(state.minute) + clock_fraction)
	if outdoors:
		return WorldAtmosphere.lit(season, weather, minute)
	return WorldAtmosphere.lit("spring", "sunny", minute)


func add_collider(body: StaticBody2D, at: Vector2, size: Vector2) -> void:
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collider.shape = shape
	collider.position = at
	body.add_child(collider)


func remove_debris(id: String) -> void:
	var anchor: Node2D = debris_nodes[id]
	actors.remove_child(anchor)
	anchor.queue_free()
	debris_nodes.erase(id)


func screen_to_world(point: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * point


func world_to_screen(point: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * point


func add_prop(id: String, ground: Vector2, offset: Vector2) -> Node2D:
	var anchor = Node2D.new()
	anchor.position = ground
	var sprite = Sprite2D.new()
	sprite.texture = tex(id)
	sprite.centered = false
	sprite.position = offset
	anchor.add_child(sprite)
	if id.begins_with("tree") or id.begins_with("weeds"):
		anchor.use_parent_material = true
		sprite.use_parent_material = true
	actors.add_child(anchor)
	return anchor


func tex(id: String) -> Texture2D:
	if not textures.has(id):
		textures[id] = load("res://assets/art/%s.png" % id)
	return textures[id]


func nearby_station() -> Dictionary:
	var nearest: Dictionary = {}
	var distance = 56.0
	for station in available_stations():
		var p = Vector2((station.cell[0] + 0.5) * 32, (station.cell[1] + 0.5) * 32)
		var d = player.position.distance_to(p)
		if d < distance and station_accessible(p):
			distance = d
			nearest = station
	return nearest


## Interaction cannot cross a partition or the corner of solid furniture.
func station_accessible(at: Vector2) -> bool:
	if region.environment != "interior":
		return true
	var steps = maxi(1, ceili(player.position.distance_to(at) / 4.0))
	var previous = player.cell()
	for i in range(1, steps + 1):
		var cell = Vector2i((player.position.lerp(at, float(i) / steps) / 32.0).floor())
		if catalog.static_blocked(cell, state.current_map):
			return false
		if cell.x != previous.x and cell.y != previous.y:
			if (
				catalog.static_blocked(Vector2i(cell.x, previous.y), state.current_map)
				or catalog.static_blocked(Vector2i(previous.x, cell.y), state.current_map)
			):
				return false
		previous = cell
	return true


func update_target(mouse_aim: bool, pointer: Vector2 = Vector2.ZERO) -> void:
	if mouse_aim:
		var point = screen_to_world(pointer)
		target = Vector2i(floori(point.x / 32), floori(point.y / 32))
	else:
		target = player.cell() + player.facing
	target_visible = (
		(state.current_map == "home_farm" and catalog.plantable(target, state.tree_damage))
		or not catalog.tree_at(target, state).is_empty()
	)
	queue_redraw()


func effect(cell: Vector2i, kind: String) -> void:
	var at = Vector2(cell) * 32 + Vector2(16, 18)
	effects.burst(kind, at)
	if kind == "water":
		effects.pour(
			player.position + (Vector2(player.facing) * 20 + Vector2(0, -17)) * ActorVisual.SCALE,
			at
		)


func strike_tree(id: String, hits: int) -> void:
	tree_nodes[id].strike(hits, player.position.x)
	if hits in [3, 5]:
		effects.pickup(tex("wood"), tree_nodes[id].position)


func _process(delta: float) -> void:
	ambient_time += delta
	_update_villagers()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.step(delta, player.position, self)
	for id in debris_nodes:
		var anchor: Node2D = debris_nodes[id]
		if anchor.position.distance_squared_to(player.position) < 500000:
			var sprite: Sprite2D = anchor.get_child(0)
			if catalog.debris_ids[id].kind == "weeds":
				sprite.skew = (
					0.0 if reduce_motion else sin(ambient_time * 2 + anchor.position.x * .05) * .045
				)
	queue_redraw()


func _draw() -> void:
	if background == null:
		return
	draw_texture(background, Vector2.ZERO)
	_draw_landmarks()
	for key in state.plots.keys() if state.current_map == "home_farm" else []:
		var cell = FarmState.key_cell(key)
		var p = state.plots[key]
		var at = Vector2(cell) * 32
		draw_texture(tex("soil_wet" if p.watered else "soil_dry"), at)
		if p.crop != "":
			draw_texture(tex(catalog.crop_texture(p.crop, int(p.growth))), at)
			if int(p.growth) >= int(catalog.crops[p.crop].growth_days):
				draw_rect(Rect2(at + Vector2(26, 3), Vector2(3, 3)), Color("f1dd97"))
	if target_visible:
		var actor = player.cell()
		var reach = maxi(absi(target.x - actor.x), absi(target.y - actor.y)) <= 1
		var color = Color("fff0af") if reach else Color("bd8270")
		var pos = Vector2(target) * 32
		for corner in [Vector2(1, 1), Vector2(30, 1), Vector2(1, 30), Vector2(30, 30)]:
			var xdir = 1 if corner.x < 16 else -1
			var ydir = 1 if corner.y < 16 else -1
			draw_line(pos + corner, pos + corner + Vector2(7 * xdir, 0), color, 2)
			draw_line(pos + corner, pos + corner + Vector2(0, 7 * ydir), color, 2)


func available_stations() -> Array:
	var stations: Array = region.stations.duplicate(true)
	for id in npc_nodes:
		if npc_nodes[id].visible:
			var cell = Vector2i((npc_nodes[id].position / 32.0).floor())
			stations.append(
				{
					"id": id,
					"name": catalog.story.npcs[id].name,
					"kind": "npc",
					"cell": [cell.x, cell.y]
				}
			)
	if state.current_map == "home_farm":
		for id in region.building_sites:
			if _built(id) and catalog.buildings[id].kind == "animal":
				var door = region.building_sites[id].door
				stations.append(
					{"id": id, "name": catalog.buildings[id].name, "kind": "animals", "cell": door}
				)
	for node in region.get("gather", []):
		if not state.daily.gathered.has(node.id):
			stations.append(
				{"id": node.id, "name": gather_label(node), "kind": "gather", "cell": node.cell}
			)
	return stations


func gather_label(node: Dictionary) -> String:
	if GatherRules.is_mine(node):
		return "敲开矿石"
	return "采集" + catalog.items[GatherRules.item_for(catalog, state, node)].name


func gather_texture(node: Dictionary) -> Texture2D:
	if GatherRules.is_mine(node):
		return tex("ore_node")
	return tex(catalog.items[GatherRules.item_for(catalog, state, node)].icon)


func _built(id: String) -> bool:
	return state.buildings.has(id) and state.day >= int(state.buildings[id].ready_day)


func _place_building_sites() -> void:
	for id in region.building_sites:
		var site = region.building_sites[id]
		var door = Vector2(site.door[0] * 32 + 16, site.door[1] * 32 + 16)
		if _built(id):
			add_prop(site.texture, door, Vector2(site.offset[0], site.offset[1]))
		elif catalog.buildings[id].kind == "animal":
			var rect = site.rect
			var ground = Vector2((rect[0] + rect[2] / 2.0) * 32, (rect[1] + rect[3]) * 32 - 4)
			add_prop("lot_sign", ground, Vector2(-32, -56))


## Moves every villager to where today's schedule says they are at the current minute.
func _update_villagers() -> void:
	var minute = float(state.minute) + clock_fraction
	for id in npc_nodes:
		var info = planner.where(id, minute)
		var node: Node2D = npc_nodes[id]
		node.visible = info.present and info.map == state.current_map and not info.hidden
		if not node.visible:
			continue
		node.position = info.position * 32.0 + Vector2(16, 16)
		var sprite: Sprite2D = node.get_child(0)
		var row = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT].find(info.facing)
		var frame = int(ambient_time * 9.0) % 4 if info.moving else 0
		sprite.region_rect = Rect2(frame * 32, maxi(row, 0) * 48, 32, 48)
		var breath = (
			0 if info.moving else (1 if sin(ambient_time * 2.2 + node.position.x) > 0.6 else 0)
		)
		sprite.position.y = (ActorVisual.ORIGIN.y + breath) * ActorVisual.SCALE


func _draw_landmarks() -> void:
	for node in region.get("gather", []):
		if not state.daily.gathered.has(node.id):
			draw_texture(gather_texture(node), Vector2(node.cell[0] * 32, node.cell[1] * 32))
	for station in region.stations:
		var at = Vector2(station.cell[0] * 32 + 16, station.cell[1] * 32 + 16)
		if station.kind in ["exit", "bridge", "ferry"]:
			draw_circle(at, 12, Color("ead49660"))
			draw_line(at + Vector2(-5, -3), at + Vector2(0, 3), Color("fff0bc"), 2)
			draw_line(at + Vector2(0, 3), at + Vector2(5, -3), Color("fff0bc"), 2)
			var label = station.name
			if station.kind == "bridge":
				label = "前往湖畔 →" if stories.bridge_open(state) else "修复旧桥"
			if station.kind == "ferry":
				label = "乘船去对岸 →" if stories.ferry_open(state) else "搁浅的渡船"
			if player.position.distance_to(at) > 72:
				map_label(label, at + Vector2(0, 29), 14)
	for id in npc_nodes:
		if npc_nodes[id].visible:
			map_label(
				catalog.story.npcs[id].name, npc_nodes[id].position + ActorVisual.NAME_OFFSET, 15
			)
	if state.current_map == "home_farm":
		for id in region.building_sites:
			if (
				state.buildings.has(id)
				and not _built(id)
				and catalog.buildings[id].kind == "animal"
			):
				var rect = region.building_sites[id].rect
				var at = Vector2((rect[0] + rect[2] / 2.0) * 32, rect[1] * 32 - 12)
				var days = int(state.buildings[id].ready_day) - state.day
				map_label("%s施工中 · %d 天后完工" % [catalog.buildings[id].name, days], at, 15)
	if state.current_map == "town" and stories.bridge_open(state):
		var bridge = region.bridge_rect
		for y in range(int(bridge[1]) * 32, int(bridge[1] + bridge[3]) * 32, 12):
			draw_rect(Rect2(int(bridge[0]) * 32, y, int(bridge[2]) * 32, 10), Color("b98d57"))
	if state.current_map == "lake":
		_draw_lake_lights()
	if state.current_map == "far_shore" and int(state.narrative.stage) >= 1:
		_draw_shrine_glow()


## Six lamps on the lantern stand, lit one by one as the story restores them, and paper lanterns
## drifting on the water once the first lantern night has happened.
func _draw_lake_lights() -> void:
	var stand = Vector2(37 * 32 + 16, 29 * 32 + 16)
	for i in range(6):
		var at = stand + Vector2(-36 + i * 14.4, -74)
		var lit = stories.lamp_lit(state, _lamp_number(i))
		draw_rect(
			Rect2(at - Vector2(4, 5), Vector2(8, 10)), Color("f6d890") if lit else Color("5a4a3a")
		)
		draw_rect(Rect2(at - Vector2(5, 7), Vector2(10, 3)), Color("3e2a1a"))
		if lit:
			var pulse = 0.6 + 0.2 * sin(ambient_time * 2.4 + i)
			draw_circle(at, 13.0, Color(0.96, 0.85, 0.55, 0.16 * pulse))
			draw_circle(at, 7.0, Color(1.0, 0.92, 0.65, 0.22 * pulse))
	if int(state.narrative.stage) < 6:
		return
	var count = 8 + stories.lamps(state) * 4
	for i in range(count):
		var area = region.lantern_area
		var at = (
			Vector2(area[0] + (i * 137) % int(area[2]), area[1] + (i * 79) % int(area[3]))
			+ Vector2(sin(ambient_time * .4 + i) * 6, sin(ambient_time + i) * 2)
		)
		draw_circle(at, 12, Color("f6d89825"))
		draw_rect(Rect2(at - Vector2(4, 3), Vector2(8, 6)), Color("f1d28b"))
		draw_line(at + Vector2(0, 6), at + Vector2(0, 14), Color("c6b681"), 2)


func _lamp_number(slot: int) -> int:
	return slot + 1


func _draw_shrine_glow() -> void:
	var at = Vector2(29 * 32 + 16, 14 * 32 - 24)
	var lit = stories.lamp_lit(state, 4)
	if lit:
		var pulse = 0.5 + 0.3 * sin(ambient_time * 2.0)
		draw_circle(at, 16.0, Color(0.96, 0.85, 0.55, 0.18 * pulse))
		draw_rect(Rect2(at - Vector2(3, 4), Vector2(6, 8)), Color("f6d890"))


# ---------------------------------------------------------------------------- monsters


## Puts the day's monsters on the floor: [{kind, cell}] from CombatRules.spawn_plan.
func add_enemies(plan: Array) -> void:
	for entry in plan:
		var spec = catalog.enemies[entry.kind]
		var enemy = MineEnemy.new()
		actors.add_child(enemy)
		enemy.configure(
			entry.kind, spec, tex("enemy_" + entry.kind), Vector2(entry.cell) * 32 + Vector2(16, 16)
		)
		enemy.touched.connect(func(damage, direction): player_hit.emit(damage, direction))
		enemy.defeated.connect(
			func(kind, at):
				enemies.erase(enemy)
				enemy_defeated.emit(kind, at)
		)
		enemies.append(enemy)


## A sword stroke: hurts every monster within `reach` of `center`. Returns how many were hit.
func strike_enemies(center: Vector2, reach: float, amount: int, knock: float) -> int:
	var hits = 0
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		var margin = reach + 8.0 * int(enemy.spec.size)
		if enemy.position.distance_to(center) <= margin:
			hits += 1
			effects.burst("pickaxe", enemy.position + Vector2(0, -12), 10)
			enemy.hurt(amount, player.position, knock)
	return hits


func map_label(text: String, center: Vector2, size_px: int) -> void:
	var width = map_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	var at = Vector2(
		clampf(center.x - width / 2, 8, float(region.width) * 32 - 8 - width), center.y
	)
	draw_string(
		map_font, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color("253d2b")
	)
	draw_string(map_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color("fff0be"))

class_name FarmWorld
extends Node2D

var catalog: ContentCatalog
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
var last_period: int = -1
var camera: Camera2D
var debris_nodes: Dictionary = {}


func configure(content: ContentCatalog, initial_state: FarmState) -> void:
	catalog = content
	state = initial_state
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
	for id in catalog.story.npcs:
		var npc = catalog.story.npcs[id]
		if npc.map == state.current_map:
			var at = Vector2(catalog.npc_cell(id, state.minute)) * 32 + Vector2(16, 16)
			npc_nodes[id] = add_prop(npc.sprite, at, Vector2(-16, -44))
	effects = WorldEffects.new()
	effects.z_index = 2
	add_child(effects)
	player = Farmer.new()
	player.appearance = state.profile
	player.position = state.player_position
	actors.add_child(player)
	camera = Camera2D.new()
	camera.zoom = Vector2(1.34, 1.34) if region.width <= 30 else Vector2(1.5, 1.5)
	camera.offset = Vector2.ZERO if region.width <= 30 else Vector2(0, -48)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(region.width) * 32
	camera.limit_bottom = int(region.height) * 32
	camera.position_smoothing_enabled = false
	if region.width <= 30:
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
	outdoors = int(region.width) > 30
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
		season_material.set_shader_parameter(key, float(weights.get(key, 0.0)))


## The colour the whole world is multiplied by: season, weather and evening dusk.
func light_color() -> Color:
	if outdoors:
		return WorldAtmosphere.lit(season, weather, state.minute)
	return WorldAtmosphere.lit("spring", "sunny", state.minute)


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
		if d < distance:
			distance = d
			nearest = station
	return nearest


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
		effects.pour(player.position + Vector2(player.facing) * 20 + Vector2(0, -17), at)


func strike_tree(id: String, hits: int) -> void:
	tree_nodes[id].strike(hits, player.position.x)
	if hits in [3, 5]:
		effects.pickup(tex("wood"), tree_nodes[id].position)


func _process(delta: float) -> void:
	ambient_time += delta
	if state != null and int(state.minute / 840) != last_period:
		last_period = int(state.minute / 840)
		for id in npc_nodes:
			npc_nodes[id].position = (
				Vector2(catalog.npc_cell(id, state.minute)) * 32 + Vector2(16, 16)
			)
	for id in npc_nodes:
		var sprite: Sprite2D = npc_nodes[id].get_child(0)
		sprite.position.y = (
			-44 + (1 if sin(ambient_time * 2.2 + npc_nodes[id].position.x) > 0.6 else 0)
		)
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
		var npc = catalog.story.npcs[id]
		var cell = catalog.npc_cell(id, state.minute)
		stations.append({"id": id, "name": npc.name, "kind": "npc", "cell": [cell.x, cell.y]})
	for node in region.get("gather", []):
		if not state.daily.gathered.has(node.id):
			stations.append(
				{
					"id": node.id,
					"name": "采集" + catalog.items[node.item].name,
					"kind": "gather",
					"cell": node.cell
				}
			)
	return stations


func _draw_landmarks() -> void:
	for node in region.get("gather", []):
		if not state.daily.gathered.has(node.id):
			draw_texture(tex(node.item), Vector2(node.cell[0] * 32, node.cell[1] * 32))
	for station in region.stations:
		var at = Vector2(station.cell[0] * 32 + 16, station.cell[1] * 32 + 16)
		if station.kind in ["exit", "bridge"]:
			draw_circle(at, 12, Color("ead49660"))
			draw_line(at + Vector2(-5, -3), at + Vector2(0, 3), Color("fff0bc"), 2)
			draw_line(at + Vector2(0, 3), at + Vector2(5, -3), Color("fff0bc"), 2)
			var label = station.name
			if station.kind == "bridge":
				label = "前往湖畔 →" if state.narrative.stage >= 3 else "修复旧桥"
			if player.position.distance_to(at) > 72:
				map_label(label, at + Vector2(0, 29), 14)
	for id in npc_nodes:
		var at = npc_nodes[id].position
		map_label(catalog.story.npcs[id].name, at + Vector2(0, -48), 15)
	if state.current_map == "town" and state.narrative.stage >= 3:
		var bridge = region.bridge_rect
		for y in range(int(bridge[1]) * 32, int(bridge[1] + bridge[3]) * 32, 12):
			draw_rect(Rect2(int(bridge[0]) * 32, y, int(bridge[2]) * 32, 10), Color("b98d57"))
	if state.current_map == "lake" and state.narrative.stage == 6:
		for i in range(18):
			var area = region.lantern_area
			var at = (
				Vector2(area[0] + (i * 137) % int(area[2]), area[1] + (i * 79) % int(area[3]))
				+ Vector2(sin(ambient_time * .4 + i) * 6, sin(ambient_time + i) * 2)
			)
			draw_circle(at, 12, Color("f6d89825"))
			draw_rect(Rect2(at - Vector2(4, 3), Vector2(8, 6)), Color("f1d28b"))
			draw_line(at + Vector2(0, 6), at + Vector2(0, 14), Color("c6b681"), 2)


func map_label(text: String, center: Vector2, size_px: int) -> void:
	var width = map_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	var at = Vector2(
		clampf(center.x - width / 2, 8, float(region.width) * 32 - 8 - width), center.y
	)
	draw_string(
		map_font, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color("253d2b")
	)
	draw_string(map_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color("fff0be"))

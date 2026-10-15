class_name FarmWorld
extends Node2D

var catalog: ContentCatalog
var state: FarmState
var player: Farmer
var actors: Node2D
var textures: Dictionary = {}
var target: Vector2i = Vector2i(-1, -1)
var target_visible: bool = false
var particles: Array = []
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
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	for prop in region.props:
		add_prop(
			prop.texture,
			Vector2(prop.ground[0], prop.ground[1]),
			Vector2(prop.offset[0], prop.offset[1])
		)
	for p in region.trees:
		add_prop(
			"tree_%d" % ((int(p[0]) + int(p[1])) % 4),
			Vector2((p[0] + 0.5) * 32, (p[1] + 0.5) * 32),
			Vector2(-48, -120)
		)
	var body = StaticBody2D.new()
	add_child(body)
	# Merge contiguous occupied cells into row rectangles rather than one body per tile.
	for y in range(int(region.height)):
		var x = 0
		while x < int(region.width):
			if not catalog.blocked(Vector2i(x, y), state.current_map):
				x += 1
				continue
			var start = x
			while x < int(region.width) and catalog.blocked(Vector2i(x, y), state.current_map):
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
	player = Farmer.new()
	player.appearance = state.profile
	player.position = state.player_position
	actors.add_child(player)
	camera = Camera2D.new()
	camera.zoom = Vector2(1.2, 1.2) if region.width <= 30 else Vector2(1.5, 1.5)
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
	queue_redraw()


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
	target_visible = state.current_map == "home_farm" and catalog.plantable(target)
	queue_redraw()


func effect(cell: Vector2i, kind: String) -> void:
	var color = Color("a7d7c9") if kind == "water" else Color("ecd38b")
	for i in range(8):
		var a = float(i) * TAU / 8.0
		particles.append(
			{
				"p": Vector2(cell) * 32 + Vector2(16, 18),
				"v": Vector2(cos(a) * 25, sin(a) * 23 - 20),
				"life": 0.5,
				"color": color
			}
		)
	player.celebrate()


func _process(delta: float) -> void:
	if state != null and int(state.minute / 840) != last_period:
		last_period = int(state.minute / 840)
		for id in npc_nodes:
			npc_nodes[id].position = (
				Vector2(catalog.npc_cell(id, state.minute)) * 32 + Vector2(16, 16)
			)
		queue_redraw()
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= delta
		particles[i].p += particles[i].v * delta
		particles[i].v.y += 55 * delta
		if particles[i].life <= 0:
			particles.remove_at(i)
	if not particles.is_empty():
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
	for p in particles:
		var col = p.color
		col.a = p.life * 2.0
		draw_rect(Rect2(p.p, Vector2(3, 3)), col)


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
			var at = Vector2(area[0] + (i * 137) % int(area[2]), area[1] + (i * 79) % int(area[3]))
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

class_name MapOverview
extends Control

var catalog: ContentCatalog
var state: FarmState
var region: Dictionary
var background: Texture2D
var map_rect: Rect2
var ratio: float


func configure(content: ContentCatalog, initial_state: FarmState) -> void:
	catalog = content
	state = initial_state
	region = catalog.region(state.current_map)
	background = load("res://assets/art/%s.png" % region.background)
	ratio = minf(size.x / (region.width * 32), size.y / (region.height * 32))
	var extent = Vector2(region.width * 32, region.height * 32) * ratio
	map_rect = Rect2((size - extent) / 2, extent)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	if background == null:
		return
	draw_texture_rect(background, map_rect, false)
	for prop in region.props:
		var texture = load("res://assets/art/%s.png" % prop.texture)
		var at = Vector2(prop.ground[0] + prop.offset[0], prop.ground[1] + prop.offset[1])
		draw_texture_rect(
			texture, Rect2(map_rect.position + at * ratio, texture.get_size() * ratio), false
		)
	for p in region.trees:
		draw_circle(map_rect.position + Vector2(p[0] * 32, p[1] * 32) * ratio, 2, Color("36573b"))
	for station in region.stations:
		var at = (
			map_rect.position
			+ Vector2(station.cell[0] * 32 + 16, station.cell[1] * 32 + 16) * ratio
		)
		draw_circle(at, 4, Color("f1e7c3"))
	for id in catalog.story.npcs:
		if catalog.story.npcs[id].map == state.current_map:
			var at = (
				map_rect.position
				+ (Vector2(catalog.npc_cell(id, state.minute)) * 32 + Vector2(16, 16)) * ratio
			)
			draw_circle(at, 4, Color("e19e9f"))
	var player = map_rect.position + state.player_position * ratio
	draw_circle(player, 7, Color("253e32"))
	draw_circle(player, 4, Color("ffe18d"))
	draw_rect(map_rect, Color("aeab7b"), false, 1)

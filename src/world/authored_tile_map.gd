class_name AuthoredTileMap
extends Node2D

## The compiled layers of an authored map as real TileMapLayers over atlas sources.
## Terrain layers sit on a dual grid (offset by half a cell); open water is an animated tile.
var tile_set: TileSet
var animation: Dictionary
var animated: Array[Vector2i] = []


func configure(region: Dictionary) -> void:
	name = "AuthoredTerrain"
	z_index = -10
	use_parent_material = true
	animation = region.tile_animation
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	for index in region.tile_sources.size():
		var atlas = TileSetAtlasSource.new()
		atlas.texture = load("res://assets/art/%s.png" % region.tile_sources[index].texture)
		atlas.texture_region_size = Vector2i(32, 32)
		tile_set.add_source(atlas, index)
	var r: Array = animation.rect
	var moving = Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	for definition in region.tile_layers:
		var layer = TileMapLayer.new()
		layer.name = definition.name
		layer.tile_set = tile_set
		layer.position = Vector2(definition.offset[0], definition.offset[1])
		layer.use_parent_material = true
		layer.collision_enabled = false  # Collision comes from the shared gameplay cells.
		add_child(layer)
		var source = int(definition.source)
		var atlas: TileSetAtlasSource = tile_set.get_source(source)
		var columns = int(region.tile_sources[source].columns)
		var width = int(definition.width)
		for index in definition.cells.size():
			var gid = int(definition.cells[index])
			if gid == 0:
				continue
			var coords = Vector2i((gid - 1) % columns, (gid - 1) / columns)
			if not atlas.has_tile(coords):
				atlas.create_tile(coords)
				if source == int(animation.source) and moving.has_point(coords):
					atlas.set_tile_animation_separation(
						coords, Vector2i(int(animation.separation[0]), int(animation.separation[1]))
					)
					animated.append(coords)
			layer.set_cell(Vector2i(index % width, index / width), source, coords)
	set_calm(false)


## With reduced motion the water rests on its first frame.
func set_calm(calm: bool) -> void:
	if tile_set == null:
		return
	var atlas: TileSetAtlasSource = tile_set.get_source(int(animation.source))
	var frames = 1 if calm else int(animation.frames)
	for coords in animated:
		atlas.set_tile_animation_frames_count(coords, frames)
		for frame in frames:
			atlas.set_tile_animation_frame_duration(coords, frame, float(animation.duration))

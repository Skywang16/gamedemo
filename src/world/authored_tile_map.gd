class_name AuthoredTileMap
extends Node2D

## Runtime rendering of the authored Tiled layers. Cells remain independently editable data.
const WATER = Vector2i(8, 0)
var atlas: TileSetAtlasSource
var tile_set: TileSet
var water_layer: TileMapLayer


func configure(region: Dictionary, texture: Texture2D) -> void:
	name = "AuthoredTerrain"
	z_index = -10
	use_parent_material = true
	atlas = TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(32, 32)
	for index in 528:
		if index in [9, 10, 11]:
			continue  # Reserved by the four-frame water tile at (8, 0).
		atlas.create_tile(Vector2i(index % 16, index / 16))
	atlas.set_tile_animation_columns(WATER, 4)
	set_calm(false)
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	tile_set.add_source(atlas, 0)
	for definition in region.tile_layers:
		var layer = TileMapLayer.new()
		layer.name = definition.name
		layer.tile_set = tile_set
		layer.use_parent_material = true
		layer.collision_enabled = false  # The same authored cells feed the shared gameplay collider.
		add_child(layer)
		for index in definition.cells.size():
			var gid = int(definition.cells[index])
			if gid == 0:
				continue
			var tile = gid - 1
			layer.set_cell(
				Vector2i(index % int(region.width), index / int(region.width)),
				0,
				Vector2i(tile % 16, tile / 16)
			)
		if definition.name == "Water":
			water_layer = layer


func set_calm(calm: bool) -> void:
	if atlas == null:
		return
	atlas.set_tile_animation_frames_count(WATER, 1 if calm else 4)
	for frame in 1 if calm else 4:
		atlas.set_tile_animation_frame_duration(WATER, frame, 0.28)

class_name WorldAmbient
extends Node2D

var time: float = 0
var ripples: Array[Vector2] = []
var smoke_sources: Array[Vector2] = []
var outdoors: bool = false
var calm: bool = false


func configure(region: Dictionary) -> void:
	outdoors = region.environment == "exterior"
	for polygon in region.get("water", []):
		var points = PackedVector2Array()
		for p in polygon:
			points.append(Vector2(p[0] * 32, p[1] * 32))
		for y in range(32, int(region.height) * 32, 64):
			for x in range(32, int(region.width) * 32, 80):
				var at = Vector2(x + (y % 3) * 11, y)
				if Geometry2D.is_point_in_polygon(at, points):
					ripples.append(at)
	for prop in region.props:
		if prop.texture in ["house", "inn", "workshop"]:
			smoke_sources.append(
				Vector2(prop.ground[0] + prop.offset[0] + 205, prop.ground[1] + prop.offset[1] + 22)
			)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var visible_area = (
		get_viewport().get_canvas_transform().affine_inverse()
		* Rect2(Vector2.ZERO, get_viewport_rect().size)
	)
	for at in ripples:
		if not visible_area.has_point(at):
			continue
		var wave = sin(time * 1.6 + at.x * .1 + at.y * .03)
		var pos = at + Vector2(sin(time + at.y) * 3, wave * 2)
		draw_line(
			pos, pos + Vector2(10 + wave * 5, 0), Color(0.72, .89, .85, .25 + (wave + 1) * .18), 1
		)
	for chimney in smoke_sources:
		for i in range(4):
			var phase = fmod(time * .17 + i * .25, 1.0)
			var at = chimney + Vector2(sin(phase * 4 + time * .3) * 7 + phase * 8, -phase * 75)
			var size = 5 + phase * 10
			draw_rect(
				Rect2(at.round(), Vector2(size, size)), Color(.88, .86, .73, (1 - phase) * .3)
			)
	if outdoors and not calm:
		for i in range(8):
			var phase = fmod(time * .035 + i * .127, 1.0)
			var at = (
				visible_area.position
				+ Vector2(phase * visible_area.size.x, fmod(i * 89 + time * 7, visible_area.size.y))
			)
			at.y += sin(time * 2 + i) * 7
			draw_rect(Rect2(at.round(), Vector2(3 + sin(time * 5 + i) * 2, 2)), Color("d5cb7e88"))

class_name WorldEffects
extends Node2D

var particles: Array = []
var streams: Array = []
var pickups: Array = []


func burst(kind: String, at: Vector2, count: int = 14) -> void:
	var colors = {
		"hoe": [Color("a37b48"), Color("d2ad70"), Color("765432")],
		"water": [Color("a6d9df"), Color("dbf5e8"), Color("7ab9cb")],
		"axe": [Color("cc9a55"), Color("ecc586"), Color("8a6135")],
		"scythe": [Color("8fbb59"), Color("c2d77e"), Color("598544")],
		"pickaxe": [Color("b7b5a0"), Color("e2dcc0"), Color("797f73")],
		"seed": [Color("d7b675"), Color("a78148")],
		"harvest": [Color("ffe4a1"), Color("d8e998")]
	}
	for i in range(count):
		var life = randf_range(0.3, 0.65)
		particles.append(
			{
				"at": at + Vector2(randf_range(-7, 7), randf_range(-3, 3)),
				"velocity": Vector2(randf_range(-48, 48), randf_range(-82, -24)),
				"life": life,
				"duration": life,
				"color": colors[kind][i % colors[kind].size()],
				"size": Vector2(randf_range(2, 5), randf_range(2, 4)),
				"kind": kind
			}
		)
	queue_redraw()


func pour(from: Vector2, at: Vector2) -> void:
	streams.append({"from": from, "at": at, "life": 0.38, "elapsed": 0.0})


func pickup(texture: Texture2D, at: Vector2) -> void:
	pickups.append({"texture": texture, "at": at, "life": 0.65})


func _process(delta: float) -> void:
	for i in range(streams.size() - 1, -1, -1):
		var stream = streams[i]
		stream.life -= delta
		stream.elapsed += delta
		if stream.life <= 0:
			streams.remove_at(i)
	for i in range(particles.size() - 1, -1, -1):
		var p = particles[i]
		p.life -= delta
		p.at += p.velocity * delta
		p.velocity.y += 190 * delta
		if p.life <= 0:
			particles.remove_at(i)
	for i in range(pickups.size() - 1, -1, -1):
		pickups[i].life -= delta
		if pickups[i].life <= 0:
			pickups.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for stream in streams:
		for i in range(12):
			var t = fmod(stream.elapsed * 2.5 + i / 12.0, 1.0)
			var at = stream.from.lerp(stream.at, t) + Vector2(0, -sin(t * PI) * 6)
			draw_rect(Rect2(at.round(), Vector2(2, 4)), Color("bdebf0"))
	for p in particles:
		var color: Color = p.color
		color.a = minf(1, p.life / 0.18)
		draw_rect(Rect2(p.at.round(), p.size), color)
	for p in pickups:
		var t = 1.0 - p.life / 0.65
		var at: Vector2 = p.at + Vector2(-12, -16 - sin(t * PI) * 22)
		draw_texture_rect(
			p.texture,
			Rect2(at.round(), Vector2(24, 24)),
			false,
			Color(1, 1, 1, minf(1, p.life / .2))
		)

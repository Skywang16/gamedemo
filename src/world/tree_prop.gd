class_name TreeProp
extends Node2D

signal landed(at: Vector2)

var hits: int = 0
var trunk: Sprite2D
var collider: CollisionShape2D
var stump: Texture2D
var time: float = 0
var shake: float = 0
var calm: bool = false
var fall_time: float = -1
var fall_direction: float = 1
var art_scale: float = 1.0


func configure(texture: Texture2D, damage: int) -> void:
	hits = damage
	stump = load("res://assets/art/tree_stump.png")
	trunk = Sprite2D.new()
	trunk.texture = texture
	art_scale = texture.get_width() / 96.0
	trunk.centered = false
	trunk.position = Vector2(-texture.get_width() / 2.0, 8 - texture.get_height())
	var pivot = Node2D.new()
	pivot.name = "TrunkPivot"
	pivot.add_child(trunk)
	pivot.use_parent_material = true
	trunk.use_parent_material = true
	add_child(pivot)
	trunk.visible = hits < 3
	var body = StaticBody2D.new()
	collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28)
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	collider.disabled = hits >= 5
	time = position.x * 0.13 + position.y * 0.09
	queue_redraw()


func strike(damage: int, actor_x: float) -> void:
	hits = damage
	shake = 0.36
	fall_direction = 1 if position.x >= actor_x else -1
	if hits == 3:
		fall_time = 0
	if hits == 5:
		collider.set_deferred("disabled", true)
	queue_redraw()


func _process(delta: float) -> void:
	time += delta
	shake = maxf(0, shake - delta)
	var pivot = trunk.get_parent()
	if fall_time >= 0:
		fall_time += delta
		var phase = minf(fall_time / 0.85, 1)
		pivot.rotation = fall_direction * phase * phase * PI * 0.48
		trunk.modulate.a = 1.0 - maxf(0, (phase - 0.82) / 0.18)
		if phase >= 1:
			fall_time = -1
			trunk.hide()
			landed.emit(position + Vector2(fall_direction * 80, -8))
	elif hits < 3:
		var sway = 0.0 if calm else sin(time * 1.6) * 0.009
		pivot.rotation = sway + sin(shake * 60) * shake * 0.28
	queue_redraw()


func _draw() -> void:
	if hits < 3:
		draw_ellipse_shadow()
	elif hits < 5:
		draw_texture_rect(
			stump,
			Rect2(
				Vector2(-16 + sin(shake * 60) * shake * 5, -18) * art_scale,
				Vector2(32, 32) * art_scale
			),
			false
		)


func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(3, -1), 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 33 * art_scale, Color("243c274d"))
	draw_set_transform(Vector2.ZERO)

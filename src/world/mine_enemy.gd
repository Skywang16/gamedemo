class_name MineEnemy
extends Node2D

## One monster on a mine floor: it wanders until the player comes into view, then chases. The
## world moves it; the game decides what its contact and its death are worth.

signal touched(damage: int, push: Vector2)
signal defeated(kind: String, at: Vector2)

var kind: String = ""
var spec: Dictionary = {}
var hp: int = 1
var home: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var frame_time: float = 0.0
var flash: float = 0.0
var cooldown: float = 0.0
var push: Vector2 = Vector2.ZERO
var wander_dir: Vector2 = Vector2.ZERO
var wander_left: float = 0.0
var seed_offset: float = 0.0
var radius: float = 14.0


func configure(enemy_kind: String, enemy_spec: Dictionary, texture: Texture2D, at: Vector2) -> void:
	kind = enemy_kind
	spec = enemy_spec
	hp = int(spec.hp)
	position = at
	home = at
	seed_offset = fposmod(at.x * 0.37 + at.y * 0.11, TAU)
	var size = int(spec.size)
	radius = 14.0 * size
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.region_enabled = true
	var cell = Vector2(texture.get_width() / 2.0, texture.get_height())
	sprite.region_rect = Rect2(0, 0, cell.x, cell.y)
	sprite.position = Vector2(-cell.x / 2.0, -cell.y + 6.0)
	add_child(sprite)
	if kind == "bat":
		sprite.position.y -= 10.0


func hurt(amount: int, from: Vector2, knock: float) -> bool:
	hp -= amount
	flash = 0.25
	var away = (position - from).normalized()
	push = away * knock * (0.4 if bool(spec.boss) else 1.0)
	if hp <= 0:
		defeated.emit(kind, position)
		queue_free()
		return true
	return false


## Moves the monster and returns nothing; `world` answers whether a cell is walkable.
func step(delta: float, player_pos: Vector2, world: FarmWorld) -> void:
	frame_time += delta
	flash = maxf(0.0, flash - delta)
	cooldown = maxf(0.0, cooldown - delta)
	var cell_size = Vector2(sprite.region_rect.size)
	var rect: Rect2 = sprite.region_rect
	rect.position.x = cell_size.x if int(frame_time * 4.0) % 2 == 1 else 0.0
	sprite.region_rect = rect
	sprite.modulate = Color(1.7, 1.2, 1.2) if flash > 0.0 else Color.WHITE
	var velocity = Vector2.ZERO
	var to_player = player_pos - position
	var distance = to_player.length()
	if push.length() > 4.0:
		velocity = push
		push = push.move_toward(Vector2.ZERO, 260.0 * delta)
	elif distance < float(spec.aggro):
		var heading = to_player.normalized()
		if kind == "bat":
			heading = heading.rotated(sin(frame_time * 5.0 + seed_offset) * 0.9)
		velocity = heading * float(spec.speed)
	else:
		wander_left -= delta
		if wander_left <= 0.0:
			wander_left = 1.2 + fposmod(seed_offset * 3.0 + frame_time, 1.8)
			var angle = fposmod(seed_offset + frame_time * 1.7, TAU)
			wander_dir = (
				Vector2.from_angle(angle) * 0.3
				if position.distance_to(home) < 90.0
				else (home - position).normalized() * 0.4
			)
		velocity = wander_dir * float(spec.speed)
	_move(velocity * delta, world)
	sprite.flip_h = to_player.x < 0.0 and distance < float(spec.aggro)
	if distance < radius + 10.0 and cooldown <= 0.0:
		cooldown = 1.0
		touched.emit(int(spec.damage), to_player.normalized())
	queue_redraw()


func _move(step_vector: Vector2, world: FarmWorld) -> void:
	for axis in [Vector2(step_vector.x, 0.0), Vector2(0.0, step_vector.y)]:
		var target = position + axis
		var probe = target + axis.normalized() * radius * 0.5
		var cell = Vector2i(floori(probe.x / 32.0), floori(probe.y / 32.0))
		if not world.catalog.blocked(cell, world.state.current_map, world.state.tree_damage):
			position = target


func _draw() -> void:
	draw_circle(Vector2(0, 6), radius * 0.9, Color(0, 0, 0, 0.22))
	if hp < int(spec.hp) or bool(spec.boss):
		var width = radius * 2.0
		var top = -sprite.region_rect.size.y - 4.0 + (-10.0 if kind == "bat" else 0.0)
		draw_rect(Rect2(-width / 2.0, top, width, 4.0), Color("2a1a1a"))
		draw_rect(
			Rect2(-width / 2.0 + 1.0, top + 1.0, (width - 2.0) * float(hp) / float(spec.hp), 2.0),
			Color("e8503a")
		)

class_name Farmer
extends CharacterBody2D

const WALK_SPEED = 160.0
const RUN_SPEED = 260.0
var can_move: bool = true
var facing: Vector2i = Vector2i.DOWN
var elapsed: float = 0.0
var frame: int = 0
var texture: Texture2D
var flash_time: float = 0.0
var appearance: Dictionary = {}


func _ready() -> void:
	texture = (
		load(ContentCatalog.avatar_path(appearance))
		if not appearance.is_empty()
		else load("res://assets/art/avatar_0_0_0_1.png")
	)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(14, 8)
	collider.shape = shape
	collider.position = Vector2(0, -3)
	add_child(collider)


func _physics_process(delta: float) -> void:
	var movement = (
		Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if can_move
		else Vector2.ZERO
	)
	velocity = movement * (RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED)
	if movement != Vector2.ZERO:
		if absf(movement.x) > absf(movement.y):
			facing = Vector2i.RIGHT if movement.x > 0 else Vector2i.LEFT
		else:
			facing = Vector2i.DOWN if movement.y > 0 else Vector2i.UP
		elapsed += delta
		frame = int(elapsed * 8) % 4
	else:
		frame = 0
	move_and_slide()
	flash_time = maxf(0.0, flash_time - delta)
	queue_redraw()


func cell() -> Vector2i:
	return Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))


func celebrate() -> void:
	flash_time = 0.18


func _draw() -> void:
	if texture == null:
		return
	var row = 0
	if facing == Vector2i.UP:
		row = 1
	elif facing == Vector2i.LEFT:
		row = 2
	elif facing == Vector2i.RIGHT:
		row = 3
	var tint = Color(1.15, 1.12, 0.95) if flash_time > 0 else Color.WHITE
	draw_texture_rect_region(
		texture, Rect2(-16, -44, 32, 48), Rect2(frame * 32, row * 48, 32, 48), tint
	)

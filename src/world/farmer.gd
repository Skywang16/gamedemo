class_name Farmer
extends CharacterBody2D

signal action_contact(tool: String, cell: Vector2i)

const WALK_SPEED = 160.0
const RUN_SPEED = 260.0
var can_move: bool = true
var facing: Vector2i = Vector2i.DOWN
var elapsed: float = 0.0
var idle_time: float = 0.0
var frame: int = 0
var texture: Texture2D
var action_texture: Texture2D
var appearance: Dictionary = {}
var action_remaining: float = 0.0
var action_duration: float = 0.0
var action_tool: String = ""
var action_target: Vector2i
var contacted: bool = false


func _ready() -> void:
	var path = ContentCatalog.avatar_path(appearance)
	texture = load(path)
	action_texture = load(path.replace("avatar_", "action_"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var collider = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(14, 8)
	collider.shape = shape
	collider.position = Vector2(0, -3)
	add_child(collider)


func _physics_process(delta: float) -> void:
	idle_time += delta
	var movement = (
		Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if can_move and action_remaining == 0
		else Vector2.ZERO
	)
	velocity = movement * (RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED)
	if movement != Vector2.ZERO:
		face(movement)
		elapsed += delta
		frame = int(elapsed * (12 if Input.is_action_pressed("sprint") else 8)) % 4
	else:
		frame = 0
	move_and_slide()
	if can_move and action_remaining > 0:
		action_remaining = maxf(0, action_remaining - delta)
		if not contacted and action_phase() >= ToolMotion.CONTACT:
			contacted = true
			action_contact.emit(action_tool, action_target)
	queue_redraw()


func face(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		facing = Vector2i.RIGHT if direction.x > 0 else Vector2i.LEFT
	elif direction != Vector2.ZERO:
		facing = Vector2i.DOWN if direction.y > 0 else Vector2i.UP


func cell() -> Vector2i:
	return Vector2i(floori(position.x / 32.0), floori(position.y / 32.0))


func swing_tool(tool: String, target: Vector2i) -> bool:
	if action_remaining > 0:
		return false
	face(Vector2(target - cell()))
	action_tool = tool
	action_target = target
	action_duration = ToolMotion.DURATIONS[tool]
	action_remaining = action_duration
	contacted = false
	queue_redraw()
	return true


func action_phase() -> float:
	return 1.0 - action_remaining / action_duration if action_duration > 0 else 0.0


func _draw() -> void:
	if texture == null:
		return
	var row = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT].find(facing)
	if action_remaining > 0:
		draw_texture_rect_region(
			action_texture,
			Rect2(-48, -72, 96, 112),
			ToolMotion.atlas_rect(action_tool, row, action_phase())
		)
	else:
		var breath = 1 if velocity == Vector2.ZERO and sin(idle_time * 2.4) > 0.65 else 0
		draw_texture_rect_region(
			texture, Rect2(-16, -44 + breath, 32, 48 - breath), Rect2(frame * 32, row * 48, 32, 48)
		)

class_name UIMotion
extends RefCounted

## Small shared UI animations. Everything degrades to "instant" when the player turned
## on reduced motion, so callers never need to check the setting themselves.

static var reduced: bool = false


## Fades a node in while it settles up from `lift` pixels below its final position.
static func appear(
	node: CanvasItem, seconds: float = 0.16, lift: float = 12.0, delay: float = 0.0
) -> void:
	if reduced or node == null or not node.is_inside_tree():
		return
	_stop(node)
	var settled: float = node.position.y if node is Control or node is Node2D else 0.0
	node.modulate.a = 0.0
	if node is Control or node is Node2D:
		node.position.y = settled + lift
	var tween = node.create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "modulate:a", 1.0, seconds).set_delay(delay)
	if node is Control or node is Node2D:
		tween.tween_property(node, "position:y", settled, seconds).set_delay(delay)
	node.set_meta("ui_motion", tween)


## A quick grow-and-settle, used for numbers that just changed.
static func pulse(node: Control, grow: float = 1.2, seconds: float = 0.24) -> void:
	if reduced or node == null or not node.is_inside_tree():
		return
	_stop(node)
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2.ONE
	var tween = node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * grow, seconds * 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, seconds * 0.65).set_ease(Tween.EASE_IN_OUT)
	node.set_meta("ui_motion", tween)


## Exponential smoothing towards `target`; snaps once close enough or when reduced.
static func ease_toward(
	current: float, target: float, delta: float, speed: float = 10.0, snap: float = 0.5
) -> float:
	if reduced or absf(target - current) <= snap:
		return target
	return lerpf(current, target, 1.0 - exp(-speed * delta))


static func _stop(node: Node) -> void:
	if node.has_meta("ui_motion"):
		var old = node.get_meta("ui_motion")
		if old is Tween and old.is_valid():
			old.kill()
		node.remove_meta("ui_motion")

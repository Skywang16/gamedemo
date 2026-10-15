extends SceneTree

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)


func run() -> void:
	UIMotion.reduced = false
	var value = 0.0
	var previous = -1.0
	for frame in 600:
		value = UIMotion.ease_toward(value, 100.0, 1.0 / 60.0, 8.0)
		check(value >= previous and value <= 100.0, "easing is monotonic and never overshoots")
		previous = value
	check(value == 100.0, "easing settles exactly on the target")
	check(UIMotion.ease_toward(10.0, 10.3, 0.016) == 10.3, "tiny gaps snap")
	var step = UIMotion.ease_toward(0.0, 100.0, 1.0 / 60.0, 8.0)
	check(step > 0.0 and step < 20.0, "one frame moves part of the way")
	var slow = UIMotion.ease_toward(0.0, 100.0, 1.0 / 60.0, 2.0)
	check(slow < step, "lower speed moves less")
	check(UIMotion.ease_toward(0.0, 100.0, 0.0, 8.0) == 0.0, "zero time does not move")
	check(UIMotion.ease_toward(50.0, 0.0, 1.0 / 60.0, 8.0) < 50.0, "it also eases downwards")
	UIMotion.reduced = true
	check(UIMotion.ease_toward(0.0, 100.0, 0.001, 1.0) == 100.0, "reduced motion is instant")
	var node = Control.new()
	UIMotion.appear(node)
	UIMotion.pulse(node)
	check(node.modulate.a == 1.0, "reduced motion never hides a node")
	UIMotion.reduced = false
	UIMotion.appear(node)
	check(node.modulate.a == 1.0, "a node outside the tree is left alone")
	node.free()
	print("MOTION_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

class_name WeatherLayer
extends Node2D

## Screen-space weather: rain with splashes, storms with lightning, snow, wind-blown
## leaves and petals, and drifting cloud shadows. Lives on its own CanvasLayer, so the
## world's colour grading does not tint it.

const SIZE = Vector2(1280, 800)
const RAIN_COLOR = Color(0.78, 0.88, 0.97, 0.55)
const TINTS = {
	"cloudy": Color(0.45, 0.5, 0.58, 0.07),
	"rain": Color(0.12, 0.18, 0.28, 0.16),
	"storm": Color(0.06, 0.09, 0.18, 0.3),
	"snow": Color(0.85, 0.92, 1.0, 0.08),
}
const LEAF_COLORS = {
	"spring": [Color("f4c6d0"), Color("f8dfe3"), Color("e9a9bb")],
	"summer": [Color("a9cf6a"), Color("86b254")],
	"autumn": [Color("d98a3d"), Color("c4622a"), Color("e8b552")],
	"winter": [Color("f2f6fb"), Color("d5e3f2")],
}

var kind: String = "sunny"
var season: String = "spring"
var calm: bool = false
var time: float = 0.0
var rng := RandomNumberGenerator.new()
# Parallel arrays keep per-frame cost low: x, y, vx, vy, size/length.
var px: PackedFloat32Array = PackedFloat32Array()
var py: PackedFloat32Array = PackedFloat32Array()
var pvx: PackedFloat32Array = PackedFloat32Array()
var pvy: PackedFloat32Array = PackedFloat32Array()
var pextra: PackedFloat32Array = PackedFloat32Array()
var splashes: Array = []
var flash: float = 0.0
var next_flash: float = 6.0


func configure(season_id: String, weather: String, reduce_motion: bool) -> void:
	season = season_id
	kind = weather
	calm = reduce_motion
	rng.seed = hash(season_id + weather)
	splashes.clear()
	flash = 0.0
	next_flash = rng.randf_range(4.0, 9.0)
	var count = particle_count()
	px.resize(count)
	py.resize(count)
	pvx.resize(count)
	pvy.resize(count)
	pextra.resize(count)
	for i in count:
		_respawn(i, true)
	visible = true
	queue_redraw()


## Number of falling or drifting particles for the current weather.
func particle_count() -> int:
	var count = 0
	match kind:
		"rain":
			count = 170
		"storm":
			count = 300
		"snow":
			count = 150
		"wind":
			count = 34
		_:
			count = 0
	if kind in ["sunny", "cloudy"] and season in ["spring", "autumn"]:
		count = 5
	if calm:
		count = int(count / 2)
	return count


func _respawn(i: int, anywhere: bool) -> void:
	px[i] = rng.randf_range(-80.0, SIZE.x + 80.0)
	py[i] = rng.randf_range(0.0, SIZE.y) if anywhere else rng.randf_range(-60.0, -4.0)
	match kind:
		"rain":
			pvx[i] = -110.0
			pvy[i] = rng.randf_range(760.0, 980.0)
			pextra[i] = rng.randf_range(10.0, 17.0)
		"storm":
			pvx[i] = -230.0
			pvy[i] = rng.randf_range(900.0, 1180.0)
			pextra[i] = rng.randf_range(13.0, 22.0)
		"snow":
			pvx[i] = rng.randf_range(-12.0, 12.0)
			pvy[i] = rng.randf_range(38.0, 92.0)
			pextra[i] = float(rng.randi_range(2, 3))
		_:
			var gust = kind == "wind"
			pvx[i] = rng.randf_range(220.0, 340.0) if gust else rng.randf_range(14.0, 34.0)
			pvy[i] = rng.randf_range(20.0, 60.0) if gust else rng.randf_range(16.0, 36.0)
			pextra[i] = rng.randf_range(0.0, TAU)
			if not anywhere and gust:
				px[i] = rng.randf_range(-120.0, -8.0)
				py[i] = rng.randf_range(0.0, SIZE.y * 0.8)


func _process(delta: float) -> void:
	if not visible:
		return
	time += delta
	for i in px.size():
		px[i] += pvx[i] * delta
		py[i] += pvy[i] * delta
		if kind == "snow":
			px[i] += sin(time * 1.3 + i) * 14.0 * delta
		if py[i] > SIZE.y + 20.0 or px[i] > SIZE.x + 120.0 or px[i] < -140.0:
			_respawn(i, false)
			if kind in ["rain", "storm"] and splashes.size() < 36 and rng.randf() < 0.5:
				splashes.append([rng.randf_range(0.0, SIZE.x), rng.randf_range(120.0, SIZE.y), 0.0])
	for s in splashes:
		s[2] += delta
	splashes = splashes.filter(func(s): return s[2] < 0.32)
	if kind == "storm" and not calm:
		next_flash -= delta
		if next_flash <= 0.0:
			flash = 0.5
			next_flash = rng.randf_range(7.0, 15.0)
	flash = maxf(0.0, flash - delta)
	queue_redraw()


func _draw() -> void:
	if TINTS.has(kind):
		draw_rect(Rect2(Vector2.ZERO, SIZE), TINTS[kind])
	if kind == "sunny" and not calm:
		_draw_cloud_shadows()
	match kind:
		"rain", "storm":
			_draw_rain()
		"snow":
			_draw_snow()
		_:
			_draw_leaves()
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.92, 0.95, 1.0, flash * 0.9))


func _draw_rain() -> void:
	for i in px.size():
		var from = Vector2(px[i], py[i])
		var along = Vector2(pvx[i], pvy[i]).normalized() * pextra[i]
		draw_line(from.round(), (from - along).round(), RAIN_COLOR, 1.0)
	for s in splashes:
		var t: float = s[2] / 0.32
		var radius = 2.0 + t * 6.0
		var at = Vector2(s[0], s[1]).round()
		draw_arc(at, radius, PI, TAU, 8, Color(0.85, 0.93, 1.0, 0.45 * (1.0 - t)), 1.0)


func _draw_snow() -> void:
	for i in px.size():
		var size = pextra[i]
		draw_rect(Rect2(Vector2(px[i], py[i]).round(), Vector2(size, size)), Color(1, 1, 1, 0.88))


func _draw_leaves() -> void:
	var palette: Array = LEAF_COLORS.get(season, LEAF_COLORS.spring)
	for i in px.size():
		var wobble = sin(time * 2.2 + pextra[i]) * 6.0
		var at = Vector2(px[i], py[i] + wobble).round()
		var color: Color = palette[i % palette.size()]
		draw_rect(Rect2(at, Vector2(5, 3)), color)
		draw_rect(Rect2(at + Vector2(1, 1), Vector2(3, 1)), color.darkened(0.18))


func _draw_cloud_shadows() -> void:
	for i in 3:
		var x = fposmod(time * (9.0 + i * 3.0) + i * 520.0, SIZE.x + 700.0) - 350.0
		var at = Vector2(x, 160.0 + i * 230.0)
		draw_set_transform(at, 0.0, Vector2(2.6, 1.0))
		draw_circle(Vector2.ZERO, 120.0, Color(0.1, 0.18, 0.2, 0.06))
	draw_set_transform(Vector2.ZERO)

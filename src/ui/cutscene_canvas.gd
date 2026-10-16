class_name CutsceneCanvas
extends Node2D

## The picture of a story scene: a painted backdrop, the people standing in it, weather and light
## effects, a slow camera, flashes and shakes. It is drawn at 320x200 and scaled up by the view.

const SLOT_X = {
	"far_left": 36.0,
	"left": 78.0,
	"center_left": 120.0,
	"center": 160.0,
	"center_right": 200.0,
	"right": 242.0,
	"far_right": 284.0,
}
const FEET_Y = 142.0
const WALK_SPEED = 62.0
const ACT_TIME = 0.5

var catalog: ContentCatalog
var profile: Dictionary = {}
var scene_bg: String = "farm"
var mood: String = "day"
var lamps: int = 0
var effects: Array = []
var actors: Dictionary = {}
var leaving: Array = []
var textures: Dictionary = {}
var time: float = 0.0
var speaker: String = ""
var camera_mode: String = "still"
var camera_time: float = 0.0
var flash_color: Color = Color.WHITE
var flash_left: float = 0.0
var shake_left: float = 0.0
var reduced: bool = false


func configure(content: ContentCatalog, player_profile: Dictionary, lit_lamps: int) -> void:
	catalog = content
	profile = player_profile
	lamps = lit_lamps
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_backdrop(id: String, new_mood: String) -> void:
	scene_bg = id
	mood = new_mood
	queue_redraw()


func set_effects(list: Array) -> void:
	effects = list.duplicate()


func set_camera(mode: String) -> void:
	camera_mode = mode
	camera_time = 0.0


func flash(kind: String) -> void:
	if reduced:
		return
	flash_color = {"white": Color.WHITE, "gold": Color("ffe9a0"), "black": Color.BLACK}[kind]
	flash_left = 0.7


func shake(seconds: float) -> void:
	if not reduced:
		shake_left = seconds


func _texture_for(id: String) -> Texture2D:
	if not textures.has(id):
		if id == "player":
			textures[id] = load(ContentCatalog.avatar_path(profile))
		elif catalog.story.npcs.has(id):
			textures[id] = load("res://assets/art/%s.png" % catalog.story.npcs[id].sprite)
		else:
			textures[id] = load("res://assets/art/%s.png" % catalog.story.guests[id].sprite)
	return textures[id]


## Replaces the cast on stage. New people walk in from the nearer edge; people no longer listed
## walk out the way they are closest to. `instant` places everyone without walking.
func set_actors(entries: Array, instant: bool) -> void:
	var wanted: Dictionary = {}
	var used: Array = []
	for entry in entries:
		var parts = str(entry).split("@")
		var slot = parts[1]
		var x: float = SLOT_X[slot]
		while used.has(x):
			x += 14.0
		used.append(x)
		wanted[parts[0]] = x
	for id in actors.keys():
		if not wanted.has(id):
			if instant:
				actors.erase(id)
			else:
				var gone = actors[id]
				gone.target = -40.0 if gone.x < 160.0 else 360.0
				gone.leaving = true
				leaving.append(gone)
				actors.erase(id)
	for id in wanted:
		if actors.has(id):
			actors[id].target = wanted[id]
			if instant:
				actors[id].x = wanted[id]
		else:
			var start = wanted[id]
			if not instant:
				start = -34.0 if wanted[id] < 160.0 else 354.0
			actors[id] = {
				"id": id,
				"tex": _texture_for(id),
				"x": start,
				"target": wanted[id],
				"act": "",
				"act_time": 0.0,
				"facing": 0,
				"phase": fposmod(float(hash(id)), TAU),
				"leaving": false,
				"walking": false,
			}


func trigger_act(id: String, action: String) -> void:
	if actors.has(id) and not reduced:
		actors[id].act = action
		actors[id].act_time = 0.0


func _process(delta: float) -> void:
	time += delta
	camera_time += delta
	flash_left = maxf(0.0, flash_left - delta)
	shake_left = maxf(0.0, shake_left - delta)
	for actor in actors.values() + leaving:
		_walk(actor, delta)
		if actor.act != "":
			actor.act_time += delta
			if actor.act_time >= ACT_TIME:
				actor.act = ""
	leaving = leaving.filter(func(a): return absf(a.x - a.target) > 1.0)
	queue_redraw()


func _walk(actor: Dictionary, delta: float) -> void:
	var gap: float = actor.target - actor.x
	if absf(gap) <= 1.0:
		actor.x = actor.target
		actor.walking = false
		return
	actor.walking = true
	actor.x += signf(gap) * minf(absf(gap), WALK_SPEED * delta)
	actor.facing = 3 if gap > 0.0 else 2


func _camera() -> Transform2D:
	var centre = Vector2(160, 100)
	var zoom = 1.0
	var pan = 0.0
	var progress = minf(1.0, camera_time / 9.0)
	match camera_mode:
		"zoom_in":
			zoom = 1.0 + 0.09 * progress
		"zoom_out":
			zoom = 1.09 - 0.09 * progress
		"pan_left":
			zoom = 1.07
			pan = lerpf(9.0, -9.0, progress)
		"pan_right":
			zoom = 1.07
			pan = lerpf(-9.0, 9.0, progress)
	if reduced:
		zoom = 1.0
		pan = 0.0
	var shake_offset = Vector2.ZERO
	if shake_left > 0.0:
		shake_offset = (
			Vector2(sin(time * 80.0), cos(time * 97.0)) * 3.0 * minf(1.0, shake_left * 2.0)
		)
	var t = Transform2D(0.0, Vector2(zoom, zoom), 0.0, Vector2.ZERO)
	t.origin = centre + Vector2(pan, 0.0) + shake_offset - centre * zoom
	return t


func _draw() -> void:
	if catalog == null:
		return
	draw_set_transform_matrix(_camera())
	var params = {"t": time, "mood": mood, "lamps": lamps}
	CutscenePaint.draw_scene(self, scene_bg, params)
	var cast: Array = actors.values() + leaving
	cast.sort_custom(func(a, b): return a.x < b.x)
	for actor in cast:
		_draw_actor(actor)
	var tint = CutscenePaint.tint_of(mood)
	if tint.a > 0.0:
		draw_rect(Rect2(-40, -40, 400, 280), tint)
	CutscenePaint.draw_glow(self, scene_bg, params)
	if not reduced or effects.size() > 0:
		for kind in effects:
			CutscenePaint.draw_fx(self, kind, time)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if flash_left > 0.0:
		var c = flash_color
		c.a = clampf(flash_left / 0.7, 0.0, 1.0) * 0.85
		draw_rect(Rect2(0, 0, 320, 200), c)


func _draw_actor(actor: Dictionary) -> void:
	var offset = Vector2.ZERO
	var u = clampf(actor.act_time / ACT_TIME, 0.0, 1.0)
	match actor.act:
		"hop":
			offset.y = -12.0 * sin(PI * u)
		"nod":
			offset.y = 2.0 * sin(TAU * u * 2.0)
		"shake":
			offset.x = 3.0 * sin(u * 34.0) * (1.0 - u)
		"bow":
			offset.y = 4.0 * sin(PI * u)
		"step":
			offset.x = (10.0 if actor.x < 160.0 else -10.0) * sin(PI * u)
	var talking = speaker == actor.id and not reduced
	if talking and actor.act == "":
		offset.y = -1.0 if sin(time * 11.0 + actor.phase) > 0.2 else 0.0
	var row = 0
	if actor.walking:
		row = actor.facing
	elif absf(actor.x - 160.0) > 14.0:
		row = 3 if actor.x < 160.0 else 2
	var frame = int(time * 8.0) % 4 if actor.walking else 0
	var base = Vector2(actor.x - 16.0, FEET_Y - 46.0) + offset
	draw_rect(Rect2(actor.x - 11.0, FEET_Y - 1.0, 22.0, 3.0), Color(0, 0, 0, 0.28))
	draw_texture_rect_region(
		actor.tex, Rect2(base, Vector2(32, 48)), Rect2(frame * 32, row * 48, 32, 48)
	)
	if talking:
		draw_rect(Rect2(actor.x - 1.0, base.y - 5.0, 2, 2), Color(1, 1, 1, 0.8))

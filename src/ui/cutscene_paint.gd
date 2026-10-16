class_name CutscenePaint
extends RefCounted

## Backdrops and weather for the story scenes, painted with rectangles and polygons into a small
## 320x200 picture that the cutscene view scales up four times, so everything is chunky pixels.
## Each painter draws the lit scenery; `glow` draws the light sources again after the mood tint
## so windows and lanterns shine through the dark.

const W = 320
const H = 200
const GROUND = 150

const SKY = {
	"day": [Color("7ec4ea"), Color("dcf2f8")],
	"dawn": [Color("e8987c"), Color("ffe6b8")],
	"dusk": [Color("4e4c92"), Color("f6a272")],
	"night": [Color("10163a"), Color("2c3c6c")],
	"rain": [Color("6a7a8a"), Color("aab6be")],
	"snow": [Color("a6b6c8"), Color("e8eef4")],
}
const TINT = {
	"day": Color(0.0, 0.0, 0.0, 0.0),
	"dawn": Color(1.0, 0.62, 0.34, 0.08),
	"dusk": Color(0.9, 0.4, 0.2, 0.13),
	"night": Color(0.03, 0.05, 0.22, 0.46),
	"rain": Color(0.2, 0.26, 0.32, 0.24),
	"snow": Color(0.8, 0.9, 1.0, 0.1),
}


static func rand(i: float) -> float:
	return fposmod(sin(i * 12.9898 + 4.1414) * 43758.5453, 1.0)


static func box(c: CanvasItem, x: float, y: float, w: float, h: float, col: Color) -> void:
	c.draw_rect(Rect2(x, y, w, h), col)


static func poly(c: CanvasItem, points: Array, col: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(points), col)


static func tint_of(mood: String) -> Color:
	return TINT.get(mood, TINT.day)


static func sky(c: CanvasItem, mood: String, bottom: float = 150.0) -> void:
	var pair: Array = SKY.get(mood, SKY.day)
	var steps = 14
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		box(c, 0, bottom * i / steps, W, bottom / steps + 1.0, pair[0].lerp(pair[1], t))


static func stars(c: CanvasItem, t: float) -> void:
	for i in range(46):
		var x = rand(i * 1.7) * W
		var y = rand(i * 3.3 + 1.0) * 90.0
		var tw = 0.5 + 0.5 * sin(t * 2.0 + i)
		box(c, x, y, 1.0, 1.0, Color(1, 1, 0.9, 0.35 + 0.5 * tw))


static func sun_or_moon(c: CanvasItem, mood: String, t: float) -> void:
	match mood:
		"night":
			stars(c, t)
			c.draw_circle(Vector2(246, 34), 13, Color("f6f0d0"))
			c.draw_circle(Vector2(251, 31), 11, Color("2c3c6c"))
		"day":
			c.draw_circle(Vector2(250, 30), 14, Color("fff0a8"))
		"dawn":
			c.draw_circle(Vector2(72, 118), 18, Color("ffd898"))
		"dusk":
			c.draw_circle(Vector2(262, 112), 18, Color("ffb070"))


static func cloud(c: CanvasItem, x: float, y: float, s: float, col: Color) -> void:
	box(c, x, y + 4 * s, 34 * s, 7 * s, col)
	box(c, x + 6 * s, y, 18 * s, 8 * s, col)
	box(c, x + 18 * s, y + 2 * s, 14 * s, 8 * s, col)


static func mountains(
	c: CanvasItem, base: float, col: Color, seed_value: float, amp: float
) -> void:
	var pts: Array = [Vector2(0, base + 30)]
	var x = 0.0
	while x <= W + 20.0:
		pts.append(
			Vector2(
				x, base - rand(seed_value + x * 0.05) * amp - amp * 0.4 * sin(x * 0.03 + seed_value)
			)
		)
		x += 20.0
	pts.append(Vector2(W + 20, base + 30))
	poly(c, pts, col)


static func hills(c: CanvasItem, base: float, col: Color, phase: float, amp: float) -> void:
	var pts: Array = [Vector2(0, H)]
	var x = 0.0
	while x <= W + 8.0:
		pts.append(
			Vector2(
				x, base - amp * sin(x * 0.02 + phase) - amp * 0.5 * sin(x * 0.047 + phase * 2.0)
			)
		)
		x += 8.0
	pts.append(Vector2(W + 8, H))
	poly(c, pts, col)


static func grass(mood: String) -> Color:
	return Color("e6eef2") if mood == "snow" else Color("58a048")


static func tree(c: CanvasItem, x: float, y: float, s: float, mood: String) -> void:
	box(c, x - 2 * s, y - 14 * s, 4 * s, 14 * s, Color("5a3e28"))
	var leaf = Color("dfe8ec") if mood == "snow" else Color("3f8a3f")
	var light = Color("f4f8fa") if mood == "snow" else Color("5fae50")
	c.draw_circle(Vector2(x, y - 22 * s), 11 * s, leaf)
	c.draw_circle(Vector2(x - 7 * s, y - 16 * s), 8 * s, leaf)
	c.draw_circle(Vector2(x + 7 * s, y - 17 * s), 8 * s, leaf)
	c.draw_circle(Vector2(x - 3 * s, y - 26 * s), 6 * s, light)


static func house(
	c: CanvasItem, x: float, y: float, w: float, h: float, roof: Color, wall: Color, mood: String
) -> void:
	box(c, x, y - h, w, h, wall)
	box(c, x, y - 3, w, 3, wall.darkened(0.25))
	poly(
		c,
		[Vector2(x - 4, y - h), Vector2(x + w / 2.0, y - h - w * 0.4), Vector2(x + w + 4, y - h)],
		roof
	)
	if mood == "snow":
		poly(
			c,
			[
				Vector2(x - 4, y - h),
				Vector2(x + w / 2.0, y - h - w * 0.4),
				Vector2(x + w / 2.0, y - h - w * 0.4 + 4),
				Vector2(x - 1, y - h + 2)
			],
			Color("f4f8fa")
		)
	box(c, x + w * 0.42, y - h * 0.5, w * 0.16, h * 0.5, Color("5a3e28"))
	box(c, x + w * 0.12, y - h * 0.7, w * 0.18, h * 0.22, Color("a8d0e0"))
	box(c, x + w * 0.7, y - h * 0.7, w * 0.18, h * 0.22, Color("a8d0e0"))


static func windows_glow(c: CanvasItem, x: float, y: float, w: float, h: float, on: bool) -> void:
	if not on:
		return
	box(c, x + w * 0.12, y - h * 0.7, w * 0.18, h * 0.22, Color("ffd878"))
	box(c, x + w * 0.7, y - h * 0.7, w * 0.18, h * 0.22, Color("ffd878"))
	c.draw_circle(Vector2(x + w * 0.21, y - h * 0.59), 7, Color(1.0, 0.85, 0.4, 0.2))
	c.draw_circle(Vector2(x + w * 0.79, y - h * 0.59), 7, Color(1.0, 0.85, 0.4, 0.2))


static func lamp(c: CanvasItem, x: float, y: float, lit: bool) -> void:
	box(c, x - 1, y - 24, 2, 24, Color("2c2a30"))
	box(c, x - 3, y - 29, 6, 6, Color("ffe08a") if lit else Color("8a8070"))


static func lamp_glow(c: CanvasItem, x: float, y: float) -> void:
	c.draw_circle(Vector2(x, y - 26), 12, Color(1.0, 0.86, 0.45, 0.18))
	c.draw_circle(Vector2(x, y - 26), 6, Color(1.0, 0.9, 0.55, 0.3))


static func cobble(c: CanvasItem, y: float, mood: String) -> void:
	var base = Color("b8b4a8") if mood != "snow" else Color("dfe4e8")
	box(c, 0, y, W, H - y, base)
	for row in range(int((H - y) / 7.0) + 1):
		for col in range(-1, 20):
			var x = col * 18.0 + (row % 2) * 9.0
			var shade = base.lightened(0.06) if (row + col) % 3 == 0 else base.darkened(0.04)
			box(c, x, y + row * 7.0, 17.0, 6.0, shade)


static func water(c: CanvasItem, y0: float, y1: float, t: float, mood: String) -> void:
	var pair: Array = SKY.get(mood, SKY.day)
	var top = Color("3f7a9a").lerp(pair[0], 0.25)
	var low = Color("2a5a7a").lerp(pair[0], 0.15)
	box(c, 0, y0, W, y1 - y0, top)
	var rows = int((y1 - y0) / 6.0)
	for r in range(rows):
		box(c, 0, y0 + r * 6.0, W, 3.0, top.lerp(low, float(r) / maxf(1.0, float(rows))))
	for i in range(34):
		var x = fposmod(rand(i) * W + t * (4.0 + rand(i + 9.0) * 6.0), W)
		var y = y0 + 4.0 + rand(i + 3.0) * (y1 - y0 - 6.0)
		box(c, x, y, 6.0 + rand(i + 5.0) * 8.0, 1.0, Color(1, 1, 1, 0.28))


static func reeds(c: CanvasItem, x: float, y: float, count: int) -> void:
	for i in range(count):
		var rx = x + i * 5.0 + rand(i + x) * 3.0
		box(c, rx, y - 14 - rand(i) * 8.0, 1, 18, Color("4a7a3a"))
		box(c, rx - 1, y - 18 - rand(i) * 8.0, 3, 5, Color("7a5a38"))


static func fence(c: CanvasItem, x0: float, x1: float, y: float, mood: String) -> void:
	var col = Color("8a6a44") if mood != "snow" else Color("b8a88a")
	box(c, x0, y - 9, x1 - x0, 2, col)
	box(c, x0, y - 4, x1 - x0, 2, col)
	var x = x0
	while x <= x1:
		box(c, x, y - 12, 2, 12, col.darkened(0.2))
		x += 12.0


static func person_row(c: CanvasItem, y: float, count: int, seed_value: float) -> void:
	for i in range(count):
		var x = 10.0 + float(i) * (W - 20.0) / float(count) + rand(seed_value + i) * 8.0
		var col = Color.from_hsv(rand(seed_value + i * 2.0), 0.3, 0.2)
		c.draw_circle(Vector2(x, y), 5, col)
		box(c, x - 6, y + 2, 12, 12, col)


# ---------------------------------------------------------------------------- outdoor scenes


static func farm(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood)
	sun_or_moon(c, mood, p.t)
	cloud(c, 40 + fposmod(p.t * 2.0, 360.0) - 20, 26, 1.0, Color(1, 1, 1, 0.8))
	mountains(c, 110, Color("6a8a9a"), 1.0, 26.0)
	hills(c, 122, Color("6aa85a"), 0.4, 6.0)
	box(c, 0, 128, W, 72, grass(mood))
	for row in range(5):
		var y = 134 + row * 9
		box(c, 120, y, 190, 5, Color("7a5a3a"))
		for x in range(124, 306, 10):
			box(c, x, y - 3, 3, 3, Color("4f9a3f") if mood != "snow" else Color("e8f0f4"))
	house(c, 14, 140, 62, 34, Color("a8483a"), Color("d8b888"), mood)
	box(c, 76, 118, 7, 18, Color("8a8a90"))
	fence(c, 90, 118, 146, mood)
	tree(c, 300, 140, 1.1, mood)
	tree(c, 100, 126, 0.8, mood)
	box(c, 0, 172, W, 28, Color("c8a870") if mood != "snow" else Color("d8dde0"))


static func town(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood)
	sun_or_moon(c, mood, p.t)
	cloud(c, 210 - fposmod(p.t * 2.0, 300.0) + 20, 30, 1.2, Color(1, 1, 1, 0.7))
	hills(c, 104, Color("6a8a9a"), 1.5, 8.0)
	var wall = Color("e0cfae")
	house(c, 8, 128, 48, 30, Color("a8483a"), wall, mood)
	house(c, 60, 128, 40, 38, Color("5a7aa8"), Color("d8c8b0"), mood)
	# The town hall with its clock tower.
	box(c, 150, 76, 36, 70, Color("c8b898"))
	box(c, 150, 74, 36, 4, Color("8a6a44"))
	poly(c, [Vector2(146, 76), Vector2(168, 52), Vector2(190, 76)], Color("7a3a2a"))
	c.draw_circle(Vector2(168, 96), 12, Color("f6f0dc"))
	c.draw_arc(Vector2(168, 96), 12, 0, TAU, 28, Color("5a3e28"), 2.0)
	var minute_angle = p.t * 0.6
	c.draw_line(
		Vector2(168, 96),
		Vector2(168, 96) + Vector2(0, -9).rotated(minute_angle),
		Color("2c2018"),
		1.5
	)
	c.draw_line(
		Vector2(168, 96),
		Vector2(168, 96) + Vector2(0, -6).rotated(minute_angle / 12.0 + 1.0),
		Color("2c2018"),
		2.0
	)
	box(c, 110, 108, 36, 38, Color("d8c8a8"))
	box(c, 118, 120, 8, 26, Color("5a3e28"))
	house(c, 200, 128, 44, 32, Color("4a8a5a"), Color("e8d8b8"), mood)
	house(c, 252, 128, 50, 36, Color("a8483a"), Color("d8c0a0"), mood)
	cobble(c, 146, mood)
	box(c, 148, 150, 40, 14, Color("6a8a9a") if mood != "snow" else Color("c8d4dc"))
	for x in [36, 120, 220, 290]:
		lamp(c, x, 172, mood in ["night", "dusk", "snow", "rain"])


static func market(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood)
	sun_or_moon(c, mood, p.t)
	hills(c, 100, Color("6a8a9a"), 0.7, 7.0)
	house(c, 10, 120, 50, 30, Color("5a7aa8"), Color("d8c8b0"), mood)
	house(c, 258, 120, 52, 30, Color("a8483a"), Color("d8c0a0"), mood)
	cobble(c, 128, mood)
	var colors = [Color("d8402f"), Color("e8c040"), Color("4a9a5a"), Color("4a7aa8")]
	for i in range(4):
		var x = 18.0 + i * 74.0
		box(c, x, 112, 48, 4, colors[i])
		for s in range(6):
			box(c, x + s * 8.0, 112, 4, 14, Color.WHITE if s % 2 == 0 else colors[i])
		box(c, x + 2, 126, 44, 16, Color("8a6038"))
		for g in range(5):
			c.draw_circle(Vector2(x + 8 + g * 8, 124), 3, colors[(i + g) % 4])
	for k in range(14):
		var bx = k * 24.0
		c.draw_line(
			Vector2(bx, 92 + sin(k) * 2.0),
			Vector2(bx + 24.0, 92 + sin(k + 1) * 2.0),
			Color("6a4a2a"),
			1.0
		)
		poly(c, [Vector2(bx + 6, 92), Vector2(bx + 12, 92), Vector2(bx + 9, 100)], colors[k % 4])


static func ranch(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood)
	sun_or_moon(c, mood, p.t)
	cloud(c, 60 + fposmod(p.t * 1.5, 360.0) - 20, 24, 1.1, Color(1, 1, 1, 0.8))
	hills(c, 112, Color("7ab86a"), 0.2, 9.0)
	hills(c, 128, Color("5aa04a"), 2.0, 7.0)
	box(c, 0, 140, W, 60, grass(mood))
	# A red barn with a hay loft.
	box(c, 188, 90, 80, 54, Color("a8483a"))
	poly(c, [Vector2(180, 92), Vector2(228, 62), Vector2(276, 92)], Color("6a2e24"))
	box(c, 212, 112, 32, 32, Color("f0e8d4"))
	c.draw_line(Vector2(212, 112), Vector2(244, 144), Color("a8483a"), 2.0)
	c.draw_line(Vector2(244, 112), Vector2(212, 144), Color("a8483a"), 2.0)
	fence(c, 0, 180, 150, mood)
	for i in range(3):
		var hx = 40.0 + i * 54.0
		c.draw_circle(Vector2(hx, 150), 9, Color("d8b858"))
		box(c, hx - 9, 150, 18, 6, Color("d8b858"))
	var cx = 100.0 + sin(p.t * 0.4) * 6.0
	box(c, cx, 150, 24, 12, Color("f4f0e8"))
	box(c, cx + 20, 146, 9, 8, Color("f4f0e8"))
	box(c, cx + 4, 154, 6, 5, Color("3a2e2a"))
	box(c, cx + 2, 162, 2, 6, Color("f4f0e8"))
	box(c, cx + 18, 162, 2, 6, Color("f4f0e8"))
	box(c, 0, 172, W, 28, Color("c8a870") if mood != "snow" else Color("d8dde0"))


static func seaside(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood, 110.0)
	sun_or_moon(c, mood, p.t)
	cloud(c, 80 + fposmod(p.t * 3.0, 360.0) - 20, 30, 1.0, Color(1, 1, 1, 0.8))
	water(c, 100, 168, p.t, mood)
	# Lighthouse.
	poly(
		c,
		[Vector2(246, 100), Vector2(262, 100), Vector2(258, 52), Vector2(250, 52)],
		Color("f0e8e0")
	)
	for y in [60, 76, 92]:
		box(c, 248, y, 14, 6, Color("d8402f"))
	box(c, 247, 46, 16, 7, Color("3a3a44"))
	poly(c, [Vector2(246, 46), Vector2(255, 38), Vector2(264, 46)], Color("a8483a"))
	for i in range(3):
		var bx = 30.0 + i * 70.0 + sin(p.t * 0.8 + i) * 3.0
		poly(
			c,
			[Vector2(bx, 128), Vector2(bx + 30, 128), Vector2(bx + 24, 138), Vector2(bx + 6, 138)],
			Color("6a4a2a")
		)
		box(c, bx + 14, 108, 2, 20, Color("4a3a2a"))
		poly(
			c,
			[Vector2(bx + 16, 110), Vector2(bx + 28, 124), Vector2(bx + 16, 124)],
			Color("f0e8d4")
		)
	box(c, 0, 160, W, 40, Color("c8a870"))
	for x in range(0, W, 18):
		box(c, x, 166, 17, 5, Color("a88850"))
		box(c, x, 176, 17, 5, Color("b89860"))
	for g in range(4):
		var gx = fposmod(p.t * 14.0 + g * 80.0, W + 40.0) - 20.0
		box(c, gx, 40 + g * 10 + sin(p.t * 3.0 + g) * 3.0, 6, 1, Color("f4f4f4"))
		box(c, gx + 4, 38 + g * 10 + sin(p.t * 3.0 + g) * 3.0, 4, 1, Color("f4f4f4"))


static func forest(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood)
	mountains(c, 96, Color("3f6a5a"), 4.0, 24.0)
	box(c, 0, 120, W, 80, Color("3f7a3a") if mood != "snow" else Color("dde6ea"))
	for layer in range(3):
		for i in range(11):
			var x = i * 32.0 + layer * 11.0 + rand(i + layer * 20.0) * 10.0
			tree(c, x, 126 + layer * 16.0, 1.0 + layer * 0.35, mood)
	var path_col = Color("c8a870") if mood != "snow" else Color("e8ecee")
	poly(c, [Vector2(130, H), Vector2(190, H), Vector2(170, 130), Vector2(150, 130)], path_col)
	for k in range(4):
		var rx = 58.0 + k * 58.0
		poly(
			c,
			[Vector2(rx, 0), Vector2(rx + 10, 0), Vector2(rx + 34, 150), Vector2(rx + 14, 150)],
			Color(1.0, 0.95, 0.7, 0.06)
		)
	for m in range(5):
		var mx = 30.0 + m * 62.0
		box(c, mx, 176, 2, 5, Color("e8e0d0"))
		box(c, mx - 2, 174, 6, 3, Color("d8402f"))


static func lake(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood, 104.0)
	sun_or_moon(c, mood, p.t)
	mountains(c, 90, Color("5a7a9a"), 2.0, 26.0)
	hills(c, 100, Color("4a7a5a"), 0.9, 5.0)
	water(c, 102, 160, p.t, mood)
	# Mirror of the hills in the water.
	for i in range(16):
		var x = i * 22.0
		box(c, x, 104 + rand(i) * 5.0, 22, 1, Color(1, 1, 1, 0.12))
	box(c, 0, 150, W, 50, grass(mood))
	reeds(c, 10, 156, 7)
	reeds(c, 270, 158, 8)
	# The lantern stand with six lamps.
	box(c, 214, 112, 4, 48, Color("5a3e28"))
	box(c, 262, 112, 4, 48, Color("5a3e28"))
	box(c, 210, 108, 60, 6, Color("6a4a2a"))
	for i in range(6):
		var x = 218.0 + i * 8.0
		box(c, x, 114, 5, 8, Color("ffe08a") if i < int(p.lamps) else Color("5a4a3a"))
	box(c, 150, 152, 70, 5, Color("8a6038"))
	for x in range(150, 220, 10):
		box(c, x, 157, 2, 12, Color("5a3e28"))
	box(c, 0, 172, W, 28, Color("c8a870") if mood != "snow" else Color("d8dde0"))


static func lake_glow(c: CanvasItem, p: Dictionary) -> void:
	for i in range(int(p.lamps)):
		var x = 220.5 + i * 8.0
		c.draw_circle(Vector2(x, 118), 9, Color(1.0, 0.86, 0.45, 0.16))
		c.draw_circle(Vector2(x, 118), 4, Color(1.0, 0.92, 0.6, 0.3))
	if p.mood in ["night", "dusk"]:
		for i in range(int(p.lamps)):
			var x = 220.5 + i * 8.0
			box(c, x - 1, 105 + 52, 2, 6 + rand(i) * 6.0, Color(1.0, 0.9, 0.6, 0.25))


static func river(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood, 96.0)
	sun_or_moon(c, mood, p.t)
	hills(c, 98, Color("4a6a5a"), 1.2, 7.0)
	water(c, 98, 200, p.t, mood)
	box(c, 0, 168, W, 32, grass(mood))
	reeds(c, 4, 172, 8)
	reeds(c, 280, 174, 8)
	# A ferry boat riding the current with a lantern.
	var bx = 120.0 + sin(p.t * 0.6) * 4.0
	var by = 138.0 + sin(p.t * 1.1) * 1.5
	poly(
		c,
		[
			Vector2(bx, by),
			Vector2(bx + 84, by),
			Vector2(bx + 74, by + 14),
			Vector2(bx + 10, by + 14)
		],
		Color("6a4a2a")
	)
	box(c, bx + 8, by - 3, 68, 4, Color("8a6038"))
	box(c, bx + 40, by - 34, 2, 31, Color("4a3a2a"))
	box(c, bx + 36, by - 40, 10, 7, Color("e8704a"))
	for i in range(8):
		box(c, bx + 4 + i * 9.0, by + 4, 5, 1, Color(1, 1, 1, 0.3))


static func shore(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood, 96.0)
	sun_or_moon(c, mood, p.t)
	hills(c, 92, Color("3f5a5a"), 0.3, 6.0)
	water(c, 92, 120, p.t, mood)
	# The far side: little lights on the other bank.
	for i in range(12):
		box(c, 16 + i * 26.0, 96, 2, 2, Color("ffd878"))
	box(c, 0, 120, W, 80, Color("3f7a3a") if mood != "snow" else Color("dde6ea"))
	tree(c, 40, 140, 1.2, mood)
	tree(c, 290, 138, 1.1, mood)
	# The old stone shrine.
	box(c, 148, 124, 24, 8, Color("7a7a82"))
	box(c, 154, 100, 12, 26, Color("8a8a92"))
	box(c, 150, 92, 20, 10, Color("9a9aa2"))
	poly(c, [Vector2(146, 92), Vector2(160, 80), Vector2(174, 92)], Color("7a7a82"))
	box(c, 157, 106, 6, 8, Color("2a2a30"))
	poly(
		c, [Vector2(130, H), Vector2(190, H), Vector2(170, 132), Vector2(150, 132)], Color("b8a880")
	)


static func shore_glow(c: CanvasItem, p: Dictionary) -> void:
	if int(p.lamps) >= 4:
		c.draw_circle(Vector2(160, 110), 14, Color(1.0, 0.86, 0.45, 0.2))
		box(c, 157, 106, 6, 8, Color("ffe08a"))


static func canal(c: CanvasItem, p: Dictionary) -> void:
	var mood = p.mood
	sky(c, mood)
	sun_or_moon(c, mood, p.t)
	mountains(c, 108, Color("6a8a9a"), 3.0, 20.0)
	hills(c, 120, Color("6aa85a"), 0.1, 5.0)
	box(c, 0, 128, W, 72, grass(mood))
	for row in range(3):
		box(c, 10, 134 + row * 8, 90, 4, Color("7a5a3a"))
		box(c, 224, 134 + row * 8, 90, 4, Color("7a5a3a"))
	# The canal: stone edges, water running left to right.
	box(c, 0, 152, W, 26, Color("8a8a90"))
	box(c, 0, 156, W, 18, Color("4a86a8"))
	for i in range(40):
		var x = fposmod(rand(i) * W + p.t * (22.0 + rand(i + 3.0) * 18.0), W)
		box(c, x, 158 + rand(i + 7.0) * 14.0, 10, 1, Color(1, 1, 1, 0.45))
	for x in range(0, W, 16):
		box(c, x, 152, 15, 4, Color("a8a8ae"))
		box(c, x, 174, 15, 4, Color("6a6a72"))
	box(c, 0, 182, W, 18, Color("c8a870") if mood != "snow" else Color("d8dde0"))
	tree(c, 20, 128, 0.9, mood)
	tree(c, 300, 130, 1.0, mood)


# ---------------------------------------------------------------------------- indoor scenes


static func wall_and_floor(
	c: CanvasItem, wall: Color, floor_col: Color, horizon: float = 124.0
) -> void:
	box(c, 0, 0, W, horizon, wall)
	for x in range(0, W, 20):
		box(c, x, 0, 1, horizon, wall.darkened(0.08))
	box(c, 0, horizon - 22, W, 22, wall.darkened(0.14))
	box(c, 0, horizon, W, H - horizon, floor_col)
	for y in range(int(horizon), H, 10):
		box(c, 0, y, W, 1, floor_col.darkened(0.16))
	box(c, 0, horizon - 3, W, 3, wall.darkened(0.35))


static func window_at(c: CanvasItem, x: float, y: float, mood: String) -> void:
	var pair: Array = SKY.get(mood, SKY.day)
	box(c, x - 2, y - 2, 40, 48, Color("4a3a2a"))
	box(c, x, y, 36, 44, pair[0].lerp(pair[1], 0.5))
	box(c, x + 17, y, 2, 44, Color("d8c390"))
	box(c, x, y + 21, 36, 2, Color("d8c390"))
	if mood == "night":
		for i in range(5):
			box(c, x + 3 + rand(i) * 30.0, y + 3 + rand(i + 4.0) * 16.0, 1, 1, Color(1, 1, 0.9))


static func hall(c: CanvasItem, p: Dictionary) -> void:
	wall_and_floor(c, Color("a88a62"), Color("7a5a3a"))
	window_at(c, 40, 30, p.mood)
	window_at(c, 244, 30, p.mood)
	box(c, 138, 20, 44, 58, Color("7a2e2a"))
	box(c, 142, 24, 36, 50, Color("a8483a"))
	c.draw_circle(Vector2(160, 44), 9, Color("e8c040"))
	box(c, 40, 150, 240, 14, Color("5a3e28"))
	box(c, 44, 140, 232, 10, Color("8a6038"))
	for i in range(6):
		box(c, 52 + i * 38.0, 160, 5, 26, Color("4a3220"))
	for i in range(5):
		box(c, 60 + i * 46.0, 132, 14, 8, Color("c8b890"))


static func clock_interior(c: CanvasItem, p: Dictionary) -> void:
	wall_and_floor(c, Color("6a5a4a"), Color("4a3a2e"), 150.0)
	var gears = [Vector2(100, 80), Vector2(160, 96), Vector2(216, 70), Vector2(150, 40)]
	var sizes = [34.0, 24.0, 28.0, 18.0]
	for i in range(gears.size()):
		var g: Vector2 = gears[i]
		var r: float = sizes[i]
		var dir = 1.0 if i % 2 == 0 else -1.0
		c.draw_circle(g, r, Color("a8803a"))
		c.draw_circle(g, r * 0.7, Color("6a5030"))
		c.draw_circle(g, r * 0.18, Color("e8c870"))
		for t in range(12):
			var a = p.t * 0.5 * dir + TAU * float(t) / 12.0
			var tip = g + Vector2(cos(a), sin(a)) * (r + 4.0)
			c.draw_line(g + Vector2(cos(a), sin(a)) * (r - 2.0), tip, Color("c89a48"), 4.0)
	var sway = sin(p.t * 2.2) * 22.0
	c.draw_line(Vector2(160, 20), Vector2(160 + sway, 142), Color("3a2e20"), 2.0)
	c.draw_circle(Vector2(160 + sway, 144), 8, Color("c89a48"))


static func quarry(c: CanvasItem, p: Dictionary) -> void:
	box(c, 0, 0, W, H, Color("2a2a36"))
	for i in range(18):
		var x = rand(i) * W
		var h = 30.0 + rand(i + 5.0) * 70.0
		poly(c, [Vector2(x, 0), Vector2(x + 18, 0), Vector2(x + 9, h)], Color("3a3a48"))
	box(c, 0, 150, W, 50, Color("4a4a56"))
	for i in range(8):
		var x = 20.0 + i * 40.0
		var h = 14.0 + rand(i + 2.0) * 16.0
		poly(
			c,
			[Vector2(x, 150), Vector2(x + 7, 150 - h), Vector2(x + 14, 150)],
			Color("6a5ad8") if i % 2 == 0 else Color("4ab8e8")
		)
	# A sealed stone door with a round hollow for the core.
	box(c, 118, 54, 84, 98, Color("5a5a68"))
	box(c, 124, 60, 72, 92, Color("7a7a88"))
	c.draw_circle(Vector2(160, 98), 12, Color("2a2a36"))
	c.draw_arc(Vector2(160, 98), 18, 0, TAU, 24, Color("a8a8b8"), 2.0)
	box(c, 159, 60, 2, 92, Color("5a5a68"))


static func quarry_glow(c: CanvasItem, p: Dictionary) -> void:
	for i in range(8):
		var x = 27.0 + i * 40.0
		c.draw_circle(Vector2(x, 140), 14, Color(0.5, 0.6, 1.0, 0.14 + 0.06 * sin(p.t * 2.0 + i)))
	c.draw_circle(Vector2(160, 98), 12, Color(1.0, 0.82, 0.4, 0.15 + 0.1 * sin(p.t * 3.0)))


static func vault(c: CanvasItem, p: Dictionary) -> void:
	box(c, 0, 0, W, H, Color("3a3a46"))
	for y in range(0, H, 16):
		for x in range(-8 + (y / 16 % 2) * 8, W, 16):
			box(c, x, y, 15, 15, Color("46465a") if (x + y) % 3 else Color("3e3e50"))
	box(c, 0, 150, W, 50, Color("4a4a58"))
	for shelf in range(3):
		var y = 40.0 + shelf * 40.0
		box(c, 20, y, 280, 4, Color("6a4a2a"))
		for i in range(22):
			var x = 26.0 + i * 12.5
			box(
				c,
				x,
				y - 12 - rand(i + shelf * 9.0) * 6.0,
				8,
				12,
				Color("f0e8d0") if (i + shelf) % 3 else Color("e8c890")
			)


static func vault_glow(c: CanvasItem, p: Dictionary) -> void:
	for shelf in range(3):
		var y = 40.0 + shelf * 40.0
		for i in range(22):
			if (i * 7 + shelf * 3) % 5 == 0:
				var x = 30.0 + i * 12.5
				c.draw_circle(
					Vector2(x, y - 8), 9, Color(1.0, 0.85, 0.5, 0.12 + 0.06 * sin(p.t * 2.0 + i))
				)


static func inn(c: CanvasItem, p: Dictionary) -> void:
	wall_and_floor(c, Color("b89a6a"), Color("8a6038"))
	window_at(c, 40, 32, p.mood)
	window_at(c, 244, 32, p.mood)
	box(c, 100, 112, 120, 24, Color("5a3e28"))
	box(c, 104, 108, 112, 8, Color("a87a48"))
	for i in range(6):
		box(
			c, 112 + i * 17.0, 90, 8, 18, Color(["#6a8a5a", "#a8483a", "#c8a050", "#5a7aa8"][i % 4])
		)
	box(c, 158, 20, 4, 30, Color("3a2e22"))
	poly(
		c, [Vector2(148, 50), Vector2(172, 50), Vector2(166, 42), Vector2(154, 42)], Color("e8c868")
	)
	box(c, 30, 148, 70, 8, Color("8a6038"))
	box(c, 220, 148, 70, 8, Color("8a6038"))
	box(c, 56, 156, 4, 22, Color("5a3e28"))
	box(c, 246, 156, 4, 22, Color("5a3e28"))


static func shop(c: CanvasItem, p: Dictionary) -> void:
	wall_and_floor(c, Color("9a8a74"), Color("6a5a48"))
	window_at(c, 244, 32, p.mood)
	box(c, 40, 60, 120, 50, Color("5a3e28"))
	for i in range(8):
		box(
			c, 46 + i * 14.0, 66, 10, 38, Color(["#c8d0d8", "#a87a3a", "#8a8a98", "#d8b060"][i % 4])
		)
	box(c, 40, 128, 150, 12, Color("8a6038"))
	box(c, 46, 140, 4, 30, Color("5a3e28"))
	box(c, 180, 140, 4, 30, Color("5a3e28"))
	c.draw_circle(Vector2(230, 140), 14, Color("6a6a74"))
	box(c, 224, 140, 12, 24, Color("3a3a44"))


static func cottage(c: CanvasItem, p: Dictionary) -> void:
	wall_and_floor(c, Color("a8b898"), Color("a88150"))
	window_at(c, 140, 30, p.mood)
	box(c, 20, 100, 70, 40, Color("5c4534"))
	box(c, 24, 104, 62, 32, Color("eee0b2"))
	box(c, 24, 118, 62, 18, Color("748d8b"))
	box(c, 28, 106, 18, 10, Color("f7eccd"))
	box(c, 214, 112, 70, 30, Color("5b6660"))
	box(c, 218, 116, 62, 8, Color("d0bea1"))
	box(c, 120, 140, 80, 6, Color("6c4d32"))
	box(c, 124, 146, 4, 22, Color("6c4d32"))
	box(c, 192, 146, 4, 22, Color("6c4d32"))
	box(c, 150, 130, 20, 10, Color("e8dcb8"))


static func greenhouse(c: CanvasItem, p: Dictionary) -> void:
	box(c, 0, 0, W, H, Color("dff4f6"))
	for x in range(0, W, 40):
		box(c, x, 0, 3, 150, Color("3f5a54"))
	for y in range(0, 150, 38):
		box(c, 0, y, W, 3, Color("3f5a54"))
	var sky_col: Array = SKY.get(p.mood, SKY.day)
	box(c, 3, 3, W - 6, 60, sky_col[0].lerp(Color("dff4f6"), 0.6))
	for k in range(5):
		var rx = 20.0 + k * 62.0
		poly(
			c,
			[Vector2(rx, 0), Vector2(rx + 14, 0), Vector2(rx + 50, 150), Vector2(rx + 22, 150)],
			Color(1, 1, 0.8, 0.1)
		)
	box(c, 0, 150, W, 50, Color("7a5a3a"))
	for row in range(3):
		var y = 156 + row * 14
		box(c, 10, y, 300, 5, Color("5a4028"))
		for x in range(16, 308, 12):
			var h = 8.0 + rand(x + row * 7.0) * 12.0 + sin(p.t * 0.8 + x) * 0.8
			box(c, x, y - h, 2, h, Color("3f7a35"))
			c.draw_circle(Vector2(x + 1, y - h), 4, Color("4f9a3f"))
			if x % 3 == 0:
				c.draw_circle(
					Vector2(x + 1, y - h + 1), 2, Color("d8402f") if row != 1 else Color("e8c040")
				)


static func stage(c: CanvasItem, p: Dictionary) -> void:
	box(c, 0, 0, W, H, Color("1c1424"))
	box(c, 30, 30, 260, 100, Color("2a3a6a"))
	c.draw_circle(Vector2(230, 56), 14, Color("f6f0d0"))
	for i in range(9):
		var x = 40.0 + i * 28.0
		box(c, x, 100 + rand(i) * 18.0, 18, 34, Color("1c1c30"))
	box(c, 0, 128, W, 72, Color("8a6038"))
	for y in range(130, H, 9):
		box(c, 0, y, W, 1, Color("5a3e28"))
	# Curtains and a valance.
	box(c, 0, 0, 38, H, Color("8a1f2a"))
	box(c, 282, 0, 38, H, Color("8a1f2a"))
	for x in range(0, 38, 6):
		box(c, x, 0, 2, H, Color("6a1620"))
		box(c, 282 + x, 0, 2, H, Color("6a1620"))
	box(c, 0, 0, W, 20, Color("a8283a"))
	for x in range(0, W, 24):
		poly(c, [Vector2(x, 20), Vector2(x + 24, 20), Vector2(x + 12, 30)], Color("c8a050"))
	person_row(c, 190, 14, 3.0)


static func stage_glow(c: CanvasItem, p: Dictionary) -> void:
	for x in [90, 160, 230]:
		poly(
			c,
			[Vector2(x - 4, 0), Vector2(x + 4, 0), Vector2(x + 40, 150), Vector2(x - 40, 150)],
			Color(1.0, 0.95, 0.7, 0.08)
		)
	for i in range(8):
		c.draw_circle(Vector2(30 + i * 37.0, 176), 3, Color(1.0, 0.85, 0.5, 0.5))


static func train(c: CanvasItem, p: Dictionary) -> void:
	sky(c, p.mood, 120.0)
	sun_or_moon(c, p.mood, p.t)
	for layer in range(3):
		var speed = 8.0 + layer * 22.0
		var col = [Color("6a8a9a"), Color("5a8a6a"), Color("3f7a3a")][layer]
		hills(c, 92 + layer * 14.0, col, -p.t * speed * 0.02 + layer, 10.0 - layer * 2.0)
	for i in range(5):
		var x = fposmod(i * 90.0 - p.t * 90.0, 450.0) - 60.0
		box(c, x, 70, 2, 70, Color("3a2e22"))
		box(c, x - 8, 74, 18, 2, Color("3a2e22"))
	box(c, 0, 140, W, 60, Color("6a5a48"))
	for i in range(14):
		var x = fposmod(i * 26.0 - p.t * 120.0, 364.0) - 20.0
		box(c, x, 150, 4, 50, Color("5a4a38"))
	# The window frame and a seat in front of it.
	box(c, 0, 0, W, 12, Color("5a3e28"))
	box(c, 0, 0, 14, H, Color("5a3e28"))
	box(c, 306, 0, 14, H, Color("5a3e28"))
	box(c, 0, 168, W, 32, Color("7a2e2a"))
	box(c, 0, 168, W, 4, Color("a8483a"))


static func feast(c: CanvasItem, p: Dictionary) -> void:
	sky(c, p.mood)
	sun_or_moon(c, p.mood, p.t)
	house(c, 6, 110, 52, 34, Color("5a7aa8"), Color("d8c8b0"), p.mood)
	house(c, 262, 110, 52, 34, Color("a8483a"), Color("d8c0a0"), p.mood)
	hills(c, 100, Color("4a6a7a"), 1.0, 5.0)
	cobble(c, 112, p.mood)
	# One long table, plates and candles.
	box(c, 24, 140, 272, 14, Color("8a6038"))
	box(c, 24, 154, 272, 6, Color("6a4a2a"))
	for i in range(14):
		var x = 34.0 + i * 19.0
		c.draw_circle(Vector2(x, 144), 4, Color("f0e8d4"))
		if i % 3 == 0:
			box(c, x - 1, 132, 2, 8, Color("f4ecc8"))
	# Strings of paper lanterns.
	for k in range(2):
		for i in range(11):
			var x = i * 30.0 + 6.0
			var y = 56.0 + k * 26.0 + sin(i * 0.9 + k) * 5.0
			box(c, x, y, 6, 7, Color(["#e8704a", "#f0c050", "#e8a0a0"][i % 3]))
		c.draw_line(Vector2(0, 54 + k * 26.0), Vector2(W, 56 + k * 26.0), Color("3a2e22"), 1.0)


static func feast_glow(c: CanvasItem, p: Dictionary) -> void:
	for k in range(2):
		for i in range(11):
			var x = i * 30.0 + 9.0
			var y = 59.0 + k * 26.0 + sin(i * 0.9 + k) * 5.0
			c.draw_circle(Vector2(x, y), 8, Color(1.0, 0.8, 0.4, 0.14))
	for i in range(14):
		if i % 3 == 0:
			c.draw_circle(Vector2(34.0 + i * 19.0, 130), 7, Color(1.0, 0.85, 0.5, 0.2))


# ---------------------------------------------------------------------------- dispatch


static func draw_scene(c: CanvasItem, id: String, p: Dictionary) -> void:
	match id:
		"farm":
			farm(c, p)
		"town":
			town(c, p)
		"market":
			market(c, p)
		"ranch":
			ranch(c, p)
		"seaside":
			seaside(c, p)
		"forest":
			forest(c, p)
		"lake":
			lake(c, p)
		"greenhouse":
			greenhouse(c, p)
		"river":
			river(c, p)
		"shore":
			shore(c, p)
		"canal":
			canal(c, p)
		"stage":
			stage(c, p)
		"hall":
			hall(c, p)
		"clock":
			clock_interior(c, p)
		"quarry":
			quarry(c, p)
		"vault":
			vault(c, p)
		"inn":
			inn(c, p)
		"shop":
			shop(c, p)
		"cottage":
			cottage(c, p)
		"train":
			train(c, p)
		"feast":
			feast(c, p)
		_:
			box(c, 0, 0, W, H, Color.BLACK)


## Light sources drawn after the mood tint so they shine in the dark.
static func draw_glow(c: CanvasItem, id: String, p: Dictionary) -> void:
	var dark = p.mood in ["night", "dusk", "rain", "snow"]
	match id:
		"lake":
			lake_glow(c, p)
		"shore":
			shore_glow(c, p)
		"quarry":
			quarry_glow(c, p)
		"vault":
			vault_glow(c, p)
		"stage":
			stage_glow(c, p)
		"feast":
			feast_glow(c, p)
		"town":
			if dark:
				for x in [36, 120, 220, 290]:
					lamp_glow(c, x, 172)
				windows_glow(c, 8, 128, 48, 30, true)
				windows_glow(c, 60, 128, 40, 38, true)
				windows_glow(c, 200, 128, 44, 32, true)
				windows_glow(c, 252, 128, 50, 36, true)
		"market":
			if dark:
				windows_glow(c, 10, 120, 50, 30, true)
				windows_glow(c, 258, 120, 52, 30, true)
		"inn", "shop", "hall", "cottage":
			if p.mood in ["night", "dusk"]:
				c.draw_circle(Vector2(160, 44), 40, Color(1.0, 0.85, 0.45, 0.1))
				c.draw_circle(Vector2(160, 44), 18, Color(1.0, 0.9, 0.6, 0.12))
		"river":
			if dark:
				c.draw_circle(
					Vector2(0, 0) + Vector2(162 + sin(p.t * 0.6) * 4.0, 102),
					16,
					Color(1.0, 0.7, 0.4, 0.2)
				)


## Particle effects drawn in front of everything.
static func draw_fx(c: CanvasItem, kind: String, t: float) -> void:
	match kind:
		"fireflies":
			for i in range(26):
				var x = fposmod(rand(i) * W + sin(t * 0.5 + i) * 18.0, W)
				var y = 80.0 + rand(i + 4.0) * 100.0 + cos(t * 0.7 + i * 2.0) * 10.0
				var glow = 0.4 + 0.6 * abs(sin(t * 1.4 + i))
				c.draw_circle(Vector2(x, y), 4, Color(0.9, 1.0, 0.4, 0.1 * glow))
				box(c, x, y, 1.5, 1.5, Color(1.0, 1.0, 0.6, 0.4 + 0.6 * glow))
		"lanterns":
			for i in range(14):
				var x = rand(i * 2.0) * W + sin(t * 0.6 + i) * 8.0
				var y = (
					fposmod(H + 10.0 - (t * (6.0 + rand(i) * 8.0) + rand(i + 9.0) * H), H + 30.0)
					- 10.0
				)
				c.draw_circle(Vector2(x, y), 8, Color(1.0, 0.8, 0.4, 0.16))
				box(c, x - 3, y - 4, 6, 8, Color(1.0, 0.75, 0.4, 0.95))
				box(c, x - 3, y - 4, 6, 2, Color(1.0, 0.95, 0.7, 0.95))
		"petals":
			for i in range(36):
				var x = fposmod(rand(i) * W + sin(t * 0.8 + i) * 14.0 + t * 6.0, W)
				var y = fposmod(rand(i + 7.0) * H + t * (10.0 + rand(i + 2.0) * 10.0), H)
				box(c, x, y, 2, 2, Color("f6b8c8") if i % 2 == 0 else Color("fff0f4"))
		"rain":
			for i in range(90):
				var x = rand(i) * W
				var y = fposmod(rand(i + 5.0) * H + t * 190.0, H + 20.0) - 10.0
				c.draw_line(Vector2(x, y), Vector2(x - 2, y + 7), Color(0.8, 0.9, 1.0, 0.5), 1.0)
		"snow":
			for i in range(80):
				var x = fposmod(rand(i) * W + sin(t * 0.7 + i) * 10.0, W)
				var y = fposmod(rand(i + 3.0) * H + t * (14.0 + rand(i + 1.0) * 14.0), H)
				box(c, x, y, 2, 2, Color(1, 1, 1, 0.85))
		"leaves":
			for i in range(20):
				var x = fposmod(rand(i) * W + t * 16.0 + sin(t + i) * 10.0, W)
				var y = fposmod(rand(i + 6.0) * H + t * (12.0 + rand(i) * 10.0), H)
				box(c, x, y, 3, 2, Color("d89a3a") if i % 2 == 0 else Color("8aa84a"))
		"dust":
			for i in range(30):
				var x = fposmod(rand(i) * W + sin(t * 0.3 + i) * 12.0, W)
				var y = fposmod(rand(i + 2.0) * H - t * 4.0, H)
				box(c, x, y, 1.5, 1.5, Color(1.0, 0.95, 0.8, 0.35))
		"confetti":
			for i in range(60):
				var x = fposmod(rand(i) * W + sin(t * 2.0 + i) * 6.0, W)
				var y = fposmod(rand(i + 4.0) * H + t * (24.0 + rand(i + 1.0) * 24.0), H)
				box(c, x, y, 2, 3, Color.from_hsv(rand(i + 8.0), 0.7, 1.0))
		"sparks":
			for i in range(24):
				var x = 150.0 + rand(i) * 40.0 + sin(t * 3.0 + i) * 6.0
				var y = fposmod(
					150.0 - t * (30.0 + rand(i + 1.0) * 30.0) + rand(i + 3.0) * 120.0, 150.0
				)
				box(c, x, y, 1.5, 1.5, Color(1.0, 0.7 + rand(i) * 0.3, 0.2, 0.9))
		"steam":
			for i in range(10):
				var x = 40.0 + i * 8.0 + fposmod(t * 20.0, 30.0)
				var y = 130.0 - fposmod(t * 14.0 + rand(i) * 40.0, 60.0)
				c.draw_circle(Vector2(x, y), 5 + rand(i) * 4.0, Color(1, 1, 1, 0.2))
		"bells":
			for k in range(3):
				var phase = fposmod(t * 0.9 + k * 0.33, 1.0)
				c.draw_arc(
					Vector2(168, 96),
					14.0 + phase * 140.0,
					0,
					TAU,
					40,
					Color(1.0, 0.9, 0.5, 0.4 * (1.0 - phase)),
					1.5
				)
		"water":
			for i in range(18):
				var x = fposmod(rand(i) * W + t * 20.0, W)
				var y = 140.0 + rand(i + 2.0) * 50.0
				box(c, x, y, 6, 1, Color(1, 1, 1, 0.4))

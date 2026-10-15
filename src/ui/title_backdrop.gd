class_name TitleBackdrop
extends Control

var time: float = 0
var landscape: Texture2D
var clouds: Texture2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	landscape = load("res://assets/art/title_landscape.png")
	clouds = load("res://assets/art/title_clouds.png")


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	if landscape == null:
		return
	draw_texture(landscape, Vector2.ZERO)
	var drift = fmod(time * 6, 1280)
	draw_texture(clouds, Vector2(drift, 0).round())
	draw_texture(clouds, Vector2(drift - 1280, 0).round())
	for i in range(20):
		var at = Vector2(888 + (i * 41) % 105, 534 + (i * 31) % 72)
		var wave = sin(time * 1.4 + i * 1.3)
		draw_line(
			at + Vector2(wave * 3, 0),
			at + Vector2(7 + wave * 5, 0),
			Color(.78, .91, .83, (wave + 1) * .22),
			2
		)
	for i in range(5):
		var phase = fmod(time * .15 + i * .2, 1.0)
		var at = Vector2(398 + sin(time + phase * 4) * 7 + phase * 14, 400 - phase * 100)
		draw_rect(
			Rect2(at.round(), Vector2(8, 8) * (1 + phase)), Color(.91, .89, .78, (1 - phase) * .32)
		)
	for i in range(4):
		var at = Vector2(360 + i * 154 + sin(time * .5 + i) * 24, 668 + sin(time * .9 + i * 2) * 28)
		var wing = 2 + absf(sin(time * 10 + i)) * 4
		draw_rect(Rect2(at.round() - Vector2(wing, 0), Vector2(wing * 2, 4)), Color("e6c789"))
		draw_rect(Rect2(at.round(), Vector2(2, 5)), Color("665139"))

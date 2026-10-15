extends "res://tests/ui_driver.gd"

const SEASONS = ["spring", "summer", "autumn", "winter"]
const CASES = [
	["spring", "sunny"],
	["spring", "rain"],
	["summer", "storm"],
	["autumn", "wind"],
	["autumn", "cloudy"],
	["winter", "snow"],
]


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir=user://ui-test-"):
			folder = arg.trim_prefix("--save-dir=")
	if folder.is_empty() or FileAccess.file_exists(folder + "/farm.json"):
		push_error("Use a fresh -- --save-dir=user://ui-test-UNIQUE")
		quit(2)
		return
	scene = load("res://scenes/main.tscn")
	await spawn()
	await press("开始新生活")
	await press("带着这份期待，出发")
	await press("开始在这里")
	check(game.initialized, "game starts")
	var middle = Vector2i(48, 40)
	var best = middle
	var best_distance = 1000000
	for cell in free_cells(100000):
		if (cell - middle).length_squared() < best_distance:
			best = cell
			best_distance = (cell - middle).length_squared()
	place_cell(best)
	var world: FarmWorld = game.world
	check(world.weather_layer != null and world.outdoors, "farm has a weather layer")
	check(world.weather == "sunny" and world.season == "spring", "day 1 is fair spring")
	for entry in CASES:
		world.season = entry[0]
		world.weather = entry[1]
		world.weather_layer.configure(entry[0], entry[1], false)
		world.set_season_look(WorldAtmosphere.season_weights(SEASONS.find(entry[0]), 14, 28))
		for i in 40:
			await process_frame
		var layer: WeatherLayer = world.weather_layer
		check(layer.visible, "layer visible for " + entry[1])
		match entry[1]:
			"rain":
				check(layer.px.size() == 170, "rain particle count")
			"storm":
				check(layer.px.size() == 300, "storm particle count")
			"snow":
				check(layer.px.size() == 150, "snow particle count")
			"wind":
				check(layer.px.size() == 34, "wind leaf count")
		var expected = WorldAtmosphere.lit(entry[0], entry[1], game.state.minute)
		check(world.light_color().is_equal_approx(expected), "world tinted for " + entry[1])
		if entry[1] == "storm":
			layer.flash = 0.0
			layer.next_flash = 999.0
		await capture("weather-%s-%s" % [entry[0], entry[1]])
		check_season_pixels(entry[0])
	var layer: WeatherLayer = world.weather_layer
	layer.configure("summer", "storm", false)
	layer.flash = 0.5
	await capture("weather-lightning")
	layer.configure("summer", "storm", true)
	check(layer.px.size() == 150, "reduce motion halves particles")
	layer.next_flash = 0.0
	for i in 10:
		await process_frame
	check(layer.flash == 0.0, "reduce motion disables lightning")
	# Weather stays outside: the cottage is dry and untinted by the season.
	await interact("to_cottage")
	check(game.state.current_map == "cottage", "entered cottage")
	check(not game.world.weather_layer.visible, "no weather indoors")
	check(
		game.world.light_color().is_equal_approx(
			WorldAtmosphere.lit("spring", "sunny", game.state.minute)
		),
		"indoor light ignores the weather"
	)
	print("WEATHER_SMOKE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


## Samples open grass on the real rendered frame, so a shader that silently fails to
## compile (and falls back to the plain spring art) is caught here.
func check_season_pixels(season: String) -> void:
	RenderingServer.force_draw()
	var image = game.get_viewport().get_texture().get_image()
	var total = Color(0, 0, 0)
	var count = 0
	for x in range(660, 960, 6):
		for y in range(470, 640, 6):
			total += image.get_pixel(x, y)
			count += 1
	var c = total / float(count)
	print("SEASON_PIXEL ", season, " ", c)
	match season:
		"spring":
			check(c.g > c.r and c.g > c.b, "spring grass is green")
		"autumn":
			check(c.r > c.g * 0.92 and c.r > c.b + 0.12, "autumn grass is gold, not green")
		"winter":
			check(c.b >= c.r and c.get_luminance() > 0.5, "winter grass is frosted")

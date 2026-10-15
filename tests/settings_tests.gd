extends SceneTree

var failures: Array[String] = []
var checks: int = 0
var folder: String = "user://settings-test-%d" % Time.get_ticks_usec()


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)


func run() -> void:
	test_defaults()
	test_validate()
	test_files()
	test_rebinding()
	test_apply()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder + "/settings.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	print("SETTINGS_TESTS: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func test_defaults() -> void:
	var s = GameSettings.new(folder)
	check(s.get_value("master") == 80 and s.get_value("sfx") == 100, "default volumes")
	check(s.get_value("autosave") == true and s.get_value("show_hints") == true, "default toggles")
	check(s.get_value("fullscreen") == false and s.get_value("reduce_motion") == false, "off")
	check(s.get_value("bindings").is_empty(), "no overrides by default")
	var copy = GameSettings.defaults()
	copy.master = 1
	check(GameSettings.DEFAULTS.master == 80, "defaults are never mutated through a copy")
	for action in GameSettings.REBINDABLE:
		check(GameSettings.DEFAULT_KEYS.has(action), "every rebindable action has a default")
		check(GameSettings.ACTION_NAMES.has(action), "every rebindable action has a name")
	var seen: Array = []
	for action in GameSettings.DEFAULT_KEYS:
		for code in GameSettings.DEFAULT_KEYS[action]:
			check(not seen.has(code), "default keys never collide: " + str(code))
			seen.append(code)


func test_validate() -> void:
	for junk in [null, 5, "text", [], [1, 2], {}]:
		check(not GameSettings.validate(junk).is_empty(), "junk is rejected")
	check(GameSettings.validate(GameSettings.defaults()).is_empty(), "defaults are valid")
	var loud = GameSettings.defaults()
	loud.master = 250
	check(not GameSettings.validate(loud).is_empty(), "volume above 100 is rejected, not clamped")
	loud.master = -1
	check(not GameSettings.validate(loud).is_empty(), "negative volume is rejected")
	loud.master = 33.7
	check(not GameSettings.validate(loud).is_empty(), "fractional volume is rejected")
	loud.master = INF
	check(not GameSettings.validate(loud).is_empty(), "infinite volume is rejected")
	loud.master = "loud"
	check(not GameSettings.validate(loud).is_empty(), "wrong type is rejected")
	var partial = GameSettings.defaults()
	partial.erase("sfx")
	check(not GameSettings.validate(partial).is_empty(), "a missing field is rejected")
	var flags = GameSettings.defaults()
	flags.fullscreen = "yes"
	check(not GameSettings.validate(flags).is_empty(), "a switch must be a boolean")
	var extra = GameSettings.defaults()
	extra.bogus = 1
	check(not GameSettings.validate(extra).is_empty(), "unknown fields are rejected")
	var bad = {
		"interact": KEY_ESCAPE,
		"bag": KEY_3,
		"map": 999999999,
		"journal": "x",
		"use_tool": KEY_Q,
		"menu": KEY_H,
		"move_up": KEY_LEFT,
	}
	for action in bad:
		var candidate = GameSettings.defaults()
		candidate.bindings = {action: bad[action]}
		check(not GameSettings.validate(candidate).is_empty(), "bad binding rejected: " + action)
	var twice = GameSettings.defaults()
	twice.bindings = {"interact": KEY_G, "map": KEY_G}
	check(not GameSettings.validate(twice).is_empty(), "one key cannot serve two actions")
	var swap = GameSettings.defaults()
	swap.bindings = {"move_up": KEY_Q, "cycle_seed": KEY_W}
	check(GameSettings.validate(swap).is_empty(), "a consistent swap is valid")
	var steal = GameSettings.defaults()
	steal.bindings = {"move_up": KEY_Q}
	check(not GameSettings.validate(steal).is_empty(), "cannot steal an unmoved action's key")


func test_files() -> void:
	var s = GameSettings.new(folder)
	check(s.load_file().is_empty() and s.values == GameSettings.defaults(), "missing file is fine")
	s.set_value("master", 35)
	s.set_value("reduce_motion", true)
	check(s.rebind("interact", KEY_G).is_empty(), "rebind before save")
	check(s.save_file().is_empty(), "settings save")
	var loaded = GameSettings.new(folder)
	check(loaded.load_file().is_empty(), "settings load")
	check(loaded.values == s.values, "settings survive a round trip exactly")
	check(loaded.key_for("interact") == KEY_G, "binding survives a round trip")
	check(
		not FileAccess.file_exists(folder + "/settings.json.tmp"),
		"no temporary file is left behind"
	)
	var broken = FileAccess.open(folder + "/settings.json", FileAccess.WRITE)
	broken.store_string("{ this is not json")
	broken.close()
	loaded = GameSettings.new(folder)
	check(not loaded.load_file().is_empty(), "corrupt file is reported")
	check(loaded.values == GameSettings.defaults(), "a corrupt file uses defaults for the session")
	broken = FileAccess.open(folder + "/settings.json", FileAccess.WRITE)
	broken.store_string(JSON.stringify({"version": 1, "values": {"master": 12, "bindings": 7}}))
	broken.close()
	loaded = GameSettings.new(folder)
	check(not loaded.load_file().is_empty(), "an incomplete file is reported, not repaired")
	check(loaded.values == GameSettings.defaults(), "an incomplete file uses defaults")
	broken = FileAccess.open(folder + "/settings.json", FileAccess.WRITE)
	broken.store_string("[1, 2, 3]")
	broken.close()
	loaded = GameSettings.new(folder)
	check(not loaded.load_file().is_empty(), "wrong top-level type is reported")
	check(loaded.values == GameSettings.defaults(), "wrong top-level type uses defaults")


func test_rebinding() -> void:
	var s = GameSettings.new(folder)
	check(s.key_for("interact") == KEY_E and s.key_for("move_up") == KEY_W, "default keys")
	check(s.rebind("interact", KEY_F).is_empty() and s.key_for("interact") == KEY_F, "plain")
	check(s.key_for("use_tool") == KEY_SPACE, "other actions untouched")
	check(s.rebind("use_tool", KEY_F).is_empty(), "taking a used key succeeds")
	check(s.key_for("use_tool") == KEY_F and s.key_for("interact") == KEY_SPACE, "keys swapped")
	var keys: Array = []
	for action in GameSettings.REBINDABLE:
		check(not keys.has(s.key_for(action)), "no duplicate keys after swap: " + action)
		keys.append(s.key_for(action))
	check(not s.rebind("bag", KEY_ESCAPE).is_empty(), "escape is reserved")
	check(not s.rebind("bag", KEY_5).is_empty(), "number keys are reserved")
	check(not s.rebind("menu", KEY_Z).is_empty(), "fixed actions cannot be rebound")
	check(not s.rebind("nothing", KEY_Z).is_empty(), "unknown action refused")
	check(not s.rebind("bag", 0).is_empty(), "invalid keycode refused")
	var before = s.values.duplicate(true)
	check(not s.rebind("move_up", KEY_LEFT).is_empty(), "alternative keys of others are refused")
	check(s.values == before, "a refused rebind changes nothing")
	s.rebind("move_left", KEY_Z)
	check(not s.rebind("move_up", KEY_LEFT).is_empty(), "an alternative key stays with its owner")
	check(s.rebind("move_up", KEY_UP).is_empty(), "an action may take its own alternative key")
	check(not GameSettings.is_usable_key(999999999), "nonsense key codes are unusable")
	check(not GameSettings.is_usable_key(-5) and not GameSettings.is_usable_key(0), "negative")
	check(GameSettings.is_usable_key(KEY_SHIFT) and GameSettings.is_usable_key(KEY_Q), "real keys")
	s.reset_bindings()
	check(s.key_for("interact") == KEY_E and s.values.bindings.is_empty(), "reset bindings")
	check(s.key_label("use_tool") == OS.get_keycode_string(KEY_SPACE), "key label")


func test_apply() -> void:
	var s = GameSettings.new(folder)
	s.set_value("master", 50)
	s.set_value("sfx", 0)
	s.rebind("interact", KEY_F)
	s.apply()
	var master = AudioServer.get_bus_index("Master")
	check(absf(AudioServer.get_bus_volume_db(master) - linear_to_db(0.5)) < 0.01, "master volume")
	var sfx = AudioServer.get_bus_index(GameSettings.SFX_BUS)
	check(sfx >= 0 and AudioServer.is_bus_mute(sfx), "zero volume mutes the bus")
	s.apply()
	check(
		AudioServer.get_bus_index(GameSettings.SFX_BUS) == sfx,
		"applying twice does not create more buses"
	)
	var events = InputMap.action_get_events("interact")
	check(events.size() == 1 and events[0].physical_keycode == KEY_F, "binding in input map")
	events = InputMap.action_get_events("move_up")
	check(events.size() == 2, "move_up keeps its W and arrow keys")
	s.rebind("move_left", KEY_UP)
	check(not s.rebind("move_left", KEY_UP).is_empty(), "arrow key still belongs to move_up")
	s.reset_all()
	s.apply()
	events = InputMap.action_get_events("interact")
	check(events.size() == 1 and events[0].physical_keycode == KEY_E, "defaults restored")
	for action in GameSettings.DEFAULT_KEYS:
		check(InputMap.has_action(action), "action registered: " + action)
	AudioServer.set_bus_mute(master, false)
	AudioServer.set_bus_volume_db(master, 0.0)

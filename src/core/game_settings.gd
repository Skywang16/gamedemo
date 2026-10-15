class_name GameSettings
extends RefCounted

## Player preferences. They live next to, but never inside, the save file, and are
## always repaired rather than rejected: a damaged settings file must never stop the
## game from starting.

const FILE_VERSION = 1
const SFX_BUS = "SFX"
const DEFAULTS = {
	"master": 80,
	"sfx": 100,
	"fullscreen": false,
	"vsync": true,
	"reduce_motion": false,
	"autosave": true,
	"sprint_toggle": false,
	"show_hints": true,
	"bindings": {},
}
const BOOLEANS = ["fullscreen", "vsync", "reduce_motion", "autosave", "sprint_toggle", "show_hints"]
const LEVELS = ["master", "sfx"]
## Every action with its default keys. The first key is the one the player may rebind;
## the rest stay as built-in alternatives (arrow keys) unless they collide.
const DEFAULT_KEYS = {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"use_tool": [KEY_SPACE],
	"interact": [KEY_E],
	"cycle_seed": [KEY_Q],
	"menu": [KEY_ESCAPE],
	"tool_1": [KEY_1],
	"tool_2": [KEY_2],
	"tool_3": [KEY_3],
	"tool_4": [KEY_4],
	"tool_5": [KEY_5],
	"tool_6": [KEY_6],
	"tool_7": [KEY_7],
	"sprint": [KEY_SHIFT],
	"journal": [KEY_J],
	"map": [KEY_M],
	"bag": [KEY_B],
}
const REBINDABLE = [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"interact",
	"use_tool",
	"sprint",
	"cycle_seed",
	"journal",
	"map",
	"bag",
]
const RESERVED_KEYS = [KEY_ESCAPE, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7]
const ACTION_NAMES = {
	"move_up": "向上走",
	"move_down": "向下走",
	"move_left": "向左走",
	"move_right": "向右走",
	"interact": "交谈 / 互动",
	"use_tool": "使用工具",
	"sprint": "跑步",
	"cycle_seed": "切换种子",
	"journal": "故事手记",
	"map": "地图册",
	"bag": "背包",
}

var values: Dictionary = {}
var directory: String


func _init(folder: String = "user://") -> void:
	directory = folder.trim_suffix("/")
	values = defaults()


static func defaults() -> Dictionary:
	return DEFAULTS.duplicate(true)


## Physical key codes are printable Latin-1 characters or Godot's "special" key block.
## OS.get_keycode_string() happily names nonsense codes, so it cannot be the validator.
static func is_usable_key(code: int) -> bool:
	var printable = code >= KEY_SPACE and code <= 255
	var special = code >= KEY_SPECIAL and code < KEY_SPECIAL + 0x400
	return (printable or special) and not OS.get_keycode_string(code).is_empty()


func path() -> String:
	return directory + "/settings.json"


## Returns a complete, well-typed settings dictionary no matter what `raw` contains.
static func sanitize(raw: Variant) -> Dictionary:
	var clean = defaults()
	if not raw is Dictionary:
		return clean
	for key in LEVELS:
		var value = raw.get(key)
		if (value is int or value is float) and is_finite(float(value)):
			clean[key] = clampi(int(value), 0, 100)
	for key in BOOLEANS:
		if raw.get(key) is bool:
			clean[key] = raw[key]
	var bindings = raw.get("bindings")
	if bindings is Dictionary:
		var used: Array = []
		for action in REBINDABLE:
			var code = bindings.get(action)
			if not (code is int or code is float) or float(code) != floor(float(code)):
				continue
			var key = int(code)
			if key in RESERVED_KEYS or key in used or not is_usable_key(key):
				continue
			used.append(key)
			clean.bindings[action] = key
		# An override must not steal a key that another action still uses by default.
		for action in clean.bindings.keys():
			for other in REBINDABLE:
				if other != action and not clean.bindings.has(other):
					if int(clean.bindings[action]) in DEFAULT_KEYS[other]:
						clean.bindings.erase(action)
						break
	return clean


func load_file() -> String:
	values = defaults()
	if not FileAccess.file_exists(path()):
		return ""
	var file = FileAccess.open(path(), FileAccess.READ)
	if file == null or file.get_length() > 64 * 1024:
		return "设置文件无法读取，已使用默认设置。"
	var parser = JSON.new()
	var data = parser.data if parser.parse(file.get_as_text()) == OK else null
	values = sanitize(data.get("values") if data is Dictionary else null)
	return "" if data is Dictionary else "设置文件已损坏，已使用默认设置。"


func save_file() -> String:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		return "无法创建设置目录。"
	var temp = path() + ".tmp"
	var file = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return "无法写入设置。"
	file.store_string(JSON.stringify({"version": FILE_VERSION, "values": values}))
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK:
		return "设置写入失败。"
	if (
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(path())
		)
		!= OK
	):
		return "设置替换失败。"
	return ""


func get_value(key: String) -> Variant:
	return values[key]


func set_value(key: String, value: Variant) -> void:
	values[key] = value
	values = sanitize(values)


func reset_all() -> void:
	values = defaults()


func reset_bindings() -> void:
	values.bindings = {}


func key_for(action: String) -> int:
	if values.bindings.has(action):
		return int(values.bindings[action])
	return int(DEFAULT_KEYS[action][0])


func key_label(action: String) -> String:
	return OS.get_keycode_string(key_for(action))


## Binds `keycode` to `action`. A key already used by another rebindable action is
## swapped, so no two actions ever share a key. Returns "" or a short reason.
func rebind(action: String, keycode: int) -> String:
	if action not in REBINDABLE:
		return "这个操作不能改键。"
	if keycode in RESERVED_KEYS:
		return "%s 是固定按键。" % OS.get_keycode_string(keycode)
	if not is_usable_key(keycode):
		return "这个按键无法使用。"
	var previous = key_for(action)
	for other in REBINDABLE:
		if other == action:
			continue
		if key_for(other) == keycode:
			values.bindings[other] = previous
		elif keycode in DEFAULT_KEYS[other].slice(1) and not _key_taken(keycode, other):
			return "%s 已是「%s」的备用按键。" % [OS.get_keycode_string(keycode), ACTION_NAMES[other]]
	values.bindings[action] = keycode
	values = sanitize(values)
	return ""


func volume_db(percent: int) -> float:
	return -80.0 if percent <= 0 else linear_to_db(float(percent) / 100.0)


## Pushes the current values into the engine. Safe to call repeatedly, and a no-op for
## display features when running without a window (tests, servers).
func apply() -> void:
	_ensure_bus()
	var master = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master, volume_db(int(values.master)))
	AudioServer.set_bus_mute(master, int(values.master) <= 0)
	var sfx = AudioServer.get_bus_index(SFX_BUS)
	AudioServer.set_bus_volume_db(sfx, volume_db(int(values.sfx)))
	AudioServer.set_bus_mute(sfx, int(values.sfx) <= 0)
	if DisplayServer.get_name() != "headless":
		var mode = DisplayServer.WINDOW_MODE_WINDOWED
		if values.fullscreen:
			mode = DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(mode)
		var vsync = DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED
		DisplayServer.window_set_vsync_mode(vsync)
	apply_bindings()


func apply_bindings() -> void:
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var codes: Array = DEFAULT_KEYS[action].duplicate()
		if action in REBINDABLE:
			codes = [key_for(action)]
			for extra in DEFAULT_KEYS[action].slice(1):
				if not codes.has(extra) and not _key_taken(extra, action):
					codes.append(extra)
		for code in codes:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)


func _key_taken(code: int, except_action: String) -> bool:
	for other in REBINDABLE:
		if other != except_action and key_for(other) == code:
			return true
	return false


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS) >= 0:
		return
	AudioServer.add_bus()
	var index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, SFX_BUS)
	AudioServer.set_bus_send(index, "Master")

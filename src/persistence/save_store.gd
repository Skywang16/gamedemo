class_name SaveStore
extends RefCounted

## Three save slots, each one JSON file written atomically (temp file, then rename).

const SLOTS = 3
const MAX_BYTES = 4 * 1024 * 1024

var catalog: ContentCatalog
var directory: String


func _init(content: ContentCatalog, folder: String = "user://") -> void:
	catalog = content
	directory = folder.trim_suffix("/")


func slot_path(slot: int) -> String:
	return directory + ("/farm.json" if slot == 1 else "/farm_%d.json" % slot)


## One entry per slot: {slot, state (FarmState or null), message, modified}. A slot that
## exists but cannot be used says why in `message`.
func slots() -> Array:
	var out: Array = []
	for slot in range(1, SLOTS + 1):
		out.append(load_slot(slot))
	return out


func load_slot(slot: int) -> Dictionary:
	var path = slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"slot": slot, "state": null, "message": "空的存档位", "modified": 0}
	var modified = FileAccess.get_modified_time(path)
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		return {"slot": slot, "state": null, "message": "存档无法读取", "modified": modified}
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {"slot": slot, "state": null, "message": "存档文件已损坏", "modified": modified}
	var error = validate(parser.data)
	if not error.is_empty():
		return {"slot": slot, "state": null, "message": "存档不可用：" + error, "modified": modified}
	return {
		"slot": slot,
		"state": FarmState.from_validated(parser.data),
		"message": "",
		"modified": modified
	}


## The most recently written usable slot, or {slot: 0, state: null, ...} when there is none.
func latest() -> Dictionary:
	var best = {"slot": 0, "state": null, "message": "从一片荒地，开始自己的生活。", "modified": 0}
	for entry in slots():
		if entry.state != null and int(entry.modified) >= int(best.modified):
			best = entry
	return best


func first_empty_slot() -> int:
	for entry in slots():
		if not FileAccess.file_exists(slot_path(entry.slot)):
			return int(entry.slot)
	return 0


func save_game(state: FarmState, slot: int) -> String:
	var absolute = ProjectSettings.globalize_path(directory)
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		return "无法创建存档目录。"
	var temp = slot_path(slot) + ".tmp"
	var file = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return "无法写入存档。"
	file.store_string(JSON.stringify(state.snapshot(catalog)))
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK:
		return "存档写入失败。"
	if (
		DirAccess.rename_absolute(
			ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(slot_path(slot))
		)
		!= OK
	):
		return "存档替换失败。"
	return ""


func delete_slot(slot: int) -> String:
	if not FileAccess.file_exists(slot_path(slot)):
		return ""
	if DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot))) != OK:
		return "无法删除存档。"
	return ""


func validate(data: Variant) -> String:
	return SaveValidator.new(catalog).validate(data)

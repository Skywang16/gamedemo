class_name SaveStore
extends RefCounted

var catalog: ContentCatalog
var directory: String


func _init(content: ContentCatalog, folder: String = "user://") -> void:
	catalog = content
	directory = folder.trim_suffix("/")


func slot_path() -> String:
	return directory + "/farm.json"


func load_game() -> Dictionary:
	if not FileAccess.file_exists(slot_path()):
		return {"state": null, "message": "从一片荒地，开始自己的生活。"}
	var file = FileAccess.open(slot_path(), FileAccess.READ)
	if file == null or file.get_length() > 4 * 1024 * 1024:
		return {"state": null, "message": "存档无法读取，请开始新生活。"}
	var data = JSON.parse_string(file.get_as_text())
	var error = validate(data)
	if not error.is_empty():
		return {"state": null, "message": "开发版本已更新，请创建新角色。"}
	return {"state": FarmState.from_validated(data), "message": "欢迎回来。"}


func save_game(state: FarmState) -> String:
	var absolute = ProjectSettings.globalize_path(directory)
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		return "无法创建存档目录。"
	var temp = slot_path() + ".tmp"
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
			ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(slot_path())
		)
		!= OK
	):
		return "存档替换失败。"
	return ""


func validate(data: Variant) -> String:
	return SaveValidator.new(catalog).validate(data)

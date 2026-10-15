class_name CookingRules
extends RefCounted

var catalog: ContentCatalog
var stories: StoryRules


func _init(content: ContentCatalog) -> void:
	catalog = content
	stories = StoryRules.new(content)


func result(ok: bool, message: String, extra: Dictionary = {}) -> Dictionary:
	var r = {"ok": ok, "message": message}
	r.merge(extra)
	return r


func level(s: FarmState) -> int:
	return stories.level(int(s.development.cooking_xp))


## Recipes the cook's level allows, easiest first.
func known(s: FarmState) -> Array:
	var out: Array = []
	for id in catalog.recipes:
		var recipe = catalog.recipes[id]
		if int(recipe.level) <= level(s):
			out.append(recipe)
	out.sort_custom(
		func(a, b):
			return int(a.level) < int(b.level) or (int(a.level) == int(b.level) and a.id < b.id)
	)
	return out


func can_cook(s: FarmState, recipe_id: String) -> bool:
	if not catalog.recipes.has(recipe_id):
		return false
	for need in catalog.recipes[recipe_id].needs:
		if s.inventory[need] < int(catalog.recipes[recipe_id].needs[need]):
			return false
	return int(catalog.recipes[recipe_id].level) <= level(s)


func cook(s: FarmState, recipe_id: String) -> Dictionary:
	if not catalog.recipes.has(recipe_id):
		return result(false, "没有这道菜的做法。")
	var recipe = catalog.recipes[recipe_id]
	if int(recipe.level) > level(s):
		return result(false, "烹饪等级不够（需要 Lv.%d）。" % int(recipe.level))
	for need in recipe.needs:
		if s.inventory[need] < int(recipe.needs[need]):
			return result(false, "材料不够：%s。" % catalog.items[need].name)
	for need in recipe.needs:
		s.inventory[need] -= int(recipe.needs[need])
	s.inventory[recipe_id] += 1
	s.development.cooking_xp += 5
	s.stats.cooked += 1
	return result(true, "做好了%s。" % catalog.items[recipe_id].name)

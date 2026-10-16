class_name ToolMotion
extends RefCounted

const TOOLS = ["hoe", "seed", "water", "harvest", "scythe", "axe", "pickaxe", "sword"]
const DURATIONS = {
	"hoe": 0.54,
	"seed": 0.44,
	"water": 0.8,
	"harvest": 0.44,
	"scythe": 0.42,
	"axe": 0.6,
	"pickaxe": 0.6,
	"sword": 0.42
}
const CONTACT = 0.5
const MAX_DURATION = 0.8


static func atlas_rect(tool: String, direction: int, phase: float) -> Rect2:
	return Rect2(mini(5, int(phase * 6)) * 96, (TOOLS.find(tool) * 4 + direction) * 112, 96, 112)

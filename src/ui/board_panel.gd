class_name BoardPanel
extends GameScreen

## The notice board: this week's requests from the villagers.

var state: FarmState
var board: BoardRules
var panel_size: Vector2


func open(content: ContentCatalog, s: FarmState, rules: BoardRules, size_px: Vector2) -> void:
	catalog = content
	state = s
	board = rules
	panel_size = size_px
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	_label("告示栏", Rect2(36, 16, 400, 44), 28)
	_label("每周一更新。在这里交付物品，领取金币和好感。", Rect2(36, 58, 700, 28), 17, MUTED)
	var list = board.requests(state)
	for i in list.size():
		var r: Dictionary = list[i]
		var y = 110.0 + float(i) * 104.0
		_frame(Rect2(30, y, panel_size.x - 60, 96), "inset")
		var item = catalog.items[r.item]
		icon(item.icon, Rect2(46, y + 18, 60, 60), self)
		var who = catalog.story.npcs[r.npc]
		_label("%s想要 %s ×%d" % [who.name, item.name, r.count], Rect2(122, y + 8, 560, 34), 21)
		_label(
			"%s · 报酬 %d G，好感 +%d" % [who.role, r.gold, r.friendship],
			Rect2(122, y + 46, 640, 30),
			15,
			MUTED
		)
		var done = i in state.board.done
		var button = _button(
			"已完成" if done else "交付（有 %d）" % state.inventory[r.item],
			Rect2(panel_size.x - 230, y + 24, 170, 46),
			func(): action_requested.emit("board_deliver", {"index": i})
		)
		button.disabled = done or state.inventory[r.item] < int(r.count)
	_button(
		"关闭",
		Rect2(panel_size.x - 226, footer_y(panel_size), 190, 46),
		func(): action_requested.emit("close", {})
	)

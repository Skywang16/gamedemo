class_name JournalPanel
extends GameScreen

## Chapter progress and requirements scroll independently; the footer always stays visible.

const CHAPTER_NAMES = [
	"第一章 · 灯夜重燃",
	"第二章 · 留下的人",
	"第三章 · 水从哪里来",
	"第四章 · 写给明年的信",
	"终章 · 新的河灯",
]


func open(content: ContentCatalog, state: FarmState, stories: StoryRules, size_px: Vector2) -> void:
	catalog = content
	size = size_px
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_theme(18)
	var current = stories.quest(state)
	var chapter = int(current.chapter)
	_label("故事手记", Rect2(36, 20, 300, 46), 28)
	_label(CHAPTER_NAMES[chapter - 1], Rect2(430, 24, 500, 40), 22, GOLD)
	_panel(Rect2(392, 88, 2, 464), Color("cba365"), self)
	var quests: Array = []
	for i in catalog.story.quests.size():
		if int(catalog.story.quests[i].chapter) == chapter:
			quests.append(i)
	var list = scroll_column(Rect2(36, 88, 348, 464), quests.size() * 42, self)
	for row in quests.size():
		var i: int = quests[row]
		var mark = (
			"✓" if i < state.narrative.stage else ("›" if i == state.narrative.stage else "·")
		)
		_label(
			"%s  %s" % [mark, catalog.story.quests[i].title],
			Rect2(0, row * 42, 326, 34),
			18,
			INK if i <= state.narrative.stage else MUTED,
			false,
			list
		)
	var list_scroll: ScrollContainer = list.get_parent()
	var current_row = quests.find(int(state.narrative.stage))
	list_scroll.set_deferred("scroll_vertical", maxi(0, current_row * 42 - 200))
	var detail = scroll_column(Rect2(430, 88, 514, 420), 0, self)
	_label(current.title, Rect2(0, 0, 490, 44), 28, INK, false, detail)
	_label(current.where, Rect2(0, 50, 490, 32), 17, GOLD, false, detail)
	_label(current.hint, Rect2(0, 90, 490, 110), 20, INK, true, detail)
	var y = 212.0
	if state.day < int(current.available_day):
		_label(
			"%s起可以进行" % catalog.calendar.label(int(current.available_day)),
			Rect2(0, y, 490, 30),
			17,
			MUTED,
			false,
			detail
		)
		y += 36
	for id in current.friendship:
		_label(
			(
				"%s 好感 %d / %d"
				% [catalog.story.npcs[id].name, state.relationships[id], current.friendship[id]]
			),
			Rect2(0, y, 490, 32),
			19,
			INK,
			false,
			detail
		)
		y += 38
	for id in current.needs:
		icon(catalog.items[id].icon, Rect2(0, y, 38, 38), detail)
		_label(
			"%s   %d / %d" % [catalog.items[id].name, state.inventory[id], current.needs[id]],
			Rect2(50, y, 440, 38),
			20,
			INK,
			false,
			detail
		)
		y += 44
	detail.custom_minimum_size.y = y + 8
	_label("灯", Rect2(430, 520, 40, 30), 18, MUTED)
	for i in 6:
		_panel(
			Rect2(466 + i * 34, 524, 22, 22),
			Color("f6d890") if stories.lamp_lit(state, i + 1) else Color("5a4a3a"),
			self
		)
	_button(
		"合上手记",
		Rect2(664, footer_y(size_px), 280, FOOTER_HEIGHT),
		func(): action_requested.emit("close", {})
	)

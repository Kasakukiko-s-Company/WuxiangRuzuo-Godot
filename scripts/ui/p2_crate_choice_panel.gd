class_name P2CrateChoicePanel
extends Control

@onready var _header_label: Label = $Panel/Margin/Content/Header
@onready var _selected_status_label: Label = (
	$Panel/Margin/Content/SelectedStatus
)
@onready var _cards: Array[P2CrateActionCard] = [
	$Panel/Margin/Content/Cards/Card1,
	$Panel/Margin/Content/Cards/Card2,
	$Panel/Margin/Content/Cards/Card3,
	$Panel/Margin/Content/Cards/Card4,
]

var _presentation: NorthMeadowCratePresentation


func _ready() -> void:
	_close()


func present(presentation: NorthMeadowCratePresentation) -> void:
	assert(presentation != null, "crate choice panel requires a presentation")
	_presentation = presentation
	if not presentation.is_open:
		_close()
		return
	_header_label.text = (
		"北草甸物资箱 · 今日资源可领取"
		if presentation.daily_claim_available
		else "北草甸物资箱 · 今日资源已领取"
	)
	for card_index: int in _cards.size():
		if card_index < presentation.actions.size():
			_cards[card_index].present(
				presentation.actions[card_index],
				card_index == presentation.selected_index,
			)
		else:
			_cards[card_index].clear()
	var selected := presentation.selected_action()
	_selected_status_label.text = _selected_status_text(selected)
	visible = true


func is_open() -> bool:
	return visible


func get_visible_action_count() -> int:
	var count: int = 0
	for card: P2CrateActionCard in _cards:
		if card.visible:
			count += 1
	return count


func get_selected_action_id() -> StringName:
	if _presentation == null:
		return &""
	var selected := _presentation.selected_action()
	return &"" if selected == null else selected.definition_id


func get_header_text() -> String:
	return _header_label.text


func get_selected_status_text() -> String:
	return _selected_status_label.text


func get_card_text(card_index: int) -> String:
	assert(card_index >= 0 and card_index < _cards.size())
	return _cards[card_index].display_text()


func get_card_rect(card_index: int) -> Rect2:
	assert(card_index >= 0 and card_index < _cards.size())
	var card := _cards[card_index]
	return Rect2(card.global_position, card.size)


func _close() -> void:
	visible = false
	for card: P2CrateActionCard in _cards:
		card.clear()


func _selected_status_text(action: NorthMeadowCrateAction) -> String:
	if action == null:
		return ""
	if action.enabled:
		return "已选择：%s · 可执行" % action.label
	return "已选择：%s · 暂不可执行：%s" % [
		action.label,
		action.blocked_reason_label(),
	]

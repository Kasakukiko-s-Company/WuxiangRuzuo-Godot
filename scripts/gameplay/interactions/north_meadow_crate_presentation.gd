class_name NorthMeadowCratePresentation
extends RefCounted

var is_open: bool
var daily_claim_available: bool
var actions: Array[NorthMeadowCrateAction]
var selected_index: int


func _init(
	presentation_is_open: bool,
	presentation_daily_claim_available: bool,
	presentation_actions: Array[NorthMeadowCrateAction],
	presentation_selected_index: int,
) -> void:
	assert(
		not presentation_is_open or not presentation_actions.is_empty(),
		"an open crate presentation requires actions",
	)
	assert(
		not presentation_is_open
		or (
			presentation_selected_index >= 0
			and presentation_selected_index < presentation_actions.size()
		),
		"an open crate presentation requires a valid selection",
	)
	is_open = presentation_is_open
	daily_claim_available = presentation_daily_claim_available
	actions = presentation_actions.duplicate()
	selected_index = presentation_selected_index


func selected_action() -> NorthMeadowCrateAction:
	if not is_open or selected_index < 0 or selected_index >= actions.size():
		return null
	return actions[selected_index]

class_name NorthMeadowCrateAction
extends RefCounted

enum Kind {
	DAILY_RESOURCE,
	TRADE,
}

enum VisualRole {
	DAILY_SEED,
	DAILY_FORAGE,
	TRADE_SELL,
	TRADE_BUY,
}

var kind: Kind
var visual_role: VisualRole
var definition_id: StringName
var label: String
var enabled: bool
var blocked_reason: StringName


func _init(
	action_kind: Kind,
	action_visual_role: VisualRole,
	action_definition_id: StringName,
	action_label: String,
	action_enabled: bool,
	action_blocked_reason: StringName = &"",
) -> void:
	assert(
		not action_definition_id.is_empty(),
		"crate actions require a stable definition ID",
	)
	assert(
		not action_label.strip_edges().is_empty(),
		"crate actions require a visible label",
	)
	assert(
		action_enabled or not action_blocked_reason.is_empty(),
		"disabled crate actions require a stable reason",
	)
	var role_matches_kind := (
		(
			action_kind == Kind.DAILY_RESOURCE
			and action_visual_role in [VisualRole.DAILY_SEED, VisualRole.DAILY_FORAGE]
		)
		or (
			action_kind == Kind.TRADE
			and action_visual_role in [VisualRole.TRADE_SELL, VisualRole.TRADE_BUY]
		)
	)
	assert(
		role_matches_kind,
		"crate action kind and visual role must describe the same behavior",
	)
	kind = action_kind
	visual_role = action_visual_role
	definition_id = action_definition_id
	label = action_label
	enabled = action_enabled
	blocked_reason = action_blocked_reason

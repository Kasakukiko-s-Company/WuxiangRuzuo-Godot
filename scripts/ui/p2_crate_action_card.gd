class_name P2CrateActionCard
extends PanelContainer

@onready var _role_label: Label = $Margin/Content/Role
@onready var _action_label: Label = $Margin/Content/Action
@onready var _state_label: Label = $Margin/Content/State

var _action: NorthMeadowCrateAction
var _selected: bool = false


func _ready() -> void:
	clear()


func present(
	action: NorthMeadowCrateAction,
	selected: bool,
) -> void:
	assert(action != null, "crate action card requires a typed action")
	_action = action
	_selected = selected
	_role_label.text = action.role_label()
	_action_label.text = action.label
	_state_label.text = action.execution_state_label()
	_role_label.add_theme_color_override(
		"font_color",
		_role_color(action.visual_role, action.enabled),
	)
	_state_label.add_theme_color_override(
		"font_color",
		_state_color(action.enabled),
	)
	add_theme_stylebox_override(
		"panel",
		_card_style(action.visual_role, action.enabled, selected),
	)
	visible = true


func clear() -> void:
	_action = null
	_selected = false
	visible = false


func action_id() -> StringName:
	return &"" if _action == null else _action.definition_id


func display_text() -> String:
	if _action == null:
		return ""
	return "%s\n%s\n%s" % [
		_role_label.text,
		_action_label.text,
		_state_label.text,
	]


func is_selected() -> bool:
	return _selected


func _role_color(
	role: NorthMeadowCrateAction.VisualRole,
	enabled: bool,
) -> Color:
	var color: Color
	match role:
		NorthMeadowCrateAction.VisualRole.DAILY_SEED:
			color = Color(0.72, 0.92, 0.54, 1.0)
		NorthMeadowCrateAction.VisualRole.DAILY_FORAGE:
			color = Color(0.94, 0.76, 0.42, 1.0)
		NorthMeadowCrateAction.VisualRole.TRADE_SELL:
			color = Color(0.48, 0.84, 0.68, 1.0)
		_:
			color = Color(0.58, 0.78, 0.94, 1.0)
	return color if enabled else color.darkened(0.46)


func _state_color(enabled: bool) -> Color:
	if enabled:
		return Color(0.72, 0.84, 0.74, 1.0)
	return Color(0.66, 0.62, 0.58, 1.0)


func _card_style(
	role: NorthMeadowCrateAction.VisualRole,
	enabled: bool,
	selected: bool,
) -> StyleBoxFlat:
	var accent := _role_color(role, enabled)
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(0.075, 0.11, 0.105, 0.98)
		if selected
		else Color(0.035, 0.055, 0.055, 0.94)
	)
	style.border_color = accent if selected else Color(0.23, 0.3, 0.29, 0.82)
	var border_width := 2 if selected else 1
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

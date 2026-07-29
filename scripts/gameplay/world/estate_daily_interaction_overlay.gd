class_name EstateDailyInteractionOverlay
extends Node2D

var _resource_position: Vector2
var _rest_position: Vector2
var _rest_confirmation_pending: bool = false
var _crate_presentation := NorthMeadowCratePresentation.new(
	false,
	true,
	[],
	-1,
)


func configure(
	resource_world_position: Vector2,
	rest_world_position: Vector2,
) -> void:
	_resource_position = resource_world_position
	_rest_position = rest_world_position
	queue_redraw()


func show_crate(presentation: NorthMeadowCratePresentation) -> void:
	assert(presentation != null, "daily overlay requires a crate presentation")
	_crate_presentation = presentation
	queue_redraw()


func show_rest_confirmation(pending: bool) -> void:
	if _rest_confirmation_pending == pending:
		return
	_rest_confirmation_pending = pending
	queue_redraw()


func get_resource_world_position() -> Vector2:
	return _resource_position


func get_rest_world_position() -> Vector2:
	return _rest_position


func is_crate_open() -> bool:
	return _crate_presentation.is_open


func get_crate_selected_index() -> int:
	return _crate_presentation.selected_index


func get_crate_action_count() -> int:
	return _crate_presentation.actions.size()


func get_selected_crate_action_id() -> StringName:
	var selected := _crate_presentation.selected_action()
	return &"" if selected == null else selected.definition_id


func is_daily_claim_available() -> bool:
	return _crate_presentation.daily_claim_available


func _draw() -> void:
	_draw_resource_source()
	_draw_rest_point()


func _draw_resource_source() -> void:
	var aura := Color(0.42, 0.78, 0.48, 0.24)
	var crate := Color(0.48, 0.30, 0.17, 1.0)
	var sprout := Color(0.68, 0.92, 0.52, 1.0)
	if _crate_presentation.is_open:
		aura = Color(0.92, 0.72, 0.28, 0.30)
		crate = Color(0.55, 0.34, 0.16, 1.0)
		sprout = Color(0.94, 0.78, 0.34, 1.0)
	elif not _crate_presentation.daily_claim_available:
		aura = Color(0.42, 0.45, 0.43, 0.13)
		crate = Color(0.33, 0.31, 0.28, 1.0)
		sprout = Color(0.44, 0.48, 0.44, 1.0)
	draw_circle(_resource_position, 14.0, aura)
	draw_rect(
		Rect2(_resource_position + Vector2(-9.0, -4.0), Vector2(18.0, 11.0)),
		crate,
	)
	draw_line(
		_resource_position + Vector2(0.0, -4.0),
		_resource_position + Vector2(0.0, -12.0),
		sprout,
		2.0,
	)
	draw_line(
		_resource_position + Vector2(0.0, -9.0),
		_resource_position + Vector2(-5.0, -12.0),
		sprout,
		2.0,
	)
	draw_line(
		_resource_position + Vector2(0.0, -8.0),
		_resource_position + Vector2(5.0, -11.0),
		sprout,
		2.0,
	)
	if _crate_presentation.is_open:
		_draw_crate_actions()


func _draw_crate_actions() -> void:
	var count := _crate_presentation.actions.size()
	for index: int in count:
		var action := _crate_presentation.actions[index]
		var center := _resource_position + Vector2(
			(float(index) - (float(count - 1) * 0.5)) * 11.0,
			-23.0,
		)
		var color := _action_color(action)
		draw_circle(center, 4.0, color)
		if not action.enabled:
			draw_line(
				center + Vector2(-3.0, -3.0),
				center + Vector2(3.0, 3.0),
				Color(0.20, 0.22, 0.22, 0.9),
				1.5,
			)
		if index == _crate_presentation.selected_index:
			draw_arc(
				center,
				7.0,
				0.0,
				TAU,
				12,
				Color(1.0, 0.96, 0.72, 1.0),
				2.0,
			)


func _action_color(action: NorthMeadowCrateAction) -> Color:
	var color: Color
	match action.visual_role:
		NorthMeadowCrateAction.VisualRole.DAILY_SEED:
			color = Color(0.72, 0.95, 0.52, 1.0)
		NorthMeadowCrateAction.VisualRole.DAILY_FORAGE:
			color = Color(0.92, 0.72, 0.38, 1.0)
		NorthMeadowCrateAction.VisualRole.TRADE_SELL:
			color = Color(0.48, 0.82, 0.66, 1.0)
		_:
			color = Color(0.96, 0.72, 0.30, 1.0)
	return color if action.enabled else color.darkened(0.55)


func _draw_rest_point() -> void:
	var glow := Color(0.95, 0.78, 0.39, 0.22)
	if _rest_confirmation_pending:
		glow = Color(1.0, 0.85, 0.48, 0.48)
	draw_circle(_rest_position, 13.0, glow)
	draw_rect(
		Rect2(_rest_position + Vector2(-10.0, 5.0), Vector2(20.0, 5.0)),
		Color(0.42, 0.25, 0.16, 0.95),
	)
	var chevron_color := Color(1.0, 0.88, 0.55, 1.0)
	draw_polyline(
		PackedVector2Array([
			_rest_position + Vector2(-6.0, -7.0),
			_rest_position + Vector2(0.0, -2.0),
			_rest_position + Vector2(6.0, -7.0),
		]),
		chevron_color,
		2.0,
	)

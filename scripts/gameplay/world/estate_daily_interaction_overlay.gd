class_name EstateDailyInteractionOverlay
extends Node2D

var _resource_position: Vector2
var _rest_position: Vector2
var _resource_available: bool = true
var _rest_confirmation_pending: bool = false


func configure(
	resource_world_position: Vector2,
	rest_world_position: Vector2,
) -> void:
	_resource_position = resource_world_position
	_rest_position = rest_world_position
	queue_redraw()


func show_state(
	resource_available: bool,
	rest_confirmation_pending: bool,
) -> void:
	if (
		_resource_available == resource_available
		and _rest_confirmation_pending == rest_confirmation_pending
	):
		return
	_resource_available = resource_available
	_rest_confirmation_pending = rest_confirmation_pending
	queue_redraw()


func get_resource_world_position() -> Vector2:
	return _resource_position


func get_rest_world_position() -> Vector2:
	return _rest_position


func _draw() -> void:
	_draw_resource_source()
	_draw_rest_point()


func _draw_resource_source() -> void:
	var aura := Color(0.42, 0.78, 0.48, 0.24)
	var crate := Color(0.48, 0.30, 0.17, 1.0)
	var sprout := Color(0.68, 0.92, 0.52, 1.0)
	if not _resource_available:
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

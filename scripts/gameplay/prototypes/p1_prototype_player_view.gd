class_name P1PrototypePlayerView
extends Node2D

var _walk_phase: float = 0.0
var _last_facing: Vector2i = Vector2i.DOWN


func _process(delta: float) -> void:
	var controller := get_parent() as P1PlayerController
	if controller == null:
		return
	if controller.velocity.length_squared() > 1.0:
		_walk_phase += delta * 11.0
	else:
		_walk_phase = 0.0
	position.y = -2.0 + sin(_walk_phase) * 1.2
	if controller.facing != _last_facing:
		_last_facing = controller.facing
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(1.5, 16.0), 10.0, Color(0.02, 0.04, 0.05, 0.45))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-10, -5), Vector2(10, -5), Vector2(13, 14), Vector2(-13, 14)]),
		Color(0.3, 0.45, 0.42, 1.0),
	)
	draw_polyline(
		PackedVector2Array([Vector2(-10, -5), Vector2(10, -5), Vector2(13, 14), Vector2(-13, 14), Vector2(-10, -5)]),
		Color(0.12, 0.19, 0.19, 1.0),
		2.0,
	)
	draw_circle(Vector2(0, -13), 9.0, Color(0.78, 0.68, 0.55, 1.0))
	draw_arc(Vector2(0, -15), 9.0, 3.2, 6.15, 16, Color(0.12, 0.16, 0.17, 1.0), 5.0, true)
	_draw_facing_mark()


func _draw_facing_mark() -> void:
	var direction := Vector2(_last_facing)
	var eye_center := Vector2(0, -13) + direction * 3.0
	if _last_facing.x == 0:
		draw_circle(eye_center + Vector2(-2.5, 0), 1.2, Color(0.08, 0.1, 0.1, 1.0))
		draw_circle(eye_center + Vector2(2.5, 0), 1.2, Color(0.08, 0.1, 0.1, 1.0))
	else:
		draw_circle(eye_center, 1.4, Color(0.08, 0.1, 0.1, 1.0))
	draw_line(Vector2.ZERO, direction * 19.0, Color(0.82, 0.9, 0.68, 0.8), 2.0)

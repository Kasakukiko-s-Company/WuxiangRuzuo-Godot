class_name P1PrototypeForeground
extends Node2D

var _quality_level: StringName = &"high"


func set_quality_level(level: StringName) -> void:
	assert(level == &"low" or level == &"high", "P1 quality must be low or high")
	_quality_level = level
	queue_redraw()


func get_quality_level() -> StringName:
	return _quality_level


func _draw() -> void:
	_draw_canopy(Vector2(620.0, 135.0), Color("203c35"), 74.0)
	_draw_canopy(Vector2(735.0, 178.0), Color("29483d"), 68.0)
	_draw_reeds(Vector2(925.0, 500.0))
	if _quality_level == &"high":
		_draw_mist_ribbon()


func _draw_canopy(center: Vector2, color: Color, radius: float) -> void:
	for offset in [Vector2(-30.0, 4.0), Vector2(0.0, -12.0), Vector2(34.0, 8.0)]:
		draw_circle(center + offset, radius * 0.56, color)
		draw_arc(center + offset, radius * 0.56, 0.0, TAU, 24, color.lightened(0.12), 2.0)


func _draw_reeds(origin: Vector2) -> void:
	for reed_index in range(7):
		var x_offset := float(reed_index) * 12.0
		var height := 34.0 + float((reed_index * 11) % 18)
		var base := origin + Vector2(x_offset, 34.0)
		draw_line(base, base - Vector2(3.0, height), Color("58734d"), 3.0)
		draw_circle(base - Vector2(3.0, height), 3.5, Color("9a8454"))


func _draw_mist_ribbon() -> void:
	var mist_color := Color(0.68, 0.78, 0.75, 0.11)
	var points := PackedVector2Array([
		Vector2(0.0, 690.0),
		Vector2(250.0, 650.0),
		Vector2(530.0, 700.0),
		Vector2(820.0, 660.0),
		Vector2(1100.0, 720.0),
		Vector2(1280.0, 680.0),
	])
	draw_polyline(points, mist_color, 22.0, true)

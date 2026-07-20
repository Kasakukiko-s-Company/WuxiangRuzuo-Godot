class_name PrototypeInspectable
extends Node2D

@export var interaction_cell: Vector2i
@export var prompt_text: String = "检查"
@export_multiline var inspect_text: String = "这里还只是原型。"
@export var one_shot: bool = false
@export_multiline var exhausted_text: String = "已经检查过了。"
@export var marker_color: Color = Color(0.72, 0.82, 0.62, 1.0)
@export var marker_size: Vector2 = Vector2(18.0, 18.0)

var _inspection_count: int = 0


func matches_cell(cell: Vector2i) -> bool:
	return interaction_cell == cell


func take_inspection_text() -> String:
	var result := exhausted_text if one_shot and _inspection_count > 0 else inspect_text
	_inspection_count += 1
	return result


func reset_inspection() -> void:
	_inspection_count = 0


func _draw() -> void:
	var half_size := marker_size * 0.5
	draw_ellipse_shadow(half_size)
	draw_rect(Rect2(-half_size, marker_size), marker_color, true)
	draw_rect(Rect2(-half_size, marker_size), marker_color.lightened(0.25), false, 2.0)
	draw_line(Vector2(-half_size.x + 3.0, 0.0), Vector2(half_size.x - 3.0, 0.0), marker_color.darkened(0.35), 2.0)


func draw_ellipse_shadow(half_size: Vector2) -> void:
	draw_circle(Vector2(2.0, half_size.y + 3.0), maxf(half_size.x * 0.8, 4.0), Color(0.03, 0.06, 0.06, 0.35))

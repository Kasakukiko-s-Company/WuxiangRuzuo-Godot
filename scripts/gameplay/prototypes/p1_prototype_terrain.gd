class_name P1PrototypeTerrain
extends Node2D

const TILE_SIZE: int = 32
const GRID_SIZE: Vector2i = Vector2i(40, 28)
const WORLD_SIZE: Vector2 = Vector2(1280.0, 896.0)

var _quality_level: StringName = &"high"
var _debug_grid_visible: bool = false


func set_quality_level(level: StringName) -> void:
	assert(level == &"low" or level == &"high", "P1 quality must be low or high")
	_quality_level = level
	queue_redraw()


func get_quality_level() -> StringName:
	return _quality_level


func set_debug_grid_visible(visible: bool) -> void:
	_debug_grid_visible = visible
	queue_redraw()


func _draw() -> void:
	_draw_ground_tiles()
	_draw_paths()
	_draw_water()
	_draw_house()
	_draw_gate_and_landmark()
	_draw_grove()
	if _quality_level == &"high":
		_draw_high_quality_accents()
	if _debug_grid_visible:
		_draw_debug_grid()


func _draw_ground_tiles() -> void:
	for cell_y in range(GRID_SIZE.y):
		for cell_x in range(GRID_SIZE.x):
			var variation := float((cell_x * 7 + cell_y * 11) % 5) / 100.0
			var color := Color(0.18 + variation, 0.29 + variation, 0.25 + variation * 0.5, 1.0)
			draw_rect(Rect2(cell_x * TILE_SIZE, cell_y * TILE_SIZE, TILE_SIZE, TILE_SIZE), color, true)


func _draw_paths() -> void:
	var main_path := PackedVector2Array([
		Vector2(190, 896), Vector2(310, 896), Vector2(330, 620), Vector2(560, 570),
		Vector2(860, 590), Vector2(940, 690), Vector2(1010, 650), Vector2(920, 540),
		Vector2(660, 500), Vector2(410, 520), Vector2(300, 430), Vector2(280, 250),
		Vector2(180, 250), Vector2(190, 500),
	])
	draw_colored_polygon(main_path, Color(0.47, 0.43, 0.32, 1.0))
	draw_polyline(main_path, Color(0.62, 0.57, 0.42, 0.72), 3.0, true)

	var north_path := PackedVector2Array([
		Vector2(540, 510), Vector2(570, 370), Vector2(610, 270), Vector2(610, 0),
		Vector2(720, 0), Vector2(720, 280), Vector2(680, 390), Vector2(650, 520),
	])
	draw_colored_polygon(north_path, Color(0.38, 0.38, 0.31, 1.0))


func _draw_water() -> void:
	var water_rect := Rect2(940, 370, 220, 300)
	draw_rect(water_rect, Color(0.13, 0.3, 0.35, 1.0), true)
	draw_rect(water_rect, Color(0.38, 0.58, 0.58, 0.8), false, 4.0)
	var line_step := 24 if _quality_level == &"high" else 48
	for offset_y in range(16, 300, line_step):
		draw_line(Vector2(952, 370 + offset_y), Vector2(1148, 370 + offset_y + 5), Color(0.42, 0.64, 0.64, 0.34), 2.0)


func _draw_house() -> void:
	draw_rect(Rect2(100, 80, 240, 160), Color(0.36, 0.25, 0.2, 1.0), true)
	draw_colored_polygon(PackedVector2Array([Vector2(80, 96), Vector2(220, 24), Vector2(360, 96)]), Color(0.27, 0.2, 0.2, 1.0))
	draw_rect(Rect2(190, 156, 60, 84), Color(0.18, 0.14, 0.13, 1.0), true)
	draw_rect(Rect2(124, 124, 42, 36), Color(0.55, 0.67, 0.58, 0.7), true)
	draw_rect(Rect2(276, 124, 42, 36), Color(0.55, 0.67, 0.58, 0.7), true)


func _draw_gate_and_landmark() -> void:
	draw_rect(Rect2(330, 404, 320, 32), Color(0.23, 0.19, 0.17, 1.0), true)
	draw_rect(Rect2(462, 364, 18, 72), Color(0.31, 0.25, 0.2, 1.0), true)
	draw_rect(Rect2(526, 364, 18, 72), Color(0.31, 0.25, 0.2, 1.0), true)
	draw_line(Vector2(471, 370), Vector2(535, 392), Color(0.65, 0.3, 0.3, 0.9), 5.0)

	draw_circle(Vector2(816, 272), 24.0, Color(0.27, 0.3, 0.35, 1.0))
	draw_arc(Vector2(816, 272), 18.0, -2.6, 0.6, 18, Color(0.58, 0.68, 0.7, 0.75), 3.0, true)


func _draw_grove() -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(620, 112), Vector2(680, 92), Vector2(742, 118), Vector2(650, 184),
		Vector2(720, 194), Vector2(842, 735), Vector2(900, 746), Vector2(870, 802),
	]
	for tree_position in tree_positions:
		draw_circle(tree_position + Vector2(4, 12), 25.0, Color(0.04, 0.09, 0.08, 0.45))
		draw_rect(Rect2(tree_position.x - 5, tree_position.y, 10, 34), Color(0.25, 0.19, 0.14, 1.0), true)
		draw_circle(tree_position, 30.0, Color(0.12, 0.25, 0.2, 1.0))
		draw_circle(tree_position + Vector2(-10, -7), 17.0, Color(0.2, 0.36, 0.27, 1.0))


func _draw_high_quality_accents() -> void:
	for index in range(11):
		var center := Vector2(70.0 + index * 113.0, 66.0 + float((index * 47) % 760))
		draw_arc(center, 42.0 + float(index % 3) * 14.0, 0.2, 2.9, 22, Color(0.72, 0.82, 0.77, 0.08), 8.0, true)
	for index in range(28):
		var position := Vector2(24.0 + float((index * 83) % 1230), 30.0 + float((index * 137) % 830))
		draw_circle(position, 1.5, Color(0.78, 0.85, 0.62, 0.35))


func _draw_debug_grid() -> void:
	for cell_x in range(GRID_SIZE.x + 1):
		draw_line(Vector2(cell_x * TILE_SIZE, 0), Vector2(cell_x * TILE_SIZE, WORLD_SIZE.y), Color(0.35, 0.8, 0.75, 0.22), 1.0)
	for cell_y in range(GRID_SIZE.y + 1):
		draw_line(Vector2(0, cell_y * TILE_SIZE), Vector2(WORLD_SIZE.x, cell_y * TILE_SIZE), Color(0.35, 0.8, 0.75, 0.22), 1.0)

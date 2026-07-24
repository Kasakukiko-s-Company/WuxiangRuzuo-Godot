class_name FarmPlotOverlay
extends Node2D

const TILE_SIZE: Vector2 = Vector2(32.0, 32.0)

var _farm: FarmState
var _world_day: int = 1


func show_state(farm: FarmState, world_day: int) -> void:
	assert(farm != null, "farm overlay requires a FarmState")
	assert(world_day >= 1, "farm overlay requires a valid world day")
	if _farm == farm and _world_day == world_day:
		return
	_farm = farm
	_world_day = world_day
	queue_redraw()


func get_rendered_tile_count() -> int:
	return 0 if _farm == null else _farm.tile_count()


func _draw() -> void:
	if _farm == null:
		return
	for tile: FarmTileState in _farm.copy_tiles():
		var origin := Vector2(tile.coordinate) * TILE_SIZE
		var soil_rect := Rect2(origin + Vector2(2.0, 4.0), Vector2(28.0, 24.0))
		draw_rect(soil_rect, Color("76513c"))
		draw_line(
			soil_rect.position + Vector2(3.0, 7.0),
			soil_rect.end - Vector2(3.0, 17.0),
			Color("9e7251"),
			2.0,
		)
		draw_line(
			soil_rect.position + Vector2(3.0, 16.0),
			soil_rect.end - Vector2(3.0, 8.0),
			Color("9e7251"),
			2.0,
		)
		if tile.watered_on_day == _world_day:
			draw_rect(soil_rect, Color(0.16, 0.38, 0.48, 0.42))
		if tile.crop != null:
			_draw_crop(origin, tile.crop)


func _draw_crop(origin: Vector2, crop: CropState) -> void:
	var center := origin + Vector2(16.0, 17.0)
	var stage := clampi(crop.stage_index, 0, 3)
	if stage == 0:
		draw_circle(center + Vector2(-2.0, 4.0), 3.0, Color("c9d67a"))
		return
	var stem_height: float = 5.0 + float(stage * 3)
	draw_line(
		center + Vector2(0.0, 7.0),
		center + Vector2(0.0, 7.0 - stem_height),
		Color("5f8f53"),
		3.0,
	)
	draw_circle(
		center + Vector2(-4.0, 3.0 - float(stage)),
		3.0 + float(stage),
		Color("7fb66a"),
	)
	draw_circle(
		center + Vector2(4.0, 2.0 - float(stage)),
		3.0 + float(stage),
		Color("96c873"),
	)
	if stage >= 3:
		draw_circle(center + Vector2(0.0, -6.0), 4.0, Color("d6e8a5"))

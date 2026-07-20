class_name TileCoordinateMapper
extends RefCounted

var tile_size: Vector2i
var world_origin: Vector2


func _init(size: Vector2i, origin: Vector2 = Vector2.ZERO) -> void:
	assert(size.x > 0 and size.y > 0, "tile size must be positive")
	tile_size = size
	world_origin = origin


func world_to_cell(world_position: Vector2) -> Vector2i:
	var local_position := world_position - world_origin
	return Vector2i(
		floori(local_position.x / float(tile_size.x)),
		floori(local_position.y / float(tile_size.y)),
	)


func cell_center(cell: Vector2i) -> Vector2:
	return world_origin + Vector2(
		(float(cell.x) + 0.5) * float(tile_size.x),
		(float(cell.y) + 0.5) * float(tile_size.y),
	)


func facing_cell(world_position: Vector2, facing: Vector2i) -> Vector2i:
	assert(absi(facing.x) + absi(facing.y) == 1, "facing must be cardinal")
	return world_to_cell(world_position) + facing

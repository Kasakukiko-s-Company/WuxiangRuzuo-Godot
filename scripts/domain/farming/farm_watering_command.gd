class_name FarmWateringCommand
extends RefCounted

var map_id: StringName
var coordinate: Vector2i
var world_day: int


func _init(
	command_map_id: StringName,
	command_coordinate: Vector2i,
	command_world_day: int,
) -> void:
	map_id = command_map_id
	coordinate = command_coordinate
	world_day = command_world_day

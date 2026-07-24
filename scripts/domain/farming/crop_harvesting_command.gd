class_name CropHarvestingCommand
extends RefCounted

var map_id: StringName
var coordinate: Vector2i


func _init(
	command_map_id: StringName,
	command_coordinate: Vector2i,
) -> void:
	map_id = command_map_id
	coordinate = command_coordinate

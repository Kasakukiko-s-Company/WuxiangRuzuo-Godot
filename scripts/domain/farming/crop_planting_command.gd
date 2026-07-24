class_name CropPlantingCommand
extends RefCounted

var map_id: StringName
var coordinate: Vector2i
var world_day: int
var season: StringName
var seed_item_id: StringName


func _init(
	command_map_id: StringName,
	command_coordinate: Vector2i,
	command_world_day: int,
	command_season: StringName,
	command_seed_item_id: StringName,
) -> void:
	map_id = command_map_id
	coordinate = command_coordinate
	world_day = command_world_day
	season = command_season
	seed_item_id = command_seed_item_id

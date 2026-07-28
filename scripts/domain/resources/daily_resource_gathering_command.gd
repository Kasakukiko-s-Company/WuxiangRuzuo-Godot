class_name DailyResourceGatheringCommand
extends RefCounted

var source_id: StringName
var world_day: int


func _init(
	command_source_id: StringName,
	command_world_day: int,
) -> void:
	source_id = command_source_id
	world_day = command_world_day

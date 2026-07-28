class_name DailyRestCommand
extends RefCounted

var rest_point_id: StringName
var completed_day: int


func _init(
	command_rest_point_id: StringName,
	command_completed_day: int,
) -> void:
	rest_point_id = command_rest_point_id
	completed_day = command_completed_day

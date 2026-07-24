class_name FarmDayAdvanceCommand
extends RefCounted

var completed_day: int


func _init(command_completed_day: int) -> void:
	assert(command_completed_day >= 1, "completed farm day starts at one")
	completed_day = command_completed_day

class_name EstateStateAxis
extends RefCounted

var id: StringName
var values: Array[StringName]


func _init(axis_id: StringName, axis_values: Array[StringName]) -> void:
	id = axis_id
	values = axis_values.duplicate()

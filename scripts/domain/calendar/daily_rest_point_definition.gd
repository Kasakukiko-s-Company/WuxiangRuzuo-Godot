class_name DailyRestPointDefinition
extends RefCounted

var id: StringName:
	get:
		return _id
	set(_attempted_value):
		push_error("DailyRestPointDefinition.id is read-only")
var map_id: StringName:
	get:
		return _map_id
	set(_attempted_value):
		push_error("DailyRestPointDefinition.map_id is read-only")
var anchor_kind: StringName:
	get:
		return _anchor_kind
	set(_attempted_value):
		push_error("DailyRestPointDefinition.anchor_kind is read-only")
var anchor_id: StringName:
	get:
		return _anchor_id
	set(_attempted_value):
		push_error("DailyRestPointDefinition.anchor_id is read-only")

var _id: StringName
var _map_id: StringName
var _anchor_kind: StringName
var _anchor_id: StringName


func _init(
	definition_id: StringName,
	definition_map_id: StringName,
	definition_anchor_kind: StringName,
	definition_anchor_id: StringName,
) -> void:
	_id = definition_id
	_map_id = definition_map_id
	_anchor_kind = definition_anchor_kind
	_anchor_id = definition_anchor_id

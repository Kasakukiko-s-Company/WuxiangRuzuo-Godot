class_name DailyResourceSourceDefinition
extends RefCounted

var id: StringName:
	get:
		return _id
	set(_attempted_value):
		push_error("DailyResourceSourceDefinition.id is read-only")
var map_id: StringName:
	get:
		return _map_id
	set(_attempted_value):
		push_error("DailyResourceSourceDefinition.map_id is read-only")
var anchor_kind: StringName:
	get:
		return _anchor_kind
	set(_attempted_value):
		push_error("DailyResourceSourceDefinition.anchor_kind is read-only")
var anchor_id: StringName:
	get:
		return _anchor_id
	set(_attempted_value):
		push_error("DailyResourceSourceDefinition.anchor_id is read-only")
var item_id: StringName:
	get:
		return _item_id
	set(_attempted_value):
		push_error("DailyResourceSourceDefinition.item_id is read-only")
var quantity: int:
	get:
		return _quantity
	set(_attempted_value):
		push_error("DailyResourceSourceDefinition.quantity is read-only")

var _id: StringName
var _map_id: StringName
var _anchor_kind: StringName
var _anchor_id: StringName
var _item_id: StringName
var _quantity: int


func _init(
	definition_id: StringName,
	definition_map_id: StringName,
	definition_anchor_kind: StringName,
	definition_anchor_id: StringName,
	definition_item_id: StringName,
	definition_quantity: int,
) -> void:
	_id = definition_id
	_map_id = definition_map_id
	_anchor_kind = definition_anchor_kind
	_anchor_id = definition_anchor_id
	_item_id = definition_item_id
	_quantity = definition_quantity

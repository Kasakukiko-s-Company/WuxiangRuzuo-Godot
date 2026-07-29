class_name TradeCommand
extends RefCounted

var endpoint_id: StringName
var offer_id: StringName


func _init(
	command_endpoint_id: StringName,
	command_offer_id: StringName,
) -> void:
	endpoint_id = command_endpoint_id
	offer_id = command_offer_id

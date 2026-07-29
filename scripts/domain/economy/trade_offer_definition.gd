class_name TradeOfferDefinition
extends RefCounted

var id: StringName:
	get:
		return _id
	set(_attempted_value):
		push_error("TradeOfferDefinition.id is read-only")
var endpoint_id: StringName:
	get:
		return _endpoint_id
	set(_attempted_value):
		push_error("TradeOfferDefinition.endpoint_id is read-only")
var cost_item_id: StringName:
	get:
		return _cost_item_id
	set(_attempted_value):
		push_error("TradeOfferDefinition.cost_item_id is read-only")
var cost_quantity: int:
	get:
		return _cost_quantity
	set(_attempted_value):
		push_error("TradeOfferDefinition.cost_quantity is read-only")
var reward_item_id: StringName:
	get:
		return _reward_item_id
	set(_attempted_value):
		push_error("TradeOfferDefinition.reward_item_id is read-only")
var reward_quantity: int:
	get:
		return _reward_quantity
	set(_attempted_value):
		push_error("TradeOfferDefinition.reward_quantity is read-only")

var _id: StringName
var _endpoint_id: StringName
var _cost_item_id: StringName
var _cost_quantity: int
var _reward_item_id: StringName
var _reward_quantity: int


func _init(
	offer_id: StringName,
	offer_endpoint_id: StringName,
	offer_cost_item_id: StringName,
	offer_cost_quantity: int,
	offer_reward_item_id: StringName,
	offer_reward_quantity: int,
) -> void:
	_id = offer_id
	_endpoint_id = offer_endpoint_id
	_cost_item_id = offer_cost_item_id
	_cost_quantity = offer_cost_quantity
	_reward_item_id = offer_reward_item_id
	_reward_quantity = offer_reward_quantity

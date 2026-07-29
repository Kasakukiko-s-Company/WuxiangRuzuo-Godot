class_name TradeResult
extends RefCounted

enum Status {
	COMPLETED,
	INVALID_OFFER,
	ENDPOINT_MISMATCH,
	INSUFFICIENT_COST,
	REWARD_CAPACITY,
}

var status: Status
var inventory: InventoryState
var offer: TradeOfferDefinition


func _init(
	result_status: Status,
	result_inventory: InventoryState,
	result_offer: TradeOfferDefinition = null,
) -> void:
	status = result_status
	inventory = result_inventory
	offer = result_offer

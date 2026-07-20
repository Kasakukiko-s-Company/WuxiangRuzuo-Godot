class_name InventoryTransactionResult
extends RefCounted

enum Status {
	ADDED,
	INVENTORY_FULL,
	INVALID_ITEM,
	INVALID_QUANTITY,
	REMOVED,
	INSUFFICIENT_ITEM,
	SELECTED,
	ALREADY_SELECTED,
	INVALID_SLOT,
}

var status: Status
var inventory: InventoryState


func _init(result_status: Status, result_inventory: InventoryState) -> void:
	status = result_status
	inventory = result_inventory

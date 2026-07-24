class_name FarmingTransactionState
extends RefCounted

var farm: FarmState:
	get:
		return _farm
	set(_attempted_value):
		push_error("FarmingTransactionState.farm is read-only")
var inventory: InventoryState:
	get:
		return _inventory
	set(_attempted_value):
		push_error("FarmingTransactionState.inventory is read-only")

var _farm: FarmState
var _inventory: InventoryState


func _init(
	state_farm: FarmState,
	state_inventory: InventoryState,
) -> void:
	assert(state_farm != null, "farming transaction requires a farm state")
	assert(state_inventory != null, "farming transaction requires an inventory state")
	_farm = state_farm
	_inventory = state_inventory


func snapshot() -> FarmingTransactionState:
	return FarmingTransactionState.new(_farm, _inventory)

class_name CropHarvestingResult
extends RefCounted

enum Status {
	HARVESTED,
	MAP_MISMATCH,
	NOT_TILLED,
	NO_CROP,
	UNKNOWN_CROP,
	NOT_MATURE,
	INVENTORY_FULL,
}

var status: Status
var session: FarmingSessionState
var harvested_quantity: int


func _init(
	result_status: Status,
	result_session: FarmingSessionState,
	result_harvested_quantity: int = 0,
) -> void:
	status = result_status
	session = result_session
	harvested_quantity = result_harvested_quantity


func is_success() -> bool:
	return status == Status.HARVESTED

class_name CropPlantingResult
extends RefCounted

enum Status {
	PLANTED,
	MAP_MISMATCH,
	NOT_TILLED,
	TILE_OCCUPIED,
	INVALID_SEED,
	INVALID_DAY,
	WRONG_SEASON,
	INSUFFICIENT_SEED,
}

var status: Status
var session: FarmingSessionState


func _init(
	result_status: Status,
	result_session: FarmingSessionState,
) -> void:
	status = result_status
	session = result_session


func is_success() -> bool:
	return status == Status.PLANTED

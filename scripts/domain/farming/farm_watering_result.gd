class_name FarmWateringResult
extends RefCounted

enum Status {
	WATERED,
	MAP_MISMATCH,
	NOT_TILLED,
	INVALID_DAY,
	ALREADY_WATERED,
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
	return status == Status.WATERED

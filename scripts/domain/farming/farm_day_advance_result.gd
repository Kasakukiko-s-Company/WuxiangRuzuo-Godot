class_name FarmDayAdvanceResult
extends RefCounted

enum Status {
	ADVANCED,
	ALREADY_APPLIED,
	DAY_GAP,
	UNKNOWN_CROP,
}

var status: Status
var session: FarmingSessionState
var grown_crop_count: int


func _init(
	result_status: Status,
	result_session: FarmingSessionState,
	result_grown_crop_count: int = 0,
) -> void:
	status = result_status
	session = result_session
	grown_crop_count = result_grown_crop_count


func is_success() -> bool:
	return status == Status.ADVANCED

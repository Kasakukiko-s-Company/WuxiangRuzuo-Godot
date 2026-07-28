class_name DailyResourceGatheringResult
extends RefCounted

enum Status {
	COLLECTED,
	MAP_MISMATCH,
	INVALID_DAY,
	INVALID_SOURCE,
	ALREADY_COLLECTED,
	INVALID_ITEM,
	INVALID_QUANTITY,
	INVENTORY_FULL,
}

var status: Status
var session: FarmingSessionState
var claims: DailyResourceClaims


func _init(
	result_status: Status,
	result_session: FarmingSessionState,
	result_claims: DailyResourceClaims,
) -> void:
	status = result_status
	session = result_session
	claims = result_claims


func is_success() -> bool:
	return status == Status.COLLECTED

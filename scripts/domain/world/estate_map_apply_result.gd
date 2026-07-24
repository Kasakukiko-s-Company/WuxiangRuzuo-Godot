class_name EstateMapApplyResult
extends RefCounted

enum Status {
	APPLIED,
	INVALID_STATE,
	RUNTIME_ERROR,
}

var status: Status
var message: String


func _init(result_status: Status, result_message: String = "") -> void:
	status = result_status
	message = result_message


static func applied() -> EstateMapApplyResult:
	return EstateMapApplyResult.new(Status.APPLIED)


static func invalid(message: String) -> EstateMapApplyResult:
	return EstateMapApplyResult.new(Status.INVALID_STATE, message)


static func runtime_error(message: String) -> EstateMapApplyResult:
	return EstateMapApplyResult.new(Status.RUNTIME_ERROR, message)


func is_success() -> bool:
	return status == Status.APPLIED

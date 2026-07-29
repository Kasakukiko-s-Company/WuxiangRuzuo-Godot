class_name GameSaveCommitResult
extends RefCounted

enum Status {
	SAVED,
	SAVED_RECOVERY_DEGRADED,
	REJECTED,
	STORAGE_FAILED,
}

var status: Status
var message: String


static func saved() -> GameSaveCommitResult:
	var result := GameSaveCommitResult.new()
	result.status = Status.SAVED
	return result


static func recovery_degraded(failure_message: String) -> GameSaveCommitResult:
	var result := GameSaveCommitResult.new()
	result.status = Status.SAVED_RECOVERY_DEGRADED
	result.message = failure_message
	return result


static func rejected(failure_message: String) -> GameSaveCommitResult:
	var result := GameSaveCommitResult.new()
	result.status = Status.REJECTED
	result.message = failure_message
	return result


static func storage_failed(failure_message: String) -> GameSaveCommitResult:
	var result := GameSaveCommitResult.new()
	result.status = Status.STORAGE_FAILED
	result.message = failure_message
	return result


func is_saved() -> bool:
	return (
		status == Status.SAVED
		or status == Status.SAVED_RECOVERY_DEGRADED
	)

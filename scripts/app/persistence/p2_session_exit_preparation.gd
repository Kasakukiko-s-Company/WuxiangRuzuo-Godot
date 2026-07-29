class_name P2SessionExitPreparation
extends RefCounted

enum Status {
	READY_SAVED,
	READY_READ_ONLY,
	BLOCKED,
}

var status: Status
var message: String


static func ready_saved() -> P2SessionExitPreparation:
	var result := P2SessionExitPreparation.new()
	result.status = Status.READY_SAVED
	return result


static func ready_read_only() -> P2SessionExitPreparation:
	var result := P2SessionExitPreparation.new()
	result.status = Status.READY_READ_ONLY
	return result


static func blocked(failure_message: String) -> P2SessionExitPreparation:
	var result := P2SessionExitPreparation.new()
	result.status = Status.BLOCKED
	result.message = failure_message
	return result


func is_ready() -> bool:
	return (
		status == Status.READY_SAVED
		or status == Status.READY_READ_ONLY
	)

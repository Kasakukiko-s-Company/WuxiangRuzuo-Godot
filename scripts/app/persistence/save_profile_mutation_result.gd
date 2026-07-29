class_name SaveProfileMutationResult
extends RefCounted

enum Status {
	APPLIED,
	PARTIAL,
	REJECTED,
	STORAGE_FAILED,
}

var status: Status
var message: String


static func applied() -> SaveProfileMutationResult:
	var result := SaveProfileMutationResult.new()
	result.status = Status.APPLIED
	return result


static func partial(failure_message: String) -> SaveProfileMutationResult:
	var result := SaveProfileMutationResult.new()
	result.status = Status.PARTIAL
	result.message = failure_message
	return result


static func rejected(failure_message: String) -> SaveProfileMutationResult:
	var result := SaveProfileMutationResult.new()
	result.status = Status.REJECTED
	result.message = failure_message
	return result


static func storage_failed(failure_message: String) -> SaveProfileMutationResult:
	var result := SaveProfileMutationResult.new()
	result.status = Status.STORAGE_FAILED
	result.message = failure_message
	return result


func is_applied() -> bool:
	return status == Status.APPLIED

class_name SaveReadResult
extends RefCounted

enum Status {
	FOUND,
	MISSING,
	FAILED,
}

var status: Status
var payload: String
var message: String


static func found(found_payload: String) -> SaveReadResult:
	var result := SaveReadResult.new()
	result.status = Status.FOUND
	result.payload = found_payload
	return result


static func missing() -> SaveReadResult:
	var result := SaveReadResult.new()
	result.status = Status.MISSING
	return result


static func failed(failure_message: String) -> SaveReadResult:
	var result := SaveReadResult.new()
	result.status = Status.FAILED
	result.message = failure_message
	return result

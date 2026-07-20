class_name SaveWriteResult
extends RefCounted

enum Status {
	WRITTEN,
	FAILED,
}

var status: Status
var message: String


static func written() -> SaveWriteResult:
	var result := SaveWriteResult.new()
	result.status = Status.WRITTEN
	return result


static func failed(failure_message: String) -> SaveWriteResult:
	var result := SaveWriteResult.new()
	result.status = Status.FAILED
	result.message = failure_message
	return result

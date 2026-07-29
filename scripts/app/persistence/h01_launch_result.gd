class_name H01LaunchResult
extends RefCounted

enum Status {
	READY,
	BLOCKED,
}

var status: Status
var pilot: P2EstatePilot
var message: String


static func ready(ready_pilot: P2EstatePilot) -> H01LaunchResult:
	var result := H01LaunchResult.new()
	result.status = Status.READY
	result.pilot = ready_pilot
	return result


static func blocked(failure_message: String) -> H01LaunchResult:
	var result := H01LaunchResult.new()
	result.status = Status.BLOCKED
	result.message = failure_message
	return result


func is_ready() -> bool:
	return status == Status.READY and pilot != null

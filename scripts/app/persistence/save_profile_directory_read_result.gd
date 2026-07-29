class_name SaveProfileDirectoryReadResult
extends RefCounted

enum Status {
	MISSING,
	FOUND,
	RECOVERED,
	UNAVAILABLE,
}

var status: Status = Status.MISSING
var profile_id: StringName
var advisory: String


static func found(
	recent_profile_id: StringName,
	read_advisory: String = "",
) -> SaveProfileDirectoryReadResult:
	var result := SaveProfileDirectoryReadResult.new()
	result.status = Status.FOUND
	result.profile_id = recent_profile_id
	result.advisory = read_advisory
	return result


static func recovered(
	recent_profile_id: StringName,
	read_advisory: String,
) -> SaveProfileDirectoryReadResult:
	var result := SaveProfileDirectoryReadResult.new()
	result.status = Status.RECOVERED
	result.profile_id = recent_profile_id
	result.advisory = read_advisory
	return result


static func missing(
	read_advisory: String = "",
) -> SaveProfileDirectoryReadResult:
	var result := SaveProfileDirectoryReadResult.new()
	result.status = Status.MISSING
	result.profile_id = &""
	result.advisory = read_advisory
	return result


static func unavailable(
	read_advisory: String,
) -> SaveProfileDirectoryReadResult:
	var result := SaveProfileDirectoryReadResult.new()
	result.status = Status.UNAVAILABLE
	result.profile_id = &""
	result.advisory = read_advisory
	return result


func requires_cleanup() -> bool:
	return status == Status.UNAVAILABLE

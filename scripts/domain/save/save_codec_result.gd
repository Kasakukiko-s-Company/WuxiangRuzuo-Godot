class_name SaveCodecResult
extends RefCounted

enum Status {
	ENCODED,
	DECODED,
	INVALID_JSON,
	UNSUPPORTED_SCHEMA,
	INVALID_DATA,
}

var status: Status
var payload: String
var snapshot: SaveSnapshot
var issues: Array[DataValidationIssue] = []


static func encoded(encoded_payload: String) -> SaveCodecResult:
	var result := SaveCodecResult.new()
	result.status = Status.ENCODED
	result.payload = encoded_payload
	return result


static func decoded(decoded_snapshot: SaveSnapshot) -> SaveCodecResult:
	var result := SaveCodecResult.new()
	result.status = Status.DECODED
	result.snapshot = decoded_snapshot
	return result


static func failed(
	failure_status: Status,
	validation_issues: Array[DataValidationIssue],
) -> SaveCodecResult:
	var result := SaveCodecResult.new()
	result.status = failure_status
	result.issues = validation_issues
	return result


func describe_issues() -> String:
	var descriptions: PackedStringArray = []
	for issue: DataValidationIssue in issues:
		descriptions.append(issue.describe())
	return "\n".join(descriptions)

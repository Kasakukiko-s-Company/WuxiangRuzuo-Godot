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
var source_schema_version: int = 0
var requires_resave: bool = false
var issues: Array[DataValidationIssue] = []


static func encoded(encoded_payload: String) -> SaveCodecResult:
	var result := SaveCodecResult.new()
	result.status = Status.ENCODED
	result.payload = encoded_payload
	return result


static func decoded(
	decoded_snapshot: SaveSnapshot,
	decoded_schema_version: int = SaveSnapshot.SCHEMA_VERSION,
) -> SaveCodecResult:
	var result := SaveCodecResult.new()
	result.status = Status.DECODED
	result.snapshot = decoded_snapshot
	result.source_schema_version = decoded_schema_version
	result.requires_resave = (
		decoded_schema_version != SaveSnapshot.SCHEMA_VERSION
	)
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

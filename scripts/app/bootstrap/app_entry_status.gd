class_name AppEntryStatus
extends RefCounted

enum Availability {
	UNKNOWN,
	AVAILABLE,
	BLOCKED,
}

var entry_id: StringName:
	get:
		return _entry_id
	set(_attempted_value):
		push_error("AppEntryStatus.entry_id is read-only")

var availability: Availability:
	get:
		return _availability
	set(_attempted_value):
		push_error("AppEntryStatus.availability is read-only")

var issues: Array[DataValidationIssue]:
	get:
		return _issues.duplicate()
	set(_attempted_value):
		push_error("AppEntryStatus.issues is read-only")

var _entry_id: StringName
var _availability: Availability = Availability.UNKNOWN
var _issues: Array[DataValidationIssue] = []


static func available(status_entry_id: StringName) -> AppEntryStatus:
	return AppEntryStatus.new(
		status_entry_id,
		Availability.AVAILABLE,
		[],
	)


static func blocked(
	status_entry_id: StringName,
	status_issues: Array[DataValidationIssue],
) -> AppEntryStatus:
	assert(not status_issues.is_empty(), "blocked entry status requires issues")
	return AppEntryStatus.new(
		status_entry_id,
		Availability.BLOCKED,
		status_issues,
	)


static func unknown(status_entry_id: StringName) -> AppEntryStatus:
	return AppEntryStatus.new(
		status_entry_id,
		Availability.UNKNOWN,
		[],
	)


func _init(
	status_entry_id: StringName,
	status_availability: Availability,
	status_issues: Array[DataValidationIssue],
) -> void:
	assert(not status_entry_id.is_empty(), "entry status requires a stable ID")
	_entry_id = status_entry_id
	_availability = status_availability
	_issues = status_issues.duplicate()


func is_available() -> bool:
	return _availability == Availability.AVAILABLE


func describe_issues() -> String:
	if _issues.is_empty():
		return "no issues"
	var descriptions: PackedStringArray = []
	for issue: DataValidationIssue in _issues:
		descriptions.append(issue.describe())
	return "; ".join(descriptions)

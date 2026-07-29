class_name GameSaveLoadResult
extends RefCounted

enum Status {
	LOADED,
	MISSING,
	UNAVAILABLE,
}

enum Source {
	NONE,
	CURRENT,
	CURRENT_PREVIOUS,
	PROTECTED,
	PROTECTED_PREVIOUS,
}

enum UnavailableReason {
	NONE,
	CORRUPT,
	UNSUPPORTED_SCHEMA,
	INCOMPATIBLE,
	READ_FAILED,
}

var status: Status
var source: Source = Source.NONE
var state: P2PersistentState
var source_schema_version: int = 0
var requires_resave: bool = false
var saving_allowed: bool = true
var message: String
var saved_at: String
var unavailable_reason: UnavailableReason = UnavailableReason.NONE


static func loaded(
	loaded_state: P2PersistentState,
	loaded_source: Source,
	loaded_schema_version: int,
	loaded_requires_resave: bool,
	load_message: String = "",
	load_saving_allowed: bool = true,
	load_saved_at: String = "",
) -> GameSaveLoadResult:
	var result := GameSaveLoadResult.new()
	result.status = Status.LOADED
	result.source = loaded_source
	result.state = loaded_state.snapshot()
	result.source_schema_version = loaded_schema_version
	result.requires_resave = loaded_requires_resave
	result.message = load_message
	result.saving_allowed = load_saving_allowed
	result.saved_at = load_saved_at
	return result


static func missing() -> GameSaveLoadResult:
	var result := GameSaveLoadResult.new()
	result.status = Status.MISSING
	return result


static func unavailable(
	failure_message: String,
	failure_reason: UnavailableReason = UnavailableReason.CORRUPT,
) -> GameSaveLoadResult:
	var result := GameSaveLoadResult.new()
	result.status = Status.UNAVAILABLE
	result.message = failure_message
	result.unavailable_reason = failure_reason
	return result


func is_loaded() -> bool:
	return status == Status.LOADED

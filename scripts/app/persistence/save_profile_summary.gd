class_name SaveProfileSummary
extends RefCounted

enum Status {
	EMPTY,
	READY,
	RECOVERY_AVAILABLE,
	CORRUPT,
	UNSUPPORTED_SCHEMA,
	INCOMPATIBLE,
	READ_FAILED,
}

var profile_id: StringName
var status: Status
var world_day: int
var map_id: StringName
var recovery_source: GameSaveLoadResult.Source
var message: String
var saved_at: String


func _init(
	summary_profile_id: StringName,
	summary_status: Status,
	summary_world_day: int = 0,
	summary_map_id: StringName = &"",
	summary_recovery_source: GameSaveLoadResult.Source = (
		GameSaveLoadResult.Source.NONE
	),
	summary_message: String = "",
	summary_saved_at: String = "",
) -> void:
	assert(
		SaveSnapshot.PROFILE_IDS.has(summary_profile_id),
		"profile summary requires a registered profile ID",
	)
	assert(
		summary_world_day >= 0,
		"profile summary world day cannot be negative",
	)
	profile_id = summary_profile_id
	status = summary_status
	world_day = summary_world_day
	map_id = summary_map_id
	recovery_source = summary_recovery_source
	message = summary_message
	saved_at = summary_saved_at


func is_launchable() -> bool:
	return status in [Status.EMPTY, Status.READY, Status.RECOVERY_AVAILABLE]


func is_empty() -> bool:
	return status == Status.EMPTY

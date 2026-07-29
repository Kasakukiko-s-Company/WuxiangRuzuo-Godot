class_name ProfileScreenState
extends RefCounted

var roster: SaveProfileRosterSnapshot
var selected_profile_id: StringName
var pending_delete_profile_id: StringName
var message: String


func _init(
	screen_roster: SaveProfileRosterSnapshot,
	screen_selected_profile_id: StringName,
	screen_pending_delete_profile_id: StringName = &"",
	screen_message: String = "",
) -> void:
	assert(screen_roster != null, "profile screen state requires a roster")
	assert(
		SaveSnapshot.PROFILE_IDS.has(screen_selected_profile_id),
		"profile screen state requires a registered selection",
	)
	roster = screen_roster
	selected_profile_id = screen_selected_profile_id
	pending_delete_profile_id = screen_pending_delete_profile_id
	message = screen_message


func selected_profile() -> SaveProfileSummary:
	return roster.profile(selected_profile_id)


func can_launch() -> bool:
	var summary := selected_profile()
	return (
		not is_delete_confirmation_open()
		and summary != null
		and summary.is_launchable()
	)


func can_delete() -> bool:
	var summary := selected_profile()
	return (
		not is_delete_confirmation_open()
		and summary != null
		and not summary.is_empty()
	)


func is_delete_confirmation_open() -> bool:
	return not pending_delete_profile_id.is_empty()

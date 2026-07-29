class_name SaveProfileRosterSnapshot
extends RefCounted

var profiles: Array[SaveProfileSummary]
var recent_profile_id: StringName
var advisory: String


func _init(
	snapshot_profiles: Array[SaveProfileSummary],
	snapshot_recent_profile_id: StringName = &"",
	snapshot_advisory: String = "",
) -> void:
	assert(
		snapshot_profiles.size() == SaveSnapshot.PROFILE_IDS.size(),
		"profile roster snapshot requires every registered profile",
	)
	profiles = snapshot_profiles.duplicate()
	recent_profile_id = snapshot_recent_profile_id
	advisory = snapshot_advisory


func profile(profile_id: StringName) -> SaveProfileSummary:
	for summary: SaveProfileSummary in profiles:
		if summary.profile_id == profile_id:
			return summary
	return null


func default_profile_id() -> StringName:
	var recent := profile(recent_profile_id)
	## A broken recent profile remains selected so the player sees its failure
	## instead of silently entering another profile.
	if recent != null:
		return recent.profile_id
	for summary: SaveProfileSummary in profiles:
		if summary.is_launchable():
			return summary.profile_id
	return profiles[0].profile_id

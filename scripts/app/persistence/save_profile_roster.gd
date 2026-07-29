class_name SaveProfileRoster
extends RefCounted

const DIRECTORY_SCHEMA_VERSION: int = 1
const DIRECTORY_SLOT_ID: StringName = &"profile-directory"

var _storage: SaveService
var _game_catalog: GameCatalog
var _estate_catalog: EstateMapCatalog
var _expected_map_id: StringName


func _init(
	storage: SaveService,
	game_catalog: GameCatalog,
	estate_catalog: EstateMapCatalog,
	expected_map_id: StringName,
) -> void:
	assert(storage != null, "profile roster requires a SaveService")
	assert(game_catalog != null, "profile roster requires a GameCatalog")
	assert(estate_catalog != null, "profile roster requires an EstateMapCatalog")
	assert(
		estate_catalog.get_map(expected_map_id) != null,
		"profile roster requires a registered estate map",
	)
	_storage = storage
	_game_catalog = game_catalog
	_estate_catalog = estate_catalog
	_expected_map_id = expected_map_id


## Profile inspection reuses GameSaveModule's candidate ordering without invoking
## its quarantine/write behavior. Refreshing title UI is strictly read-only.
func refresh() -> SaveProfileRosterSnapshot:
	var profiles: Array[SaveProfileSummary] = []
	for profile_id: StringName in SaveSnapshot.PROFILE_IDS:
		var load_result := GameSaveModule.new(
			_storage,
			_game_catalog,
			_estate_catalog,
			profile_id,
			_expected_map_id,
		).inspect()
		profiles.append(_summary(profile_id, load_result))
	var recent := _read_recent_profile()
	return SaveProfileRosterSnapshot.new(
		profiles,
		recent.profile_id,
		recent.advisory,
	)


## Recent-profile metadata is intentionally independent of SaveSnapshot schema
## and is committed only after a profile launch has succeeded.
func record_recent(profile_id: StringName) -> SaveProfileMutationResult:
	if not SaveSnapshot.PROFILE_IDS.has(profile_id):
		return SaveProfileMutationResult.rejected(
			"recent profile must be a registered profile ID"
		)
	var payload := JSON.stringify({
		"schemaVersion": DIRECTORY_SCHEMA_VERSION,
		"lastPlayedProfileId": String(profile_id),
	})
	var write_result := _storage.write(DIRECTORY_SLOT_ID, payload)
	if write_result.status != SaveWriteResult.Status.WRITTEN:
		return SaveProfileMutationResult.storage_failed(write_result.message)
	var verification := _storage.read(DIRECTORY_SLOT_ID)
	if verification.status != SaveReadResult.Status.FOUND:
		return SaveProfileMutationResult.storage_failed(
			"recent-profile metadata could not be read back"
		)
	var decoded := _decode_recent_profile(verification.payload)
	if decoded.profile_id != profile_id:
		return SaveProfileMutationResult.storage_failed(
			"recent-profile metadata failed read-back validation"
		)
	return SaveProfileMutationResult.applied()


## SaveService is atomic per logical key, not across the profile namespace.
## Evidence and protected keys are removed first; current is deliberately last
## so any partial failure retains the most useful playable checkpoint.
func delete_profile(profile_id: StringName) -> SaveProfileMutationResult:
	if not SaveSnapshot.PROFILE_IDS.has(profile_id):
		return SaveProfileMutationResult.rejected(
			"deleted profile must be a registered profile ID"
		)
	for slot_id: StringName in _profile_slot_ids(profile_id):
		var remove_result := _storage.remove(slot_id)
		if remove_result.status != SaveWriteResult.Status.WRITTEN:
			return SaveProfileMutationResult.partial(
				"profile deletion stopped at %s: %s"
				% [slot_id, remove_result.message]
			)
		var current := _storage.read(slot_id)
		var previous := _storage.read_previous(slot_id)
		if (
			current.status != SaveReadResult.Status.MISSING
			or previous.status != SaveReadResult.Status.MISSING
		):
			return SaveProfileMutationResult.partial(
				"profile deletion could not verify %s" % slot_id
			)
	var recent := _read_recent_profile()
	if recent.profile_id == profile_id or recent.requires_cleanup():
		var metadata_remove := _storage.remove(DIRECTORY_SLOT_ID)
		if metadata_remove.status != SaveWriteResult.Status.WRITTEN:
			return SaveProfileMutationResult.partial(
				"profile data was deleted but recent metadata remains: %s"
				% metadata_remove.message
			)
		if (
			_storage.read(DIRECTORY_SLOT_ID).status
			!= SaveReadResult.Status.MISSING
			or _storage.read_previous(DIRECTORY_SLOT_ID).status
			!= SaveReadResult.Status.MISSING
		):
			return SaveProfileMutationResult.partial(
				"profile data was deleted but metadata removal was not verified"
			)
	return SaveProfileMutationResult.applied()


func _summary(
	profile_id: StringName,
	load_result: GameSaveLoadResult,
) -> SaveProfileSummary:
	if load_result.status == GameSaveLoadResult.Status.MISSING:
		return SaveProfileSummary.new(
			profile_id,
			SaveProfileSummary.Status.EMPTY,
		)
	if load_result.status == GameSaveLoadResult.Status.UNAVAILABLE:
		return SaveProfileSummary.new(
			profile_id,
			_summary_unavailable_status(load_result.unavailable_reason),
			0,
			&"",
			GameSaveLoadResult.Source.NONE,
			load_result.message,
		)
	var status := SaveProfileSummary.Status.READY
	if load_result.source != GameSaveLoadResult.Source.CURRENT:
		status = SaveProfileSummary.Status.RECOVERY_AVAILABLE
	return SaveProfileSummary.new(
		profile_id,
		status,
		load_result.state.farming_session.world_day,
		load_result.state.map_id,
		load_result.source,
		load_result.message,
		load_result.saved_at,
	)


func _summary_unavailable_status(
	reason: GameSaveLoadResult.UnavailableReason,
) -> SaveProfileSummary.Status:
	if reason == GameSaveLoadResult.UnavailableReason.UNSUPPORTED_SCHEMA:
		return SaveProfileSummary.Status.UNSUPPORTED_SCHEMA
	if reason == GameSaveLoadResult.UnavailableReason.INCOMPATIBLE:
		return SaveProfileSummary.Status.INCOMPATIBLE
	if reason == GameSaveLoadResult.UnavailableReason.READ_FAILED:
		return SaveProfileSummary.Status.READ_FAILED
	return SaveProfileSummary.Status.CORRUPT


func _read_recent_profile() -> SaveProfileDirectoryReadResult:
	var current := _storage.read(DIRECTORY_SLOT_ID)
	if current.status == SaveReadResult.Status.FOUND:
		var decoded := _decode_recent_profile(current.payload)
		if not decoded.profile_id.is_empty():
			return decoded
	var previous := _storage.read_previous(DIRECTORY_SLOT_ID)
	if previous.status == SaveReadResult.Status.FOUND:
		var decoded_previous := _decode_recent_profile(previous.payload)
		if not decoded_previous.profile_id.is_empty():
			return SaveProfileDirectoryReadResult.recovered(
				decoded_previous.profile_id,
				"recent-profile metadata recovered from its previous version"
			)
	if (
		current.status == SaveReadResult.Status.MISSING
		and previous.status == SaveReadResult.Status.MISSING
	):
		return SaveProfileDirectoryReadResult.missing()
	return SaveProfileDirectoryReadResult.unavailable(
		"recent-profile metadata is unavailable; profile-1 is selected"
	)


func _decode_recent_profile(
	payload: String,
) -> SaveProfileDirectoryReadResult:
	var json := JSON.new()
	if json.parse(payload) != OK or not json.data is Dictionary:
		return SaveProfileDirectoryReadResult.unavailable(
			"invalid metadata JSON"
		)
	var document := json.data as Dictionary
	var schema: Variant = document.get("schemaVersion")
	var profile_value: Variant = document.get("lastPlayedProfileId")
	if (
		not _is_integer(schema)
		or int(schema) != DIRECTORY_SCHEMA_VERSION
		or not profile_value is String
	):
		return SaveProfileDirectoryReadResult.unavailable(
			"invalid metadata schema"
		)
	var profile_id := StringName(profile_value)
	if not SaveSnapshot.PROFILE_IDS.has(profile_id):
		return SaveProfileDirectoryReadResult.unavailable(
			"invalid recent profile ID"
		)
	return SaveProfileDirectoryReadResult.found(profile_id)


func _is_integer(value: Variant) -> bool:
	return (
		value is int
		or (value is float and float(value) == floorf(float(value)))
	)


func _profile_slot_ids(profile_id: StringName) -> Array[StringName]:
	var prefix := String(profile_id)
	return [
		StringName("%s.quarantine-primary" % prefix),
		StringName("%s.quarantine-previous" % prefix),
		StringName("%s.protected.quarantine-primary" % prefix),
		StringName("%s.protected.quarantine-previous" % prefix),
		StringName("%s.protected" % prefix),
		profile_id,
	]

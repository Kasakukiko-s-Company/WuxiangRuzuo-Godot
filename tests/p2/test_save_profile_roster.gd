extends SceneTree


class MemorySaveService extends SaveService:
	var payloads: Dictionary[StringName, String] = {}
	var previous_payloads: Dictionary[StringName, String] = {}
	var write_count: int = 0
	var remove_count: int = 0
	var removed_slot_ids: Array[StringName] = []
	var failed_remove_slot: StringName = &""
	var failed_read_slot: StringName = &""


	func read(slot_id: StringName) -> SaveReadResult:
		if slot_id == failed_read_slot:
			return SaveReadResult.failed("injected read failure")
		if not payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(payloads[slot_id])


	func read_previous(slot_id: StringName) -> SaveReadResult:
		if not previous_payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(previous_payloads[slot_id])


	func write(slot_id: StringName, payload: String) -> SaveWriteResult:
		write_count += 1
		payloads[slot_id] = payload
		return SaveWriteResult.written()


	func remove(slot_id: StringName) -> SaveWriteResult:
		remove_count += 1
		removed_slot_ids.append(slot_id)
		if slot_id == failed_remove_slot:
			return SaveWriteResult.failed("injected remove failure")
		payloads.erase(slot_id)
		previous_payloads.erase(slot_id)
		return SaveWriteResult.written()


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_result := CatalogFileLoader.load_catalog()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	_check(
		game_result.is_valid() and estate_result.is_valid(),
		"profile roster test loads validated catalogs",
	)
	if not game_result.is_valid() or not estate_result.is_valid():
		_finish()
		return

	var storage := MemorySaveService.new()
	var roster := SaveProfileRoster.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"home_h01_open_meadow",
	)
	var snapshot := roster.refresh()
	_check(
		snapshot.profiles.size() == 3,
		"profile roster always exposes exactly three registered slots",
	)
	_check(
		snapshot.profile(&"profile-1").status
		== SaveProfileSummary.Status.EMPTY
		and snapshot.profile(&"profile-2").status
		== SaveProfileSummary.Status.EMPTY
		and snapshot.profile(&"profile-3").status
		== SaveProfileSummary.Status.EMPTY,
		"missing payloads are represented as three launchable empty slots",
	)
	_check(
		snapshot.default_profile_id() == &"profile-1",
		"the first launchable slot is the deterministic default without recency",
	)
	var recent_result := roster.record_recent(&"profile-2")
	var recent_snapshot := roster.refresh()
	_check(
		recent_result.status == SaveProfileMutationResult.Status.APPLIED
		and recent_snapshot.recent_profile_id == &"profile-2"
		and recent_snapshot.default_profile_id() == &"profile-2",
		"a verified metadata write makes the last launched profile the default",
	)
	_check(
		storage.payloads.has(&"profile-directory")
		and not storage.payloads.has(&"profile-1.metadata")
		and not storage.payloads.has(&"profile-2.metadata")
		and not storage.payloads.has(&"profile-3.metadata"),
		"recent-profile metadata remains separate from all three save payloads",
	)
	var profile_two_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-2",
		&"home_h01_open_meadow",
	)
	profile_two_module.load()
	var profile_two_state := _state_at(game_result.catalog, 4)
	profile_two_module.save(profile_two_state, true)
	var ready_snapshot := roster.refresh()
	var ready_summary := ready_snapshot.profile(&"profile-2")
	_check(
		ready_summary.status == SaveProfileSummary.Status.READY
		and ready_summary.world_day == 4
		and ready_summary.map_id == &"home_h01_open_meadow"
		and not ready_summary.saved_at.is_empty(),
		"a valid current checkpoint exposes day, map and save time",
	)

	var protected_payload: String = storage.payloads[&"profile-2.protected"]
	storage.payloads[&"profile-2"] = "{corrupt-current"
	storage.write_count = 0
	storage.remove_count = 0
	var recovery_snapshot := roster.refresh()
	var recovery_summary := recovery_snapshot.profile(&"profile-2")
	_check(
		recovery_summary.status
		== SaveProfileSummary.Status.RECOVERY_AVAILABLE
		and recovery_summary.recovery_source
		== GameSaveLoadResult.Source.PROTECTED
		and recovery_summary.world_day == 4,
		"a damaged current checkpoint exposes its valid protected recovery",
	)
	_check(
		storage.write_count == 0
		and storage.remove_count == 0
		and not storage.payloads.has(&"profile-2.quarantine-primary"),
		"refreshing profile summaries never writes, removes or quarantines",
	)

	storage.payloads[&"profile-2.protected"] = "{corrupt-protected"
	var corrupt_snapshot := roster.refresh()
	var corrupt_summary := corrupt_snapshot.profile(&"profile-2")
	_check(
		corrupt_snapshot.default_profile_id() == &"profile-2"
		and corrupt_summary.status == SaveProfileSummary.Status.CORRUPT
		and not corrupt_summary.is_launchable()
		and not corrupt_summary.message.is_empty(),
		"a damaged recent profile remains selected with an explicit block reason",
	)
	storage.payloads[&"profile-2.protected"] = protected_payload
	storage.payloads[&"profile-3"] = '{"schemaVersion":99}'
	_check(
		roster.refresh().profile(&"profile-3").status
		== SaveProfileSummary.Status.UNSUPPORTED_SCHEMA,
		"unsupported save schema is distinct from a corrupt payload",
	)
	storage.failed_read_slot = &"profile-3"
	_check(
		roster.refresh().profile(&"profile-3").status
		== SaveProfileSummary.Status.READ_FAILED,
		"storage read failure is distinct from codec rejection",
	)
	storage.failed_read_slot = &""
	storage.payloads.erase(&"profile-3")
	storage.payloads[&"profile-directory"] = "{corrupt-metadata"
	var metadata_failure := roster.refresh()
	_check(
		metadata_failure.recent_profile_id.is_empty()
		and metadata_failure.default_profile_id() == &"profile-1"
		and not metadata_failure.advisory.is_empty(),
		"corrupt recent metadata falls back visibly without blocking profiles",
	)
	var profile_two_logical_slots: Array[StringName] = [
		&"profile-2",
		&"profile-2.protected",
		&"profile-2.quarantine-primary",
		&"profile-2.quarantine-previous",
		&"profile-2.protected.quarantine-primary",
		&"profile-2.protected.quarantine-previous",
	]
	for slot_id: StringName in profile_two_logical_slots:
		storage.payloads[slot_id] = "evidence-%s" % slot_id
		storage.previous_payloads[slot_id] = "previous-%s" % slot_id
	var profile_one_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	profile_one_module.load()
	profile_one_module.save(_state_at(game_result.catalog, 2))
	var other_profile_payload: String = storage.payloads[&"profile-1"]
	roster.record_recent(&"profile-2")
	storage.removed_slot_ids = []
	var delete_result := roster.delete_profile(&"profile-2")
	var deleted_snapshot := roster.refresh()
	var every_target_removed := true
	for slot_id: StringName in profile_two_logical_slots:
		every_target_removed = (
			every_target_removed
			and storage.read(slot_id).status == SaveReadResult.Status.MISSING
			and storage.read_previous(slot_id).status
			== SaveReadResult.Status.MISSING
		)
	_check(
		delete_result.status == SaveProfileMutationResult.Status.APPLIED
		and every_target_removed
		and storage.removed_slot_ids.back() == &"profile-directory"
		and storage.removed_slot_ids[
			storage.removed_slot_ids.size() - 2
		] == &"profile-2",
		"confirmed deletion verifies every profile key and removes current last",
	)
	_check(
		storage.payloads.get(&"profile-1", "") == other_profile_payload
		and deleted_snapshot.profile(&"profile-2").is_empty()
		and deleted_snapshot.recent_profile_id.is_empty()
		and deleted_snapshot.default_profile_id() == &"profile-1",
		"deleting the recent profile preserves other profiles and clears recency",
	)
	var profile_three_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-3",
		&"home_h01_open_meadow",
	)
	profile_three_module.load()
	profile_three_module.save(_state_at(game_result.catalog, 5), true)
	var profile_three_current: String = storage.payloads[&"profile-3"]
	storage.payloads[&"profile-3.quarantine-primary"] = "evidence"
	storage.failed_remove_slot = &"profile-3.protected"
	storage.removed_slot_ids = []
	var partial_delete := roster.delete_profile(&"profile-3")
	_check(
		partial_delete.status == SaveProfileMutationResult.Status.PARTIAL
		and storage.payloads.get(&"profile-3", "") == profile_three_current
		and not storage.removed_slot_ids.has(&"profile-3")
		and roster.refresh().profile(&"profile-3").is_launchable(),
		"a partial auxiliary-key failure stops before current and stays explicit",
	)
	storage.failed_remove_slot = &""
	storage.failed_read_slot = &"profile-directory"
	storage.payloads[&"profile-directory"] = (
		'{"schemaVersion":1,"lastPlayedProfileId":"profile-1"}'
	)
	storage.removed_slot_ids = []
	var unreadable_directory_delete := roster.delete_profile(&"profile-1")
	_check(
		unreadable_directory_delete.status
		== SaveProfileMutationResult.Status.PARTIAL
		and storage.removed_slot_ids.has(&"profile-directory")
		and not storage.payloads.has(&"profile-directory"),
		"unreadable recent metadata is cleaned explicitly and cannot yield a false success",
	)

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _state_at(
	game_catalog: GameCatalog,
	world_day: int,
) -> P2PersistentState:
	return P2PersistentState.new(
		&"home_h01_open_meadow",
		FarmingSessionState.new(
			FarmingTransactionState.new(
				FarmState.create_empty(&"home_h01_open_meadow"),
				InventoryState.create_empty(),
			),
			world_day,
		),
		Vector2(640.0, 480.0),
		Vector2i.DOWN,
		&"home_safe_spawn_meadow",
		5,
		EstateMapState.new(&"spring", &"reclaimed", &"normal"),
		DailyResourceClaims.create_empty(),
	)


func _finish() -> void:
	if _failures == 0:
		print("P2_SAVE_PROFILE_ROSTER_OK")
		quit(0)
		return
	push_error("P2 save-profile roster failed: %d check(s)" % _failures)
	quit(1)

extends SceneTree

const TEST_DIRECTORY: String = "res://builds/test-profile-roster"
const PROFILE_TWO_SLOTS: Array[StringName] = [
	&"profile-2",
	&"profile-2.protected",
	&"profile-2.quarantine-primary",
	&"profile-2.quarantine-previous",
	&"profile-2.protected.quarantine-primary",
	&"profile-2.protected.quarantine-previous",
]

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var base_directory := ProjectSettings.globalize_path(TEST_DIRECTORY)
	var storage: SaveService = AtomicFileSaveAdapter.new(base_directory)
	_cleanup(storage, base_directory)
	_check(
		base_directory.replace("\\", "/").begins_with("D:/"),
		"profile roster integration writes only inside the D-drive project",
	)
	var game_result := CatalogFileLoader.load_catalog()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	if not game_result.is_valid() or not estate_result.is_valid():
		_check(false, "profile roster integration loads validated catalogs")
		_finish(storage, base_directory)
		return
	var profile_one := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	profile_one.load()
	profile_one.save(_state_at(game_result.catalog, 2))
	var profile_one_payload := storage.read(&"profile-1").payload

	var profile_two := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-2",
		&"home_h01_open_meadow",
	)
	profile_two.load()
	profile_two.save(_state_at(game_result.catalog, 3), true)
	profile_two.save(_state_at(game_result.catalog, 4), true)
	for slot_id: StringName in PROFILE_TWO_SLOTS:
		if slot_id in [&"profile-2", &"profile-2.protected"]:
			continue
		storage.write(slot_id, "evidence-one-%s" % slot_id)
		storage.write(slot_id, "evidence-two-%s" % slot_id)
	var roster := SaveProfileRoster.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"home_h01_open_meadow",
	)
	roster.record_recent(&"profile-2")
	roster.record_recent(&"profile-2")
	var deletion := roster.delete_profile(&"profile-2")
	var all_missing := true
	for slot_id: StringName in PROFILE_TWO_SLOTS + [
		SaveProfileRoster.DIRECTORY_SLOT_ID,
	]:
		all_missing = (
			all_missing
			and storage.read(slot_id).status == SaveReadResult.Status.MISSING
			and storage.read_previous(slot_id).status
			== SaveReadResult.Status.MISSING
		)
	var residual_files := PackedStringArray()
	if DirAccess.dir_exists_absolute(base_directory):
		for file_name: String in DirAccess.get_files_at(base_directory):
			if (
				file_name.begins_with("profile-2")
				or file_name.begins_with("profile-directory")
			):
				residual_files.append(file_name)
	_check(
		deletion.status == SaveProfileMutationResult.Status.APPLIED
		and all_missing
		and residual_files.is_empty(),
		"confirmed deletion removes all current/previous/temp physical files",
	)
	_check(
		storage.read(&"profile-1").status == SaveReadResult.Status.FOUND
		and storage.read(&"profile-1").payload == profile_one_payload,
		"real adapter deletion preserves the other profile byte-for-byte",
	)
	_finish(storage, base_directory)


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


func _cleanup(storage: SaveService, base_directory: String) -> void:
	for slot_id: StringName in PROFILE_TWO_SLOTS + [
		&"profile-1",
		SaveProfileRoster.DIRECTORY_SLOT_ID,
	]:
		storage.remove(slot_id)
	if DirAccess.dir_exists_absolute(base_directory):
		DirAccess.remove_absolute(base_directory)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish(storage: SaveService, base_directory: String) -> void:
	_cleanup(storage, base_directory)
	if _failures == 0:
		print("P2_SAVE_PROFILE_ROSTER_ATOMIC_OK")
		quit(0)
		return
	push_error(
		"P2 save-profile roster atomic integration failed: %d check(s)"
		% _failures
	)
	quit(1)

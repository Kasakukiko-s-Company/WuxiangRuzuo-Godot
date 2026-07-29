extends SceneTree

const AtomicFileSaveAdapterScript = preload(
	"res://scripts/persistence/atomic_file_save_adapter.gd"
)

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_result := CatalogFileLoader.load_catalog()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	_check(
		game_result.is_valid() and estate_result.is_valid(),
		"atomic recovery integration loads both validated catalogs",
	)
	if not game_result.is_valid() or not estate_result.is_valid():
		_finish()
		return
	var base_directory := ProjectSettings.globalize_path(
		"res://builds/test-game-save-atomic"
	)
	var storage: SaveService = AtomicFileSaveAdapterScript.new(
		base_directory
	)
	_cleanup(storage)
	var state := _state(game_result.catalog)
	var initial_module := _module(
		storage,
		game_result.catalog,
		estate_result.catalog,
	)
	initial_module.load()
	_check(
		initial_module.save(state).status == GameSaveCommitResult.Status.SAVED,
		"an initial valid H01 checkpoint is written through the real adapter",
	)
	var newer_state := _state_at(
		game_result.catalog,
		4,
		Vector2(672.0, 512.0),
	)
	initial_module.save(newer_state)
	var initial_target_path := base_directory.path_join("profile-1.json")
	var initial_rollback_path := initial_target_path + ".rollback"
	var initial_temporary_path := initial_target_path + ".tmp"
	DirAccess.rename_absolute(initial_target_path, initial_rollback_path)
	_write_raw(initial_temporary_path, "{\"interrupted\":true}")
	var normal_interruption_module := _module(
		storage,
		game_result.catalog,
		estate_result.catalog,
	)
	var normal_interruption := normal_interruption_module.load()
	_check(
		normal_interruption.status == GameSaveLoadResult.Status.LOADED
		and normal_interruption.source == GameSaveLoadResult.Source.CURRENT
		and normal_interruption.state.farming_session.world_day == 4
		and normal_interruption.state.player_position
		== Vector2(672.0, 512.0),
		"a normal pre-promote crash restores the newest valid rollback",
	)
	normal_interruption_module.save(newer_state)
	storage.write(&"profile-1", "{corrupt-current")
	var recovered_module := _module(
		storage,
		game_result.catalog,
		estate_result.catalog,
	)
	var recovered := recovered_module.load()
	_check(
		recovered.status == GameSaveLoadResult.Status.LOADED
		and recovered.source
		== GameSaveLoadResult.Source.CURRENT_PREVIOUS
		and recovered.saving_allowed,
		"a corrupt target recovers from the real adapter previous candidate",
	)
	_check(
		recovered_module.save(state).status
		== GameSaveCommitResult.Status.SAVED,
		"the recovered session can commit a new valid current checkpoint",
	)
	var decoded_after_recovery := SaveCodec.decode(
		storage.read(&"profile-1").payload,
		game_result.catalog,
		estate_result.catalog,
	)
	_check(
		decoded_after_recovery.status == SaveCodecResult.Status.DECODED
		and storage.read(&"profile-1.quarantine-primary").payload
		== "{corrupt-current",
		"real recovery preserves corrupt evidence and exposes a valid current",
	)

	_cleanup(storage)
	var interruption_module := _module(
		storage,
		game_result.catalog,
		estate_result.catalog,
	)
	interruption_module.load()
	interruption_module.save(state)
	storage.write(&"profile-1", "{corrupt-before-promote")
	var before_crash_module := _module(
		storage,
		game_result.catalog,
		estate_result.catalog,
	)
	_check(
		before_crash_module.load().source
		== GameSaveLoadResult.Source.CURRENT_PREVIOUS,
		"the integration fixture begins from previous recovery",
	)
	var target_path := base_directory.path_join("profile-1.json")
	var rollback_path := target_path + ".rollback"
	var temporary_path := target_path + ".tmp"
	DirAccess.rename_absolute(target_path, rollback_path)
	_write_raw(temporary_path, "{\"interrupted\":true}")
	var after_crash_module := _module(
		storage,
		game_result.catalog,
		estate_result.catalog,
	)
	var after_crash := after_crash_module.load()
	_check(
		after_crash.status == GameSaveLoadResult.Status.LOADED
		and after_crash.source
		== GameSaveLoadResult.Source.CURRENT_PREVIOUS,
		"a target-to-rollback interruption retains the last valid checkpoint",
	)
	after_crash_module.save(state)
	var decoded_after_interruption := SaveCodec.decode(
		storage.read(&"profile-1").payload,
		game_result.catalog,
		estate_result.catalog,
	)
	_check(
		decoded_after_interruption.status == SaveCodecResult.Status.DECODED
		and not FileAccess.file_exists(rollback_path)
		and not FileAccess.file_exists(temporary_path),
		"the real module and adapter reconcile interruption before the next save",
	)
	_cleanup(storage)
	_finish()


func _module(
	storage: SaveService,
	game_catalog: GameCatalog,
	estate_catalog: EstateMapCatalog,
) -> GameSaveModule:
	return GameSaveModule.new(
		storage,
		game_catalog,
		estate_catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)


func _state(game_catalog: GameCatalog) -> P2PersistentState:
	return _state_at(game_catalog, 3, Vector2(640.0, 480.0))


func _state_at(
	game_catalog: GameCatalog,
	world_day: int,
	player_position: Vector2,
) -> P2PersistentState:
	var inventory := InventoryState.create_empty()
	var addition := inventory.with_added(&"mistleaf_seed", 2, game_catalog)
	return P2PersistentState.new(
		&"home_h01_open_meadow",
		FarmingSessionState.new(
			FarmingTransactionState.new(
				FarmState.create_empty(&"home_h01_open_meadow"),
				addition.inventory,
			),
			world_day,
		),
		player_position,
		Vector2i.LEFT,
		&"home_safe_spawn_meadow",
		5,
		EstateMapState.new(&"spring", &"reclaimed", &"light"),
		DailyResourceClaims.create_empty().with_claim(
			&"home.h01.resource.north_meadow.daily_choice",
			mini(world_day, 2),
		),
	)


func _cleanup(storage: SaveService) -> void:
	for slot_id: StringName in [
		&"profile-1",
		&"profile-1.protected",
		&"profile-1.quarantine-primary",
		&"profile-1.quarantine-previous",
		&"profile-1.protected.quarantine-primary",
		&"profile-1.protected.quarantine-previous",
	]:
		storage.remove(slot_id)


func _write_raw(path: String, payload: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	return write_error == OK


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_GAME_SAVE_ATOMIC_RECOVERY_OK")
		quit(0)
		return
	push_error(
		"P2 game-save atomic recovery failed: %d check(s)" % _failures
	)
	quit(1)

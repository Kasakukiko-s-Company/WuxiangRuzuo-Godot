extends SceneTree

const LEGACY_V1_PAYLOAD: String = (
	'{"schemaVersion":1,"savedAt":"2026-07-20T12:00:00+08:00",'
	+ '"profileId":"profile-1","worldDay":1,"currentMapId":"hometown_main",'
	+ '"player":{"anchorId":"main_safe_spawn","position":{"x":336.0,"y":240.0},'
	+ '"facing":"down","health":5},"farm":{"mapId":"hometown_main","tiles":[]},'
	+ '"inventory":{"selectedIndex":0,"slots":[null,null,null,null,null,null,null,null]},'
	+ '"storyFlags":{},"relationships":[],"spouseCharacterId":null,'
	+ '"mineRun":{"worldDay":0,"brokenNodeIds":[],"defeatedEncounterIds":[]}}'
)


class MemorySaveService extends SaveService:
	var payloads: Dictionary[StringName, String] = {}
	var previous_payloads: Dictionary[StringName, String] = {}
	var failed_write_slot: StringName = &""


	func read(slot_id: StringName) -> SaveReadResult:
		if not payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(payloads[slot_id])


	func read_previous(slot_id: StringName) -> SaveReadResult:
		if not previous_payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(previous_payloads[slot_id])


	func write(slot_id: StringName, payload: String) -> SaveWriteResult:
		if slot_id == failed_write_slot:
			return SaveWriteResult.failed("injected write failure")
		payloads[slot_id] = payload
		return SaveWriteResult.written()


	func remove(slot_id: StringName) -> SaveWriteResult:
		payloads.erase(slot_id)
		return SaveWriteResult.written()


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_result := CatalogFileLoader.load_catalog()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	_check(
		game_result.is_valid() and estate_result.is_valid(),
		"game-save module loads both validated catalogs",
	)
	if not game_result.is_valid() or not estate_result.is_valid():
		_finish()
		return
	var storage := MemorySaveService.new()
	var module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var missing := module.load()
	_check(
		missing.status == GameSaveLoadResult.Status.MISSING,
		"a profile with no current or recovery payload is explicitly missing",
	)

	var state := _state(game_result.catalog)
	var unopened_storage := MemorySaveService.new()
	var unopened_module := GameSaveModule.new(
		unopened_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-3",
		&"home_h01_open_meadow",
	)
	_check(
		unopened_module.save(state).status
		== GameSaveCommitResult.Status.REJECTED
		and unopened_storage.payloads.is_empty(),
		"a save module cannot overwrite a profile before attempting load",
	)
	var saved := module.save(state)
	_check(
		saved.status == GameSaveCommitResult.Status.SAVED,
		"a valid H01 state saves through the opaque storage seam",
	)
	var reloaded_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var loaded := reloaded_module.load()
	_check(
		loaded.status == GameSaveLoadResult.Status.LOADED
		and loaded.source == GameSaveLoadResult.Source.CURRENT,
		"a new module restores the current checkpoint",
	)
	if loaded.status == GameSaveLoadResult.Status.LOADED:
		_check(
			loaded.state.farming_session.world_day == 3
			and loaded.state.player_position == Vector2(640.0, 480.0)
			and loaded.state.player_facing == Vector2i.LEFT,
			"world day and player transform restore through the typed state",
		)
		_check(
			loaded.state.daily_resource_claims.last_claimed_day(
				&"home.h01.resource.north_meadow.daily_choice"
			) == 2
			and loaded.state.estate_map_state.anomaly == &"light",
			"estate and daily resource state restore through the typed state",
		)

	var protected_saved := module.save(state, true)
	_check(
		protected_saved.status == GameSaveCommitResult.Status.SAVED
		and storage.payloads.has(&"profile-1.protected"),
		"a confirmed rest can update the protected recovery checkpoint",
	)
	var protected_payload := storage.payloads[&"profile-1.protected"]
	var narrative_decoded := SaveCodec.decode(
		protected_payload,
		game_result.catalog,
		estate_result.catalog,
	)
	var narrative_snapshot := narrative_decoded.snapshot
	narrative_snapshot.story_flags = {"opening.testPreserved": true}
	narrative_snapshot.relationships = [
		SaveSnapshot.Relationship.new(
			&"npc_shen_he",
			42,
			&"spouse",
		),
	]
	narrative_snapshot.spouse_character_id = &"npc_shen_he"
	narrative_snapshot.mine_run = SaveSnapshot.MineRun.new(
		3,
		[&"old_mine.node.1"],
		[&"old_mine.encounter.1"],
	)
	var narrative_encoded := SaveCodec.encode(
		narrative_snapshot,
		game_result.catalog,
		estate_result.catalog,
	)
	var narrative_storage := MemorySaveService.new()
	narrative_storage.payloads[&"profile-1"] = narrative_encoded.payload
	var narrative_module := GameSaveModule.new(
		narrative_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var narrative_loaded := narrative_module.load()
	var updated_state := _state_at(
		game_result.catalog,
		4,
		Vector2(672.0, 512.0),
	)
	var narrative_saved := narrative_module.save(updated_state)
	var narrative_round_trip := SaveCodec.decode(
		narrative_storage.payloads[&"profile-1"],
		game_result.catalog,
		estate_result.catalog,
	)
	_check(
		narrative_loaded.status == GameSaveLoadResult.Status.LOADED
		and narrative_saved.status == GameSaveCommitResult.Status.SAVED
		and narrative_round_trip.status == SaveCodecResult.Status.DECODED
		and narrative_round_trip.snapshot.world_day == 4
		and narrative_round_trip.snapshot.player.position
		== Vector2(672.0, 512.0)
		and narrative_round_trip.snapshot.story_flags.get(
			"opening.testPreserved",
			false,
		)
		and narrative_round_trip.snapshot.relationships.size() == 1
		and narrative_round_trip.snapshot.spouse_character_id
		== &"npc_shen_he"
		and narrative_round_trip.snapshot.mine_run.broken_node_ids
		== [&"old_mine.node.1"],
		"H01 autosave preserves non-empty story, relationship, spouse, and mine fields",
	)
	storage.payloads[&"profile-1"] = "{corrupt-current"
	var recovered_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var recovered := recovered_module.load()
	_check(
		recovered.status == GameSaveLoadResult.Status.LOADED
		and recovered.source == GameSaveLoadResult.Source.PROTECTED,
		"an invalid current checkpoint falls back to a valid protected checkpoint",
	)
	storage.payloads[&"profile-1.protected"] = "{corrupt-protected"
	var unavailable_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var unavailable := unavailable_module.load()
	var unavailable_save := unavailable_module.save(state)
	_check(
		unavailable.status == GameSaveLoadResult.Status.UNAVAILABLE
		and unavailable_save.status == GameSaveCommitResult.Status.REJECTED
		and storage.payloads[&"profile-1"] == "{corrupt-current",
		"an unavailable profile locks direct saves without overwriting evidence",
	)

	storage.payloads[&"profile-1.protected"] = protected_payload
	storage.failed_write_slot = &"profile-1.protected"
	var degraded := module.save(state, true)
	_check(
		degraded.status
		== GameSaveCommitResult.Status.SAVED_RECOVERY_DEGRADED
		and storage.payloads.has(&"profile-1"),
		"a recovery write failure reports partial durability after current save",
	)
	storage.failed_write_slot = &""
	var profile_one_payload := storage.payloads[&"profile-1"]
	var profile_two_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-2",
		&"home_h01_open_meadow",
	)
	profile_two_module.load()
	var profile_two_saved := profile_two_module.save(state)
	_check(
		profile_two_saved.status == GameSaveCommitResult.Status.SAVED
		and storage.payloads.has(&"profile-2")
		and storage.payloads[&"profile-1"] == profile_one_payload,
		"profile-2 writes are isolated from profile-1",
	)
	var profile_two_payload := storage.payloads[&"profile-2"]
	var profile_three_module := GameSaveModule.new(
		storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-3",
		&"home_h01_open_meadow",
	)
	profile_three_module.load()
	var profile_three_saved := profile_three_module.save(state)
	_check(
		profile_three_saved.status == GameSaveCommitResult.Status.SAVED
		and storage.payloads.has(&"profile-3")
		and storage.payloads[&"profile-1"] == profile_one_payload
		and storage.payloads[&"profile-2"] == profile_two_payload,
		"profile-3 writes are isolated from profile-1 and profile-2",
	)

	var previous_storage := MemorySaveService.new()
	previous_storage.payloads[&"profile-1"] = "{corrupt-current"
	previous_storage.previous_payloads[&"profile-1"] = protected_payload
	var previous_module := GameSaveModule.new(
		previous_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var previous_loaded := previous_module.load()
	_check(
		previous_loaded.status == GameSaveLoadResult.Status.LOADED
		and previous_loaded.source
		== GameSaveLoadResult.Source.CURRENT_PREVIOUS
		and previous_storage.payloads.get(
			&"profile-1.quarantine-primary",
			"",
		) == "{corrupt-current",
		"a valid previous current is used only after corrupt target evidence is quarantined",
	)
	previous_module.save(state)
	previous_module.save(state)
	_check(
		previous_storage.payloads[&"profile-1.quarantine-primary"]
		== "{corrupt-current",
		"repeated autosaves do not erase quarantined corrupt current evidence",
	)

	var day_one_storage := MemorySaveService.new()
	var day_one_module := GameSaveModule.new(
		day_one_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	day_one_module.load()
	day_one_module.save(
		_state_at(game_result.catalog, 1, Vector2(608.0, 448.0))
	)
	var day_five_storage := MemorySaveService.new()
	var day_five_module := GameSaveModule.new(
		day_five_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	day_five_module.load()
	day_five_module.save(
		_state_at(game_result.catalog, 5, Vector2(704.0, 544.0))
	)
	var recency_storage := MemorySaveService.new()
	recency_storage.payloads[&"profile-1"] = "{corrupt-current"
	recency_storage.previous_payloads[&"profile-1"] = (
		day_one_storage.payloads[&"profile-1"]
	)
	recency_storage.payloads[&"profile-1.protected"] = (
		day_five_storage.payloads[&"profile-1"]
	)
	var recency_module := GameSaveModule.new(
		recency_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var recency_loaded := recency_module.load()
	_check(
		recency_loaded.status == GameSaveLoadResult.Status.LOADED
		and recency_loaded.source == GameSaveLoadResult.Source.PROTECTED
		and recency_loaded.state.farming_session.world_day == 5
		and recency_loaded.state.player_position == Vector2(704.0, 544.0),
		"a newer protected checkpoint outranks an older current previous fallback",
	)

	var legacy_storage := MemorySaveService.new()
	legacy_storage.payloads[&"profile-1"] = LEGACY_V1_PAYLOAD
	legacy_storage.payloads[&"profile-1.protected"] = protected_payload
	var legacy_module := GameSaveModule.new(
		legacy_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var legacy_loaded := legacy_module.load()
	_check(
		legacy_loaded.status == GameSaveLoadResult.Status.LOADED
		and legacy_loaded.source == GameSaveLoadResult.Source.PROTECTED
		and legacy_storage.payloads.get(
			&"profile-1.quarantine-primary",
			"",
		) == LEGACY_V1_PAYLOAD,
		"a valid v1 non-H01 current is preserved before protected H01 recovery",
	)
	legacy_module.save(state)
	legacy_module.save(state)
	_check(
		legacy_storage.payloads[&"profile-1.quarantine-primary"]
		== LEGACY_V1_PAYLOAD,
		"schema-incompatible v1 evidence survives repeated H01 autosaves",
	)

	var protected_previous_storage := MemorySaveService.new()
	protected_previous_storage.payloads[&"profile-1.protected"] = (
		"{corrupt-protected"
	)
	protected_previous_storage.previous_payloads[
		&"profile-1.protected"
	] = protected_payload
	var protected_previous_loaded := GameSaveModule.new(
		protected_previous_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	).load()
	_check(
		protected_previous_loaded.status
		== GameSaveLoadResult.Status.LOADED
		and protected_previous_loaded.source
		== GameSaveLoadResult.Source.PROTECTED_PREVIOUS
		and protected_previous_storage.payloads.get(
			&"profile-1.protected.quarantine-primary",
			"",
		) == "{corrupt-protected",
		"a previous protected checkpoint is used after preserving its corrupt target",
	)

	var read_only_storage := MemorySaveService.new()
	read_only_storage.payloads[&"profile-1"] = "{new-corrupt-current"
	read_only_storage.payloads[&"profile-1.protected"] = protected_payload
	read_only_storage.payloads[
		&"profile-1.quarantine-primary"
	] = "{older-corrupt-current"
	var read_only_module := GameSaveModule.new(
		read_only_storage,
		game_result.catalog,
		estate_result.catalog,
		&"profile-1",
		&"home_h01_open_meadow",
	)
	var read_only_loaded := read_only_module.load()
	_check(
		read_only_loaded.status == GameSaveLoadResult.Status.LOADED
		and read_only_loaded.source == GameSaveLoadResult.Source.PROTECTED
		and not read_only_loaded.saving_allowed
		and read_only_storage.payloads[&"profile-1"]
		== "{new-corrupt-current",
		"a valid recovery remains playable read-only when new evidence cannot be quarantined",
	)
	var read_only_save := read_only_module.save(state)
	_check(
		read_only_save.status == GameSaveCommitResult.Status.REJECTED
		and read_only_storage.payloads[&"profile-1"]
		== "{new-corrupt-current"
		and read_only_storage.payloads[&"profile-1.quarantine-primary"]
		== "{older-corrupt-current",
		"the save module itself enforces read-only recovery without relying on UI binding",
	)

	_finish()


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


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_GAME_SAVE_MODULE_OK")
		quit(0)
		return
	push_error("P2 game-save module test failed: %d check(s)" % _failures)
	quit(1)

class_name GameSaveModule
extends RefCounted


class Candidate extends RefCounted:
	var is_valid: bool = false
	var is_missing: bool = false
	var read_failed: bool = false
	var slot_id: StringName
	var is_previous: bool = false
	var raw_payload: String
	var snapshot: SaveSnapshot
	var state: P2PersistentState
	var source_schema_version: int = 0
	var requires_resave: bool = false
	var message: String
	var source: GameSaveLoadResult.Source = GameSaveLoadResult.Source.NONE
	var unavailable_reason: GameSaveLoadResult.UnavailableReason = (
		GameSaveLoadResult.UnavailableReason.NONE
	)


var _storage: SaveService
var _game_catalog: GameCatalog
var _estate_catalog: EstateMapCatalog
var _profile_id: StringName
var _expected_map_id: StringName
var _base_snapshot: SaveSnapshot
var _saving_allowed: bool = true
var _load_attempted: bool = false


func _init(
	storage: SaveService,
	game_catalog: GameCatalog,
	estate_catalog: EstateMapCatalog,
	profile_id: StringName,
	expected_map_id: StringName,
) -> void:
	assert(storage != null, "game-save module requires a SaveService")
	assert(game_catalog != null, "game-save module requires a GameCatalog")
	assert(
		estate_catalog != null,
		"game-save module requires an EstateMapCatalog",
	)
	assert(
		SaveSnapshot.PROFILE_IDS.has(profile_id),
		"game-save module requires a registered profile ID",
	)
	assert(
		estate_catalog.get_map(expected_map_id) != null,
		"game-save module requires a registered estate map",
	)
	_storage = storage
	_game_catalog = game_catalog
	_estate_catalog = estate_catalog
	_profile_id = profile_id
	_expected_map_id = expected_map_id


## Resolves the same candidate order as load(), but never writes quarantine,
## adopts a base snapshot, or unlocks save(). Title/profile UI must use this.
func inspect() -> GameSaveLoadResult:
	return _resolve_profile(false)


func load() -> GameSaveLoadResult:
	_load_attempted = true
	_saving_allowed = true
	_base_snapshot = null
	return _resolve_profile(true)


func _resolve_profile(preserve_unavailable: bool) -> GameSaveLoadResult:
	var current := _read_candidate(
		_profile_id,
		GameSaveLoadResult.Source.CURRENT,
	)
	if current.is_valid:
		return _loaded_result(
			current,
			GameSaveLoadResult.Source.CURRENT,
			"",
			true,
			preserve_unavailable,
		)
	var current_previous := _read_candidate(
		_profile_id,
		GameSaveLoadResult.Source.CURRENT_PREVIOUS,
		true,
	)
	var protected := _read_candidate(
		_protected_slot_id(),
		GameSaveLoadResult.Source.PROTECTED,
	)
	var protected_previous := _read_candidate(
		_protected_slot_id(),
		GameSaveLoadResult.Source.PROTECTED_PREVIOUS,
		true,
	)
	var candidates: Array[Candidate] = [
		current,
		current_previous,
		protected,
		protected_previous,
	]
	var fallback := _select_latest_fallback([
		current_previous,
		protected,
		protected_previous,
	])
	if fallback != null:
		if not preserve_unavailable:
			return _loaded_result(
				fallback,
				fallback.source,
				"recovery candidate available",
				true,
				false,
			)
		return _fallback_result(
			fallback,
			fallback.source,
			candidates,
		)
	if (
		current.is_missing
		and current_previous.is_missing
		and protected.is_missing
		and protected_previous.is_missing
	):
		return GameSaveLoadResult.missing()
	if preserve_unavailable:
		_saving_allowed = false
	return GameSaveLoadResult.unavailable(
		(
			"current: %s; current previous: %s; protected: %s; "
			+ "protected previous: %s"
		) % [
			_candidate_message(current),
			_candidate_message(current_previous),
			_candidate_message(protected),
			_candidate_message(protected_previous),
		],
		_unavailable_reason(candidates),
	)


func save(
	state: P2PersistentState,
	protect_recovery: bool = false,
) -> GameSaveCommitResult:
	if not _load_attempted:
		return GameSaveCommitResult.rejected(
			"save module must load its profile before the first save"
		)
	if not _saving_allowed:
		return GameSaveCommitResult.rejected(
			"save module is read-only to preserve unavailable checkpoint evidence"
		)
	if state == null or state.map_id != _expected_map_id:
		return GameSaveCommitResult.rejected(
			"state does not belong to the configured estate map"
		)
	var snapshot := _snapshot_from_state(state)
	var encoded := SaveCodec.encode(
		snapshot,
		_game_catalog,
		_estate_catalog,
	)
	if encoded.status != SaveCodecResult.Status.ENCODED:
		return GameSaveCommitResult.rejected(encoded.describe_issues())
	var current_write := _storage.write(_profile_id, encoded.payload)
	if current_write.status != SaveWriteResult.Status.WRITTEN:
		return GameSaveCommitResult.storage_failed(current_write.message)
	_base_snapshot = snapshot
	if not protect_recovery:
		return GameSaveCommitResult.saved()
	var protected_write := _storage.write(
		_protected_slot_id(),
		encoded.payload,
	)
	if protected_write.status != SaveWriteResult.Status.WRITTEN:
		return GameSaveCommitResult.recovery_degraded(
			protected_write.message
		)
	return GameSaveCommitResult.saved()


func _read_candidate(
	slot_id: StringName,
	source: GameSaveLoadResult.Source,
	read_previous: bool = false,
) -> Candidate:
	var candidate := Candidate.new()
	candidate.slot_id = slot_id
	candidate.is_previous = read_previous
	candidate.source = source
	var read_result := (
		_storage.read_previous(slot_id)
		if read_previous
		else _storage.read(slot_id)
	)
	if read_result.status == SaveReadResult.Status.MISSING:
		candidate.is_missing = true
		candidate.message = "missing"
		return candidate
	if read_result.status == SaveReadResult.Status.FAILED:
		candidate.read_failed = true
		candidate.unavailable_reason = (
			GameSaveLoadResult.UnavailableReason.READ_FAILED
		)
		candidate.message = "storage read failed: %s" % read_result.message
		return candidate
	candidate.raw_payload = read_result.payload
	var decoded := SaveCodec.decode(
		read_result.payload,
		_game_catalog,
		_estate_catalog,
	)
	if decoded.status != SaveCodecResult.Status.DECODED:
		candidate.unavailable_reason = (
			GameSaveLoadResult.UnavailableReason.UNSUPPORTED_SCHEMA
			if decoded.status == SaveCodecResult.Status.UNSUPPORTED_SCHEMA
			else GameSaveLoadResult.UnavailableReason.CORRUPT
		)
		candidate.message = "codec rejected payload: %s" % (
			decoded.describe_issues()
		)
		return candidate
	if decoded.snapshot.profile_id != _profile_id:
		candidate.unavailable_reason = (
			GameSaveLoadResult.UnavailableReason.INCOMPATIBLE
		)
		candidate.message = "payload profile does not match requested profile"
		return candidate
	var state := _state_from_snapshot(decoded.snapshot)
	if state == null:
		candidate.unavailable_reason = (
			GameSaveLoadResult.UnavailableReason.INCOMPATIBLE
		)
		candidate.message = (
			"payload is valid but incompatible with the configured estate"
		)
		return candidate
	candidate.is_valid = true
	candidate.snapshot = decoded.snapshot
	candidate.state = state
	candidate.source_schema_version = decoded.source_schema_version
	candidate.requires_resave = decoded.requires_resave
	return candidate


func _loaded_result(
	candidate: Candidate,
	source: GameSaveLoadResult.Source,
	message: String = "",
	saving_allowed: bool = true,
	adopt_snapshot: bool = true,
) -> GameSaveLoadResult:
	if adopt_snapshot:
		_base_snapshot = candidate.snapshot
	return GameSaveLoadResult.loaded(
		candidate.state,
		source,
		candidate.source_schema_version,
		candidate.requires_resave,
		message,
		saving_allowed,
		candidate.snapshot.saved_at,
	)


func _fallback_result(
	candidate: Candidate,
	source: GameSaveLoadResult.Source,
	earlier_candidates: Array[Candidate],
) -> GameSaveLoadResult:
	var preservation_error := _preserve_unavailable_candidates(
		earlier_candidates
	)
	if not preservation_error.is_empty():
		_saving_allowed = false
		return _loaded_result(
			candidate,
			source,
			(
				"restored read-only because unavailable checkpoint evidence "
				+ "could not be preserved: %s" % preservation_error
			),
			false,
		)
	return _loaded_result(
		candidate,
		source,
		"unavailable checkpoint payloads were preserved",
	)


func _select_latest_fallback(
	candidates: Array[Candidate],
) -> Candidate:
	var selected: Candidate
	for candidate: Candidate in candidates:
		if not candidate.is_valid:
			continue
		if selected == null or _is_newer_fallback(candidate, selected):
			selected = candidate
	return selected


func _is_newer_fallback(candidate: Candidate, selected: Candidate) -> bool:
	if candidate.snapshot.world_day != selected.snapshot.world_day:
		return candidate.snapshot.world_day > selected.snapshot.world_day
	var saved_at_comparison := candidate.snapshot.saved_at.casecmp_to(
		selected.snapshot.saved_at
	)
	if saved_at_comparison != 0:
		return saved_at_comparison > 0
	return (
		_fallback_source_priority(candidate.source)
		> _fallback_source_priority(selected.source)
	)


func _fallback_source_priority(
	source: GameSaveLoadResult.Source,
) -> int:
	if source == GameSaveLoadResult.Source.CURRENT_PREVIOUS:
		return 3
	if source == GameSaveLoadResult.Source.PROTECTED:
		return 2
	if source == GameSaveLoadResult.Source.PROTECTED_PREVIOUS:
		return 1
	return 0


func _preserve_unavailable_candidates(
	candidates: Array[Candidate],
) -> String:
	for candidate: Candidate in candidates:
		if candidate.is_missing or candidate.is_valid:
			continue
		if candidate.read_failed:
			return (
				"fallback is read-only because an earlier checkpoint "
				+ "could not be read: %s" % candidate.message
			)
		var preservation_error := _preserve_candidate(candidate)
		if not preservation_error.is_empty():
			return preservation_error
	return ""


func _preserve_candidate(candidate: Candidate) -> String:
	var quarantine_slot := _quarantine_slot_id(candidate)
	var existing := _storage.read(quarantine_slot)
	if existing.status == SaveReadResult.Status.FOUND:
		if existing.payload == candidate.raw_payload:
			return ""
		return "quarantine slot already contains different evidence"
	if existing.status == SaveReadResult.Status.FAILED:
		return "quarantine slot could not be read: %s" % existing.message
	var existing_previous := _storage.read_previous(quarantine_slot)
	if existing_previous.status == SaveReadResult.Status.FOUND:
		if existing_previous.payload == candidate.raw_payload:
			return ""
		return "quarantine previous slot contains different evidence"
	if existing_previous.status == SaveReadResult.Status.FAILED:
		return (
			"quarantine previous slot could not be read: %s"
			% existing_previous.message
		)
	var write_result := _storage.write(
		quarantine_slot,
		candidate.raw_payload,
	)
	if write_result.status != SaveWriteResult.Status.WRITTEN:
		return "unavailable checkpoint could not be quarantined: %s" % (
			write_result.message
		)
	return ""


func _quarantine_slot_id(candidate: Candidate) -> StringName:
	return StringName(
		"%s.quarantine-%s" % [
			candidate.slot_id,
			"previous" if candidate.is_previous else "primary",
		]
	)


func _snapshot_from_state(state: P2PersistentState) -> SaveSnapshot:
	var snapshot := SaveSnapshot.new()
	snapshot.saved_at = Time.get_datetime_string_from_system(true, false)
	snapshot.profile_id = _profile_id
	snapshot.world_day = state.farming_session.world_day
	snapshot.current_map_id = state.map_id
	snapshot.player = SaveSnapshot.Player.new(
		state.player_fallback_anchor_id,
		state.player_position,
		_facing_name(state.player_facing),
		state.player_health,
	)
	snapshot.farm = state.farming_session.state.farm
	snapshot.inventory = state.farming_session.state.inventory
	snapshot.estate_map_state = state.estate_map_state
	snapshot.daily_resource_claims = state.daily_resource_claims
	if _base_snapshot == null:
		snapshot.story_flags = {}
		snapshot.relationships = []
		snapshot.spouse_character_id = &""
		snapshot.mine_run = SaveSnapshot.MineRun.new()
		return snapshot
	snapshot.story_flags = _base_snapshot.story_flags.duplicate(true)
	snapshot.relationships = _copy_relationships(
		_base_snapshot.relationships
	)
	snapshot.spouse_character_id = _base_snapshot.spouse_character_id
	snapshot.mine_run = SaveSnapshot.MineRun.new(
		_base_snapshot.mine_run.world_day,
		_base_snapshot.mine_run.broken_node_ids,
		_base_snapshot.mine_run.defeated_encounter_ids,
	)
	return snapshot


func _state_from_snapshot(snapshot: SaveSnapshot) -> P2PersistentState:
	if (
		snapshot.current_map_id != _expected_map_id
		or snapshot.farm.map_id != _expected_map_id
		or snapshot.estate_map_state == null
		or snapshot.daily_resource_claims == null
	):
		return null
	var facing := _facing_vector(snapshot.player.facing)
	if facing == Vector2i.ZERO:
		return null
	return P2PersistentState.new(
		snapshot.current_map_id,
		FarmingSessionState.new(
			FarmingTransactionState.new(
				snapshot.farm,
				snapshot.inventory,
			),
			snapshot.world_day,
		),
		snapshot.player.position,
		facing,
		snapshot.player.anchor_id,
		snapshot.player.health,
		snapshot.estate_map_state,
		snapshot.daily_resource_claims,
	)


func _protected_slot_id() -> StringName:
	return StringName("%s.protected" % _profile_id)


func _candidate_message(candidate: Candidate) -> String:
	return "missing" if candidate.is_missing else candidate.message


func _unavailable_reason(
	candidates: Array[Candidate],
) -> GameSaveLoadResult.UnavailableReason:
	var reason := GameSaveLoadResult.UnavailableReason.CORRUPT
	for candidate: Candidate in candidates:
		if (
			candidate.unavailable_reason
			== GameSaveLoadResult.UnavailableReason.READ_FAILED
		):
			return GameSaveLoadResult.UnavailableReason.READ_FAILED
		if (
			candidate.unavailable_reason
			== GameSaveLoadResult.UnavailableReason.UNSUPPORTED_SCHEMA
		):
			reason = GameSaveLoadResult.UnavailableReason.UNSUPPORTED_SCHEMA
		elif (
			candidate.unavailable_reason
			== GameSaveLoadResult.UnavailableReason.INCOMPATIBLE
			and reason == GameSaveLoadResult.UnavailableReason.CORRUPT
		):
			reason = GameSaveLoadResult.UnavailableReason.INCOMPATIBLE
	return reason


func _facing_name(facing: Vector2i) -> StringName:
	if facing == Vector2i.UP:
		return &"up"
	if facing == Vector2i.RIGHT:
		return &"right"
	if facing == Vector2i.DOWN:
		return &"down"
	return &"left"


func _facing_vector(facing: StringName) -> Vector2i:
	if facing == &"up":
		return Vector2i.UP
	if facing == &"right":
		return Vector2i.RIGHT
	if facing == &"down":
		return Vector2i.DOWN
	if facing == &"left":
		return Vector2i.LEFT
	return Vector2i.ZERO


func _copy_relationships(
	relationships: Array[SaveSnapshot.Relationship],
) -> Array[SaveSnapshot.Relationship]:
	var copies: Array[SaveSnapshot.Relationship] = []
	for relationship: SaveSnapshot.Relationship in relationships:
		copies.append(SaveSnapshot.Relationship.new(
			relationship.npc_id,
			relationship.affinity,
			relationship.relationship_state,
		))
	return copies

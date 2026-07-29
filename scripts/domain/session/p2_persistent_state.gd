class_name P2PersistentState
extends RefCounted

var map_id: StringName:
	get:
		return _map_id
	set(_attempted_value):
		push_error("P2PersistentState.map_id is read-only")
var farming_session: FarmingSessionState:
	get:
		return _farming_session.snapshot()
	set(_attempted_value):
		push_error("P2PersistentState.farming_session is read-only")
var player_position: Vector2:
	get:
		return _player_position
	set(_attempted_value):
		push_error("P2PersistentState.player_position is read-only")
var player_facing: Vector2i:
	get:
		return _player_facing
	set(_attempted_value):
		push_error("P2PersistentState.player_facing is read-only")
var player_fallback_anchor_id: StringName:
	get:
		return _player_fallback_anchor_id
	set(_attempted_value):
		push_error("P2PersistentState.player_fallback_anchor_id is read-only")
var player_health: int:
	get:
		return _player_health
	set(_attempted_value):
		push_error("P2PersistentState.player_health is read-only")
var estate_map_state: EstateMapState:
	get:
		return _estate_map_state.copy()
	set(_attempted_value):
		push_error("P2PersistentState.estate_map_state is read-only")
var daily_resource_claims: DailyResourceClaims:
	get:
		return _daily_resource_claims.snapshot()
	set(_attempted_value):
		push_error("P2PersistentState.daily_resource_claims is read-only")

var _map_id: StringName
var _farming_session: FarmingSessionState
var _player_position: Vector2
var _player_facing: Vector2i
var _player_fallback_anchor_id: StringName
var _player_health: int
var _estate_map_state: EstateMapState
var _daily_resource_claims: DailyResourceClaims


func _init(
	state_map_id: StringName,
	state_farming_session: FarmingSessionState,
	state_player_position: Vector2,
	state_player_facing: Vector2i,
	state_player_fallback_anchor_id: StringName,
	state_player_health: int,
	state_estate_map_state: EstateMapState,
	state_daily_resource_claims: DailyResourceClaims,
) -> void:
	assert(not state_map_id.is_empty(), "P2 persistent state requires a map ID")
	assert(
		state_farming_session != null,
		"P2 persistent state requires a farming session",
	)
	assert(
		state_farming_session.state.farm.map_id == state_map_id,
		"P2 persistent farm must belong to the current map",
	)
	assert(
		is_finite(state_player_position.x)
		and is_finite(state_player_position.y),
		"P2 persistent player position must be finite",
	)
	assert(
		[
			Vector2i.UP,
			Vector2i.RIGHT,
			Vector2i.DOWN,
			Vector2i.LEFT,
		].has(state_player_facing),
		"P2 persistent facing must be four-directional",
	)
	assert(
		not state_player_fallback_anchor_id.is_empty(),
		"P2 persistent state requires a player fallback anchor",
	)
	assert(
		state_player_health >= 0 and state_player_health <= 5,
		"P2 persistent health must be between zero and five",
	)
	assert(
		state_estate_map_state != null,
		"P2 persistent state requires an estate map state",
	)
	assert(
		state_daily_resource_claims != null,
		"P2 persistent state requires daily resource claims",
	)
	_map_id = state_map_id
	_farming_session = state_farming_session.snapshot()
	_player_position = state_player_position
	_player_facing = state_player_facing
	_player_fallback_anchor_id = state_player_fallback_anchor_id
	_player_health = state_player_health
	_estate_map_state = state_estate_map_state.copy()
	_daily_resource_claims = state_daily_resource_claims.snapshot()


func snapshot() -> P2PersistentState:
	return P2PersistentState.new(
		_map_id,
		_farming_session,
		_player_position,
		_player_facing,
		_player_fallback_anchor_id,
		_player_health,
		_estate_map_state,
		_daily_resource_claims,
	)

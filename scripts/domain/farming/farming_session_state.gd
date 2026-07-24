class_name FarmingSessionState
extends RefCounted

var state: FarmingTransactionState:
	get:
		return _state
	set(_attempted_value):
		push_error("FarmingSessionState.state is read-only")
var world_day: int:
	get:
		return _world_day
	set(_attempted_value):
		push_error("FarmingSessionState.world_day is read-only")

var _state: FarmingTransactionState
var _world_day: int


func _init(
	session_state: FarmingTransactionState,
	session_world_day: int,
) -> void:
	assert(session_state != null, "farming session requires transaction state")
	assert(session_world_day >= 1, "farming session world day starts at one")
	_state = session_state
	_world_day = session_world_day


func snapshot() -> FarmingSessionState:
	return FarmingSessionState.new(_state.snapshot(), _world_day)

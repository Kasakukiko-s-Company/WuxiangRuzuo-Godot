class_name P2EstatePilot
extends Node2D

const SAFE_SPAWN_ID: StringName = &"home_safe_spawn_meadow"

@onready var _player: P1PlayerController = $Player
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _debug_panel: PanelContainer = $HUD/DebugPanel
@onready var _debug_label: Label = $HUD/DebugPanel/Margin/DebugLabel
@onready var _status_label: Label = $HUD/StatusPanel/Margin/StatusLabel

var _input_service: InputService
var _estate_runtime: EstateMapRuntime
var _coordinate_mapper := TileCoordinateMapper.new(Vector2i(32, 32))
var _reduce_motion: bool = false


func _ready() -> void:
	assert(_input_service != null, "P2 estate pilot requires an injected InputService")
	assert(_estate_runtime != null, "P2 estate pilot requires an injected estate runtime")
	_player.configure_input_service(_input_service)
	_player.interaction_requested.connect(_on_interaction_requested)
	reset_to_safe_spawn()
	_apply_camera_bounds()
	_update_debug()
	print("[WuxiangRuzuo] H01 estate pilot started: %s" % _estate_runtime.get_map_id())


func _process(_delta: float) -> void:
	if _input_service == null:
		return
	var snapshot: InputSnapshot = _input_service.snapshot()
	if snapshot.reset:
		reset_to_safe_spawn()
	if snapshot.debug_toggle:
		set_debug_visible(not _debug_panel.visible)
	if snapshot.reduce_motion_toggle:
		set_reduce_motion(not _reduce_motion)
	if snapshot.primary_action:
		_cycle_anomaly_preview()
	_update_debug()


func configure_input_service(service: InputService) -> void:
	assert(service != null, "P2 estate pilot requires an InputService")
	_input_service = service
	if is_node_ready():
		_player.configure_input_service(service)


func configure_estate_runtime(runtime: EstateMapRuntime) -> void:
	assert(runtime != null, "P2 estate pilot requires an EstateMapRuntime")
	assert(not is_node_ready(), "estate runtime must be injected before the pilot enters the tree")
	assert(runtime.get_parent() == null, "estate runtime must be unparented before injection")
	_estate_runtime = runtime
	runtime.name = "EstateMap"
	add_child(runtime)
	move_child(runtime, 0)


func get_estate_runtime() -> EstateMapRuntime:
	return _estate_runtime


func get_player() -> P1PlayerController:
	return _player


func get_camera() -> Camera2D:
	return _camera


func get_player_cell() -> Vector2i:
	return _coordinate_mapper.world_to_cell(_player.global_position)


func reset_to_safe_spawn() -> void:
	var spawn: EstateAnchorResult = _estate_runtime.query_anchor(
		&"spawn",
		SAFE_SPAWN_ID,
	)
	assert(spawn.is_found(), "H01 formal runtime must provide its safe spawn")
	_player.global_position = spawn.world_position
	_player.facing = Vector2i.DOWN
	_player.velocity = Vector2.ZERO
	_player.set_input_locked(false)
	_status_label.text = "H01 工程先导：已回到安全出生点"
	_camera.reset_smoothing()


func apply_estate_state(state: EstateMapState) -> EstateMapApplyResult:
	var result: EstateMapApplyResult = _estate_runtime.apply_state(state)
	if result.is_success():
		_status_label.text = "地产状态：%s / %s / %s" % [
			state.season,
			state.development,
			state.anomaly,
		]
	else:
		_status_label.text = "地产状态切换失败：%s" % result.message
	return result


func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled
	_camera.position_smoothing_enabled = not enabled
	if enabled:
		_camera.reset_smoothing()


func set_debug_visible(enabled: bool) -> void:
	_debug_panel.visible = enabled


func _apply_camera_bounds() -> void:
	var bounds: Rect2 = _estate_runtime.get_world_bounds()
	_camera.limit_left = roundi(bounds.position.x)
	_camera.limit_top = roundi(bounds.position.y)
	_camera.limit_right = roundi(bounds.end.x)
	_camera.limit_bottom = roundi(bounds.end.y)


func _cycle_anomaly_preview() -> void:
	var current: EstateMapState = _estate_runtime.get_current_state()
	var next_anomaly: StringName = &"light"
	if current.anomaly == &"light":
		next_anomaly = &"medium"
	elif current.anomaly == &"medium":
		next_anomaly = &"normal"
	apply_estate_state(
		EstateMapState.new(current.season, current.development, next_anomaly)
	)


func _on_interaction_requested(
	world_position: Vector2,
	facing_direction: Vector2i,
) -> void:
	var target_cell := _coordinate_mapper.facing_cell(
		world_position,
		facing_direction,
	)
	var semantics: EstateCellSemantics = _estate_runtime.query_cell(target_cell)
	if not semantics.is_in_bounds():
		_status_label.text = "目标在地产边界外"
		return
	var build_label := ""
	if semantics.buildable_free:
		build_label = "可建造 "
	elif semantics.buildable_reserved:
		build_label = "保留区 "
	_status_label.text = "目标格 %s · %s%s%s" % [
		target_cell,
		"可耕 " if semantics.farmable else "",
		build_label,
		"阻挡" if semantics.colliding else "可通行",
	]


func _update_debug() -> void:
	if not _debug_panel.visible:
		return
	var state: EstateMapState = _estate_runtime.get_current_state()
	_debug_label.text = (
		"H01 ESTATE PILOT\n"
		+ "map: %s\n" % _estate_runtime.get_map_id()
		+ "cell: %s\n" % get_player_cell()
		+ "facing: %s\n" % _player.facing
		+ "state: %s / %s / %s\n" % [
			state.season,
			state.development,
			state.anomaly,
		]
		+ "reduce motion: %s" % _reduce_motion
	)

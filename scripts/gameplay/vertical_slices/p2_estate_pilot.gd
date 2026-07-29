class_name P2EstatePilot
extends Node2D

signal durable_state_committed(
	reason: StringName,
	protect_recovery: bool,
)
signal playtest_action_committed(action_id: StringName)
signal return_to_title_requested

const SAFE_SPAWN_ID: StringName = &"home_safe_spawn_meadow"
const RESOURCE_SEED_SOURCE_ID: StringName = &"home.h01.resource.north_meadow"
const RESOURCE_FORAGE_SOURCE_ID: StringName = &"home.h01.resource.north_meadow.forage"
const RESOURCE_CHOICE_GROUP_ID: StringName = &"home.h01.resource.north_meadow.daily_choice"
const REST_POINT_ID: StringName = &"home.h01.rest.home_door"
const TRADE_ENDPOINT_ID: StringName = &"economy.h01.north_meadow_crate"
const RESOURCE_SEED_QUANTITY: int = 3
const RESOURCE_FORAGE_QUANTITY: int = 1

@onready var _player: P1PlayerController = $Player
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _farm_overlay: FarmPlotOverlay = $FarmPlotOverlay
@onready var _daily_overlay: EstateDailyInteractionOverlay = $DailyInteractionOverlay
@onready var _interaction_feedback: P2InteractionFeedback = $InteractionFeedback
@onready var _title_label: Label = $HUD/TitlePanel/Margin/Title
@onready var _debug_panel: PanelContainer = $HUD/DebugPanel
@onready var _debug_label: Label = $HUD/DebugPanel/Margin/DebugLabel
@onready var _status_label: Label = $HUD/StatusPanel/Margin/StatusLabel
@onready var _day_label: Label = $HUD/FarmingPanel/Margin/Rows/DayLabel
@onready var _quickbar_label: Label = $HUD/FarmingPanel/Margin/Rows/QuickbarLabel
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _day_transition: P2DayTransitionOverlay = $HUD/DayTransition
@onready var _pause_menu: P2PauseMenu = $HUD/PauseMenu

var _input_service: InputService
var _audio_service: AudioService
var _estate_runtime: EstateMapRuntime
var _game_catalog: GameCatalog
var _trade_book: TradeBook
var _farming_session: FarmingSessionState
var _rendered_farming_session: FarmingSessionState
var _daily_resource_claims: DailyResourceClaims
var _daily_resource_sources: DailyResourceSourceCatalog
var _daily_rest_points: DailyRestPointCatalog
var _crate_flow: NorthMeadowCrateFlow
var _rest_point: DailyRestPointDefinition
var _resource_anchor: EstateAnchorResult
var _rest_anchor: EstateAnchorResult
var _rest_confirmation_day: int = 0
var _coordinate_mapper := TileCoordinateMapper.new(Vector2i(32, 32))
var _life_loop_guide: H01LifeLoopGuide
var _reduce_motion: bool = false
var _initial_persistent_state: P2PersistentState
var _persistence_status: String = "内存状态，不写存档"
var _persistence_saving_allowed: bool = true
var _player_health: int = 5
var _discard_next_input_sample: bool = false


func _ready() -> void:
	assert(_input_service != null, "P2 estate pilot requires an injected InputService")
	assert(_estate_runtime != null, "P2 estate pilot requires an injected estate runtime")
	assert(_game_catalog != null, "P2 estate pilot requires an injected GameCatalog")
	assert(_trade_book != null, "P2 estate pilot requires an injected TradeBook")
	_player.set_external_snapshot_mode(true)
	_player.interaction_requested.connect(_on_interaction_requested)
	_pause_menu.resume_requested.connect(_close_pause_menu)
	_pause_menu.return_to_title_requested.connect(
		_on_return_to_title_requested
	)
	_initialize_farming_session()
	_initialize_daily_interactions()
	_life_loop_guide = H01LifeLoopGuide.new(
		_game_catalog,
		_trade_book,
		_daily_resource_sources,
	)
	if not _restore_initial_state():
		reset_to_safe_spawn()
	_apply_camera_bounds()
	_update_persistence_labels()
	_refresh_farming_view()
	_update_debug()
	if _audio_service != null:
		_audio_service.play_music(&"music.h01.spring_day")
	print("[WuxiangRuzuo] H01 estate pilot started: %s" % _estate_runtime.get_map_id())


func _exit_tree() -> void:
	if _pause_menu != null and _pause_menu.is_open():
		get_tree().paused = false
	if _farming_session != null and _estate_runtime != null:
		_commit_durable_state(&"session.exiting")
	if _audio_service != null:
		_audio_service.stop_music()


func _physics_process(_delta: float) -> void:
	if _input_service == null:
		return
	var snapshot: InputSnapshot = _input_service.snapshot()
	if _discard_next_input_sample:
		_discard_next_input_sample = false
		return
	if (
		snapshot.pause
		or _pause_menu.is_open()
		or _day_transition.is_open()
	):
		apply_input_snapshot(snapshot)
		return
	_player.apply_input_snapshot(snapshot)
	if _day_transition.is_open():
		_refresh_farming_view()
		_update_debug()
		return
	apply_input_snapshot(snapshot)


func apply_input_snapshot(snapshot: InputSnapshot) -> void:
	assert(snapshot != null, "P2 estate pilot input snapshot must be present")
	if snapshot.pause:
		if _pause_menu.is_return_confirmation_open():
			_pause_menu.cancel_return_confirmation()
		elif _pause_menu.is_open():
			_close_pause_menu()
		else:
			_open_pause_menu()
		return
	if _pause_menu.is_open():
		return
	if _day_transition.is_open():
		if snapshot.reduce_motion_toggle:
			set_reduce_motion(not _reduce_motion)
		if snapshot.interact or snapshot.primary_action:
			_dismiss_day_transition()
		return
	if snapshot.reset:
		reset_to_safe_spawn()
	if snapshot.debug_toggle:
		set_debug_visible(not _debug_panel.visible)
	if snapshot.reduce_motion_toggle:
		set_reduce_motion(not _reduce_motion)
	if snapshot.quickbar_slot_index >= 0:
		_cancel_crate()
		_select_quickbar_slot(snapshot.quickbar_slot_index)
	if snapshot.select_previous:
		if _is_crate_open():
			_advance_crate(NorthMeadowCrateFlow.Intent.PREVIOUS)
		else:
			_select_relative_slot(-1)
	if snapshot.select_next:
		if _is_crate_open():
			_advance_crate(NorthMeadowCrateFlow.Intent.NEXT)
		else:
			_select_relative_slot(1)
	if snapshot.secondary_action:
		_cancel_crate()
		_cycle_anomaly_preview()
	if snapshot.primary_action:
		_cancel_crate()
		_use_selected_item()
	if snapshot.watering_action:
		_cancel_crate()
		_select_and_use_watering_can()
	if snapshot.move != Vector2.ZERO:
		_clear_rest_confirmation()
		_cancel_crate()
	_refresh_farming_view()
	_update_debug()


func configure_input_service(service: InputService) -> void:
	assert(service != null, "P2 estate pilot requires an InputService")
	_input_service = service


func configure_audio_service(service: AudioService) -> void:
	assert(service != null, "P2 estate pilot requires a valid AudioService")
	assert(not is_node_ready(), "audio service must be injected before the pilot enters the tree")
	_audio_service = service


func configure_estate_runtime(runtime: EstateMapRuntime) -> void:
	assert(runtime != null, "P2 estate pilot requires an EstateMapRuntime")
	assert(not is_node_ready(), "estate runtime must be injected before the pilot enters the tree")
	assert(runtime.get_parent() == null, "estate runtime must be unparented before injection")
	_estate_runtime = runtime
	runtime.name = "EstateMap"
	add_child(runtime)
	move_child(runtime, 0)


func configure_game_catalog(catalog: GameCatalog) -> void:
	assert(catalog != null, "P2 estate pilot requires a GameCatalog")
	assert(not is_node_ready(), "game catalog must be injected before the pilot enters the tree")
	_game_catalog = catalog


func configure_trade_book(book: TradeBook) -> void:
	assert(book != null, "P2 estate pilot requires a TradeBook")
	assert(not is_node_ready(), "trade book must be injected before the pilot enters the tree")
	_trade_book = book


func configure_initial_state(state: P2PersistentState) -> bool:
	assert(
		not is_node_ready(),
		"initial persistent state must be configured before entering the tree",
	)
	if (
		state == null
		or _estate_runtime == null
		or state.map_id != _estate_runtime.get_map_id()
	):
		return false
	_initial_persistent_state = state.snapshot()
	return true


func configure_persistence_status(
	status: String,
	saving_allowed: bool = true,
) -> void:
	assert(
		not is_node_ready(),
		"persistence status must be configured before entering the tree",
	)
	assert(
		not status.strip_edges().is_empty(),
		"persistence status must not be empty",
	)
	_persistence_status = status.strip_edges()
	_persistence_saving_allowed = saving_allowed


func capture_persistent_state() -> P2PersistentState:
	assert(
		_farming_session != null and _estate_runtime != null,
		"persistent state can only be captured after pilot initialization",
	)
	return P2PersistentState.new(
		_estate_runtime.get_map_id(),
		_farming_session,
		_player.global_position,
		_player.facing,
		SAFE_SPAWN_ID,
		_player_health,
		_estate_runtime.get_current_state(),
		_daily_resource_claims,
	)


func present_persistence_failure(
	message: String,
	saving_allowed: bool = true,
) -> void:
	_persistence_saving_allowed = saving_allowed
	_persistence_status = (
		"自动保存失败 · 后续操作将重试"
		if saving_allowed
		else "存档故障 · 只读（不会覆盖）"
	)
	_update_persistence_labels()
	_refresh_persistence_day_label()
	_status_label.text = "自动保存失败：%s" % message


func present_persistence_status(status: String, message: String = "") -> void:
	assert(not status.strip_edges().is_empty(), "persistence status must not be empty")
	_persistence_status = status.strip_edges()
	_update_persistence_labels()
	_refresh_persistence_day_label()
	if not message.is_empty():
		_status_label.text = message


func present_navigation_failure(message: String) -> void:
	_close_pause_menu()
	_status_label.text = message


func present_return_save_failure(message: String) -> void:
	_pause_menu.present_return_failure(
		message,
		_persistence_status,
		_persistence_saving_allowed,
	)


func get_estate_runtime() -> EstateMapRuntime:
	return _estate_runtime


func get_player() -> P1PlayerController:
	return _player


func get_camera() -> Camera2D:
	return _camera


func get_farming_session() -> FarmingSessionState:
	return _farming_session.snapshot()


func get_farm_overlay() -> FarmPlotOverlay:
	return _farm_overlay


func get_daily_interaction_overlay() -> EstateDailyInteractionOverlay:
	return _daily_overlay


func get_interaction_feedback() -> P2InteractionFeedback:
	return _interaction_feedback


func get_pause_menu() -> P2PauseMenu:
	return _pause_menu


func get_day_transition() -> P2DayTransitionOverlay:
	return _day_transition


func current_life_loop_objective() -> P2LifeLoopObjective:
	if (
		_farming_session == null
		or _daily_resource_claims == null
		or _life_loop_guide == null
	):
		return null
	return _life_loop_guide.present(
		_farming_session,
		_daily_resource_claims,
	)


func get_player_cell() -> Vector2i:
	return _coordinate_mapper.world_to_cell(_player.global_position)


func reset_to_safe_spawn() -> void:
	_dismiss_day_transition()
	var spawn: EstateAnchorResult = _estate_runtime.query_anchor(
		&"spawn",
		SAFE_SPAWN_ID,
	)
	assert(spawn.is_found(), "H01 formal runtime must provide its safe spawn")
	_player.global_position = spawn.world_position
	_player.facing = Vector2i.DOWN
	_player.velocity = Vector2.ZERO
	_player.set_input_locked(false)
	_clear_rest_confirmation()
	_cancel_crate()
	_status_label.text = "已回到安全出生点 · 农作状态保留"
	_camera.reset_smoothing()


func apply_estate_state(state: EstateMapState) -> EstateMapApplyResult:
	_cancel_crate()
	var result: EstateMapApplyResult = _estate_runtime.apply_state(state)
	if result.is_success():
		_rendered_farming_session = null
		_refresh_farming_view()
		_status_label.text = "地产状态：%s / %s / %s" % [
			state.season,
			state.development,
			state.anomaly,
		]
		_commit_durable_state(&"estate.state_changed")
	else:
		_status_label.text = "地产状态切换失败：%s" % result.message
	return result


func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled
	_camera.position_smoothing_enabled = not enabled
	if enabled:
		_camera.reset_smoothing()
		_day_transition.finish_motion()


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


func _initialize_farming_session() -> void:
	var inventory := InventoryState.create_empty()
	inventory = _add_starter_item(inventory, &"hoe_basic", 1)
	inventory = _add_starter_item(inventory, &"watering_can_basic", 1)
	_farming_session = FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(_estate_runtime.get_map_id()),
			inventory,
		),
		1,
	)


func _initialize_daily_interactions() -> void:
	_daily_resource_claims = DailyResourceClaims.create_empty()
	var source_definitions: Array[DailyResourceSourceDefinition] = [
		DailyResourceSourceDefinition.new(
			RESOURCE_SEED_SOURCE_ID,
			_estate_runtime.get_map_id(),
			&"resource_spawn_zone",
			&"resource_north_meadow",
			&"mistleaf_seed",
			RESOURCE_SEED_QUANTITY,
			RESOURCE_CHOICE_GROUP_ID,
		),
		DailyResourceSourceDefinition.new(
			RESOURCE_FORAGE_SOURCE_ID,
			_estate_runtime.get_map_id(),
			&"resource_spawn_zone",
			&"resource_north_meadow",
			&"mistleaf",
			RESOURCE_FORAGE_QUANTITY,
			RESOURCE_CHOICE_GROUP_ID,
		),
	]
	_daily_resource_sources = DailyResourceSourceCatalog.create(
		source_definitions,
		_game_catalog,
	)
	assert(
		_daily_resource_sources != null,
		"P2 resource source definitions must match the validated game catalog",
	)
	var seed_source := _daily_resource_sources.get_source(
		RESOURCE_SEED_SOURCE_ID
	)
	var forage_source := _daily_resource_sources.get_source(
		RESOURCE_FORAGE_SOURCE_ID
	)
	assert(
		seed_source != null and forage_source != null,
		"P2 resource choice offers must resolve from the source catalog",
	)
	_crate_flow = NorthMeadowCrateFlow.new(
		_daily_resource_sources,
		_trade_book,
		_game_catalog,
		RESOURCE_SEED_SOURCE_ID,
		RESOURCE_FORAGE_SOURCE_ID,
		TRADE_ENDPOINT_ID,
	)
	var rest_definitions: Array[DailyRestPointDefinition] = [
		DailyRestPointDefinition.new(
			REST_POINT_ID,
			_estate_runtime.get_map_id(),
			&"interaction",
			&"home_door",
		),
	]
	_daily_rest_points = DailyRestPointCatalog.create(rest_definitions)
	assert(
		_daily_rest_points != null,
		"P2 rest-point definitions must be valid and unique",
	)
	_rest_point = _daily_rest_points.get_point(REST_POINT_ID)
	_resource_anchor = _estate_runtime.query_anchor(
		seed_source.anchor_kind,
		seed_source.anchor_id,
	)
	_rest_anchor = _estate_runtime.query_anchor(
		_rest_point.anchor_kind,
		_rest_point.anchor_id,
	)
	assert(
		_resource_anchor.is_found(),
		"H01 formal runtime must expose its resource placement zone",
	)
	assert(
		_rest_anchor.is_found(),
		"H01 formal runtime must expose its home-door rest point",
	)
	_daily_overlay.configure(
		_resource_anchor.world_position,
		_rest_anchor.world_position,
	)


func _restore_initial_state() -> bool:
	if _initial_persistent_state == null:
		return false
	var state := _initial_persistent_state
	var map_result := _estate_runtime.apply_state(state.estate_map_state)
	if not map_result.is_success():
		return false
	_farming_session = state.farming_session
	_daily_resource_claims = state.daily_resource_claims
	_player_health = state.player_health
	_rest_confirmation_day = 0
	var player_cell := _coordinate_mapper.world_to_cell(
		state.player_position
	)
	var semantics := _estate_runtime.query_cell(player_cell)
	if semantics.is_in_bounds() and not semantics.colliding:
		_player.global_position = state.player_position
		_player.facing = state.player_facing
	else:
		var fallback := _estate_runtime.query_anchor(
			&"spawn",
			state.player_fallback_anchor_id,
		)
		if not fallback.is_found():
			fallback = _estate_runtime.query_anchor(
				&"spawn",
				SAFE_SPAWN_ID,
			)
		if not fallback.is_found():
			return false
		_player.global_position = fallback.world_position
		_player.facing = Vector2i.DOWN
	_player.velocity = Vector2.ZERO
	_player.set_input_locked(false)
	_status_label.text = "已恢复本地档位 · 第 %d 天" % (
		_farming_session.world_day
	)
	_initial_persistent_state = null
	return true


func _add_starter_item(
	inventory: InventoryState,
	item_id: StringName,
	quantity: int,
) -> InventoryState:
	var addition := inventory.with_added(item_id, quantity, _game_catalog)
	assert(
		addition.status == InventoryTransactionResult.Status.ADDED,
		"P2 in-memory starter inventory must match the validated catalog",
	)
	return addition.inventory


func _select_quickbar_slot(slot_index: int) -> void:
	var selection := _farming_session.state.inventory.with_selected_slot(slot_index)
	if selection.status == InventoryTransactionResult.Status.INVALID_SLOT:
		return
	_replace_inventory(selection.inventory)


func _select_relative_slot(offset: int) -> void:
	var inventory := _farming_session.state.inventory
	var next_index := posmod(
		inventory.selected_slot_index + offset,
		inventory.capacity(),
	)
	_select_quickbar_slot(next_index)


func _replace_inventory(inventory: InventoryState) -> void:
	_farming_session = _farming_session.with_inventory(inventory)


func _use_selected_item() -> void:
	var stack: ItemStack = _farming_session.state.inventory.selected_stack()
	if stack == null:
		_status_label.text = "当前快捷栏为空"
		return
	var item: CatalogDefinitions.Item = _game_catalog.get_item(stack.item_id)
	if item == null:
		_status_label.text = "未知物品：%s" % stack.item_id
		return
	if item.kind == CatalogDefinitions.Item.Kind.SEED:
		_plant_seed(item.id)
		return
	if item.kind != CatalogDefinitions.Item.Kind.TOOL:
		_status_label.text = "该物品暂不能直接使用"
		return
	var tool: CatalogDefinitions.Tool = _game_catalog.get_tool(item.tool_id)
	if tool == null:
		_status_label.text = "工具定义缺失：%s" % item.tool_id
		return
	if tool.action == CatalogDefinitions.Tool.Action.TILL:
		_till_target()
	elif tool.action == CatalogDefinitions.Tool.Action.WATER:
		_water_target()


func _target_cell() -> Vector2i:
	return _coordinate_mapper.facing_cell(
		_player.global_position,
		_player.facing,
	)


func _till_target() -> void:
	var target := _target_cell()
	var semantics: EstateCellSemantics = _estate_runtime.query_cell(target)
	var is_farmable := (
		semantics.is_in_bounds()
		and semantics.farmable
		and not semantics.colliding
	)
	var result: FarmTransactionResult = _farming_session.state.farm.try_till(
		target,
		is_farmable,
	)
	if result.status == FarmTransactionResult.Status.TILLED:
		_farming_session = FarmingSessionState.new(
			FarmingTransactionState.new(
				result.farm,
				_farming_session.state.inventory,
			),
			_farming_session.world_day,
		)
		_status_label.text = "已耕地：%s" % target
		_play_interaction_feedback(&"sfx.farm.till", target)
		_commit_durable_state(&"farm.tilled", false, &"farm.tilled")
	elif result.status == FarmTransactionResult.Status.ALREADY_TILLED:
		_status_label.text = "这里已经耕过"
	else:
		_status_label.text = "这里不能耕作"


func _plant_seed(seed_item_id: StringName) -> void:
	var result := CropPlanting.attempt(
		_farming_session,
		CropPlantingCommand.new(
			_estate_runtime.get_map_id(),
			_target_cell(),
			_farming_session.world_day,
			_estate_runtime.get_current_state().season,
			seed_item_id,
		),
		_game_catalog,
	)
	if result.is_success():
		_farming_session = result.session
		_status_label.text = "已播种雾叶草"
		_play_interaction_feedback(&"sfx.farm.plant", _target_cell())
		_commit_durable_state(&"farm.planted", false, &"farm.planted")
	elif result.status == CropPlantingResult.Status.NOT_TILLED:
		_status_label.text = "需要先耕地"
	elif result.status == CropPlantingResult.Status.TILE_OCCUPIED:
		_status_label.text = "这块地已有作物"
	elif result.status == CropPlantingResult.Status.INSUFFICIENT_SEED:
		_status_label.text = "种子不足"
	else:
		_status_label.text = "当前不能播种"


func _water_target() -> void:
	var result := FarmWatering.attempt(
		_farming_session,
		FarmWateringCommand.new(
			_estate_runtime.get_map_id(),
			_target_cell(),
			_farming_session.world_day,
		),
	)
	if result.is_success():
		_farming_session = result.session
		_status_label.text = "已浇水：%s" % _target_cell()
		_play_interaction_feedback(&"sfx.farm.water", _target_cell())
		_commit_durable_state(&"farm.watered", false, &"farm.watered")
	elif result.status == FarmWateringResult.Status.ALREADY_WATERED:
		_status_label.text = "今天已经浇过水"
	else:
		_status_label.text = "只能给耕地浇水"


func _select_and_use_watering_can() -> void:
	for slot_index: int in _farming_session.state.inventory.capacity():
		var stack: ItemStack = _farming_session.state.inventory.stack_at(slot_index)
		if stack != null and stack.item_id == &"watering_can_basic":
			_select_quickbar_slot(slot_index)
			_water_target()
			return


func _advance_crate(intent: NorthMeadowCrateFlow.Intent) -> void:
	var result := _crate_flow.advance(
		intent,
		_farming_session,
		_daily_resource_claims,
	)
	_farming_session = result.session
	_daily_resource_claims = result.claims
	if not result.message.is_empty():
		_status_label.text = result.message
	if not result.durable_reason.is_empty():
		_play_interaction_feedback(result.audio_id, _resource_anchor.cell)
		_commit_durable_state(
			result.durable_reason,
			false,
			result.committed_action_id,
		)
	_update_daily_overlay()


func _is_crate_open() -> bool:
	if _crate_flow == null:
		return false
	return _crate_flow.presentation(
		_farming_session,
		_daily_resource_claims,
	).is_open


func _cancel_crate() -> void:
	if _crate_flow == null or _farming_session == null:
		return
	_advance_crate(NorthMeadowCrateFlow.Intent.CANCEL)


func _request_or_complete_rest() -> void:
	_cancel_crate()
	if _rest_confirmation_day != _farming_session.world_day:
		_rest_confirmation_day = _farming_session.world_day
		_status_label.text = "回屋休息并结束今天？再次交互确认"
		_update_daily_overlay()
		_play_interaction_feedback(&"sfx.rest.confirm", _rest_anchor.cell)
		return
	var completed_day: int = _farming_session.world_day
	var result := DailyRestCycle.attempt(
		_farming_session,
		DailyRestCommand.new(
			REST_POINT_ID,
			_farming_session.world_day,
		),
		_daily_rest_points,
		_game_catalog,
	)
	if result.is_success():
		_farming_session = result.session
		_clear_rest_confirmation()
		_status_label.text = "天亮了 · 第 %d 天 · %d 株作物成长" % [
			_farming_session.world_day,
			result.grown_crop_count,
		]
		_play_interaction_feedback(&"sfx.rest.complete", _rest_anchor.cell)
		_play_rest_transition(P2DayTransitionSummary.new(
			completed_day,
			_farming_session.world_day,
			result.grown_crop_count,
		))
		_commit_durable_state(&"day.rested", true, &"day.rested")
	else:
		_clear_rest_confirmation()
		_status_label.text = "休息失败：当天状态不连续"


func _clear_rest_confirmation() -> void:
	if _rest_confirmation_day == 0:
		return
	_rest_confirmation_day = 0
	_update_daily_overlay()


func _play_rest_transition(summary: P2DayTransitionSummary) -> void:
	_player.velocity = Vector2.ZERO
	_player.set_input_locked(true)
	_day_transition.present(summary, _reduce_motion)


func _dismiss_day_transition() -> void:
	if _day_transition == null or not _day_transition.is_open():
		return
	_day_transition.dismiss()
	_player.set_input_locked(_pause_menu.is_open())


func _attempt_harvest(target_cell: Vector2i) -> bool:
	var result := CropHarvesting.attempt(
		_farming_session,
		CropHarvestingCommand.new(
			_estate_runtime.get_map_id(),
			target_cell,
		),
		_game_catalog,
	)
	if result.is_success():
		_farming_session = result.session
		_status_label.text = "收获雾叶草 ×%d" % result.harvested_quantity
		_play_interaction_feedback(&"sfx.farm.harvest", target_cell)
		_commit_durable_state(
			&"farm.harvested",
			false,
			&"farm.harvested",
		)
		return true
	if result.status == CropHarvestingResult.Status.NOT_MATURE:
		_status_label.text = "作物尚未成熟"
		return true
	if result.status == CropHarvestingResult.Status.INVENTORY_FULL:
		_status_label.text = "背包已满，无法收获"
		return true
	return false


func _on_interaction_requested(
	world_position: Vector2,
	facing_direction: Vector2i,
) -> void:
	if _day_transition.is_open():
		return
	var target_cell := _coordinate_mapper.facing_cell(
		world_position,
		facing_direction,
	)
	if target_cell == _resource_anchor.cell:
		_clear_rest_confirmation()
		_advance_crate(NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM)
		_refresh_farming_view()
		return
	if target_cell == _rest_anchor.cell:
		_cancel_crate()
		_request_or_complete_rest()
		_refresh_farming_view()
		return
	_clear_rest_confirmation()
	_cancel_crate()
	if _attempt_harvest(target_cell):
		_refresh_farming_view()
		return
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


func _refresh_farming_view() -> void:
	if _farming_session == null:
		return
	if _rendered_farming_session == _farming_session:
		return
	_rendered_farming_session = _farming_session
	_farm_overlay.show_state(
		_farming_session.state.farm,
		_farming_session.world_day,
	)
	_update_daily_overlay()
	_day_label.text = "第 %d 天 · %s · %s" % [
		_farming_session.world_day,
		_season_display_name(_estate_runtime.get_current_state().season),
		_persistence_status,
	]
	var inventory := _farming_session.state.inventory
	var slot_labels: PackedStringArray = []
	for slot_index: int in inventory.capacity():
		var stack: ItemStack = inventory.stack_at(slot_index)
		var marker := ">" if slot_index == inventory.selected_slot_index else " "
		if stack == null:
			slot_labels.append("%s%d:空" % [marker, slot_index + 1])
		else:
			slot_labels.append(
				"%s%d:%s×%d" % [
					marker,
					slot_index + 1,
					_short_item_name(stack.item_id),
					stack.quantity,
				]
			)
	_quickbar_label.text = "  ".join(slot_labels)
	var objective := current_life_loop_objective()
	_objective_label.text = (
		"目标：%s" % objective.text
		if objective != null
		else "目标：生活循环状态暂不可用"
	)


func _update_persistence_labels() -> void:
	if _title_label == null:
		return
	_title_label.text = (
		"P2 地产生活闭环 · H01 开阔草甸（%s）\n"
		+ "移动 · E/A 选择/确认/收获/休息 · "
		+ "Q/Tab/肩键切换 · F/X 使用 · Esc/Start 暂停"
	) % _persistence_status


func _open_pause_menu() -> void:
	_clear_rest_confirmation()
	_cancel_crate()
	_player.velocity = Vector2.ZERO
	_player.set_input_locked(true)
	_pause_menu.open(
		_persistence_status,
		_persistence_saving_allowed,
	)
	get_tree().paused = true


func _close_pause_menu() -> void:
	if get_tree() != null:
		get_tree().paused = false
	_pause_menu.close()
	_player.set_input_locked(_day_transition.is_open())
	_discard_next_input_sample = true


func _on_return_to_title_requested() -> void:
	return_to_title_requested.emit()


func _refresh_persistence_day_label() -> void:
	if _day_label == null or _farming_session == null:
		return
	_day_label.text = "第 %d 天 · %s · %s" % [
		_farming_session.world_day,
		_season_display_name(_estate_runtime.get_current_state().season),
		_persistence_status,
	]


func _commit_durable_state(
	reason: StringName,
	protect_recovery: bool = false,
	playtest_action_id: StringName = &"",
) -> void:
	durable_state_committed.emit(reason, protect_recovery)
	if not playtest_action_id.is_empty():
		playtest_action_committed.emit(playtest_action_id)


func _update_daily_overlay() -> void:
	if (
		_daily_overlay == null
		or _daily_resource_claims == null
		or _crate_flow == null
	):
		return
	_daily_overlay.show_crate(
		_crate_flow.presentation(
			_farming_session,
			_daily_resource_claims,
		)
	)
	_daily_overlay.show_rest_confirmation(
		_rest_confirmation_day == _farming_session.world_day
	)


func _play_interaction_feedback(
	audio_id: StringName,
	target_cell: Vector2i,
) -> void:
	if _audio_service != null:
		_audio_service.play_sound(audio_id)
	_interaction_feedback.play(
		audio_id,
		_coordinate_mapper.cell_center(target_cell),
		_reduce_motion,
	)


func _short_item_name(item_id: StringName) -> String:
	if item_id == &"hoe_basic":
		return "锄"
	if item_id == &"watering_can_basic":
		return "壶"
	if item_id == &"mistleaf_seed":
		return "种"
	if item_id == &"mistleaf":
		return "雾叶"
	if item_id == &"village_scrip":
		return "券"
	return String(item_id)


func _season_display_name(season: StringName) -> String:
	if season == &"spring":
		return "春季"
	if season == &"summer":
		return "夏季"
	if season == &"autumn":
		return "秋季"
	if season == &"winter":
		return "冬季"
	return String(season)


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
		+ "day: %d\n" % _farming_session.world_day
		+ "farm tiles: %d\n" % _farming_session.state.farm.tile_count()
		+ "selected: %d\n" % (
			_farming_session.state.inventory.selected_slot_index + 1
		)
		+ "reduce motion: %s" % _reduce_motion
	)

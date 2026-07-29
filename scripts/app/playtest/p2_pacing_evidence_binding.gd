class_name P2PacingEvidenceBinding
extends Node

## Application bridge only: gameplay emits semantic success IDs while this
## binding samples read-only state. Neither side knows a file path or JSONL.

const SCENARIO_ID: StringName = &"p2.h01.life_loop"
const INPUT_DEVICE_FAMILY: StringName = &"mixed_or_unknown"

var _pilot: P2EstatePilot
var _evidence: P2PacingEvidenceSession


func configure(
	service: AnalyticsService,
	pilot: P2EstatePilot,
	run_kind: StringName,
	starting_state_kind: StringName,
	clock: P2PacingClock = null,
) -> void:
	assert(
		not is_node_ready(),
		"pacing evidence binding must be configured before entering the tree",
	)
	assert(service != null, "pacing evidence binding requires a service")
	assert(pilot != null, "pacing evidence binding requires a P2 pilot")
	assert(
		not pilot.playtest_action_committed.is_connected(
			_on_playtest_action_committed
		),
		"pacing evidence binding must only be configured once",
	)
	_pilot = pilot
	_evidence = P2PacingEvidenceSession.new(
		service,
		clock if clock != null else SystemP2PacingClock.new(),
		run_kind,
		SCENARIO_ID,
		INPUT_DEVICE_FAMILY,
		starting_state_kind,
		P2PacingEvidenceSession.BUILD_REVISION,
		P2PacingEvidenceSession.CONTENT_REVISION,
	)
	pilot.playtest_action_committed.connect(_on_playtest_action_committed)
	pilot.durable_state_committed.connect(_on_durable_state_committed)


func _ready() -> void:
	call_deferred("_begin_after_pilot_ready")


func _begin_after_pilot_ready() -> void:
	if _pilot == null or not _pilot.is_node_ready():
		return
	_evidence.begin(_capture_sample())


func _on_playtest_action_committed(action_id: StringName) -> void:
	if not _pilot.is_node_ready():
		return
	_evidence.begin(_capture_sample())
	_evidence.record_action(action_id, _capture_sample())


func _on_durable_state_committed(
	reason: StringName,
	_protect_recovery: bool,
) -> void:
	if reason != &"session.exiting" or not _pilot.is_node_ready():
		return
	_evidence.begin(_capture_sample())
	_evidence.finish(_capture_sample())


func _capture_sample() -> P2PacingEvidenceSample:
	var session := _pilot.get_farming_session()
	var objective := _pilot.current_life_loop_objective()
	var objective_id := (
		objective.stable_id
		if objective != null
		else &"p2.h01.guide.unavailable"
	)
	var farm_tiles := session.state.farm.copy_tiles()
	var crop_count: int = 0
	for tile: FarmTileState in farm_tiles:
		if tile.crop != null:
			crop_count += 1
	var inventory := session.state.inventory
	return P2PacingEvidenceSample.new(
		_pilot.get_estate_runtime().get_map_id(),
		session.world_day,
		objective_id,
		farm_tiles.size(),
		crop_count,
		_inventory_quantity(inventory, &"mistleaf_seed"),
		_inventory_quantity(inventory, &"mistleaf"),
		_inventory_quantity(inventory, &"village_scrip"),
	)


func _inventory_quantity(
	inventory: InventoryState,
	item_id: StringName,
) -> int:
	var total: int = 0
	for slot_index: int in inventory.capacity():
		var stack: ItemStack = inventory.stack_at(slot_index)
		if stack != null and stack.item_id == item_id:
			total += stack.quantity
	return total

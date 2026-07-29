class_name P2PacingEvidenceSession
extends RefCounted

## Versioned, privacy-bounded P2 evidence policy. Callers provide typed
## snapshots and stable action IDs; only this module constructs analytics
## properties or decides whether one observed session covered the full loop.

const EVIDENCE_SCHEMA_VERSION: int = 1
const RUN_KIND_HUMAN_INTERNAL: StringName = &"human_internal"
const RUN_KIND_AUTOMATION: StringName = &"automation"
const STARTING_STATE_FRESH: StringName = &"fresh"
const STARTING_STATE_RESUMED: StringName = &"resumed"
const BUILD_REVISION: StringName = &"p2.pacing.instrumentation.v1"
const CONTENT_REVISION: StringName = &"p2.h01.balance.v1"

const ACTION_RESOURCE_SEED: StringName = &"home.h01.resource.north_meadow"
const ACTION_RESOURCE_FORAGE: StringName = (
	&"home.h01.resource.north_meadow.forage"
)
const ACTION_TILL: StringName = &"farm.tilled"
const ACTION_PLANT: StringName = &"farm.planted"
const ACTION_WATER: StringName = &"farm.watered"
const ACTION_REST: StringName = &"day.rested"
const ACTION_HARVEST: StringName = &"farm.harvested"
const ACTION_SELL: StringName = &"economy.h01.sell_mistleaf"
const ACTION_BUY: StringName = &"economy.h01.buy_mistleaf_seed"

const EVENT_SESSION_STARTED: StringName = &"p2.pacing.session_started"
const EVENT_OBJECTIVE_CHANGED: StringName = &"p2.pacing.objective_changed"
const EVENT_ACTION_COMMITTED: StringName = &"p2.pacing.action_committed"
const EVENT_SESSION_ENDED: StringName = &"p2.pacing.session_ended"

const _ALLOWLISTED_ACTIONS: Array[StringName] = [
	ACTION_RESOURCE_SEED,
	ACTION_RESOURCE_FORAGE,
	ACTION_TILL,
	ACTION_PLANT,
	ACTION_WATER,
	ACTION_REST,
	ACTION_HARVEST,
	ACTION_SELL,
	ACTION_BUY,
]
const _ORDERED_LOOP_ACTIONS: Array[StringName] = [
	ACTION_TILL,
	ACTION_PLANT,
	ACTION_WATER,
	ACTION_REST,
	ACTION_HARVEST,
	ACTION_SELL,
]

var _sink: AnalyticsService
var _clock: P2PacingClock
var _run_kind: StringName
var _scenario_id: StringName
var _input_device_family: StringName
var _starting_state_kind: StringName
var _build_revision: StringName
var _content_revision: StringName
var _started_at_msec: int = 0
var _started: bool = false
var _finished: bool = false
var _last_objective_id: StringName = &""
var _resource_choice_observed: bool = false
var _ordered_loop_index: int = 0
var _unknown_actions: int = 0


func _init(
	sink: AnalyticsService,
	clock: P2PacingClock,
	run_kind: StringName,
	scenario_id: StringName,
	input_device_family: StringName,
	starting_state_kind: StringName,
	build_revision: StringName,
	content_revision: StringName,
) -> void:
	assert(sink != null, "pacing evidence requires an analytics sink")
	assert(clock != null, "pacing evidence requires a monotonic clock")
	assert(
		run_kind == RUN_KIND_HUMAN_INTERNAL
		or run_kind == RUN_KIND_AUTOMATION,
		"pacing evidence must separate human and automation data",
	)
	assert(not scenario_id.is_empty(), "pacing evidence requires a scenario ID")
	assert(
		not input_device_family.is_empty(),
		"pacing evidence requires an input-device family",
	)
	assert(
		starting_state_kind == STARTING_STATE_FRESH
		or starting_state_kind == STARTING_STATE_RESUMED,
		"pacing evidence requires an explicit starting-state kind",
	)
	assert(not build_revision.is_empty(), "pacing evidence requires a build revision")
	assert(
		not content_revision.is_empty(),
		"pacing evidence requires a content revision",
	)
	_sink = sink
	_clock = clock
	_run_kind = run_kind
	_scenario_id = scenario_id
	_input_device_family = input_device_family
	_starting_state_kind = starting_state_kind
	_build_revision = build_revision
	_content_revision = content_revision


func begin(sample: P2PacingEvidenceSample) -> bool:
	assert(sample != null, "pacing evidence begin requires a typed sample")
	if _started or _finished:
		return false
	_started = true
	_started_at_msec = _clock.now_msec()
	_last_objective_id = sample.objective_id
	_sink.track(EVENT_SESSION_STARTED, _properties(sample))
	_sink.track(EVENT_OBJECTIVE_CHANGED, _properties(sample))
	return true


func record_action(
	action_id: StringName,
	sample: P2PacingEvidenceSample,
) -> bool:
	assert(sample != null, "pacing evidence actions require a typed sample")
	if not _started or _finished:
		return false
	if not _ALLOWLISTED_ACTIONS.has(action_id):
		_unknown_actions += 1
		return false
	var properties := _properties(sample)
	properties["actionId"] = String(action_id)
	_sink.track(EVENT_ACTION_COMMITTED, properties)
	_advance_ordered_loop(action_id)
	if sample.objective_id != _last_objective_id:
		_last_objective_id = sample.objective_id
		_sink.track(EVENT_OBJECTIVE_CHANGED, _properties(sample))
	return true


func finish(sample: P2PacingEvidenceSample) -> bool:
	assert(sample != null, "pacing evidence finish requires a typed sample")
	if not _started or _finished:
		return false
	_finished = true
	var properties := _properties(sample)
	if _starting_state_kind == STARTING_STATE_RESUMED:
		properties["outcome"] = "excluded_resumed"
	elif _has_complete_ordered_loop():
		properties["outcome"] = "complete_loop"
	else:
		properties["outcome"] = "incomplete"
	properties["unknownActionCount"] = _unknown_actions
	_sink.track(EVENT_SESSION_ENDED, properties)
	return true


func unknown_action_count() -> int:
	return _unknown_actions


func is_finished() -> bool:
	return _finished


func _properties(sample: P2PacingEvidenceSample) -> Dictionary:
	return {
		"evidenceSchemaVersion": EVIDENCE_SCHEMA_VERSION,
		"runKind": String(_run_kind),
		"scenarioId": String(_scenario_id),
		"inputDeviceFamily": String(_input_device_family),
		"startingStateKind": String(_starting_state_kind),
		"buildRevision": String(_build_revision),
		"contentRevision": String(_content_revision),
		"elapsedMs": maxi(0, _clock.now_msec() - _started_at_msec),
		"mapId": String(sample.map_id),
		"worldDay": sample.world_day,
		"objectiveId": String(sample.objective_id),
		"farmTileCount": sample.farm_tile_count,
		"cropCount": sample.crop_count,
		"seedCount": sample.seed_count,
		"forageCount": sample.forage_count,
		"scripCount": sample.scrip_count,
	}


func _advance_ordered_loop(action_id: StringName) -> void:
	## Extra valid actions are still recorded, but only the first ordered
	## resource -> farm -> day -> harvest -> sale chain advances completion.
	if (
		action_id == ACTION_RESOURCE_SEED
		or action_id == ACTION_RESOURCE_FORAGE
	):
		if _ordered_loop_index == 0:
			_resource_choice_observed = true
		return
	if (
		not _resource_choice_observed
		or _ordered_loop_index >= _ORDERED_LOOP_ACTIONS.size()
		or action_id != _ORDERED_LOOP_ACTIONS[_ordered_loop_index]
	):
		return
	_ordered_loop_index += 1


func _has_complete_ordered_loop() -> bool:
	return (
		_resource_choice_observed
		and _ordered_loop_index == _ORDERED_LOOP_ACTIONS.size()
	)

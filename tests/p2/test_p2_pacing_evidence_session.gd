extends SceneTree


class FakePacingClock extends P2PacingClock:
	var current_msec: int = 0


	func now_msec() -> int:
		return current_msec


class RecordingAnalyticsService extends AnalyticsService:
	var events: Array[Dictionary] = []


	func track(event_name: StringName, properties: Dictionary = {}) -> void:
		events.append({
			"eventName": event_name,
			"properties": properties.duplicate(true),
		})


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_complete_loop_uses_stable_events_and_monotonic_time()
	_test_unknown_actions_are_rejected_and_incomplete_runs_stay_distinct()
	_test_order_and_starting_state_prevent_false_complete_loops()
	_finish()


func _test_complete_loop_uses_stable_events_and_monotonic_time() -> void:
	var sink := RecordingAnalyticsService.new()
	var clock := FakePacingClock.new()
	clock.current_msec = 1000
	var evidence := P2PacingEvidenceSession.new(
		sink,
		clock,
		P2PacingEvidenceSession.RUN_KIND_AUTOMATION,
		&"p2.h01.life_loop",
		&"mixed_or_unknown",
		P2PacingEvidenceSession.STARTING_STATE_FRESH,
		P2PacingEvidenceSession.BUILD_REVISION,
		P2PacingEvidenceSession.CONTENT_REVISION,
	)
	_check(
		evidence.begin(_sample(1, &"p2.h01.guide.claim_daily", 0, 0, 0)),
		"a pacing session begins once from a typed sample",
	)
	var actions: Array[StringName] = [
		P2PacingEvidenceSession.ACTION_RESOURCE_SEED,
		P2PacingEvidenceSession.ACTION_TILL,
		P2PacingEvidenceSession.ACTION_PLANT,
		P2PacingEvidenceSession.ACTION_WATER,
		P2PacingEvidenceSession.ACTION_REST,
		P2PacingEvidenceSession.ACTION_HARVEST,
		P2PacingEvidenceSession.ACTION_SELL,
	]
	var objective_ids: Array[StringName] = [
		&"p2.h01.guide.till",
		&"p2.h01.guide.plant",
		&"p2.h01.guide.water",
		&"p2.h01.guide.rest_growth",
		&"p2.h01.guide.harvest",
		&"p2.h01.guide.sell",
		&"p2.h01.guide.claim_daily",
	]
	for index: int in actions.size():
		clock.current_msec += 250
		_check(
			evidence.record_action(
				actions[index],
				_sample(
					2 if actions[index] == P2PacingEvidenceSession.ACTION_REST else 1,
					objective_ids[index],
					1 if index >= 1 else 0,
					1 if index >= 2 and index < 5 else 0,
					30 if index == actions.size() - 1 else 0,
				),
			),
			"the allowlisted life-loop action is recorded: %s" % actions[index],
		)
	clock.current_msec = 3000
	_check(
		evidence.finish(_sample(
			2,
			&"p2.h01.guide.claim_daily",
			1,
			0,
			30,
		)),
		"a pacing session finishes once",
	)
	var started := _events_named(sink.events, &"p2.pacing.session_started")
	var actions_recorded := _events_named(
		sink.events,
		&"p2.pacing.action_committed",
	)
	var ended := _events_named(sink.events, &"p2.pacing.session_ended")
	_check(started.size() == 1, "one session-start event is emitted")
	_check(
		actions_recorded.size() == actions.size(),
		"each successful life-loop milestone emits one action event",
	)
	_check(ended.size() == 1, "one session-end event is emitted")
	if not started.is_empty():
		var properties: Dictionary = started[0]["properties"]
		_check(
			properties["runKind"] == "automation"
			and properties["scenarioId"] == "p2.h01.life_loop"
			and properties["startingStateKind"] == "fresh"
			and properties["buildRevision"] == "p2.pacing.instrumentation.v1"
			and properties["contentRevision"] == "p2.h01.balance.v1"
			and properties["evidenceSchemaVersion"] == 1,
			"automation evidence is explicitly separated and revisioned",
		)
		_check(
			not properties.has("profileId")
			and not properties.has("filePath")
			and not properties.has("position"),
			"session evidence excludes profile, path, and position data",
		)
	if not ended.is_empty():
		var properties: Dictionary = ended[0]["properties"]
		_check(
			properties["outcome"] == "complete_loop"
			and properties["elapsedMs"] == 2000,
			"the required action set derives a complete loop with deterministic time",
		)


func _test_unknown_actions_are_rejected_and_incomplete_runs_stay_distinct() -> void:
	var sink := RecordingAnalyticsService.new()
	var clock := FakePacingClock.new()
	var evidence := P2PacingEvidenceSession.new(
		sink,
		clock,
		P2PacingEvidenceSession.RUN_KIND_HUMAN_INTERNAL,
		&"p2.h01.life_loop",
		&"mixed_or_unknown",
		P2PacingEvidenceSession.STARTING_STATE_FRESH,
		P2PacingEvidenceSession.BUILD_REVISION,
		P2PacingEvidenceSession.CONTENT_REVISION,
	)
	evidence.begin(_sample(1, &"p2.h01.guide.claim_daily", 0, 0, 0))
	var event_count := sink.events.size()
	_check(
		not evidence.record_action(
			&"unknown.free_text.action",
			_sample(1, &"p2.h01.guide.claim_daily", 0, 0, 0),
		),
		"unknown action IDs are rejected at the typed evidence boundary",
	)
	_check(
		sink.events.size() == event_count
		and evidence.unknown_action_count() == 1,
		"rejected actions neither reach the sink nor disappear silently",
	)
	clock.current_msec = 500
	evidence.finish(_sample(1, &"p2.h01.guide.claim_daily", 0, 0, 0))
	var ended := _events_named(sink.events, &"p2.pacing.session_ended")
	_check(
		ended.size() == 1
		and ended[0]["properties"]["outcome"] == "incomplete",
		"ending without the required loop remains explicitly incomplete",
	)


func _test_order_and_starting_state_prevent_false_complete_loops() -> void:
	var out_of_order_sink := RecordingAnalyticsService.new()
	var out_of_order := P2PacingEvidenceSession.new(
		out_of_order_sink,
		FakePacingClock.new(),
		P2PacingEvidenceSession.RUN_KIND_AUTOMATION,
		&"p2.h01.life_loop",
		&"mixed_or_unknown",
		P2PacingEvidenceSession.STARTING_STATE_FRESH,
		P2PacingEvidenceSession.BUILD_REVISION,
		P2PacingEvidenceSession.CONTENT_REVISION,
	)
	out_of_order.begin(_sample(1, &"p2.h01.guide.claim_daily", 0, 0, 0))
	for action_id: StringName in [
		P2PacingEvidenceSession.ACTION_RESOURCE_SEED,
		P2PacingEvidenceSession.ACTION_PLANT,
		P2PacingEvidenceSession.ACTION_TILL,
		P2PacingEvidenceSession.ACTION_WATER,
		P2PacingEvidenceSession.ACTION_REST,
		P2PacingEvidenceSession.ACTION_HARVEST,
		P2PacingEvidenceSession.ACTION_SELL,
	]:
		out_of_order.record_action(
			action_id,
			_sample(2, &"p2.h01.guide.claim_daily", 1, 0, 30),
		)
	out_of_order.finish(_sample(
		2,
		&"p2.h01.guide.claim_daily",
		1,
		0,
		30,
	))
	var out_of_order_end := _events_named(
		out_of_order_sink.events,
		P2PacingEvidenceSession.EVENT_SESSION_ENDED,
	)
	_check(
		out_of_order_end.size() == 1
		and out_of_order_end[0]["properties"]["outcome"] == "incomplete",
		"an unordered action set cannot masquerade as one completed loop",
	)

	var resumed_sink := RecordingAnalyticsService.new()
	var resumed := P2PacingEvidenceSession.new(
		resumed_sink,
		FakePacingClock.new(),
		P2PacingEvidenceSession.RUN_KIND_HUMAN_INTERNAL,
		&"p2.h01.life_loop",
		&"mixed_or_unknown",
		P2PacingEvidenceSession.STARTING_STATE_RESUMED,
		P2PacingEvidenceSession.BUILD_REVISION,
		P2PacingEvidenceSession.CONTENT_REVISION,
	)
	resumed.begin(_sample(4, &"p2.h01.guide.claim_daily", 0, 0, 0))
	for action_id: StringName in [
		P2PacingEvidenceSession.ACTION_RESOURCE_SEED,
		P2PacingEvidenceSession.ACTION_TILL,
		P2PacingEvidenceSession.ACTION_PLANT,
		P2PacingEvidenceSession.ACTION_WATER,
		P2PacingEvidenceSession.ACTION_REST,
		P2PacingEvidenceSession.ACTION_HARVEST,
		P2PacingEvidenceSession.ACTION_SELL,
	]:
		resumed.record_action(
			action_id,
			_sample(5, &"p2.h01.guide.claim_daily", 1, 0, 30),
		)
	resumed.finish(_sample(
		5,
		&"p2.h01.guide.claim_daily",
		1,
		0,
		30,
	))
	var resumed_end := _events_named(
		resumed_sink.events,
		P2PacingEvidenceSession.EVENT_SESSION_ENDED,
	)
	_check(
		resumed_end.size() == 1
		and resumed_end[0]["properties"]["startingStateKind"] == "resumed"
		and resumed_end[0]["properties"]["outcome"] == "excluded_resumed",
		"a resumed profile remains identifiable and excluded from first-loop completion",
	)


func _sample(
	world_day: int,
	objective_id: StringName,
	farm_tile_count: int,
	crop_count: int,
	scrip_count: int,
) -> P2PacingEvidenceSample:
	return P2PacingEvidenceSample.new(
		&"home_h01_open_meadow",
		world_day,
		objective_id,
		farm_tile_count,
		crop_count,
		0,
		0,
		scrip_count,
	)


func _events_named(
	events: Array[Dictionary],
	event_name: StringName,
) -> Array[Dictionary]:
	var matching: Array[Dictionary] = []
	for event: Dictionary in events:
		if event["eventName"] == event_name:
			matching.append(event)
	return matching


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_PACING_EVIDENCE_SESSION_OK")
		quit(0)
		return
	push_error("P2 pacing-evidence session test failed: %d check(s)" % _failures)
	quit(1)

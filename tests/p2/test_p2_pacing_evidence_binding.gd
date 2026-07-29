extends SceneTree


class MemorySaveService extends SaveService:
	var payloads: Dictionary[StringName, String] = {}


	func read(slot_id: StringName) -> SaveReadResult:
		if not payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(payloads[slot_id])


	func read_previous(_slot_id: StringName) -> SaveReadResult:
		return SaveReadResult.missing()


	func write(slot_id: StringName, payload: String) -> SaveWriteResult:
		payloads[slot_id] = payload
		return SaveWriteResult.written()


	func remove(slot_id: StringName) -> SaveWriteResult:
		payloads.erase(slot_id)
		return SaveWriteResult.written()


class RecordingAnalyticsService extends AnalyticsService:
	var events: Array[Dictionary] = []


	func track(event_name: StringName, properties: Dictionary = {}) -> void:
		events.append({
			"eventName": event_name,
			"properties": properties.duplicate(true),
		})


class FaultInjectingLocalJsonlAnalyticsService extends LocalJsonlAnalyticsService:
	var _write_attempt: int = 0
	var _fail_on_attempt: int


	func _init(
		output_directory: String,
		session_id: String,
		fail_on_attempt: int,
	) -> void:
		_fail_on_attempt = fail_on_attempt
		super(output_directory, session_id)


	func _write_jsonl_line(line: String) -> bool:
		_write_attempt += 1
		if _write_attempt >= _fail_on_attempt:
			return false
		return super._write_jsonl_line(line)


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var composition_root := AppCompositionRoot.new()
	composition_root.bootstrap()
	_check(
		composition_root._resolve_local_pacing_run_kind(
			PackedStringArray(["--p2-pacing-human"])
		) == P2PacingEvidenceSession.RUN_KIND_HUMAN_INTERNAL
		and composition_root._resolve_local_pacing_run_kind(
			PackedStringArray(["--p2-pacing-automation"])
		) == P2PacingEvidenceSession.RUN_KIND_AUTOMATION
		and composition_root._resolve_local_pacing_run_kind(
			PackedStringArray([
				"--p2-pacing-human",
				"--p2-pacing-automation",
			])
		).is_empty(),
		"only one explicit pacing flag resolves to one unambiguous run kind",
	)
	var local_service := composition_root.create_analytics_service(
		"composition-test-%d" % Time.get_ticks_usec()
	) as LocalJsonlAnalyticsService
	_check(
		local_service != null
		and local_service.is_ready()
		and local_service.output_path().replace("\\", "/").begins_with("D:/"),
		"the composition root resolves local evidence to an absolute D-drive path",
	)
	if local_service != null:
		var local_path := local_service.output_path()
		local_service.close()
		if FileAccess.file_exists(local_path):
			DirAccess.remove_absolute(local_path)
	var default_launch := composition_root.create_h01_launch(
		&"profile-1",
		MemorySaveService.new(),
	)
	_check(
		default_launch.is_ready()
		and default_launch.pilot != null
		and default_launch.pilot.get_node_or_null(
			"PacingEvidenceBinding"
		) == null,
		"ordinary launches never infer that a human pacing session was armed",
	)
	if default_launch.pilot != null:
		default_launch.pilot.free()
	var sink := RecordingAnalyticsService.new()
	var launch := composition_root.create_h01_launch(
		&"profile-1",
		MemorySaveService.new(),
		sink,
		P2PacingEvidenceSession.RUN_KIND_AUTOMATION,
	)
	_check(
		launch.is_ready() and launch.pilot != null,
		"pacing evidence remains an optional composition dependency",
	)
	if not launch.is_ready():
		_finish()
		return
	root.add_child(launch.pilot)
	current_scene = launch.pilot
	await process_frame
	_check(
		_count_events(sink, &"p2.pacing.session_started") == 1,
		"the application binding starts evidence only after the pilot is ready",
	)
	launch.pilot.playtest_action_committed.emit(&"farm.tilled")
	launch.pilot.playtest_action_committed.emit(&"unknown.unregistered")
	_check(
		_count_events(sink, &"p2.pacing.action_committed") == 1,
		"the binding forwards allowlisted committed actions and rejects unknown IDs",
	)
	current_scene = null
	root.remove_child(launch.pilot)
	_check(
		_count_events(sink, &"p2.pacing.session_ended") == 1,
		"the real pilot exit lifecycle closes the local evidence session",
	)
	launch.pilot.durable_state_committed.emit(&"session.exiting", false)
	launch.pilot.durable_state_committed.emit(&"session.exiting", false)
	_check(
		_count_events(sink, &"p2.pacing.session_ended") == 1,
		"duplicate exit notifications cannot duplicate the session-end record",
	)
	launch.pilot.free()
	var missing_kind_launch := composition_root.create_h01_launch(
		&"profile-2",
		MemorySaveService.new(),
		RecordingAnalyticsService.new(),
	)
	_check(
		missing_kind_launch.is_ready()
		and missing_kind_launch.pilot != null
		and missing_kind_launch.pilot.get_node_or_null(
			"PacingEvidenceBinding"
		) == null,
		"an injected sink without an explicit run kind remains unarmed",
	)
	if missing_kind_launch.pilot != null:
		missing_kind_launch.pilot.free()
	await _test_mid_session_sink_failure_does_not_block_state_or_save(
		composition_root
	)
	var disabled_sink := LocalJsonlAnalyticsService.new(
		"C:/forbidden-wuxiang-pacing-evidence",
		"disabled-session",
	)
	var fallback_launch := composition_root.create_h01_launch(
		&"profile-2",
		MemorySaveService.new(),
		disabled_sink,
		P2PacingEvidenceSession.RUN_KIND_AUTOMATION,
	)
	_check(
		not disabled_sink.is_ready()
		and fallback_launch.is_ready()
		and fallback_launch.pilot != null,
		"an unavailable evidence sink cannot block a valid H01 launch",
	)
	if fallback_launch.pilot != null:
		fallback_launch.pilot.free()
	var invalid_kind_launch := composition_root.create_h01_launch(
		&"profile-3",
		MemorySaveService.new(),
		RecordingAnalyticsService.new(),
		&"invalid-run-kind",
	)
	_check(
		invalid_kind_launch.is_ready()
		and invalid_kind_launch.pilot != null
		and invalid_kind_launch.pilot.get_node_or_null(
			"PacingEvidenceBinding"
		) == null,
		"invalid evidence configuration is dropped without blocking gameplay",
	)
	if invalid_kind_launch.pilot != null:
		invalid_kind_launch.pilot.free()
	_finish()


func _test_mid_session_sink_failure_does_not_block_state_or_save(
	composition_root: AppCompositionRoot,
) -> void:
	var directory := ProjectSettings.globalize_path(
		"res://builds/test-p2-pacing-fault-%d" % Time.get_ticks_usec()
	)
	var sink := FaultInjectingLocalJsonlAnalyticsService.new(
		directory,
		"fault-session",
		3,
	)
	var storage := MemorySaveService.new()
	var launch := composition_root.create_h01_launch(
		&"profile-2",
		storage,
		sink,
		P2PacingEvidenceSession.RUN_KIND_AUTOMATION,
	)
	_check(
		sink.is_ready() and launch.is_ready() and launch.pilot != null,
		"the fault-injection launch starts with a writable D-drive sink",
	)
	if not launch.is_ready() or launch.pilot == null:
		_cleanup_evidence_path(sink.output_path(), directory)
		return
	root.add_child(launch.pilot)
	current_scene = launch.pilot
	await process_frame
	var approach := _find_farmable_approach(
		launch.pilot.get_estate_runtime()
	)
	_check(
		not approach.is_empty(),
		"the fault-injection launch exposes a real farmable interaction",
	)
	if not approach.is_empty():
		var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
		var player := launch.pilot.get_player()
		player.global_position = mapper.cell_center(approach["source"])
		player.facing = approach["direction"]
		player.velocity = Vector2.ZERO
		var till := InputSnapshot.neutral()
		till.quickbar_slot_index = 0
		till.primary_action = true
		launch.pilot.apply_input_snapshot(till)
		var session := launch.pilot.get_farming_session()
		_check(
			session.state.farm.tile_at(approach["target"]) != null,
			"a real till transaction succeeds when evidence fails mid-session",
		)
		_check(
			not sink.is_ready()
			and sink.written_event_count() == 2,
			"the third write fault disables only the evidence sink",
		)
		_check(
			_storage_contains_schema_v2_save(storage),
			"the same transaction still persists save schema v2",
		)
	current_scene = null
	root.remove_child(launch.pilot)
	launch.pilot.free()
	_cleanup_evidence_path(sink.output_path(), directory)


func _find_farmable_approach(runtime: EstateMapRuntime) -> Dictionary:
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.UP,
	]
	for y: int in range(1, 95):
		for x: int in range(1, 127):
			var source := Vector2i(x, y)
			var source_semantics := runtime.query_cell(source)
			if not source_semantics.is_in_bounds() or source_semantics.colliding:
				continue
			for direction: Vector2i in directions:
				var target := source + direction
				var target_semantics := runtime.query_cell(target)
				if (
					target_semantics.is_in_bounds()
					and target_semantics.farmable
					and not target_semantics.colliding
				):
					return {
						"source": source,
						"target": target,
						"direction": direction,
					}
	return {}


func _storage_contains_schema_v2_save(storage: MemorySaveService) -> bool:
	for payload: String in storage.payloads.values():
		var parsed: Variant = JSON.parse_string(payload)
		if (
			parsed is Dictionary
			and parsed.get("schemaVersion") == SaveSnapshot.SCHEMA_VERSION
		):
			return true
	return false


func _cleanup_evidence_path(path: String, directory: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.dir_exists_absolute(directory):
		DirAccess.remove_absolute(directory)


func _count_events(
	sink: RecordingAnalyticsService,
	event_name: StringName,
) -> int:
	var count: int = 0
	for event: Dictionary in sink.events:
		if event["eventName"] == event_name:
			count += 1
	return count


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_PACING_EVIDENCE_BINDING_OK")
		quit(0)
		return
	push_error("P2 pacing-evidence binding test failed: %d check(s)" % _failures)
	quit(1)

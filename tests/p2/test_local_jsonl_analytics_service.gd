extends SceneTree

var _failures: int = 0
var _cleanup_files: PackedStringArray = []
var _cleanup_directories: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_valid_events_are_flushed_as_parseable_jsonl()
	_test_non_d_drive_and_nested_properties_fail_closed()
	_test_registered_keys_reject_unregistered_string_values()
	_cleanup()
	_finish()


func _test_valid_events_are_flushed_as_parseable_jsonl() -> void:
	var directory := _unique_directory("valid")
	var service := LocalJsonlAnalyticsService.new(
		directory,
		"test-session",
	)
	_check(service.is_ready(), "a unique D-drive evidence session opens")
	if not service.is_ready():
		return
	_cleanup_directories.append(directory)
	_cleanup_files.append(service.output_path())
	service.track(
		&"p2.pacing.session_started",
		_valid_common_properties(),
	)
	var action_properties := _valid_common_properties()
	action_properties["actionId"] = "farm.tilled"
	action_properties["elapsedMs"] = 125
	service.track(&"p2.pacing.action_committed", action_properties)
	var end_properties := _valid_common_properties()
	end_properties["elapsedMs"] = 250
	end_properties["outcome"] = "incomplete"
	end_properties["unknownActionCount"] = 0
	service.track(&"p2.pacing.session_ended", end_properties)
	service.close()
	var lines := FileAccess.get_file_as_string(
		service.output_path()
	).strip_edges().split("\n", false)
	_check(lines.size() == 3, "one JSONL line is flushed per accepted event")
	if lines.size() != 3:
		return
	var first: Variant = JSON.parse_string(lines[0])
	var second: Variant = JSON.parse_string(lines[1])
	var third: Variant = JSON.parse_string(lines[2])
	_check(
		first is Dictionary and second is Dictionary and third is Dictionary,
		"every persisted evidence line parses independently",
	)
	if first is Dictionary and second is Dictionary and third is Dictionary:
		var first_record: Dictionary = first
		var second_record: Dictionary = second
		var third_record: Dictionary = third
		_check(
			first_record["sessionId"] == "test-session"
			and first_record["sequence"] == 1
			and second_record["sequence"] == 2
			and third_record["sequence"] == 3,
			"session identity and sequence are deterministic within one file",
		)
		_check(
			first_record["eventName"] == "p2.pacing.session_started"
			and (
				first_record["recordedAtUnixMs"] is int
				or first_record["recordedAtUnixMs"] is float
			)
			and float(first_record["recordedAtUnixMs"]) > 0.0,
			"records contain a stable event ID and wall-clock audit timestamp",
		)
		_check(
			third_record["eventName"] == "p2.pacing.session_ended"
			and third_record["properties"]["outcome"] == "incomplete",
			"the registered session-end schema is persisted without free-form fields",
		)


func _test_non_d_drive_and_nested_properties_fail_closed() -> void:
	var blocked := LocalJsonlAnalyticsService.new(
		"C:/forbidden-wuxiang-pacing-evidence",
		"blocked-session",
	)
	_check(
		not blocked.is_ready()
		and blocked.output_path().is_empty(),
		"the adapter refuses every non-D-drive output directory",
	)
	var directory := _unique_directory("privacy")
	var service := LocalJsonlAnalyticsService.new(
		directory,
		"privacy-session",
	)
	_check(service.is_ready(), "the privacy-guard session opens on D")
	if not service.is_ready():
		return
	_cleanup_directories.append(directory)
	_cleanup_files.append(service.output_path())
	service.track(&"p2.pacing.session_started", {
		"evidenceSchemaVersion": 1,
		"objectiveId": {"forbidden": true},
	})
	_check(
		not service.is_ready()
		and service.written_event_count() == 0,
		"nested analytics properties disable the sink before any write",
	)
	service.close()
	var identity_directory := _unique_directory("identity")
	var identity_service := LocalJsonlAnalyticsService.new(
		identity_directory,
		"identity-session",
	)
	_check(identity_service.is_ready(), "the identity-guard session opens on D")
	if not identity_service.is_ready():
		return
	_cleanup_directories.append(identity_directory)
	_cleanup_files.append(identity_service.output_path())
	identity_service.track(&"p2.pacing.session_started", {
		"evidenceSchemaVersion": 1,
		"profileId": "profile-1",
	})
	_check(
		not identity_service.is_ready()
		and identity_service.written_event_count() == 0,
		"profile identity is rejected before any evidence write",
	)
	identity_service.close()
	var event_directory := _unique_directory("event")
	var event_service := LocalJsonlAnalyticsService.new(
		event_directory,
		"event-session",
	)
	_check(event_service.is_ready(), "the event-registry session opens on D")
	if not event_service.is_ready():
		return
	_cleanup_directories.append(event_directory)
	_cleanup_files.append(event_service.output_path())
	event_service.track(&"p2.pacing.unregistered", {
		"evidenceSchemaVersion": 1,
	})
	_check(
		not event_service.is_ready()
		and event_service.written_event_count() == 0,
		"unregistered event IDs are rejected before any evidence write",
	)
	event_service.close()


func _test_registered_keys_reject_unregistered_string_values() -> void:
	var invalid_cases: Array[Dictionary] = [
		{
			"suffix": "run-kind-value",
			"key": "runKind",
			"value": "human notes about the session",
			"label": "run kind cannot carry free text",
		},
		{
			"suffix": "objective-value",
			"key": "objectiveId",
			"value": "p2.h01.guide.unregistered_private_note",
			"label": "objective IDs must come from the registered H01 value set",
		},
		{
			"suffix": "map-path-value",
			"key": "mapId",
			"value": "D:/private/player-location",
			"label": "registered keys cannot smuggle file paths into evidence",
		},
		{
			"suffix": "build-value",
			"key": "buildRevision",
			"value": "p2.pacing.instrumentation.private-user",
			"label": "build revision must be explicitly registered",
		},
		{
			"suffix": "elapsed-type",
			"key": "elapsedMs",
			"value": "0",
			"label": "elapsed time rejects a string disguised as a number",
		},
		{
			"suffix": "day-range",
			"key": "worldDay",
			"value": -1,
			"label": "world day rejects values outside the typed range",
		},
	]
	for invalid_case: Dictionary in invalid_cases:
		var directory := _unique_directory(invalid_case["suffix"])
		var service := LocalJsonlAnalyticsService.new(
			directory,
			"%s-session" % invalid_case["suffix"],
		)
		_check(service.is_ready(), "the value-domain guard opens on D")
		if not service.is_ready():
			continue
		_cleanup_directories.append(directory)
		_cleanup_files.append(service.output_path())
		var properties := _valid_common_properties()
		properties[invalid_case["key"]] = invalid_case["value"]
		service.track(&"p2.pacing.session_started", properties)
		_check(
			not service.is_ready()
			and service.written_event_count() == 0,
			invalid_case["label"],
		)
		service.close()


func _valid_common_properties() -> Dictionary:
	return {
		"evidenceSchemaVersion": 1,
		"runKind": "automation",
		"scenarioId": "p2.h01.life_loop",
		"inputDeviceFamily": "mixed_or_unknown",
		"startingStateKind": "fresh",
		"buildRevision": "p2.pacing.instrumentation.v1",
		"contentRevision": "p2.h01.balance.v1",
		"elapsedMs": 0,
		"mapId": "home_h01_open_meadow",
		"worldDay": 1,
		"objectiveId": "p2.h01.guide.claim_daily",
		"farmTileCount": 0,
		"cropCount": 0,
		"seedCount": 0,
		"forageCount": 0,
		"scripCount": 0,
	}


func _unique_directory(suffix: String) -> String:
	return ProjectSettings.globalize_path(
		"res://builds/test-p2-pacing-%s-%d" % [
			suffix,
			Time.get_ticks_usec(),
		]
	)


func _cleanup() -> void:
	for path: String in _cleanup_files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	for path: String in _cleanup_directories:
		if DirAccess.dir_exists_absolute(path):
			DirAccess.remove_absolute(path)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_LOCAL_JSONL_ANALYTICS_OK")
		quit(0)
		return
	push_error("P2 local-analytics test failed: %d check(s)" % _failures)
	quit(1)

class_name LocalJsonlAnalyticsService
extends AnalyticsService

## Development-only, one-session-per-file sink. Every accepted line is flushed
## immediately; a registry, privacy, size, or I/O violation disables only this
## sink and never feeds a result back into gameplay.

const MAX_EVENTS_PER_SESSION: int = 2048
const MAX_PROPERTIES_PER_EVENT: int = 24
const MAX_JSON_LINE_CHARACTERS: int = 16384
const _ALLOWED_EVENT_NAMES: PackedStringArray = [
	"p2.pacing.session_started",
	"p2.pacing.objective_changed",
	"p2.pacing.action_committed",
	"p2.pacing.session_ended",
]
const _COMMON_PROPERTY_KEYS: PackedStringArray = [
	"evidenceSchemaVersion",
	"runKind",
	"scenarioId",
	"inputDeviceFamily",
	"startingStateKind",
	"buildRevision",
	"contentRevision",
	"elapsedMs",
	"mapId",
	"worldDay",
	"objectiveId",
	"farmTileCount",
	"cropCount",
	"seedCount",
	"forageCount",
	"scripCount",
]
const _ALLOWED_RUN_KINDS: PackedStringArray = [
	"human_internal",
	"automation",
]
const _ALLOWED_SCENARIO_IDS: PackedStringArray = [
	"p2.h01.life_loop",
]
const _ALLOWED_INPUT_DEVICE_FAMILIES: PackedStringArray = [
	"mixed_or_unknown",
	"keyboard_mouse",
	"gamepad",
]
const _ALLOWED_STARTING_STATE_KINDS: PackedStringArray = [
	"fresh",
	"resumed",
]
const _ALLOWED_BUILD_REVISIONS: PackedStringArray = [
	"p2.pacing.instrumentation.v1",
]
const _ALLOWED_CONTENT_REVISIONS: PackedStringArray = [
	"p2.h01.balance.v1",
]
const _ALLOWED_MAP_IDS: PackedStringArray = [
	"home_h01_open_meadow",
]
const _ALLOWED_OBJECTIVE_IDS: PackedStringArray = [
	"p2.h01.guide.harvest",
	"p2.h01.guide.missing_watering_can",
	"p2.h01.guide.water",
	"p2.h01.guide.sell_for_space",
	"p2.h01.guide.sell",
	"p2.h01.guide.claim_daily",
	"p2.h01.guide.rest_growth",
	"p2.h01.guide.plant",
	"p2.h01.guide.missing_hoe",
	"p2.h01.guide.till",
	"p2.h01.guide.buy_seed",
	"p2.h01.guide.rest_resources",
	"p2.h01.guide.inventory_blocked",
	"p2.h01.guide.unavailable",
]
const _ALLOWED_ACTION_IDS: PackedStringArray = [
	"home.h01.resource.north_meadow",
	"home.h01.resource.north_meadow.forage",
	"farm.tilled",
	"farm.planted",
	"farm.watered",
	"day.rested",
	"farm.harvested",
	"economy.h01.sell_mistleaf",
	"economy.h01.buy_mistleaf_seed",
]
const _ALLOWED_OUTCOMES: PackedStringArray = [
	"complete_loop",
	"incomplete",
	"excluded_resumed",
]

var _file: FileAccess
var _output_path: String = ""
var _session_id: String = ""
var _sequence: int = 0
var _ready: bool = false
var _last_error: String = ""


func _init(
	output_directory: String,
	session_id_override: String = "",
) -> void:
	var normalized_directory := (
		output_directory.replace("\\", "/").trim_suffix("/")
	)
	if not _is_d_drive_path(normalized_directory):
		_last_error = "analytics output directory must be an absolute D-drive path"
		return
	_session_id = (
		session_id_override
		if not session_id_override.is_empty()
		else _create_session_id()
	)
	if not _is_safe_session_id(_session_id):
		_last_error = "analytics session ID contains unsafe characters"
		_session_id = ""
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(
		normalized_directory
	)
	if directory_error != OK:
		_last_error = "analytics output directory could not be created: %s" % (
			error_string(directory_error)
		)
		_session_id = ""
		return
	_output_path = normalized_directory.path_join(
		"p2-pacing-%s.jsonl" % _session_id
	)
	if FileAccess.file_exists(_output_path):
		_last_error = "analytics session file already exists"
		_output_path = ""
		_session_id = ""
		return
	_file = FileAccess.open(_output_path, FileAccess.WRITE)
	if _file == null:
		_last_error = "analytics session file could not be opened: %s" % (
			error_string(FileAccess.get_open_error())
		)
		_output_path = ""
		_session_id = ""
		return
	_ready = true


func track(event_name: StringName, properties: Dictionary = {}) -> void:
	if not _ready:
		return
	if (
		event_name.is_empty()
		or not _ALLOWED_EVENT_NAMES.has(String(event_name))
	):
		_disable("analytics event name is outside the P2 pacing registry")
		return
	if not _properties_are_safe(event_name, properties):
		_disable("analytics properties violated the typed P2 evidence registry")
		return
	if _sequence >= MAX_EVENTS_PER_SESSION:
		_disable("analytics session event limit exceeded")
		return
	var record := {
		"evidenceSchemaVersion": 1,
		"sessionId": _session_id,
		"sequence": _sequence + 1,
		"recordedAtUnixMs": int(Time.get_unix_time_from_system() * 1000.0),
		"eventName": String(event_name),
		"properties": _normalized_properties(properties),
	}
	var line := JSON.stringify(record)
	if line.length() > MAX_JSON_LINE_CHARACTERS:
		_disable("analytics event exceeded the JSONL line limit")
		return
	if not _write_jsonl_line(line):
		_disable("analytics event could not be flushed")
		return
	_sequence += 1


func is_ready() -> bool:
	return _ready


func output_path() -> String:
	return _output_path


func last_error() -> String:
	return _last_error


func written_event_count() -> int:
	return _sequence


func close() -> void:
	if _file != null:
		_file.flush()
		_file.close()
		_file = null
	_ready = false


func _properties_are_safe(
	event_name: StringName,
	properties: Dictionary,
) -> bool:
	if properties.size() > MAX_PROPERTIES_PER_EVENT:
		return false
	var extra_keys: PackedStringArray = []
	match String(event_name):
		"p2.pacing.action_committed":
			extra_keys = PackedStringArray(["actionId"])
		"p2.pacing.session_ended":
			extra_keys = PackedStringArray(["outcome", "unknownActionCount"])
		"p2.pacing.session_started", "p2.pacing.objective_changed":
			pass
		_:
			return false
	if properties.size() != _COMMON_PROPERTY_KEYS.size() + extra_keys.size():
		return false
	for required_key: String in _COMMON_PROPERTY_KEYS:
		if not properties.has(required_key):
			return false
	for required_key: String in extra_keys:
		if not properties.has(required_key):
			return false
	for raw_key: Variant in properties:
		if not (raw_key is String or raw_key is StringName):
			return false
		var key := String(raw_key)
		if not (
			_COMMON_PROPERTY_KEYS.has(key)
			or extra_keys.has(key)
		):
			return false
		var value: Variant = properties[raw_key]
		if not _property_value_is_registered(key, value):
			return false
	return true


func _property_value_is_registered(key: String, value: Variant) -> bool:
	if key == "evidenceSchemaVersion":
		return value is int and value == 1
	if key == "elapsedMs":
		return value is int and value >= 0
	if key == "worldDay":
		return value is int and value > 0
	if key in [
		"farmTileCount",
		"cropCount",
		"seedCount",
		"forageCount",
		"scripCount",
		"unknownActionCount",
	]:
		return value is int and value >= 0
	if not (value is String or value is StringName):
		return false
	var normalized := String(value)
	match key:
		"runKind":
			return _ALLOWED_RUN_KINDS.has(normalized)
		"scenarioId":
			return _ALLOWED_SCENARIO_IDS.has(normalized)
		"inputDeviceFamily":
			return _ALLOWED_INPUT_DEVICE_FAMILIES.has(normalized)
		"startingStateKind":
			return _ALLOWED_STARTING_STATE_KINDS.has(normalized)
		"buildRevision":
			return _ALLOWED_BUILD_REVISIONS.has(normalized)
		"contentRevision":
			return _ALLOWED_CONTENT_REVISIONS.has(normalized)
		"mapId":
			return _ALLOWED_MAP_IDS.has(normalized)
		"objectiveId":
			return _ALLOWED_OBJECTIVE_IDS.has(normalized)
		"actionId":
			return _ALLOWED_ACTION_IDS.has(normalized)
		"outcome":
			return _ALLOWED_OUTCOMES.has(normalized)
	return false


func _normalized_properties(properties: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for raw_key: Variant in properties:
		var value: Variant = properties[raw_key]
		normalized[String(raw_key)] = (
			String(value)
			if value is StringName
			else value
		)
	return normalized


func _write_jsonl_line(line: String) -> bool:
	if _file == null:
		return false
	_file.store_line(line)
	_file.flush()
	return _file.get_error() == OK


func _disable(message: String) -> void:
	_last_error = message
	close()


func _create_session_id() -> String:
	var random := RandomNumberGenerator.new()
	random.randomize()
	return "%d-%d-%06d" % [
		int(Time.get_unix_time_from_system()),
		Time.get_ticks_usec(),
		random.randi_range(0, 999999),
	]


func _is_safe_session_id(value: String) -> bool:
	if value.is_empty() or value.length() > 96:
		return false
	for index: int in value.length():
		var code := value.unicode_at(index)
		var is_digit := code >= 48 and code <= 57
		var is_upper := code >= 65 and code <= 90
		var is_lower := code >= 97 and code <= 122
		if not (is_digit or is_upper or is_lower or code == 45 or code == 95):
			return false
	return true


func _is_d_drive_path(path: String) -> bool:
	return path.to_lower().begins_with("d:/")

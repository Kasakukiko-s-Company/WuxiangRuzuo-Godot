extends SceneTree

const PROJECTION_PATH: String = "res://data/estate_maps.json"
const HANDOFF_PATH: String = (
	"res://maps/handoff/estate-map-pack-v1/ESTATE_MAP_PACK_HANDOFF.json"
)

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var projection := _load_json(PROJECTION_PATH)
	var handoff := _load_json(HANDOFF_PATH)
	_check(not projection.is_empty(), "formal estate projection parses")
	_check(not handoff.is_empty(), "audited estate handoff parses")
	if projection.is_empty() or handoff.is_empty():
		_finish()
		return

	_check(
		projection.get("packId") == handoff.get("pack_id"),
		"formal projection preserves the audited pack identity",
	)
	var projection_maps := projection.get("maps", []) as Array
	var handoff_maps := handoff.get("maps", []) as Array
	_check(
		projection_maps.size() == handoff_maps.size()
		and projection_maps.size() == 8,
		"formal projection covers exactly the eight audited estates",
	)
	var handoff_by_map_id: Dictionary = {}
	for raw_handoff: Variant in handoff_maps:
		var handoff_map := raw_handoff as Dictionary
		handoff_by_map_id[StringName(String(handoff_map.get("map_id", "")))] = handoff_map

	for raw_projection: Variant in projection_maps:
		var projected := raw_projection as Dictionary
		var map_id := StringName(String(projected.get("id", "")))
		var source := handoff_by_map_id.get(map_id, {}) as Dictionary
		_check(not source.is_empty(), "%s exists in the audited handoff" % map_id)
		if source.is_empty():
			continue
		_check(
			projected.get("estateId") == source.get("estate_id")
			and projected.get("candidateId") == source.get("candidate_id"),
			"%s preserves estate and candidate identities" % map_id,
		)
		var source_size := source.get("map_size", {}) as Dictionary
		_check(
			projected.get("widthTiles") == source_size.get("width_tiles")
			and projected.get("heightTiles") == source_size.get("height_tiles")
			and projected.get("tileSizePixels")
			== source_size.get("tile_width_pixels"),
			"%s preserves the audited grid contract" % map_id,
		)
		var object_contract := source.get("object_contract", {}) as Dictionary
		_check(
			projected.get("safeSpawnId") == object_contract.get("safe_spawn_id")
			and projected.get("stateAxes") == source.get("state_axes")
			and projected.get("stateCombinationCount")
			== source.get("state_combination_count"),
			"%s preserves spawn and state semantics" % map_id,
		)

	_finish()


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	if json.data is Dictionary:
		return json.data as Dictionary
	return {}


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("ESTATE_MAP_PROJECTION_OK")
		quit(0)
		return
	push_error("Estate map projection test failed: %d check(s)" % _failures)
	quit(1)

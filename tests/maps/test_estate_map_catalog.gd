extends SceneTree

const EstateMapCatalogCodec = preload(
	"res://scripts/domain/world/estate_map_catalog_codec.gd"
)

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var document: Variant = _read_json("res://data/estate_maps.json")
	_check(document is Dictionary, "estate catalog JSON parses as an object")
	if not document is Dictionary:
		_finish()
		return

	var result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(document as Dictionary)
	)
	_check(result.is_valid(), "the H01-H08 handoff projection decodes atomically")
	if not result.is_valid():
		push_error(result.describe_issues())
	if result.is_valid():
		_check(result.catalog.pack_id == &"206154e890aeee3e182ac022a76abee9", "catalog preserves the audited pack ID")
		_check(result.catalog.maps.size() == 8, "catalog contains exactly the eight audited estate candidates")
		var h01: EstateMapDefinition = result.catalog.get_map(&"home_h01_open_meadow")
		_check(h01 != null, "stable H01 map lookup works")
		if h01 != null:
			_check(h01.size_tiles == Vector2i(128, 96), "H01 keeps the audited 128x96 dimensions")
			_check(h01.safe_spawn_id == &"home_safe_spawn_meadow", "H01 keeps its audited safe spawn")
			_check(h01.state_combination_count == 48, "H01 keeps its audited state cardinality")
			_check(h01.values_for_axis(&"season").size() == 4, "H01 exposes four seasons through a typed definition")
		var h02: EstateMapDefinition = result.catalog.get_map(&"home_h02_braided_river")
		_check(
			h02 != null and h02.values_for_axis(&"hydrology").has(&"high_water_story_state"),
			"H02 preserves its map-specific hydrology axis",
		)

	var wrong_cardinality_document: Dictionary = document.duplicate(true)
	wrong_cardinality_document["maps"][0]["stateCombinationCount"] = 47
	var wrong_cardinality_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(wrong_cardinality_document)
	)
	_check(
		not wrong_cardinality_result.is_valid(),
		"state combination cardinality must equal the product of every axis",
	)
	_check(
		wrong_cardinality_result.describe_issues().contains("stateCombinationCount"),
		"cardinality rejection identifies the precise map field",
	)

	var empty_catalog_document: Dictionary = document.duplicate(true)
	empty_catalog_document["maps"] = []
	var empty_catalog_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(empty_catalog_document)
	)
	_check(
		not empty_catalog_result.is_valid(),
		"an empty estate map catalog is rejected",
	)
	_check(
		empty_catalog_result.describe_issues().contains("maps"),
		"empty-catalog rejection identifies the maps field",
	)

	var extended_state := EstateMapState.new(
		&"spring",
		&"derelict",
		&"normal",
		{&"hydrology": &"high_water_story_state"},
	)
	_check(
		extended_state.value_for_axis(&"hydrology") == &"high_water_story_state"
		and extended_state.copy().equals(extended_state),
		"estate state preserves typed map-specific axes without changing the runtime seam",
	)

	for identity_key: String in ["id", "estateId", "candidateId"]:
		var duplicate_identity_document: Dictionary = document.duplicate(true)
		duplicate_identity_document["maps"][1][identity_key] = (
			duplicate_identity_document["maps"][0][identity_key]
		)
		var duplicate_identity_result: EstateMapCatalogDecodeResult = (
			EstateMapCatalogCodec.decode_document(duplicate_identity_document)
		)
		_check(
			not duplicate_identity_result.is_valid(),
			"duplicate %s rejects the whole estate catalog" % identity_key,
		)
		_check(
			duplicate_identity_result.describe_issues().contains(identity_key),
			"duplicate %s rejection identifies the precise identity field" % identity_key,
		)

	var empty_axis_document: Dictionary = document.duplicate(true)
	empty_axis_document["maps"][0]["stateAxes"]["season"] = []
	var empty_axis_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(empty_axis_document)
	)
	_check(not empty_axis_result.is_valid(), "an empty state axis rejects the estate catalog")
	_check(
		empty_axis_result.describe_issues().contains("maps[0].stateAxes.season"),
		"empty-axis rejection identifies the precise axis",
	)

	var duplicate_axis_value_document: Dictionary = document.duplicate(true)
	duplicate_axis_value_document["maps"][0]["stateAxes"]["season"][1] = "spring"
	var duplicate_axis_value_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(duplicate_axis_value_document)
	)
	_check(
		not duplicate_axis_value_result.is_valid(),
		"duplicate values within a state axis reject the estate catalog",
	)
	_check(
		duplicate_axis_value_result.describe_issues().contains("maps[0].stateAxes.season"),
		"duplicate-axis-value rejection identifies the precise axis",
	)

	var candidate_scene_document: Dictionary = document.duplicate(true)
	candidate_scene_document["maps"][0]["runtimeScenePath"] = (
		"res://maps/candidates/h01-runtime-staging-v2/runtime/h01_state_ready.tscn"
	)
	var candidate_scene_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(candidate_scene_document)
	)
	_check(
		not candidate_scene_result.is_valid(),
		"formal estate definitions reject candidate staging scene paths",
	)
	_check(
		candidate_scene_result.describe_issues().contains("runtimeScenePath"),
		"candidate-path rejection identifies the precise runtime field",
	)

	var wrong_tile_size_document: Dictionary = document.duplicate(true)
	wrong_tile_size_document["maps"][0]["tileSizePixels"] = 16
	var wrong_tile_size_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(wrong_tile_size_document)
	)
	_check(not wrong_tile_size_result.is_valid(), "estate definitions reject non-32px base tiles")
	_check(
		wrong_tile_size_result.describe_issues().contains("tileSizePixels"),
		"tile-size rejection identifies the precise map field",
	)

	var missing_core_axis_document: Dictionary = document.duplicate(true)
	missing_core_axis_document["maps"][0]["stateAxes"].erase("anomaly")
	missing_core_axis_document["maps"][0]["stateCombinationCount"] = 16
	var missing_core_axis_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(missing_core_axis_document)
	)
	_check(
		not missing_core_axis_result.is_valid(),
		"every estate definition requires season, development, and anomaly axes",
	)
	_check(
		missing_core_axis_result.describe_issues().contains("stateAxes.anomaly"),
		"missing-core-axis rejection identifies the absent axis",
	)

	var invalid_map_id_document: Dictionary = document.duplicate(true)
	invalid_map_id_document["maps"][0]["id"] = "Home Invalid"
	var invalid_map_id_result: EstateMapCatalogDecodeResult = (
		EstateMapCatalogCodec.decode_document(invalid_map_id_document)
	)
	_check(not invalid_map_id_result.is_valid(), "map IDs must use the stable ID grammar")
	_check(
		invalid_map_id_result.describe_issues().contains("maps[0].id"),
		"invalid-map-ID rejection identifies the precise identity field",
	)

	_finish()


func _read_json(path: String) -> Variant:
	var json := JSON.new()
	var error: Error = json.parse(FileAccess.get_file_as_string(path))
	if error != OK:
		push_error("JSON parse failed for %s: %s" % [path, json.get_error_message()])
		return null
	return json.data


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("ESTATE_MAP_CATALOG_OK")
		quit(0)
		return
	push_error("Estate map catalog test failed: %d check(s)" % _failures)
	quit(1)

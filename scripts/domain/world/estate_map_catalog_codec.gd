class_name EstateMapCatalogCodec
extends RefCounted


static func decode_document(document: Dictionary) -> EstateMapCatalogDecodeResult:
	var issues: Array[DataValidationIssue] = []
	var schema_version := _read_integer(
		document,
		"schemaVersion",
		"schemaVersion",
		issues,
	)
	if schema_version != EstateMapCatalog.SCHEMA_VERSION:
		issues.append(DataValidationIssue.new(
			"schemaVersion",
			"expected schema version %d" % EstateMapCatalog.SCHEMA_VERSION,
		))
	var pack_id := _read_id(document, "packId", "packId", issues)
	var raw_maps := _read_array(document, "maps", "maps", issues)
	if raw_maps.is_empty():
		issues.append(DataValidationIssue.new(
			"maps",
			"must contain at least one estate map definition",
		))
	var definitions: Array[EstateMapDefinition] = []
	var seen_estate_ids: Dictionary = {}
	var seen_map_ids: Dictionary = {}
	var seen_candidate_ids: Dictionary = {}
	for index: int in raw_maps.size():
		var path := "maps[%d]" % index
		var raw_definition: Variant = raw_maps[index]
		if not raw_definition is Dictionary:
			issues.append(DataValidationIssue.new(path, "must be an object"))
			continue
		var record := raw_definition as Dictionary
		var estate_id := _read_id(record, "estateId", path + ".estateId", issues)
		var map_id := _read_stable_id(record, "id", path + ".id", issues)
		var candidate_id := _read_stable_id(
			record,
			"candidateId",
			path + ".candidateId",
			issues,
		)
		_validate_unique_id(
			estate_id,
			path + ".estateId",
			seen_estate_ids,
			issues,
		)
		_validate_unique_id(map_id, path + ".id", seen_map_ids, issues)
		_validate_unique_id(
			candidate_id,
			path + ".candidateId",
			seen_candidate_ids,
			issues,
		)
		var width := _read_integer(record, "widthTiles", path + ".widthTiles", issues)
		var height := _read_integer(record, "heightTiles", path + ".heightTiles", issues)
		var tile_size := _read_integer(
			record,
			"tileSizePixels",
			path + ".tileSizePixels",
			issues,
		)
		if tile_size != 32:
			issues.append(DataValidationIssue.new(
				path + ".tileSizePixels",
				"must match the 32px project tile baseline",
			))
		var safe_spawn_id := _read_stable_id(
			record,
			"safeSpawnId",
			path + ".safeSpawnId",
			issues,
		)
		var axes := _decode_axes(record.get("stateAxes"), path + ".stateAxes", issues)
		for required_axis_id: StringName in [&"season", &"development", &"anomaly"]:
			if not _has_axis(axes, required_axis_id):
				issues.append(DataValidationIssue.new(
					path + ".stateAxes." + String(required_axis_id),
					"required state axis is missing",
				))
		var combination_count := _read_integer(
			record,
			"stateCombinationCount",
			path + ".stateCombinationCount",
			issues,
		)
		var expected_combination_count: int = 1
		for axis: EstateStateAxis in axes:
			expected_combination_count *= axis.values.size()
		if combination_count != expected_combination_count:
			issues.append(DataValidationIssue.new(
				path + ".stateCombinationCount",
				"must equal the product of all state axis values (%d)" % expected_combination_count,
			))
		var runtime_scene_path := _read_optional_path(
			record,
			"runtimeScenePath",
			path + ".runtimeScenePath",
			issues,
		)
		definitions.append(EstateMapDefinition.new(
			estate_id,
			map_id,
			candidate_id,
			Vector2i(width, height),
			tile_size,
			safe_spawn_id,
			axes,
			combination_count,
			runtime_scene_path,
		))
	if not issues.is_empty():
		return EstateMapCatalogDecodeResult.invalid(issues)
	return EstateMapCatalogDecodeResult.valid(EstateMapCatalog.new(pack_id, definitions))


static func _decode_axes(
	value: Variant,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array[EstateStateAxis]:
	var axes: Array[EstateStateAxis] = []
	if not value is Dictionary:
		issues.append(DataValidationIssue.new(path, "must be an object"))
		return axes
	var raw_axes := value as Dictionary
	for raw_axis_id: Variant in raw_axes:
		var axis_id := StringName(String(raw_axis_id))
		var axis_path := path + "." + String(axis_id)
		if not _is_stable_id(String(axis_id)):
			issues.append(DataValidationIssue.new(
				axis_path,
				"axis ID must be a lowercase stable ID",
			))
		var raw_values: Variant = raw_axes[raw_axis_id]
		if not raw_values is Array:
			issues.append(DataValidationIssue.new(
				axis_path,
				"must be an array",
			))
			continue
		if (raw_values as Array).is_empty():
			issues.append(DataValidationIssue.new(
				axis_path,
				"must contain at least one state value",
			))
		var values: Array[StringName] = []
		var seen_values: Dictionary = {}
		for raw_value: Variant in raw_values as Array:
			if typeof(raw_value) != TYPE_STRING:
				issues.append(DataValidationIssue.new(
					axis_path,
					"values must be strings",
				))
				continue
			var state_value := StringName(String(raw_value))
			if not _is_stable_id(String(state_value)):
				issues.append(DataValidationIssue.new(
					axis_path,
					"state values must be lowercase stable IDs",
				))
				continue
			if seen_values.has(state_value):
				issues.append(DataValidationIssue.new(
					axis_path,
					"duplicate state value %s" % state_value,
				))
				continue
			seen_values[state_value] = true
			values.append(state_value)
		axes.append(EstateStateAxis.new(axis_id, values))
	return axes


static func _read_array(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array:
	var value: Variant = record.get(key)
	if value is Array:
		return value as Array
	issues.append(DataValidationIssue.new(path, "must be an array"))
	return []


static func _read_integer(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> int:
	var value: Variant = record.get(key)
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		var numeric := float(value)
		if is_finite(numeric) and numeric == floor(numeric) and numeric > 0.0:
			return int(numeric)
	issues.append(DataValidationIssue.new(path, "must be a positive integer"))
	return 1


static func _read_id(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> StringName:
	var value: Variant = record.get(key)
	if typeof(value) == TYPE_STRING and not String(value).strip_edges().is_empty():
		return StringName(String(value).strip_edges())
	issues.append(DataValidationIssue.new(path, "must be a non-empty string"))
	return &""


static func _read_optional_path(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> String:
	var value: Variant = record.get(key)
	if value == null:
		return ""
	if typeof(value) == TYPE_STRING:
		var scene_path := String(value)
		if (
			scene_path.begins_with("res://scenes/world/estate/")
			and scene_path.ends_with(".tscn")
			and not scene_path.contains("\\")
			and not scene_path.contains("..")
		):
			return scene_path
	issues.append(DataValidationIssue.new(
		path,
		"must be null or a formal res://scenes/world/estate/*.tscn path",
	))
	return ""


static func _read_stable_id(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> StringName:
	var id := _read_id(record, key, path, issues)
	if not id.is_empty() and not _is_stable_id(String(id)):
		issues.append(DataValidationIssue.new(
			path,
			"must be a lowercase stable ID",
		))
		return &""
	return id


static func _validate_unique_id(
	id: StringName,
	path: String,
	seen: Dictionary,
	issues: Array[DataValidationIssue],
) -> void:
	if id.is_empty():
		return
	if seen.has(id):
		issues.append(DataValidationIssue.new(path, "duplicate ID %s" % id))
		return
	seen[id] = true


static func _has_axis(
	axes: Array[EstateStateAxis],
	axis_id: StringName,
) -> bool:
	for axis: EstateStateAxis in axes:
		if axis.id == axis_id:
			return true
	return false


static func _is_stable_id(value: String) -> bool:
	var pattern := RegEx.new()
	return (
		pattern.compile("^[a-z0-9]+(?:[._-][a-z0-9]+)*$") == OK
		and pattern.search(value) != null
	)

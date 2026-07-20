class_name GameCatalogCodec
extends RefCounted

const EXPECTED_MAP_IDS: Array[StringName] = [
	&"home_interior",
	&"hometown_main",
	&"boundary_pass",
	&"old_mine",
]
const EXPECTED_NPC_BOUNDARIES: Dictionary = {
	&"npc_luo_censhan": &"non-romantic",
	&"npc_ning_zhao": &"adult-standard",
	&"npc_yan_xun": &"adult-standard",
	&"npc_du_heng": &"adult-standard",
	&"npc_qiao_yu": &"adult-standard",
	&"npc_shen_he": &"adult-standard",
	&"npc_wen_shu": &"adult-standard",
	&"npc_mu_yuan": &"adult-standard",
	&"npc_qiao_ling": &"minor-until-adult",
	&"npc_tang_mi": &"adult-standard",
	&"npc_he_zhou": &"adult-standard",
	&"npc_li_qing": &"adult-standard",
	&"npc_chi_que": &"adult-standard",
	&"npc_a_tao": &"minor-until-adult",
	&"npc_chen_yun": &"non-romantic",
}
const NPC_CONTENT_TIERS: Array[StringName] = [&"core", &"support", &"ambient"]
const NPC_RELATIONSHIP_BOUNDARIES: Array[StringName] = [
	&"adult-standard",
	&"minor-until-adult",
	&"non-romantic",
]
const RESOURCE_KINDS: Array[StringName] = [
	&"texture2d",
	&"audio_stream",
	&"font",
	&"shader",
]
const SOURCE_STATUSES: Array[StringName] = [
	&"not-migrated",
	&"confirmed",
]


static func decode_documents(documents: Dictionary) -> CatalogDecodeResult:
	var issues: Array[DataValidationIssue] = []
	var catalog := GameCatalog.new()

	var items_document: Dictionary = _read_document(documents, "items", issues)
	var crops_document: Dictionary = _read_document(documents, "crops", issues)
	var tools_document: Dictionary = _read_document(documents, "tools", issues)
	var npcs_document: Dictionary = _read_document(documents, "npcs", issues)
	var localization_document: Dictionary = _read_document(documents, "localization", issues)
	var world_document: Dictionary = _read_document(documents, "world", issues)
	var resources_document: Dictionary = _read_document(documents, "resources", issues)

	_decode_items(items_document, catalog, issues)
	_decode_crops(crops_document, catalog, issues)
	_decode_tools(tools_document, catalog, issues)
	_decode_npcs(npcs_document, catalog, issues)
	_decode_localization(localization_document, catalog, issues)
	_decode_world(world_document, catalog, issues)
	_decode_resources(resources_document, catalog, issues)

	catalog.rebuild_indexes()
	_validate_cross_references(catalog, issues)
	if not issues.is_empty():
		return CatalogDecodeResult.invalid(issues)
	return CatalogDecodeResult.valid(catalog)


static func _read_document(
	documents: Dictionary,
	document_name: String,
	issues: Array[DataValidationIssue],
) -> Dictionary:
	var value: Variant = documents.get(document_name)
	if not value is Dictionary:
		_add_issue(issues, document_name, "document must be an object")
		return {}
	var document: Dictionary = value as Dictionary
	var schema_version: int = _read_integer(
		document,
		"schemaVersion",
		document_name + ".schemaVersion",
		issues,
		0,
	)
	if schema_version != GameCatalog.SCHEMA_VERSION:
		_add_issue(
			issues,
			document_name + ".schemaVersion",
			"expected schema version %d" % GameCatalog.SCHEMA_VERSION,
		)
	return document


static func _decode_items(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	var values: Array = _read_array(document, "items", "items", issues)
	var seen: Dictionary = {}
	for index: int in values.size():
		var path := "items[%d]" % index
		var record: Dictionary = _as_record(values[index], path, issues)
		if record.is_empty():
			continue
		var issue_count := issues.size()
		var id := _read_stable_id(record, "id", path + ".id", issues)
		_validate_unique_id(id, path + ".id", seen, issues)
		var display_name_key := _read_stable_id(
			record,
			"displayNameKey",
			path + ".displayNameKey",
			issues,
		)
		var kind := _decode_item_kind(
			_read_string(record, "type", path + ".type", issues),
			path + ".type",
			issues,
		)
		var max_stack := _read_integer(record, "maxStack", path + ".maxStack", issues, 1)
		var buy_price := _read_integer(record, "buyPrice", path + ".buyPrice", issues, 0)
		var sell_price := _read_integer(record, "sellPrice", path + ".sellPrice", issues, 0)
		var crop_id := _read_optional_stable_id(record, "cropId", path + ".cropId", issues)
		var tool_id := _read_optional_stable_id(record, "toolId", path + ".toolId", issues)
		if kind == CatalogDefinitions.Item.Kind.SEED and crop_id.is_empty():
			_add_issue(issues, path + ".cropId", "seed item must reference a crop")
		if kind == CatalogDefinitions.Item.Kind.TOOL and tool_id.is_empty():
			_add_issue(issues, path + ".toolId", "tool item must reference a tool")
		if issues.size() != issue_count:
			continue
		catalog.items.append(CatalogDefinitions.Item.new(
			id,
			display_name_key,
			kind,
			max_stack,
			buy_price,
			sell_price,
			crop_id,
			tool_id,
		))


static func _decode_crops(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	var values: Array = _read_array(document, "crops", "crops", issues)
	var seen_ids: Dictionary = {}
	var seen_seeds: Dictionary = {}
	for index: int in values.size():
		var path := "crops[%d]" % index
		var record: Dictionary = _as_record(values[index], path, issues)
		if record.is_empty():
			continue
		var issue_count := issues.size()
		var id := _read_stable_id(record, "id", path + ".id", issues)
		_validate_unique_id(id, path + ".id", seen_ids, issues)
		var seed_item_id := _read_stable_id(record, "seedItemId", path + ".seedItemId", issues)
		_validate_unique_id(seed_item_id, path + ".seedItemId", seen_seeds, issues)
		var harvest_item_id := _read_stable_id(
			record,
			"harvestItemId",
			path + ".harvestItemId",
			issues,
		)
		var growth_stages := _read_positive_integer_array(
			record,
			"growthStages",
			path + ".growthStages",
			issues,
		)
		var harvest_quantity := _read_integer(
			record,
			"harvestQuantity",
			path + ".harvestQuantity",
			issues,
			1,
		)
		var requires_water := _read_boolean(
			record,
			"requiresWater",
			path + ".requiresWater",
			issues,
		)
		var allowed_seasons := _read_seasons(
			record,
			"allowedSeasons",
			path + ".allowedSeasons",
			issues,
		)
		if issues.size() != issue_count:
			continue
		catalog.crops.append(CatalogDefinitions.Crop.new(
			id,
			seed_item_id,
			harvest_item_id,
			growth_stages,
			harvest_quantity,
			requires_water,
			allowed_seasons,
		))


static func _decode_tools(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	var values: Array = _read_array(document, "tools", "tools", issues)
	var seen: Dictionary = {}
	for index: int in values.size():
		var path := "tools[%d]" % index
		var record: Dictionary = _as_record(values[index], path, issues)
		if record.is_empty():
			continue
		var issue_count := issues.size()
		var id := _read_stable_id(record, "id", path + ".id", issues)
		_validate_unique_id(id, path + ".id", seen, issues)
		var display_name_key := _read_stable_id(
			record,
			"displayNameKey",
			path + ".displayNameKey",
			issues,
		)
		var action := _decode_tool_action(
			_read_string(record, "action", path + ".action", issues),
			path + ".action",
			issues,
		)
		var range_tiles := _read_integer(record, "rangeTiles", path + ".rangeTiles", issues, 1)
		if issues.size() != issue_count:
			continue
		catalog.tools.append(CatalogDefinitions.Tool.new(
			id,
			display_name_key,
			action,
			range_tiles,
		))


static func _decode_localization(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	catalog.default_locale = StringName(_read_string(
		document,
		"defaultLocale",
		"localization.defaultLocale",
		issues,
	))
	var locales_value: Variant = document.get("locales")
	if not locales_value is Dictionary:
		_add_issue(issues, "localization.locales", "must be an object")
		return
	var locales: Dictionary = locales_value as Dictionary
	for locale_key: Variant in locales:
		var locale_path := "localization.locales.%s" % String(locale_key)
		var entries_value: Variant = locales[locale_key]
		if not entries_value is Dictionary:
			_add_issue(issues, locale_path, "must be an object")
			continue
		var entries: Dictionary = entries_value as Dictionary
		for text_key: Variant in entries:
			var text_value: Variant = entries[text_key]
			if typeof(text_key) != TYPE_STRING or typeof(text_value) != TYPE_STRING:
				_add_issue(issues, locale_path, "keys and translated values must be strings")
			elif String(text_value).is_empty():
				_add_issue(issues, locale_path + "." + String(text_key), "text must not be empty")
		catalog.localized_text[StringName(String(locale_key))] = entries.duplicate(true)
	if not catalog.localized_text.has(catalog.default_locale):
		_add_issue(issues, "localization.defaultLocale", "default locale must exist")


static func _decode_npcs(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	var values: Array = _read_array(document, "npcs", "npcs", issues)
	var seen: Dictionary = {}
	for index: int in values.size():
		var path := "npcs[%d]" % index
		var record: Dictionary = _as_record(values[index], path, issues)
		if record.is_empty():
			continue
		var issue_count := issues.size()
		var id := _read_stable_id(record, "id", path + ".id", issues)
		_validate_unique_id(id, path + ".id", seen, issues)
		var display_name_key := _read_stable_id(
			record,
			"displayNameKey",
			path + ".displayNameKey",
			issues,
		)
		var age := _read_integer(
			record,
			"ageAtWorldDay1",
			path + ".ageAtWorldDay1",
			issues,
			0,
		)
		var content_tier := StringName(_read_string(
			record,
			"contentTier",
			path + ".contentTier",
			issues,
		))
		if not NPC_CONTENT_TIERS.has(content_tier):
			_add_issue(issues, path + ".contentTier", "unsupported NPC content tier")
		var relationship_boundary := StringName(_read_string(
			record,
			"relationshipBoundary",
			path + ".relationshipBoundary",
			issues,
		))
		if not NPC_RELATIONSHIP_BOUNDARIES.has(relationship_boundary):
			_add_issue(issues, path + ".relationshipBoundary", "unsupported relationship boundary")
		var default_anchor_id := _read_stable_id(
			record,
			"defaultAnchorId",
			path + ".defaultAnchorId",
			issues,
		)
		if age < 18 and relationship_boundary != &"minor-until-adult":
			_add_issue(issues, path + ".relationshipBoundary", "minor must retain an explicit adult boundary")
		if issues.size() != issue_count:
			continue
		catalog.npcs.append(CatalogDefinitions.Npc.new(
			id,
			display_name_key,
			age,
			content_tier,
			relationship_boundary,
			default_anchor_id,
		))


static func _decode_world(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	catalog.fallback_map_id = _read_stable_id(
		document,
		"fallbackMapId",
		"world.fallbackMapId",
		issues,
	)
	var map_values: Array = _read_array(document, "maps", "world.maps", issues)
	var seen_maps: Dictionary = {}
	for index: int in map_values.size():
		var path := "world.maps[%d]" % index
		var record: Dictionary = _as_record(map_values[index], path, issues)
		if record.is_empty():
			continue
		var issue_count := issues.size()
		var id := _read_stable_id(record, "id", path + ".id", issues)
		_validate_unique_id(id, path + ".id", seen_maps, issues)
		var scene_path := _read_optional_path(record, "scenePath", path + ".scenePath", issues)
		var implementation_status := _read_stable_id(
			record,
			"implementationStatus",
			path + ".implementationStatus",
			issues,
		)
		var display_name_key := _read_stable_id(
			record,
			"displayNameKey",
			path + ".displayNameKey",
			issues,
		)
		var width := _read_integer(record, "widthTiles", path + ".widthTiles", issues, 1)
		var height := _read_integer(record, "heightTiles", path + ".heightTiles", issues, 1)
		var tile_size := _read_integer(
			record,
			"tileSizePixels",
			path + ".tileSizePixels",
			issues,
			1,
		)
		var safe_anchor_id := _read_stable_id(
			record,
			"safeAnchorId",
			path + ".safeAnchorId",
			issues,
		)
		var anchors := _read_stable_id_array(
			record,
			"requiredAnchorIds",
			path + ".requiredAnchorIds",
			issues,
		)
		if not anchors.has(safe_anchor_id):
			_add_issue(issues, path + ".safeAnchorId", "must be included in requiredAnchorIds")
		if issues.size() != issue_count:
			continue
		catalog.maps.append(CatalogDefinitions.DemoMap.new(
			id,
			scene_path,
			implementation_status,
			display_name_key,
			Vector2i(width, height),
			tile_size,
			safe_anchor_id,
			anchors,
		))

	var portal_values: Array = _read_array(document, "portals", "world.portals", issues)
	var seen_portals: Dictionary = {}
	for index: int in portal_values.size():
		var path := "world.portals[%d]" % index
		var record: Dictionary = _as_record(portal_values[index], path, issues)
		if record.is_empty():
			continue
		var issue_count := issues.size()
		var id := _read_stable_id(record, "id", path + ".id", issues)
		_validate_unique_id(id, path + ".id", seen_portals, issues)
		var source_map_id := _read_stable_id(record, "sourceMapId", path + ".sourceMapId", issues)
		var source_anchor_id := _read_stable_id(
			record,
			"sourceAnchorId",
			path + ".sourceAnchorId",
			issues,
		)
		var target_map_id := _read_stable_id(record, "targetMapId", path + ".targetMapId", issues)
		var target_anchor_id := _read_stable_id(
			record,
			"targetAnchorId",
			path + ".targetAnchorId",
			issues,
		)
		var condition_id := _read_optional_condition_id(
			record,
			"conditionId",
			path + ".conditionId",
			issues,
		)
		var reciprocal_id := _read_stable_id(
			record,
			"reciprocalPortalId",
			path + ".reciprocalPortalId",
			issues,
		)
		if issues.size() != issue_count:
			continue
		catalog.portals.append(CatalogDefinitions.Portal.new(
			id,
			source_map_id,
			source_anchor_id,
			target_map_id,
			target_anchor_id,
			condition_id,
			reciprocal_id,
		))


static func _decode_resources(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	var values: Array = _read_array(document, "resources", "resources", issues)
	var seen: Dictionary = {}
	for index: int in values.size():
		var path := "resources[%d]" % index
		var record: Dictionary = _as_record(values[index], path, issues)
		if record.is_empty():
			continue
		var issue_count := issues.size()
		var id := _read_stable_id(record, "id", path + ".id", issues)
		_validate_unique_id(id, path + ".id", seen, issues)
		var kind := StringName(_read_string(record, "kind", path + ".kind", issues))
		if not RESOURCE_KINDS.has(kind):
			_add_issue(issues, path + ".kind", "unsupported resource kind")
		var godot_path := _read_optional_path(record, "godotPath", path + ".godotPath", issues)
		var source_status := StringName(_read_string(
			record,
			"sourceStatus",
			path + ".sourceStatus",
			issues,
		))
		if not SOURCE_STATUSES.has(source_status):
			_add_issue(issues, path + ".sourceStatus", "unsupported source status")
		if source_status == &"confirmed" and godot_path.is_empty():
			_add_issue(issues, path + ".godotPath", "confirmed resource must have a Godot path")
		if not godot_path.is_empty() and not godot_path.begins_with("res://assets/"):
			_add_issue(issues, path + ".godotPath", "runtime resource must be under res://assets/")
		var fallback_id := _read_optional_stable_id(
			record,
			"fallbackId",
			path + ".fallbackId",
			issues,
		)
		if issues.size() != issue_count:
			continue
		catalog.resources.append(CatalogDefinitions.RuntimeResource.new(
			id,
			kind,
			godot_path,
			source_status,
			fallback_id,
		))


static func _validate_cross_references(
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	for item: CatalogDefinitions.Item in catalog.items:
		if item.kind == CatalogDefinitions.Item.Kind.SEED and catalog.get_crop(item.crop_id) == null:
			_add_issue(issues, "items.%s.cropId" % item.id, "references an unknown crop")
		if item.kind == CatalogDefinitions.Item.Kind.TOOL and catalog.get_tool(item.tool_id) == null:
			_add_issue(issues, "items.%s.toolId" % item.id, "references an unknown tool")
		if not catalog.has_localized_text(item.display_name_key):
			_add_issue(issues, "items.%s.displayNameKey" % item.id, "missing default-locale text")

	for crop: CatalogDefinitions.Crop in catalog.crops:
		var seed: CatalogDefinitions.Item = catalog.get_item(crop.seed_item_id)
		var harvest: CatalogDefinitions.Item = catalog.get_item(crop.harvest_item_id)
		if seed == null or seed.kind != CatalogDefinitions.Item.Kind.SEED:
			_add_issue(issues, "crops.%s.seedItemId" % crop.id, "must reference a seed item")
		if harvest == null or harvest.kind != CatalogDefinitions.Item.Kind.CROP:
			_add_issue(issues, "crops.%s.harvestItemId" % crop.id, "must reference a crop item")

	for tool: CatalogDefinitions.Tool in catalog.tools:
		if not catalog.has_localized_text(tool.display_name_key):
			_add_issue(issues, "tools.%s.displayNameKey" % tool.id, "missing default-locale text")

	for expected_npc_id: StringName in EXPECTED_NPC_BOUNDARIES:
		var npc: CatalogDefinitions.Npc = catalog.get_npc(expected_npc_id)
		if npc == null:
			_add_issue(issues, "npcs", "missing required NPC %s" % expected_npc_id)
		elif npc.relationship_boundary != EXPECTED_NPC_BOUNDARIES[expected_npc_id]:
			_add_issue(issues, "npcs.%s.relationshipBoundary" % expected_npc_id, "does not match the confirmed NPC boundary")
	if catalog.npcs.size() != EXPECTED_NPC_BOUNDARIES.size():
		_add_issue(issues, "npcs", "Demo must contain exactly fifteen NPCs")
	for npc: CatalogDefinitions.Npc in catalog.npcs:
		if not catalog.has_localized_text(npc.display_name_key):
			_add_issue(issues, "npcs.%s.displayNameKey" % npc.id, "missing default-locale text")

	for expected_map_id: StringName in EXPECTED_MAP_IDS:
		if catalog.get_map(expected_map_id) == null:
			_add_issue(issues, "world.maps", "missing required map %s" % expected_map_id)
	if catalog.maps.size() != EXPECTED_MAP_IDS.size():
		_add_issue(issues, "world.maps", "Demo must contain exactly four maps")
	if catalog.get_map(catalog.fallback_map_id) == null:
		_add_issue(issues, "world.fallbackMapId", "references an unknown map")

	for map: CatalogDefinitions.DemoMap in catalog.maps:
		if not catalog.has_localized_text(map.display_name_key):
			_add_issue(issues, "world.maps.%s.displayNameKey" % map.id, "missing default-locale text")

	for portal: CatalogDefinitions.Portal in catalog.portals:
		var source_map: CatalogDefinitions.DemoMap = catalog.get_map(portal.source_map_id)
		var target_map: CatalogDefinitions.DemoMap = catalog.get_map(portal.target_map_id)
		if source_map == null:
			_add_issue(issues, "world.portals.%s.sourceMapId" % portal.id, "references an unknown map")
		elif not source_map.has_anchor(portal.source_anchor_id):
			_add_issue(issues, "world.portals.%s.sourceAnchorId" % portal.id, "is not registered by source map")
		if target_map == null:
			_add_issue(issues, "world.portals.%s.targetMapId" % portal.id, "references an unknown map")
		elif not target_map.has_anchor(portal.target_anchor_id):
			_add_issue(issues, "world.portals.%s.targetAnchorId" % portal.id, "is not registered by target map")
		var reciprocal: CatalogDefinitions.Portal = catalog.get_portal(portal.reciprocal_portal_id)
		if reciprocal == null:
			_add_issue(issues, "world.portals.%s.reciprocalPortalId" % portal.id, "references an unknown portal")
		elif reciprocal.reciprocal_portal_id != portal.id or reciprocal.source_map_id != portal.target_map_id or reciprocal.target_map_id != portal.source_map_id:
			_add_issue(issues, "world.portals.%s.reciprocalPortalId" % portal.id, "does not form a reciprocal map pair")

	for resource: CatalogDefinitions.RuntimeResource in catalog.resources:
		if resource.fallback_id.is_empty():
			continue
		var fallback: CatalogDefinitions.RuntimeResource = catalog.get_resource(resource.fallback_id)
		if fallback == null:
			_add_issue(issues, "resources.%s.fallbackId" % resource.id, "references an unknown resource")
		elif fallback.kind != resource.kind:
			_add_issue(issues, "resources.%s.fallbackId" % resource.id, "fallback kind must match")
		_validate_resource_cycle(resource, catalog, issues)


static func _validate_resource_cycle(
	resource: CatalogDefinitions.RuntimeResource,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	var visited: Dictionary = {}
	var current: CatalogDefinitions.RuntimeResource = resource
	while current != null and not current.fallback_id.is_empty():
		if visited.has(current.id):
			_add_issue(issues, "resources.%s.fallbackId" % resource.id, "fallback chain contains a cycle")
			return
		visited[current.id] = true
		current = catalog.get_resource(current.fallback_id)


static func _as_record(
	value: Variant,
	path: String,
	issues: Array[DataValidationIssue],
) -> Dictionary:
	if value is Dictionary:
		return value as Dictionary
	_add_issue(issues, path, "must be an object")
	return {}


static func _read_array(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array:
	var value: Variant = record.get(key)
	if value is Array:
		return value as Array
	_add_issue(issues, path, "must be an array")
	return []


static func _read_string(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> String:
	var value: Variant = record.get(key)
	if typeof(value) == TYPE_STRING and not String(value).strip_edges().is_empty():
		return String(value).strip_edges()
	_add_issue(issues, path, "must be a non-empty string")
	return ""


static func _read_stable_id(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> StringName:
	var value := _read_string(record, key, path, issues)
	if not value.is_empty() and not _is_stable_id(value):
		_add_issue(issues, path, "must be a lowercase stable ID")
		return &""
	return StringName(value)


static func _read_optional_stable_id(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> StringName:
	if not record.has(key) or record.get(key) == null:
		return &""
	return _read_stable_id(record, key, path, issues)


static func _read_optional_condition_id(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> StringName:
	if not record.has(key) or record.get(key) == null:
		return &""
	var value := _read_string(record, key, path, issues)
	var pattern := RegEx.new()
	if pattern.compile("^[a-z][A-Za-z0-9]*(?:[._-][A-Za-z0-9]+)*$") != OK or pattern.search(value) == null:
		_add_issue(issues, path, "must be a stable condition key")
		return &""
	return StringName(value)


static func _read_optional_path(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> String:
	if not record.has(key) or record.get(key) == null:
		return ""
	var value := _read_string(record, key, path, issues)
	if value.contains("\\") or value.contains(".."):
		_add_issue(issues, path, "must not contain backslashes or parent traversal")
		return ""
	return value


static func _read_integer(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
	minimum: int,
) -> int:
	var value: Variant = record.get(key)
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		_add_issue(issues, path, "must be an integer >= %d" % minimum)
		return minimum
	var numeric := float(value)
	if not is_finite(numeric) or numeric != floor(numeric) or numeric < minimum:
		_add_issue(issues, path, "must be an integer >= %d" % minimum)
		return minimum
	return int(numeric)


static func _read_boolean(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> bool:
	var value: Variant = record.get(key)
	if typeof(value) == TYPE_BOOL:
		return bool(value)
	_add_issue(issues, path, "must be a boolean")
	return false


static func _read_positive_integer_array(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array[int]:
	var raw_values: Array = _read_array(record, key, path, issues)
	var result: Array[int] = []
	if raw_values.is_empty():
		_add_issue(issues, path, "must contain at least one value")
		return result
	for index: int in raw_values.size():
		var wrapper: Dictionary = {"value": raw_values[index]}
		result.append(_read_integer(wrapper, "value", "%s[%d]" % [path, index], issues, 1))
	return result


static func _read_stable_id_array(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array[StringName]:
	var raw_values: Array = _read_array(record, key, path, issues)
	var result: Array[StringName] = []
	var seen: Dictionary = {}
	if raw_values.is_empty():
		_add_issue(issues, path, "must contain at least one ID")
		return result
	for index: int in raw_values.size():
		var wrapper: Dictionary = {"value": raw_values[index]}
		var id := _read_stable_id(wrapper, "value", "%s[%d]" % [path, index], issues)
		_validate_unique_id(id, "%s[%d]" % [path, index], seen, issues)
		result.append(id)
	return result


static func _read_seasons(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array[StringName]:
	var seasons := _read_stable_id_array(record, key, path, issues)
	for season: StringName in seasons:
		if season != &"all":
			_add_issue(issues, path, "unsupported season %s" % season)
	return seasons


static func _decode_item_kind(
	value: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> CatalogDefinitions.Item.Kind:
	match value:
		"tool":
			return CatalogDefinitions.Item.Kind.TOOL
		"seed":
			return CatalogDefinitions.Item.Kind.SEED
		"crop":
			return CatalogDefinitions.Item.Kind.CROP
		"material":
			return CatalogDefinitions.Item.Kind.MATERIAL
		_:
			_add_issue(issues, path, "unsupported item type")
			return CatalogDefinitions.Item.Kind.MATERIAL


static func _decode_tool_action(
	value: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> CatalogDefinitions.Tool.Action:
	match value:
		"till":
			return CatalogDefinitions.Tool.Action.TILL
		"water":
			return CatalogDefinitions.Tool.Action.WATER
		_:
			_add_issue(issues, path, "unsupported tool action")
			return CatalogDefinitions.Tool.Action.TILL


static func _validate_unique_id(
	id: StringName,
	path: String,
	seen: Dictionary,
	issues: Array[DataValidationIssue],
) -> void:
	if id.is_empty():
		return
	if seen.has(id):
		_add_issue(issues, path, "duplicate ID %s" % id)
		return
	seen[id] = true


static func _is_stable_id(value: String) -> bool:
	var pattern := RegEx.new()
	if pattern.compile("^[a-z0-9]+(?:[._-][a-z0-9]+)*$") != OK:
		return false
	return pattern.search(value) != null


static func _add_issue(
	issues: Array[DataValidationIssue],
	path: String,
	message: String,
) -> void:
	issues.append(DataValidationIssue.new(path, message))

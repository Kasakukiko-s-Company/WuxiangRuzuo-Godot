class_name SaveCodec
extends RefCounted

const FACING_VALUES: Array[StringName] = [&"up", &"right", &"down", &"left"]


static func encode(snapshot: SaveSnapshot, catalog: GameCatalog) -> SaveCodecResult:
	var issues := _validate_snapshot(snapshot, catalog)
	if not issues.is_empty():
		return SaveCodecResult.failed(SaveCodecResult.Status.INVALID_DATA, issues)
	return SaveCodecResult.encoded(JSON.stringify(_snapshot_to_dictionary(snapshot)))


static func decode(payload: String, catalog: GameCatalog) -> SaveCodecResult:
	var json := JSON.new()
	if json.parse(payload) != OK:
		return SaveCodecResult.failed(
			SaveCodecResult.Status.INVALID_JSON,
			[DataValidationIssue.new("payload", json.get_error_message())],
		)
	if not json.data is Dictionary:
		return SaveCodecResult.failed(
			SaveCodecResult.Status.INVALID_DATA,
			[DataValidationIssue.new("payload", "save root must be an object")],
		)
	var document: Dictionary = json.data as Dictionary
	var schema_value: Variant = document.get("schemaVersion")
	if _is_integer(schema_value) and int(schema_value) != SaveSnapshot.SCHEMA_VERSION:
		return SaveCodecResult.failed(
			SaveCodecResult.Status.UNSUPPORTED_SCHEMA,
			[DataValidationIssue.new(
				"schemaVersion",
				"unsupported schema version %d" % int(schema_value),
			)],
		)
	if not _is_integer(schema_value):
		return SaveCodecResult.failed(
			SaveCodecResult.Status.INVALID_DATA,
			[DataValidationIssue.new("schemaVersion", "new Godot schemaVersion is required")],
		)

	var issues: Array[DataValidationIssue] = []
	var snapshot := _dictionary_to_snapshot(document, catalog, issues)
	issues.append_array(_validate_snapshot(snapshot, catalog))
	if not issues.is_empty():
		return SaveCodecResult.failed(SaveCodecResult.Status.INVALID_DATA, issues)
	return SaveCodecResult.decoded(snapshot)


static func _dictionary_to_snapshot(
	document: Dictionary,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> SaveSnapshot:
	var snapshot := SaveSnapshot.new()
	snapshot.saved_at = _read_string(document, "savedAt", "savedAt", issues)
	snapshot.profile_id = StringName(_read_string(document, "profileId", "profileId", issues))
	snapshot.world_day = _read_integer(document, "worldDay", "worldDay", issues, 1)
	snapshot.current_map_id = StringName(_read_string(
		document,
		"currentMapId",
		"currentMapId",
		issues,
	))
	snapshot.player = _decode_player(document.get("player"), issues)
	snapshot.inventory = _decode_inventory(document.get("inventory"), catalog, issues)
	snapshot.farm = _decode_farm(document.get("farm"), catalog, issues)
	snapshot.story_flags = _decode_story_flags(document.get("storyFlags"), issues)
	snapshot.relationships = _decode_relationships(document.get("relationships"), issues)
	snapshot.spouse_character_id = _read_nullable_id(
		document,
		"spouseCharacterId",
		"spouseCharacterId",
		issues,
	)
	snapshot.mine_run = _decode_mine_run(document.get("mineRun"), issues)
	return snapshot


static func _decode_player(value: Variant, issues: Array[DataValidationIssue]) -> SaveSnapshot.Player:
	var record := _as_record(value, "player", issues)
	var anchor_id := _read_nullable_id(record, "anchorId", "player.anchorId", issues)
	var position_record := _as_record(record.get("position"), "player.position", issues)
	var position := Vector2(
		_read_number(position_record, "x", "player.position.x", issues),
		_read_number(position_record, "y", "player.position.y", issues),
	)
	var facing := StringName(_read_string(record, "facing", "player.facing", issues))
	var health := _read_integer(record, "health", "player.health", issues, 0)
	return SaveSnapshot.Player.new(anchor_id, position, facing, health)


static func _decode_inventory(
	value: Variant,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> InventoryState:
	var record := _as_record(value, "inventory", issues)
	var selected_index := _read_integer(
		record,
		"selectedIndex",
		"inventory.selectedIndex",
		issues,
		0,
	)
	var raw_slots := _read_array(record, "slots", "inventory.slots", issues)
	var stacks: Array[ItemStack] = []
	for index: int in raw_slots.size():
		var slot_value: Variant = raw_slots[index]
		if slot_value == null:
			stacks.append(null)
			continue
		var slot_path := "inventory.slots[%d]" % index
		var slot_record := _as_record(slot_value, slot_path, issues)
		var item_id := StringName(_read_string(slot_record, "itemId", slot_path + ".itemId", issues))
		var quantity := _read_integer(slot_record, "quantity", slot_path + ".quantity", issues, 1)
		stacks.append(ItemStack.new(item_id, quantity))
	var inventory := InventoryState.restore(stacks, selected_index, catalog)
	if inventory == null:
		_add_issue(issues, "inventory", "slots, selection, or item references are invalid")
	return inventory


static func _decode_farm(
	value: Variant,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> FarmState:
	var record := _as_record(value, "farm", issues)
	var map_id := StringName(_read_string(record, "mapId", "farm.mapId", issues))
	var raw_tiles := _read_array(record, "tiles", "farm.tiles", issues)
	var tiles: Array[FarmTileState] = []
	for index: int in raw_tiles.size():
		var tile_path := "farm.tiles[%d]" % index
		var tile_record := _as_record(raw_tiles[index], tile_path, issues)
		var coordinate := Vector2i(
			_read_integer(tile_record, "x", tile_path + ".x", issues, 0),
			_read_integer(tile_record, "y", tile_path + ".y", issues, 0),
		)
		var watered_on_day := 0
		if tile_record.get("wateredOnDay") != null:
			watered_on_day = _read_integer(
				tile_record,
				"wateredOnDay",
				tile_path + ".wateredOnDay",
				issues,
				1,
			)
		var crop: CropState = null
		if tile_record.get("crop") != null:
			var crop_path := tile_path + ".crop"
			var crop_record := _as_record(tile_record.get("crop"), crop_path, issues)
			crop = CropState.new(
				StringName(_read_string(crop_record, "cropId", crop_path + ".cropId", issues)),
				_read_integer(crop_record, "plantedOnDay", crop_path + ".plantedOnDay", issues, 1),
				_read_integer(crop_record, "growthProgress", crop_path + ".growthProgress", issues, 0),
				_read_integer(crop_record, "stageIndex", crop_path + ".stageIndex", issues, 0),
				_read_integer(crop_record, "lastGrowthDay", crop_path + ".lastGrowthDay", issues, 0),
			)
		tiles.append(FarmTileState.new(coordinate, watered_on_day, crop))
	var farm := FarmState.restore(map_id, tiles, catalog)
	if farm == null:
		_add_issue(issues, "farm", "map, tile coordinates, or crop references are invalid")
	return farm


static func _decode_story_flags(value: Variant, issues: Array[DataValidationIssue]) -> Dictionary:
	var record := _as_record(value, "storyFlags", issues)
	var flags: Dictionary = {}
	for raw_key: Variant in record:
		var key := String(raw_key)
		if typeof(raw_key) != TYPE_STRING or not _is_condition_key(key):
			_add_issue(issues, "storyFlags", "flag IDs must be stable condition keys")
			continue
		if typeof(record[raw_key]) != TYPE_BOOL:
			_add_issue(issues, "storyFlags.%s" % key, "flag value must be boolean")
			continue
		flags[StringName(key)] = bool(record[raw_key])
	return flags


static func _decode_relationships(
	value: Variant,
	issues: Array[DataValidationIssue],
) -> Array[SaveSnapshot.Relationship]:
	var raw_relationships: Array = []
	if value is Array:
		raw_relationships = value as Array
	else:
		_add_issue(issues, "relationships", "must be an array")
	var relationships: Array[SaveSnapshot.Relationship] = []
	for index: int in raw_relationships.size():
		var path := "relationships[%d]" % index
		var record := _as_record(raw_relationships[index], path, issues)
		relationships.append(SaveSnapshot.Relationship.new(
			StringName(_read_string(record, "npcId", path + ".npcId", issues)),
			_read_any_integer(record, "affinity", path + ".affinity", issues),
			StringName(_read_string(record, "relationshipState", path + ".relationshipState", issues)),
		))
	return relationships


static func _decode_mine_run(value: Variant, issues: Array[DataValidationIssue]) -> SaveSnapshot.MineRun:
	var record := _as_record(value, "mineRun", issues)
	var world_day := _read_integer(record, "worldDay", "mineRun.worldDay", issues, 0)
	var broken_ids := _read_id_array(record, "brokenNodeIds", "mineRun.brokenNodeIds", issues)
	var defeated_ids := _read_id_array(
		record,
		"defeatedEncounterIds",
		"mineRun.defeatedEncounterIds",
		issues,
	)
	return SaveSnapshot.MineRun.new(world_day, broken_ids, defeated_ids)


static func _validate_snapshot(
	snapshot: SaveSnapshot,
	catalog: GameCatalog,
) -> Array[DataValidationIssue]:
	var issues: Array[DataValidationIssue] = []
	if snapshot == null:
		_add_issue(issues, "snapshot", "must not be null")
		return issues
	if snapshot.saved_at.strip_edges().is_empty():
		_add_issue(issues, "savedAt", "must not be empty")
	if not SaveSnapshot.PROFILE_IDS.has(snapshot.profile_id):
		_add_issue(issues, "profileId", "must be profile-1, profile-2, or profile-3")
	if snapshot.world_day < 1:
		_add_issue(issues, "worldDay", "must be >= 1")
	var current_map: CatalogDefinitions.DemoMap = catalog.get_map(snapshot.current_map_id)
	if current_map == null:
		_add_issue(issues, "currentMapId", "references an unknown map")
	if snapshot.player == null:
		_add_issue(issues, "player", "must be present")
	else:
		if not FACING_VALUES.has(snapshot.player.facing):
			_add_issue(issues, "player.facing", "must be up, right, down, or left")
		if snapshot.player.health < 0 or snapshot.player.health > 5:
			_add_issue(issues, "player.health", "must be between 0 and 5")
		if not is_finite(snapshot.player.position.x) or not is_finite(snapshot.player.position.y):
			_add_issue(issues, "player.position", "must contain finite coordinates")
		if current_map != null and not snapshot.player.anchor_id.is_empty() and not current_map.has_anchor(snapshot.player.anchor_id):
			_add_issue(issues, "player.anchorId", "is not registered by current map")
	_validate_inventory(snapshot.inventory, catalog, issues)
	_validate_farm(snapshot.farm, snapshot.world_day, catalog, issues)
	_validate_story_flags(snapshot.story_flags, issues)
	_validate_relationships(snapshot.relationships, snapshot.spouse_character_id, catalog, issues)
	_validate_mine_run(snapshot.mine_run, snapshot.world_day, issues)
	return issues


static func _validate_inventory(
	inventory: InventoryState,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	if inventory == null:
		_add_issue(issues, "inventory", "must be present")
		return
	if inventory.capacity() != InventoryState.DEFAULT_CAPACITY:
		_add_issue(issues, "inventory.slots", "Demo inventory must have eight slots")
	if inventory.selected_slot_index < 0 or inventory.selected_slot_index >= inventory.capacity():
		_add_issue(issues, "inventory.selectedIndex", "must reference a slot")
	for index: int in inventory.capacity():
		var stack: ItemStack = inventory.stack_at(index)
		if stack == null:
			continue
		var item: CatalogDefinitions.Item = catalog.get_item(stack.item_id)
		if item == null:
			_add_issue(issues, "inventory.slots[%d].itemId" % index, "references an unknown item")
		elif stack.quantity < 1 or stack.quantity > item.max_stack:
			_add_issue(issues, "inventory.slots[%d].quantity" % index, "exceeds item stack bounds")


static func _validate_farm(
	farm: FarmState,
	world_day: int,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	if farm == null:
		_add_issue(issues, "farm", "must be present")
		return
	var map: CatalogDefinitions.DemoMap = catalog.get_map(farm.map_id)
	if map == null:
		_add_issue(issues, "farm.mapId", "references an unknown map")
		return
	var tiles := farm.copy_tiles()
	var seen: Dictionary = {}
	for index: int in tiles.size():
		var tile: FarmTileState = tiles[index]
		var path := "farm.tiles[%d]" % index
		if seen.has(tile.coordinate):
			_add_issue(issues, path, "duplicates a farm coordinate")
		seen[tile.coordinate] = true
		if tile.coordinate.x < 0 or tile.coordinate.y < 0 or tile.coordinate.x >= map.size_tiles.x or tile.coordinate.y >= map.size_tiles.y:
			_add_issue(issues, path, "coordinate must be inside its map")
		if tile.watered_on_day < 0 or tile.watered_on_day > world_day:
			_add_issue(issues, path + ".wateredOnDay", "must be zero or an elapsed world day")
		if tile.crop == null:
			continue
		var crop_definition: CatalogDefinitions.Crop = catalog.get_crop(tile.crop.crop_id)
		if crop_definition == null:
			_add_issue(issues, path + ".crop.cropId", "references an unknown crop")
			continue
		if tile.crop.planted_on_day < 1 or tile.crop.planted_on_day > world_day:
			_add_issue(issues, path + ".crop.plantedOnDay", "must be an elapsed world day")
		if tile.crop.last_growth_day < 0 or tile.crop.last_growth_day > world_day:
			_add_issue(issues, path + ".crop.lastGrowthDay", "must be zero or an elapsed world day")
		if tile.crop.growth_progress < 0 or tile.crop.stage_index < 0 or tile.crop.stage_index > crop_definition.growth_stages.size():
			_add_issue(issues, path + ".crop", "growth progress or stage is invalid")


static func _validate_story_flags(flags: Dictionary, issues: Array[DataValidationIssue]) -> void:
	for raw_key: Variant in flags:
		var key := String(raw_key)
		if not _is_condition_key(key) or typeof(flags[raw_key]) != TYPE_BOOL:
			_add_issue(issues, "storyFlags.%s" % key, "must be a stable boolean flag")


static func _validate_relationships(
	relationships: Array[SaveSnapshot.Relationship],
	spouse_character_id: StringName,
	catalog: GameCatalog,
	issues: Array[DataValidationIssue],
) -> void:
	var seen: Dictionary = {}
	var spouse_records := 0
	for index: int in relationships.size():
		var relationship: SaveSnapshot.Relationship = relationships[index]
		var path := "relationships[%d]" % index
		if relationship == null or not _is_stable_id(String(relationship.npc_id)):
			_add_issue(issues, path + ".npcId", "must be a stable NPC ID")
			continue
		if catalog.get_npc(relationship.npc_id) == null:
			_add_issue(issues, path + ".npcId", "references an unknown NPC")
		if seen.has(relationship.npc_id):
			_add_issue(issues, path + ".npcId", "duplicates an NPC relationship")
		seen[relationship.npc_id] = true
		if relationship.relationship_state.is_empty():
			_add_issue(issues, path + ".relationshipState", "must not be empty")
		if relationship.relationship_state == &"spouse":
			spouse_records += 1
			if relationship.npc_id != spouse_character_id:
				_add_issue(issues, path, "spouse record must match spouseCharacterId")
	if spouse_records > 1:
		_add_issue(issues, "relationships", "at most one spouse is allowed")
	if not spouse_character_id.is_empty() and spouse_records != 1:
		_add_issue(issues, "spouseCharacterId", "must reference exactly one spouse relationship")


static func _validate_mine_run(
	mine_run: SaveSnapshot.MineRun,
	world_day: int,
	issues: Array[DataValidationIssue],
) -> void:
	if mine_run == null:
		_add_issue(issues, "mineRun", "must be present")
		return
	if mine_run.world_day < 0 or mine_run.world_day > world_day:
		_add_issue(issues, "mineRun.worldDay", "must be zero or an elapsed world day")
	_validate_unique_ids(mine_run.broken_node_ids, "mineRun.brokenNodeIds", issues)
	_validate_unique_ids(mine_run.defeated_encounter_ids, "mineRun.defeatedEncounterIds", issues)


static func _snapshot_to_dictionary(snapshot: SaveSnapshot) -> Dictionary:
	var slots: Array = []
	for stack: ItemStack in snapshot.inventory.copy_stacks():
		slots.append(null if stack == null else {
			"itemId": String(stack.item_id),
			"quantity": stack.quantity,
		})
	var tiles: Array = []
	for tile: FarmTileState in snapshot.farm.copy_tiles():
		var crop_value: Variant = null
		if tile.crop != null:
			crop_value = {
				"cropId": String(tile.crop.crop_id),
				"plantedOnDay": tile.crop.planted_on_day,
				"growthProgress": tile.crop.growth_progress,
				"stageIndex": tile.crop.stage_index,
				"lastGrowthDay": tile.crop.last_growth_day,
			}
		tiles.append({
			"x": tile.coordinate.x,
			"y": tile.coordinate.y,
			"wateredOnDay": null if tile.watered_on_day == 0 else tile.watered_on_day,
			"crop": crop_value,
		})
	var flags: Dictionary = {}
	for flag_id: Variant in snapshot.story_flags:
		flags[String(flag_id)] = snapshot.story_flags[flag_id]
	var relationships: Array = []
	for relationship: SaveSnapshot.Relationship in snapshot.relationships:
		relationships.append({
			"npcId": String(relationship.npc_id),
			"affinity": relationship.affinity,
			"relationshipState": String(relationship.relationship_state),
		})
	return {
		"schemaVersion": SaveSnapshot.SCHEMA_VERSION,
		"savedAt": snapshot.saved_at,
		"profileId": String(snapshot.profile_id),
		"worldDay": snapshot.world_day,
		"currentMapId": String(snapshot.current_map_id),
		"player": {
			"anchorId": null if snapshot.player.anchor_id.is_empty() else String(snapshot.player.anchor_id),
			"position": {"x": snapshot.player.position.x, "y": snapshot.player.position.y},
			"facing": String(snapshot.player.facing),
			"health": snapshot.player.health,
		},
		"farm": {"mapId": String(snapshot.farm.map_id), "tiles": tiles},
		"inventory": {"selectedIndex": snapshot.inventory.selected_slot_index, "slots": slots},
		"storyFlags": flags,
		"relationships": relationships,
		"spouseCharacterId": null if snapshot.spouse_character_id.is_empty() else String(snapshot.spouse_character_id),
		"mineRun": {
			"worldDay": snapshot.mine_run.world_day,
			"brokenNodeIds": _string_array(snapshot.mine_run.broken_node_ids),
			"defeatedEncounterIds": _string_array(snapshot.mine_run.defeated_encounter_ids),
		},
	}


static func _as_record(value: Variant, path: String, issues: Array[DataValidationIssue]) -> Dictionary:
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


static func _read_nullable_id(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> StringName:
	if not record.has(key) or record.get(key) == null:
		return &""
	var value := _read_string(record, key, path, issues)
	if not _is_stable_id(value):
		_add_issue(issues, path, "must be a lowercase stable ID")
		return &""
	return StringName(value)


static func _read_integer(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
	minimum: int,
) -> int:
	var value: Variant = record.get(key)
	if not _is_integer(value) or int(value) < minimum:
		_add_issue(issues, path, "must be an integer >= %d" % minimum)
		return minimum
	return int(value)


static func _read_any_integer(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> int:
	var value: Variant = record.get(key)
	if not _is_integer(value):
		_add_issue(issues, path, "must be an integer")
		return 0
	return int(value)


static func _read_number(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> float:
	var value: Variant = record.get(key)
	if (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)):
		return float(value)
	_add_issue(issues, path, "must be a finite number")
	return 0.0


static func _read_id_array(
	record: Dictionary,
	key: String,
	path: String,
	issues: Array[DataValidationIssue],
) -> Array[StringName]:
	var raw_values := _read_array(record, key, path, issues)
	var ids: Array[StringName] = []
	for index: int in raw_values.size():
		var value: Variant = raw_values[index]
		if typeof(value) != TYPE_STRING or not _is_stable_id(String(value)):
			_add_issue(issues, "%s[%d]" % [path, index], "must be a lowercase stable ID")
			continue
		ids.append(StringName(String(value)))
	_validate_unique_ids(ids, path, issues)
	return ids


static func _validate_unique_ids(
	ids: Array[StringName],
	path: String,
	issues: Array[DataValidationIssue],
) -> void:
	var seen: Dictionary = {}
	for index: int in ids.size():
		if seen.has(ids[index]):
			_add_issue(issues, "%s[%d]" % [path, index], "duplicate ID")
		seen[ids[index]] = true


static func _string_array(ids: Array[StringName]) -> Array[String]:
	var values: Array[String] = []
	for id: StringName in ids:
		values.append(String(id))
	return values


static func _is_integer(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var numeric := float(value)
	return is_finite(numeric) and numeric == floor(numeric)


static func _is_stable_id(value: String) -> bool:
	var pattern := RegEx.new()
	return pattern.compile("^[a-z0-9]+(?:[._-][a-z0-9]+)*$") == OK and pattern.search(value) != null


static func _is_condition_key(value: String) -> bool:
	var pattern := RegEx.new()
	return pattern.compile("^[a-z][A-Za-z0-9]*(?:[._-][A-Za-z0-9]+)*$") == OK and pattern.search(value) != null


static func _add_issue(
	issues: Array[DataValidationIssue],
	path: String,
	message: String,
) -> void:
	issues.append(DataValidationIssue.new(path, message))

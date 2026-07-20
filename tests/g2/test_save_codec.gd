extends SceneTree

const SaveCodecScript = preload("res://scripts/domain/save/save_codec.gd")

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := _catalog()
	var inventory := InventoryState.create_empty()
	var addition: InventoryTransactionResult = inventory.with_added(&"mistleaf_seed", 3, catalog)
	var farm := FarmState.create_empty(&"hometown_main")
	var tilling: FarmTransactionResult = farm.try_till(Vector2i(8, 9), true)

	var snapshot := SaveSnapshot.new()
	snapshot.saved_at = "2026-07-20T12:00:00+08:00"
	snapshot.profile_id = &"profile-1"
	snapshot.world_day = 1
	snapshot.current_map_id = &"hometown_main"
	snapshot.player = SaveSnapshot.Player.new(
		&"main_safe_spawn",
		Vector2(336.0, 240.0),
		&"down",
		5,
	)
	snapshot.farm = tilling.farm
	snapshot.inventory = addition.inventory
	snapshot.story_flags = {&"opening.elderConversationCompleted": true}
	snapshot.relationships = [SaveSnapshot.Relationship.new(&"npc_shen_he", 12, &"friendship")]
	snapshot.spouse_character_id = &""
	snapshot.mine_run = SaveSnapshot.MineRun.new()

	var encoded: SaveCodecResult = SaveCodecScript.encode(snapshot, catalog)
	_check(encoded.status == SaveCodecResult.Status.ENCODED, "valid snapshot encodes")
	_check(encoded.payload.contains("\"schemaVersion\":1"), "payload declares the new schemaVersion")
	_check(not encoded.payload.contains("saveVersion"), "payload does not reuse the Cocos saveVersion")

	var decoded: SaveCodecResult = SaveCodecScript.decode(encoded.payload, catalog)
	_check(decoded.status == SaveCodecResult.Status.DECODED, "encoded snapshot decodes")
	if decoded.status == SaveCodecResult.Status.DECODED:
		_check(decoded.snapshot.profile_id == &"profile-1", "profile ID round-trips")
		_check(decoded.snapshot.world_day == 1, "world day round-trips")
		_check(decoded.snapshot.current_map_id == &"hometown_main", "map ID round-trips")
		_check(decoded.snapshot.inventory.stack_at(0).quantity == 3, "inventory round-trips")
		_check(decoded.snapshot.farm.tile_at(Vector2i(8, 9)) != null, "farm tile round-trips")
		_check(decoded.snapshot.story_flags[&"opening.elderConversationCompleted"], "story flag round-trips")
		_check(decoded.snapshot.relationships[0].npc_id == &"npc_shen_he", "known NPC relationship round-trips")

	var invalid_json: SaveCodecResult = SaveCodecScript.decode("{broken", catalog)
	_check(invalid_json.status == SaveCodecResult.Status.INVALID_JSON, "invalid JSON is isolated")

	var unsupported: SaveCodecResult = SaveCodecScript.decode(
		encoded.payload.replace("\"schemaVersion\":1", "\"schemaVersion\":99"),
		catalog,
	)
	_check(unsupported.status == SaveCodecResult.Status.UNSUPPORTED_SCHEMA, "unsupported schema is explicit")

	var old_cocos: SaveCodecResult = SaveCodecScript.decode(
		'{"saveVersion":1,"currentDay":1}',
		catalog,
	)
	_check(old_cocos.status != SaveCodecResult.Status.DECODED, "old Cocos payload is never decoded as a Godot save")

	var corrupt_reference: SaveCodecResult = SaveCodecScript.decode(
		encoded.payload.replace("mistleaf_seed", "missing_item"),
		catalog,
	)
	_check(corrupt_reference.status == SaveCodecResult.Status.INVALID_DATA, "unknown item reference rejects the snapshot")

	var unknown_npc: SaveCodecResult = SaveCodecScript.decode(
		encoded.payload.replace("npc_shen_he", "npc_missing"),
		catalog,
	)
	_check(unknown_npc.status == SaveCodecResult.Status.INVALID_DATA, "unknown NPC relationship rejects the snapshot")

	_finish()


func _catalog() -> GameCatalog:
	var documents: Dictionary = {}
	var paths: Dictionary = {
		"items": "res://data/items.json",
		"crops": "res://data/crops.json",
		"tools": "res://data/tools.json",
		"npcs": "res://data/npcs.json",
		"localization": "res://data/localization.json",
		"world": "res://data/demo_world.json",
		"resources": "res://data/runtime_resources.json",
	}
	for document_name: String in paths:
		documents[document_name] = JSON.parse_string(FileAccess.get_file_as_string(paths[document_name]))
	var result := GameCatalogCodec.decode_documents(documents)
	assert(result.is_valid(), result.describe_issues())
	return result.catalog


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("G2_SAVE_CODEC_OK")
		quit(0)
		return
	push_error("G2 save-codec test failed: %d check(s)" % _failures)
	quit(1)

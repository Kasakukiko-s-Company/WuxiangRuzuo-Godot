extends SceneTree

const GameCatalogCodec = preload("res://scripts/domain/catalog/game_catalog_codec.gd")

const DOCUMENT_PATHS: Dictionary = {
	"items": "res://data/items.json",
	"crops": "res://data/crops.json",
	"tools": "res://data/tools.json",
	"npcs": "res://data/npcs.json",
	"localization": "res://data/localization.json",
	"world": "res://data/demo_world.json",
	"resources": "res://data/runtime_resources.json",
}

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var documents: Dictionary = {}
	for document_name: String in DOCUMENT_PATHS:
		var document: Variant = _read_json(String(DOCUMENT_PATHS[document_name]))
		_check(document is Dictionary, "%s JSON parses as an object" % document_name)
		documents[document_name] = document

	var result: CatalogDecodeResult = GameCatalogCodec.decode_documents(documents)
	_check(result.is_valid(), "authoritative documents decode as one catalog")
	if not result.is_valid():
		push_error(result.describe_issues())
	if result.is_valid():
		_check(result.catalog.items.size() == 5, "catalog contains five item definitions")
		_check(result.catalog.crops.size() == 1, "catalog contains mistleaf")
		_check(result.catalog.npcs.size() == 15, "catalog contains the confirmed fifteen NPCs")
		_check(result.catalog.maps.size() == 4, "catalog contains exactly four demo maps")
		_check(result.catalog.portals.size() == 6, "catalog contains six directed portals")
		_check(result.catalog.get_item(&"mistleaf_seed") != null, "stable item lookup works")
		_check(result.catalog.get_item(&"village_scrip") != null, "exchange item lookup works")
		_check(
			result.catalog.get_localized_text(
				result.catalog.get_item(&"village_scrip").display_name_key,
			) == "村社券",
			"exchange UI can resolve the localized village-scrip name",
		)
		_check(result.catalog.get_map(&"home_interior") != null, "stable map lookup works")
		_check(result.catalog.get_npc(&"npc_qiao_ling") != null, "stable NPC lookup works")
		_check(result.catalog.get_resource(&"fallback.sprite.missing") != null, "semantic resource lookup works")

	var duplicate_documents: Dictionary = documents.duplicate(true)
	var duplicate_items: Array = duplicate_documents["items"]["items"]
	duplicate_items.append(duplicate_items[0].duplicate(true))
	var duplicate_result: CatalogDecodeResult = GameCatalogCodec.decode_documents(duplicate_documents)
	_check(not duplicate_result.is_valid(), "duplicate stable IDs reject the whole catalog")
	_check(duplicate_result.describe_issues().contains("duplicate ID"), "duplicate issue keeps a precise reason")

	var broken_reference_documents: Dictionary = documents.duplicate(true)
	broken_reference_documents["crops"]["crops"][0]["seedItemId"] = "missing_seed"
	var broken_reference_result: CatalogDecodeResult = GameCatalogCodec.decode_documents(broken_reference_documents)
	_check(not broken_reference_result.is_valid(), "broken crop cross-reference rejects the whole catalog")
	_check(broken_reference_result.describe_issues().contains("must reference a seed item"), "cross-reference issue identifies seed semantics")

	var unsupported_enum_documents: Dictionary = documents.duplicate(true)
	unsupported_enum_documents["tools"]["tools"][0]["action"] = "harvest"
	var unsupported_enum_result: CatalogDecodeResult = GameCatalogCodec.decode_documents(unsupported_enum_documents)
	_check(not unsupported_enum_result.is_valid(), "unsupported enum values reject the whole catalog")

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
		print("G2_CATALOG_OK")
		quit(0)
		return
	push_error("G2 catalog test failed: %d check(s)" % _failures)
	quit(1)

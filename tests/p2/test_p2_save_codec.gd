extends SceneTree

const LEGACY_V1_PAYLOAD: String = (
	'{"schemaVersion":1,"savedAt":"2026-07-20T12:00:00+08:00",'
	+ '"profileId":"profile-1","worldDay":1,"currentMapId":"hometown_main",'
	+ '"player":{"anchorId":"main_safe_spawn","position":{"x":336.0,"y":240.0},'
	+ '"facing":"down","health":5},"farm":{"mapId":"hometown_main","tiles":[]},'
	+ '"inventory":{"selectedIndex":0,"slots":[null,null,null,null,null,null,null,null]},'
	+ '"storyFlags":{},"relationships":[],"spouseCharacterId":null,'
	+ '"mineRun":{"worldDay":0,"brokenNodeIds":[],"defeatedEncounterIds":[]}}'
)

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_result := CatalogFileLoader.load_catalog()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	_check(
		game_result.is_valid() and estate_result.is_valid(),
		"P2 save codec loads both validated catalogs",
	)
	if not game_result.is_valid() or not estate_result.is_valid():
		_finish()
		return
	var game_catalog: GameCatalog = game_result.catalog
	var estate_catalog: EstateMapCatalog = estate_result.catalog
	var inventory := InventoryState.create_empty()
	var seed_addition := inventory.with_added(&"mistleaf_seed", 2, game_catalog)
	var scrip_addition := seed_addition.inventory.with_added(
		&"village_scrip",
		10,
		game_catalog,
	)
	var snapshot := SaveSnapshot.new()
	snapshot.saved_at = "2026-07-29T02:30:00Z"
	snapshot.profile_id = &"profile-1"
	snapshot.world_day = 3
	snapshot.current_map_id = &"home_h01_open_meadow"
	snapshot.player = SaveSnapshot.Player.new(
		&"home_safe_spawn_meadow",
		Vector2(640.0, 480.0),
		&"left",
		5,
	)
	snapshot.farm = FarmState.create_empty(&"home_h01_open_meadow")
	snapshot.inventory = scrip_addition.inventory
	snapshot.estate_map_state = EstateMapState.new(
		&"spring",
		&"reclaimed",
		&"light",
	)
	snapshot.daily_resource_claims = (
		DailyResourceClaims.create_empty().with_claim(
			&"home.h01.resource.north_meadow.daily_choice",
			2,
		)
	)
	snapshot.story_flags = {}
	snapshot.relationships = []
	snapshot.spouse_character_id = &""
	snapshot.mine_run = SaveSnapshot.MineRun.new()

	var encoded := SaveCodec.encode(snapshot, game_catalog, estate_catalog)
	_check(
		encoded.status == SaveCodecResult.Status.ENCODED,
		"schema v2 encodes a complete H01 durable state",
	)
	if encoded.status == SaveCodecResult.Status.ENCODED:
		_check(
			encoded.payload.contains("\"schemaVersion\":2"),
			"H01 payload declares schema version two",
		)
		var decoded := SaveCodec.decode(
			encoded.payload,
			game_catalog,
			estate_catalog,
		)
		_check(
			decoded.status == SaveCodecResult.Status.DECODED,
			"schema v2 H01 payload decodes",
		)
		if decoded.status == SaveCodecResult.Status.DECODED:
			_check(
				decoded.snapshot.estate_map_state.equals(
					snapshot.estate_map_state
				),
				"estate map state round-trips",
			)
			_check(
				decoded.snapshot.daily_resource_claims.last_claimed_day(
					&"home.h01.resource.north_meadow.daily_choice"
				) == 2,
				"daily resource claims round-trip",
			)
			_check(
				decoded.snapshot.current_map_id
				== &"home_h01_open_meadow"
				and decoded.snapshot.world_day == 3,
				"H01 map identity and world day round-trip",
			)
			_check(
				_inventory_quantity(
					decoded.snapshot.inventory,
					&"village_scrip",
				) == 10,
				"village scrip round-trips through existing schema v2 inventory slots",
			)

	var legacy := SaveCodec.decode(
		LEGACY_V1_PAYLOAD,
		game_catalog,
		estate_catalog,
	)
	_check(
		legacy.status == SaveCodecResult.Status.DECODED,
		"a valid schema v1 Godot save remains readable",
	)
	if legacy.status == SaveCodecResult.Status.DECODED:
		_check(
			legacy.source_schema_version == 1 and legacy.requires_resave,
			"v1 decode explicitly reports its migration provenance",
		)
		_check(
			legacy.snapshot.estate_map_state == null
			and legacy.snapshot.daily_resource_claims.copy_claim_days().is_empty(),
			"v1 migration adds no invented estate state or resource history",
		)

	_finish()


func _inventory_quantity(
	inventory: InventoryState,
	item_id: StringName,
) -> int:
	var quantity: int = 0
	for slot_index: int in inventory.capacity():
		var stack := inventory.stack_at(slot_index)
		if stack != null and stack.item_id == item_id:
			quantity += stack.quantity
	return quantity


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_SAVE_CODEC_OK")
		quit(0)
		return
	push_error("P2 save-codec test failed: %d check(s)" % _failures)
	quit(1)

extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(catalog_result.is_valid(), "planting test loads the validated game catalog")
	if not catalog_result.is_valid():
		_finish()
		return
	var catalog: GameCatalog = catalog_result.catalog
	var coordinate := Vector2i(12, 9)
	var empty_farm := FarmState.create_empty(&"home_h01_open_meadow")
	var tilled_result := empty_farm.try_till(coordinate, true)
	var empty_inventory := InventoryState.create_empty()
	var seed_add := empty_inventory.with_added(&"mistleaf_seed", 2, catalog)

	var initial_state := FarmingTransactionState.new(
		tilled_result.farm,
		seed_add.inventory,
	)
	var initial_session := FarmingSessionState.new(initial_state, 1)
	var command := CropPlantingCommand.new(
		&"home_h01_open_meadow",
		coordinate,
		1,
		&"spring",
		&"mistleaf_seed",
	)
	var planted: CropPlantingResult = CropPlanting.attempt(
		initial_session,
		command,
		catalog,
	)
	_check(planted.status == CropPlantingResult.Status.PLANTED, "seed plants on an empty tilled tile")
	_check(planted.session.state.farm != tilled_result.farm, "successful planting returns a new farm state")
	_check(planted.session.state.inventory != seed_add.inventory, "successful planting returns a new inventory state")
	var planted_tile: FarmTileState = planted.session.state.farm.tile_at(coordinate)
	_check(
		planted_tile.crop != null
		and planted_tile.crop.crop_id == &"mistleaf"
		and planted_tile.crop.planted_on_day == 1,
		"planted crop records stable identity and world day",
	)
	_check(
		planted.session.state.inventory.stack_at(0).quantity == 1,
		"planting consumes exactly one matching seed",
	)
	var restored_h01 := FarmState.restore(
		&"home_h01_open_meadow",
		planted.session.state.farm.copy_tiles(),
		catalog,
	)
	_check(
		restored_h01 != null
		and restored_h01.map_id == &"home_h01_open_meadow"
		and restored_h01.tile_at(coordinate).crop.crop_id == &"mistleaf",
		"farm state can restore H01 without depending on the retired demo-map catalog",
	)
	var invalid_tiles := planted.session.state.farm.copy_tiles()
	invalid_tiles[0].crop.stage_index = 2
	_check(
		FarmState.restore(
			&"home_h01_open_meadow",
			invalid_tiles,
			catalog,
		) == null,
		"farm restore rejects a stage that disagrees with growth progress",
	)

	var untilled_state := FarmingTransactionState.new(
		empty_farm,
		seed_add.inventory,
	)
	var untilled_session := FarmingSessionState.new(untilled_state, 1)
	var untilled: CropPlantingResult = CropPlanting.attempt(
		untilled_session,
		command,
		catalog,
	)
	_check(
		untilled.status == CropPlantingResult.Status.NOT_TILLED,
		"planting rejects ordinary ground",
	)
	_check(
		untilled.session == untilled_session,
		"rejected planting preserves farm and inventory identity",
	)

	var no_seed_inventory := InventoryState.create_empty()
	var no_seed_state := FarmingTransactionState.new(
		tilled_result.farm,
		no_seed_inventory,
	)
	var no_seed_session := FarmingSessionState.new(no_seed_state, 1)
	var no_seed: CropPlantingResult = CropPlanting.attempt(
		no_seed_session,
		command,
		catalog,
	)
	_check(
		no_seed.status == CropPlantingResult.Status.INSUFFICIENT_SEED,
		"planting rejects an unavailable seed",
	)
	_check(
		no_seed.session == no_seed_session,
		"missing-seed rejection is atomic",
	)

	var tile_snapshot := planted.session.state.farm.tile_at(coordinate)
	tile_snapshot.crop.growth_progress = 99
	_check(
		planted.session.state.farm.tile_at(coordinate).crop.growth_progress == 0,
		"farm tile queries cannot mutate authoritative crop state",
	)
	var stack_snapshot := planted.session.state.inventory.stack_at(0)
	stack_snapshot.quantity = 99
	_check(
		planted.session.state.inventory.stack_at(0).quantity == 1,
		"inventory slot queries cannot mutate authoritative stack state",
	)

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_CROP_PLANTING_OK")
		quit(0)
		return
	push_error("P2 crop planting test failed: %d check(s)" % _failures)
	quit(1)

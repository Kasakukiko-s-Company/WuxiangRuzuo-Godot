extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(catalog_result.is_valid(), "harvest test loads the validated game catalog")
	if not catalog_result.is_valid():
		_finish()
		return
	var catalog: GameCatalog = catalog_result.catalog
	var coordinate := Vector2i(12, 9)
	var session := _mature_mistleaf_session(catalog, coordinate)
	var mature_crop := session.state.farm.tile_at(coordinate).crop
	_check(
		mature_crop.growth_progress == 3
		and mature_crop.stage_index == 3
		and CropGrowth.is_mature(mature_crop, catalog.get_crop(&"mistleaf")),
		"three watered day transitions produce one mature mistleaf",
	)

	var command := CropHarvestingCommand.new(
		&"home_h01_open_meadow",
		coordinate,
	)
	var harvested: CropHarvestingResult = CropHarvesting.attempt(
		session,
		command,
		catalog,
	)
	_check(
		harvested.status == CropHarvestingResult.Status.HARVESTED,
		"a mature crop can be harvested",
	)
	_check(
		harvested.session.state.farm.tile_at(coordinate) != null
		and harvested.session.state.farm.tile_at(coordinate).crop == null,
		"harvest keeps the tilled tile and removes only the crop",
	)
	_check(
		harvested.session.state.inventory.stack_at(0).item_id == &"mistleaf"
		and harvested.session.state.inventory.stack_at(0).quantity == 1,
		"harvest adds the complete configured yield to inventory",
	)

	var full_inventory := InventoryState.create_empty(1)
	full_inventory = full_inventory.with_added(&"hoe_basic", 1, catalog).inventory
	var full_session := FarmingSessionState.new(
		FarmingTransactionState.new(
			session.state.farm,
			full_inventory,
		),
		session.world_day,
	)
	var blocked: CropHarvestingResult = CropHarvesting.attempt(
		full_session,
		command,
		catalog,
	)
	_check(
		blocked.status == CropHarvestingResult.Status.INVENTORY_FULL,
		"a full inventory blocks harvest",
	)
	_check(
		blocked.session == full_session
		and blocked.session.state.farm.tile_at(coordinate).crop != null,
		"blocked harvest preserves the composite state and mature crop",
	)

	var immature_farm := FarmState.create_empty(&"home_h01_open_meadow")
	immature_farm = immature_farm.try_till(coordinate, true).farm
	var immature_inventory := InventoryState.create_empty()
	immature_inventory = immature_inventory.with_added(
		&"mistleaf_seed",
		1,
		catalog,
	).inventory
	var immature_planting := CropPlanting.attempt(
		FarmingSessionState.new(
			FarmingTransactionState.new(immature_farm, immature_inventory),
			1,
		),
		CropPlantingCommand.new(
			&"home_h01_open_meadow",
			coordinate,
			1,
			&"spring",
			&"mistleaf_seed",
		),
		catalog,
	)
	var immature: CropHarvestingResult = CropHarvesting.attempt(
		immature_planting.session,
		command,
		catalog,
	)
	_check(
		immature.status == CropHarvestingResult.Status.NOT_MATURE
		and immature.session == immature_planting.session,
		"immature harvest is rejected without changing state",
	)

	_finish()


func _mature_mistleaf_session(
	catalog: GameCatalog,
	coordinate: Vector2i,
) -> FarmingSessionState:
	var farm := FarmState.create_empty(&"home_h01_open_meadow")
	farm = farm.try_till(coordinate, true).farm
	var inventory := InventoryState.create_empty()
	inventory = inventory.with_added(&"mistleaf_seed", 1, catalog).inventory
	var planted := CropPlanting.attempt(
		FarmingSessionState.new(
			FarmingTransactionState.new(farm, inventory),
			1,
		),
		CropPlantingCommand.new(
			&"home_h01_open_meadow",
			coordinate,
			1,
			&"spring",
			&"mistleaf_seed",
		),
		catalog,
	)
	var session := planted.session
	for completed_day: int in [1, 2, 3]:
		var watered := FarmWatering.attempt(
			session,
			FarmWateringCommand.new(
				&"home_h01_open_meadow",
				coordinate,
				completed_day,
			),
		)
		session = FarmDayCycle.advance_one_day(
			watered.session,
			FarmDayAdvanceCommand.new(completed_day),
			catalog,
		).session
	return session


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_CROP_HARVESTING_OK")
		quit(0)
		return
	push_error("P2 crop harvesting test failed: %d check(s)" % _failures)
	quit(1)

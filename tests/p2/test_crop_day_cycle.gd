extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(catalog_result.is_valid(), "day-cycle test loads the validated game catalog")
	if not catalog_result.is_valid():
		_finish()
		return
	var catalog: GameCatalog = catalog_result.catalog
	var coordinate := Vector2i(12, 9)
	var farm := FarmState.create_empty(&"home_h01_open_meadow")
	farm = farm.try_till(coordinate, true).farm
	var inventory := InventoryState.create_empty()
	inventory = inventory.with_added(&"mistleaf_seed", 1, catalog).inventory
	var planting_session := FarmingSessionState.new(
		FarmingTransactionState.new(farm, inventory),
		1,
	)
	var planted := CropPlanting.attempt(
		planting_session,
		CropPlantingCommand.new(
			&"home_h01_open_meadow",
			coordinate,
			1,
			&"spring",
			&"mistleaf_seed",
		),
		catalog,
	)

	var watered: FarmWateringResult = FarmWatering.attempt(
		planted.session,
		FarmWateringCommand.new(
			&"home_h01_open_meadow",
			coordinate,
			1,
		),
	)
	_check(watered.status == FarmWateringResult.Status.WATERED, "tilled soil can be watered for the current world day")
	_check(
		watered.session.state.farm.tile_at(coordinate).watered_on_day == 1,
		"watering records the authoritative world day",
	)
	var repeated_water: FarmWateringResult = FarmWatering.attempt(
		watered.session,
		FarmWateringCommand.new(
			&"home_h01_open_meadow",
			coordinate,
			1,
		),
	)
	_check(
		repeated_water.status == FarmWateringResult.Status.ALREADY_WATERED,
		"watering the same tile twice in one day is idempotent",
	)
	_check(
		repeated_water.session == watered.session,
		"idempotent watering preserves the composite state identity",
	)

	var backdated_water: FarmWateringResult = FarmWatering.attempt(
		FarmingSessionState.new(watered.session.state, 2),
		FarmWateringCommand.new(
			&"home_h01_open_meadow",
			coordinate,
			1,
		),
	)
	_check(
		backdated_water.status == FarmWateringResult.Status.INVALID_DAY
		and backdated_water.session.state == watered.session.state,
		"watering rejects a world day that does not match the session",
	)

	var day_one := watered.session
	var advanced: FarmDayAdvanceResult = FarmDayCycle.advance_one_day(
		day_one,
		FarmDayAdvanceCommand.new(1),
		catalog,
	)
	var grown_crop: CropState = advanced.session.state.farm.tile_at(
		coordinate
	).crop
	_check(
		advanced.status == FarmDayAdvanceResult.Status.ADVANCED
		and advanced.session.world_day == 2,
		"sleep advances exactly one world day",
	)
	_check(
		grown_crop.growth_progress == 1
		and grown_crop.stage_index == 1
		and grown_crop.last_growth_day == 1,
		"a watered mistleaf advances one deterministic growth unit overnight",
	)

	var no_water_advance: FarmDayAdvanceResult = FarmDayCycle.advance_one_day(
		advanced.session,
		FarmDayAdvanceCommand.new(2),
		catalog,
	)
	var paused_crop: CropState = no_water_advance.session.state.farm.tile_at(
		coordinate
	).crop
	_check(
		paused_crop.growth_progress == 1
		and paused_crop.last_growth_day == 2,
		"a water-required crop settles but does not grow after a dry day",
	)

	var replayed_day: FarmDayAdvanceResult = FarmDayCycle.advance_one_day(
		day_one,
		FarmDayAdvanceCommand.new(1),
		catalog,
	)
	_check(
		replayed_day.session.state.farm.tile_at(coordinate).crop.growth_progress
		== advanced.session.state.farm.tile_at(coordinate).crop.growth_progress,
		"replaying the same immutable day input is deterministic",
	)

	var already_applied: FarmDayAdvanceResult = FarmDayCycle.advance_one_day(
		advanced.session,
		FarmDayAdvanceCommand.new(1),
		catalog,
	)
	_check(
		already_applied.status == FarmDayAdvanceResult.Status.ALREADY_APPLIED
		and already_applied.session == advanced.session,
		"replaying an applied completed-day command is idempotent",
	)

	var day_gap: FarmDayAdvanceResult = FarmDayCycle.advance_one_day(
		planted.session,
		FarmDayAdvanceCommand.new(3),
		catalog,
	)
	_check(
		day_gap.status == FarmDayAdvanceResult.Status.DAY_GAP
		and day_gap.session == planted.session,
		"day cycle rejects a future completed-day command without mutation",
	)

	_check_mixed_crop_batch(catalog)
	_finish()


func _check_mixed_crop_batch(catalog: GameCatalog) -> void:
	var watered_coordinate := Vector2i(20, 12)
	var dry_coordinate := Vector2i(21, 12)
	var farm := FarmState.create_empty(&"home_h01_open_meadow")
	farm = farm.try_till(watered_coordinate, true).farm
	farm = farm.try_till(dry_coordinate, true).farm
	var inventory := InventoryState.create_empty()
	inventory = inventory.with_added(&"mistleaf_seed", 2, catalog).inventory
	var session := FarmingSessionState.new(
		FarmingTransactionState.new(farm, inventory),
		1,
	)
	for coordinate: Vector2i in [watered_coordinate, dry_coordinate]:
		session = CropPlanting.attempt(
			session,
			CropPlantingCommand.new(
				&"home_h01_open_meadow",
				coordinate,
				1,
				&"spring",
				&"mistleaf_seed",
			),
			catalog,
		).session
	session = FarmWatering.attempt(
		session,
		FarmWateringCommand.new(
			&"home_h01_open_meadow",
			watered_coordinate,
			1,
		),
	).session
	var mixed_advance := FarmDayCycle.advance_one_day(
		session,
		FarmDayAdvanceCommand.new(1),
		catalog,
	)
	var watered_crop: CropState = mixed_advance.session.state.farm.tile_at(
		watered_coordinate
	).crop
	var dry_crop: CropState = mixed_advance.session.state.farm.tile_at(
		dry_coordinate
	).crop
	_check(
		mixed_advance.status == FarmDayAdvanceResult.Status.ADVANCED
		and mixed_advance.grown_crop_count == 1
		and watered_crop.growth_progress == 1
		and dry_crop.growth_progress == 0
		and watered_crop.last_growth_day == 1
		and dry_crop.last_growth_day == 1,
		"one batch can grow a watered crop while settling a dry crop without growth",
	)

	var invalid_farm := session.state.farm._with_crop_state(
		dry_coordinate,
		CropState.new(&"unknown_crop", 1, 0, 0, 0),
	)
	var invalid_session := FarmingSessionState.new(
		FarmingTransactionState.new(
			invalid_farm,
			session.state.inventory,
		),
		1,
	)
	var rejected_batch := FarmDayCycle.advance_one_day(
		invalid_session,
		FarmDayAdvanceCommand.new(1),
		catalog,
	)
	_check(
		rejected_batch.status == FarmDayAdvanceResult.Status.UNKNOWN_CROP
		and rejected_batch.session == invalid_session
		and rejected_batch.session.state.farm.tile_at(
			watered_coordinate
		).crop.growth_progress == 0,
		"a later invalid crop rejects the whole batch before an earlier crop is settled",
	)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_CROP_DAY_CYCLE_OK")
		quit(0)
		return
	push_error("P2 crop day-cycle test failed: %d check(s)" % _failures)
	quit(1)

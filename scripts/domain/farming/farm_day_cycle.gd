class_name FarmDayCycle
extends RefCounted


static func advance_one_day(
	session: FarmingSessionState,
	command: FarmDayAdvanceCommand,
	catalog: GameCatalog,
) -> FarmDayAdvanceResult:
	if command.completed_day < session.world_day:
		return FarmDayAdvanceResult.new(
			FarmDayAdvanceResult.Status.ALREADY_APPLIED,
			session,
		)
	if command.completed_day > session.world_day:
		return FarmDayAdvanceResult.new(
			FarmDayAdvanceResult.Status.DAY_GAP,
			session,
		)
	var tiles := session.state.farm.copy_tiles()
	for tile: FarmTileState in tiles:
		if tile.crop == null:
			continue
		if catalog.get_crop(tile.crop.crop_id) == null:
			return FarmDayAdvanceResult.new(
				FarmDayAdvanceResult.Status.UNKNOWN_CROP,
				session,
			)
		if tile.crop.last_growth_day != command.completed_day - 1:
			return FarmDayAdvanceResult.new(
				FarmDayAdvanceResult.Status.DAY_GAP,
				session,
			)

	var next_farm := session.state.farm
	var grown_count: int = 0
	for tile: FarmTileState in tiles:
		if tile.crop == null:
			continue
		var definition: CatalogDefinitions.Crop = catalog.get_crop(
			tile.crop.crop_id
		)
		var next_crop := CropGrowth.evaluate_one_day(
			tile.crop,
			definition,
			tile.watered_on_day,
			command.completed_day,
		)
		if next_crop.growth_progress > tile.crop.growth_progress:
			grown_count += 1
		next_farm = next_farm._with_crop_state(tile.coordinate, next_crop)

	var next_state := FarmingTransactionState.new(
		next_farm,
		session.state.inventory,
	)
	return FarmDayAdvanceResult.new(
		FarmDayAdvanceResult.Status.ADVANCED,
		FarmingSessionState.new(next_state, command.completed_day + 1),
		grown_count,
	)

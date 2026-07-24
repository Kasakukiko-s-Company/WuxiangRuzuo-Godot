class_name CropPlanting
extends RefCounted


static func attempt(
	session: FarmingSessionState,
	command: CropPlantingCommand,
	catalog: GameCatalog,
) -> CropPlantingResult:
	if command.map_id != session.state.farm.map_id:
		return CropPlantingResult.new(
			CropPlantingResult.Status.MAP_MISMATCH,
			session,
		)
	if command.world_day != session.world_day:
		return CropPlantingResult.new(
			CropPlantingResult.Status.INVALID_DAY,
			session,
		)
	var seed_definition: CatalogDefinitions.Item = catalog.get_item(
		command.seed_item_id
	)
	if (
		seed_definition == null
		or seed_definition.kind != CatalogDefinitions.Item.Kind.SEED
	):
		return CropPlantingResult.new(CropPlantingResult.Status.INVALID_SEED, session)
	var crop_definition: CatalogDefinitions.Crop = catalog.get_crop(
		seed_definition.crop_id
	)
	if (
		crop_definition == null
		or crop_definition.seed_item_id != command.seed_item_id
	):
		return CropPlantingResult.new(CropPlantingResult.Status.INVALID_SEED, session)
	if (
		not crop_definition.allowed_seasons.has(&"all")
		and not crop_definition.allowed_seasons.has(command.season)
	):
		return CropPlantingResult.new(
			CropPlantingResult.Status.WRONG_SEASON,
			session,
		)
	var tile: FarmTileState = session.state.farm.tile_at(command.coordinate)
	if tile == null:
		return CropPlantingResult.new(CropPlantingResult.Status.NOT_TILLED, session)
	if tile.crop != null:
		return CropPlantingResult.new(CropPlantingResult.Status.TILE_OCCUPIED, session)
	var seed_removal := session.state.inventory.with_removed(
		crop_definition.seed_item_id,
		1,
		catalog,
	)
	if seed_removal.status != InventoryTransactionResult.Status.REMOVED:
		return CropPlantingResult.new(
			CropPlantingResult.Status.INSUFFICIENT_SEED,
			session,
		)
	var crop := CropState.new(
		crop_definition.id,
		command.world_day,
		0,
		0,
		command.world_day - 1,
	)
	return CropPlantingResult.new(
		CropPlantingResult.Status.PLANTED,
		FarmingSessionState.new(
			FarmingTransactionState.new(
				session.state.farm._with_planted_crop(command.coordinate, crop),
				seed_removal.inventory,
			),
			session.world_day,
		),
	)

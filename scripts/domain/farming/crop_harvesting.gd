class_name CropHarvesting
extends RefCounted


static func attempt(
	session: FarmingSessionState,
	command: CropHarvestingCommand,
	catalog: GameCatalog,
) -> CropHarvestingResult:
	if command.map_id != session.state.farm.map_id:
		return CropHarvestingResult.new(
			CropHarvestingResult.Status.MAP_MISMATCH,
			session,
		)
	var tile: FarmTileState = session.state.farm.tile_at(command.coordinate)
	if tile == null:
		return CropHarvestingResult.new(
			CropHarvestingResult.Status.NOT_TILLED,
			session,
		)
	if tile.crop == null:
		return CropHarvestingResult.new(
			CropHarvestingResult.Status.NO_CROP,
			session,
		)
	var definition: CatalogDefinitions.Crop = catalog.get_crop(tile.crop.crop_id)
	if definition == null:
		return CropHarvestingResult.new(
			CropHarvestingResult.Status.UNKNOWN_CROP,
			session,
		)
	if not CropGrowth.is_mature(tile.crop, definition):
		return CropHarvestingResult.new(
			CropHarvestingResult.Status.NOT_MATURE,
			session,
		)
	var harvest_addition := session.state.inventory.with_added(
		definition.harvest_item_id,
		definition.harvest_quantity,
		catalog,
	)
	if harvest_addition.status != InventoryTransactionResult.Status.ADDED:
		return CropHarvestingResult.new(
			CropHarvestingResult.Status.INVENTORY_FULL,
			session,
		)
	return CropHarvestingResult.new(
		CropHarvestingResult.Status.HARVESTED,
		FarmingSessionState.new(
			FarmingTransactionState.new(
				session.state.farm._with_crop_state(command.coordinate, null),
				harvest_addition.inventory,
			),
			session.world_day,
		),
		definition.harvest_quantity,
	)

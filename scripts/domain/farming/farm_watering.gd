class_name FarmWatering
extends RefCounted


static func attempt(
	session: FarmingSessionState,
	command: FarmWateringCommand,
) -> FarmWateringResult:
	if command.map_id != session.state.farm.map_id:
		return FarmWateringResult.new(
			FarmWateringResult.Status.MAP_MISMATCH,
			session,
		)
	if command.world_day != session.world_day:
		return FarmWateringResult.new(
			FarmWateringResult.Status.INVALID_DAY,
			session,
		)
	var tile: FarmTileState = session.state.farm.tile_at(command.coordinate)
	if tile == null:
		return FarmWateringResult.new(FarmWateringResult.Status.NOT_TILLED, session)
	if tile.watered_on_day == command.world_day:
		return FarmWateringResult.new(
			FarmWateringResult.Status.ALREADY_WATERED,
			session,
		)
	return FarmWateringResult.new(
		FarmWateringResult.Status.WATERED,
		FarmingSessionState.new(
			FarmingTransactionState.new(
				session.state.farm._with_watered_on_day(
					command.coordinate,
					command.world_day,
				),
				session.state.inventory,
			),
			session.world_day,
		),
	)

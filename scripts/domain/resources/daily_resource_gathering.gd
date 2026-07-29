class_name DailyResourceGathering
extends RefCounted


static func attempt(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
	command: DailyResourceGatheringCommand,
	source_catalog: DailyResourceSourceCatalog,
	catalog: GameCatalog,
) -> DailyResourceGatheringResult:
	var source: DailyResourceSourceDefinition = source_catalog.get_source(
		command.source_id
	)
	if source == null:
		return _rejected(
			DailyResourceGatheringResult.Status.INVALID_SOURCE,
			session,
			claims,
		)
	if source.map_id != session.state.farm.map_id:
		return _rejected(
			DailyResourceGatheringResult.Status.MAP_MISMATCH,
			session,
			claims,
		)
	if command.world_day != session.world_day:
		return _rejected(
			DailyResourceGatheringResult.Status.INVALID_DAY,
			session,
			claims,
		)
	if catalog.get_item(source.item_id) == null:
		return _rejected(
			DailyResourceGatheringResult.Status.INVALID_ITEM,
			session,
			claims,
		)
	var claim_key := source.claim_key()
	if claims.last_claimed_day(claim_key) >= command.world_day:
		return _rejected(
			DailyResourceGatheringResult.Status.ALREADY_COLLECTED,
			session,
			claims,
		)

	var addition := session.state.inventory.with_added(
		source.item_id,
		source.quantity,
		catalog,
	)
	if addition.status == InventoryTransactionResult.Status.INVENTORY_FULL:
		return _rejected(
			DailyResourceGatheringResult.Status.INVENTORY_FULL,
			session,
			claims,
		)
	if addition.status == InventoryTransactionResult.Status.INVALID_ITEM:
		return _rejected(
			DailyResourceGatheringResult.Status.INVALID_ITEM,
			session,
			claims,
		)
	if addition.status != InventoryTransactionResult.Status.ADDED:
		return _rejected(
			DailyResourceGatheringResult.Status.INVALID_QUANTITY,
			session,
			claims,
		)

	var next_session := FarmingSessionState.new(
		FarmingTransactionState.new(
			session.state.farm,
			addition.inventory,
		),
		session.world_day,
	)
	return DailyResourceGatheringResult.new(
		DailyResourceGatheringResult.Status.COLLECTED,
		next_session,
		claims.with_claim(claim_key, command.world_day),
	)


static func _rejected(
	status: DailyResourceGatheringResult.Status,
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> DailyResourceGatheringResult:
	return DailyResourceGatheringResult.new(status, session, claims)

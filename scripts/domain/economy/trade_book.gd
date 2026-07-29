class_name TradeBook
extends RefCounted

var _catalog: TradeOfferCatalog
var _game_catalog: GameCatalog


func _init(
	offer_catalog: TradeOfferCatalog,
	game_catalog: GameCatalog,
) -> void:
	assert(offer_catalog != null, "trade offer catalog is required")
	assert(game_catalog != null, "game catalog is required")
	_catalog = offer_catalog
	_game_catalog = game_catalog


func offers(endpoint_id: StringName) -> Array[TradeOfferDefinition]:
	return _catalog.offers_for_endpoint(endpoint_id)


func execute(
	inventory: InventoryState,
	command: TradeCommand,
) -> TradeResult:
	var offer := _catalog.get_offer(command.offer_id)
	if offer == null:
		return TradeResult.new(TradeResult.Status.INVALID_OFFER, inventory)
	if offer.endpoint_id != command.endpoint_id:
		return TradeResult.new(
			TradeResult.Status.ENDPOINT_MISMATCH,
			inventory,
			offer,
		)
	var removal := inventory.with_removed(
		offer.cost_item_id,
		offer.cost_quantity,
		_game_catalog,
	)
	if removal.status != InventoryTransactionResult.Status.REMOVED:
		return TradeResult.new(
			TradeResult.Status.INSUFFICIENT_COST,
			inventory,
			offer,
		)
	var addition := removal.inventory.with_added(
		offer.reward_item_id,
		offer.reward_quantity,
		_game_catalog,
	)
	if addition.status != InventoryTransactionResult.Status.ADDED:
		return TradeResult.new(
			TradeResult.Status.REWARD_CAPACITY,
			inventory,
			offer,
		)
	return TradeResult.new(
		TradeResult.Status.COMPLETED,
		addition.inventory,
		offer,
	)

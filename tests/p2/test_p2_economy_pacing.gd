extends SceneTree

const MAP_ID: StringName = &"home_h01_open_meadow"
const SEED_SOURCE_ID: StringName = &"home.h01.resource.north_meadow"
const FORAGE_SOURCE_ID: StringName = (
	&"home.h01.resource.north_meadow.forage"
)
const CLAIM_GROUP_ID: StringName = (
	&"home.h01.resource.north_meadow.daily_choice"
)
const ENDPOINT_ID: StringName = &"economy.h01.north_meadow_crate"
const SELL_OFFER_ID: StringName = &"economy.h01.sell_mistleaf"
const BUY_OFFER_ID: StringName = &"economy.h01.buy_mistleaf_seed"

var _failures: int = 0
var _catalog: GameCatalog
var _sources: DailyResourceSourceCatalog
var _book: TradeBook


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _initialize_dependencies():
		_finish()
		return
	_test_immediate_forage_baseline()
	_test_three_seed_investment_baseline()
	_finish()


func _initialize_dependencies() -> bool:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(
		catalog_result.is_valid(),
		"economy pacing probe loads the validated game catalog",
	)
	if not catalog_result.is_valid():
		return false
	_catalog = catalog_result.catalog
	var offer_result := TradeOfferCatalogFileLoader.load_catalog(_catalog)
	_check(
		offer_result.is_valid(),
		"economy pacing probe loads validated trade offers",
	)
	if not offer_result.is_valid():
		return false
	var definitions: Array[DailyResourceSourceDefinition] = [
		DailyResourceSourceDefinition.new(
			SEED_SOURCE_ID,
			MAP_ID,
			&"resource_spawn_zone",
			&"resource_north_meadow",
			&"mistleaf_seed",
			3,
			CLAIM_GROUP_ID,
		),
		DailyResourceSourceDefinition.new(
			FORAGE_SOURCE_ID,
			MAP_ID,
			&"resource_spawn_zone",
			&"resource_north_meadow",
			&"mistleaf",
			1,
			CLAIM_GROUP_ID,
		),
	]
	_sources = DailyResourceSourceCatalog.create(definitions, _catalog)
	_book = TradeBook.new(offer_result.catalog, _catalog)
	return _sources != null


func _test_immediate_forage_baseline() -> void:
	var initial := _empty_session()
	var gathered := DailyResourceGathering.attempt(
		initial,
		DailyResourceClaims.create_empty(),
		DailyResourceGatheringCommand.new(FORAGE_SOURCE_ID, 1),
		_sources,
		_catalog,
	)
	var sold := _book.execute(
		gathered.session.state.inventory,
		TradeCommand.new(ENDPOINT_ID, SELL_OFFER_ID),
	)
	var bought := _book.execute(
		sold.inventory,
		TradeCommand.new(ENDPOINT_ID, BUY_OFFER_ID),
	)
	_check(
		gathered.is_success()
		and sold.status == TradeResult.Status.COMPLETED
		and bought.status == TradeResult.Status.COMPLETED
		and _quantity(bought.inventory, &"mistleaf_seed") == 1
		and _quantity(bought.inventory, &"village_scrip") == 10,
		"immediate forage converts to one replacement seed plus ten scrip",
	)


func _test_three_seed_investment_baseline() -> void:
	var claimed := DailyResourceGathering.attempt(
		_empty_session(),
		DailyResourceClaims.create_empty(),
		DailyResourceGatheringCommand.new(SEED_SOURCE_ID, 1),
		_sources,
		_catalog,
	)
	var coordinates: Array[Vector2i] = [
		Vector2i(12, 9),
		Vector2i(13, 9),
		Vector2i(14, 9),
	]
	var farm := claimed.session.state.farm
	for coordinate: Vector2i in coordinates:
		farm = farm.try_till(coordinate, true).farm
	var session := FarmingSessionState.new(
		FarmingTransactionState.new(
			farm,
			claimed.session.state.inventory,
		),
		1,
	)
	for coordinate: Vector2i in coordinates:
		var planted := CropPlanting.attempt(
			session,
			CropPlantingCommand.new(
				MAP_ID,
				coordinate,
				1,
				&"spring",
				&"mistleaf_seed",
			),
			_catalog,
		)
		session = planted.session
	for completed_day: int in [1, 2, 3]:
		for coordinate: Vector2i in coordinates:
			session = FarmWatering.attempt(
				session,
				FarmWateringCommand.new(
					MAP_ID,
					coordinate,
					completed_day,
				),
			).session
		session = FarmDayCycle.advance_one_day(
			session,
			FarmDayAdvanceCommand.new(completed_day),
			_catalog,
		).session
	for coordinate: Vector2i in coordinates:
		session = CropHarvesting.attempt(
			session,
			CropHarvestingCommand.new(MAP_ID, coordinate),
			_catalog,
		).session
	var inventory := session.state.inventory
	for _sale: int in 3:
		inventory = _book.execute(
			inventory,
			TradeCommand.new(ENDPOINT_ID, SELL_OFFER_ID),
		).inventory
	for _purchase: int in 4:
		inventory = _book.execute(
			inventory,
			TradeCommand.new(ENDPOINT_ID, BUY_OFFER_ID),
		).inventory
	_check(
		session.world_day == 4
		and _quantity(session.state.inventory, &"mistleaf") == 3
		and _quantity(inventory, &"mistleaf_seed") == 4
		and _quantity(inventory, &"village_scrip") == 10,
		"three watered transitions turn the seed choice into four replacement seeds plus ten scrip",
	)


func _empty_session() -> FarmingSessionState:
	return FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(MAP_ID),
			InventoryState.create_empty(),
		),
		1,
	)


func _quantity(inventory: InventoryState, item_id: StringName) -> int:
	var total: int = 0
	for slot_index: int in inventory.capacity():
		var stack := inventory.stack_at(slot_index)
		if stack != null and stack.item_id == item_id:
			total += stack.quantity
	return total


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_ECONOMY_PACING_OK")
		quit(0)
		return
	push_error("P2 economy pacing probe failed: %d check(s)" % _failures)
	quit(1)

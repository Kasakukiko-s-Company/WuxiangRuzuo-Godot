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
const FARM_CELL: Vector2i = Vector2i(12, 9)

var _failures: int = 0
var _catalog: GameCatalog
var _sources: DailyResourceSourceCatalog
var _trade_book: TradeBook
var _guide: H01LifeLoopGuide


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _initialize_dependencies():
		_finish()
		return
	var session := _empty_session()
	var claims := DailyResourceClaims.create_empty()
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.CLAIM_DAILY_RESOURCE,
		"an untouched day first guides the player to the daily resource choice",
	)
	var initial_inventory: InventoryState = session.state.inventory
	var first_projection := _guide.present(session, claims)
	var repeated_projection := _guide.present(session, claims)
	_check(
		first_projection.stage == repeated_projection.stage
		and first_projection.stable_id == repeated_projection.stable_id
		and first_projection.text == repeated_projection.text
		and session.state.inventory == initial_inventory
		and session.state.farm.tile_count() == 0
		and claims.last_claimed_day(CLAIM_GROUP_ID) == 0,
		"same inputs derive the same objective without mutating session or claims",
	)

	var seed_claim := DailyResourceGathering.attempt(
		session,
		claims,
		DailyResourceGatheringCommand.new(SEED_SOURCE_ID, 1),
		_sources,
		_catalog,
	)
	session = seed_claim.session
	claims = seed_claim.claims
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.TILL_SOIL,
		"seed choice guides the player to prepare soil",
	)

	session = FarmingSessionState.new(
		FarmingTransactionState.new(
			session.state.farm.try_till(FARM_CELL, true).farm,
			session.state.inventory,
		),
		session.world_day,
	)
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.PLANT_SEED,
		"an empty tilled cell guides the player to plant",
	)

	session = CropPlanting.attempt(
		session,
		CropPlantingCommand.new(
			MAP_ID,
			FARM_CELL,
			1,
			&"spring",
			&"mistleaf_seed",
		),
		_catalog,
	).session
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.WATER_CROP,
		"a planted crop guides the player to water it",
	)

	session = FarmWatering.attempt(
		session,
		FarmWateringCommand.new(MAP_ID, FARM_CELL, 1),
	).session
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.REST_FOR_GROWTH,
		"one cared-for crop completes the first-day loop without forcing expansion",
	)
	session = session.with_inventory(
		session.state.inventory.with_removed(
			&"mistleaf_seed",
			2,
			_catalog,
		).inventory
	)
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.REST_FOR_GROWTH,
		"a cared-for crop with no pending resource use guides rest for growth",
	)

	session = FarmDayCycle.advance_one_day(
		session,
		FarmDayAdvanceCommand.new(1),
		_catalog,
	).session
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.WATER_CROP,
		"crop care stays ahead of an unclaimed daily resource on later days",
	)
	session = FarmWatering.attempt(
		session,
		FarmWateringCommand.new(MAP_ID, FARM_CELL, 2),
	).session
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.CLAIM_DAILY_RESOURCE,
		"after time-sensitive care the guide restores the unclaimed daily choice",
	)

	for completed_day: int in [2, 3]:
		claims = claims.with_claim(CLAIM_GROUP_ID, completed_day)
		session = FarmDayCycle.advance_one_day(
			session,
			FarmDayAdvanceCommand.new(completed_day),
			_catalog,
		).session
		if completed_day < 3:
			session = FarmWatering.attempt(
				session,
				FarmWateringCommand.new(
					MAP_ID,
					FARM_CELL,
					completed_day + 1,
				),
			).session
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.HARVEST_CROP,
		"a mature crop takes priority over the next daily choice",
	)

	session = CropHarvesting.attempt(
		session,
		CropHarvestingCommand.new(MAP_ID, FARM_CELL),
		_catalog,
	).session
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.SELL_PRODUCE,
		"harvested produce guides the player to the exchange endpoint",
	)

	session = session.with_inventory(
		_trade_book.execute(
			session.state.inventory,
			TradeCommand.new(ENDPOINT_ID, SELL_OFFER_ID),
		).inventory
	)
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.CLAIM_DAILY_RESOURCE,
		"the current free daily choice stays ahead of a paid seed purchase",
	)
	claims = claims.with_claim(CLAIM_GROUP_ID, session.world_day)
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.BUY_SEED,
		"earned local scrip guides seed replenishment only after free choice is spent",
	)

	session = session.with_inventory(
		_trade_book.execute(
			session.state.inventory,
			TradeCommand.new(ENDPOINT_ID, BUY_OFFER_ID),
		).inventory
	)
	claims = claims.with_claim(CLAIM_GROUP_ID, session.world_day)
	_expect(
		session,
		claims,
		P2LifeLoopObjective.Stage.PLANT_SEED,
		"replenished seed returns the guide to the reusable farm loop",
	)

	var stocked_inventory := InventoryState.create_empty()
	stocked_inventory = stocked_inventory.with_added(
		&"hoe_basic",
		1,
		_catalog,
	).inventory
	stocked_inventory = stocked_inventory.with_added(
		&"mistleaf_seed",
		1,
		_catalog,
	).inventory
	stocked_inventory = stocked_inventory.with_added(
		&"village_scrip",
		100,
		_catalog,
	).inventory
	_expect(
		_empty_session().with_inventory(stocked_inventory),
		DailyResourceClaims.create_empty().with_claim(CLAIM_GROUP_ID, 1),
		P2LifeLoopObjective.Stage.TILL_SOIL,
		"available scrip does not force repeated seed purchases when farming can continue",
	)

	var stranded_claims := DailyResourceClaims.create_empty().with_claim(
		CLAIM_GROUP_ID,
		1,
	)
	_expect(
		_empty_session(),
		stranded_claims,
		P2LifeLoopObjective.Stage.REST_FOR_RESOURCES,
		"a spent day with no usable resources guides a safe next-day reset",
	)

	var full_stacks: Array[ItemStack] = []
	for _slot_index: int in InventoryState.DEFAULT_CAPACITY:
		full_stacks.append(ItemStack.new(&"hoe_basic", 1))
	var full_inventory := InventoryState.restore(full_stacks, 0, _catalog)
	_expect(
		_empty_session().with_inventory(full_inventory),
		DailyResourceClaims.create_empty(),
		P2LifeLoopObjective.Stage.INVENTORY_BLOCKED,
		"a full inventory with no usable exit reports an honest blocked state",
	)

	var care_stacks: Array[ItemStack] = [
		ItemStack.new(&"watering_can_basic", 1),
	]
	for _slot_index: int in InventoryState.DEFAULT_CAPACITY - 1:
		care_stacks.append(ItemStack.new(&"hoe_basic", 1))
	var care_inventory := InventoryState.restore(care_stacks, 0, _catalog)
	var mixed_farm := FarmState.restore(
		MAP_ID,
		[
			FarmTileState.new(
				FARM_CELL,
				3,
				CropState.new(&"mistleaf", 1, 3, 3, 3),
			),
			FarmTileState.new(
				FARM_CELL + Vector2i.RIGHT,
				0,
				CropState.new(&"mistleaf", 4, 0, 0, 3),
			),
		],
		_catalog,
	)
	var mixed_session := FarmingSessionState.new(
		FarmingTransactionState.new(mixed_farm, care_inventory),
		4,
	)
	_expect(
		mixed_session,
		DailyResourceClaims.create_empty().with_claim(CLAIM_GROUP_ID, 4),
		P2LifeLoopObjective.Stage.WATER_CROP,
		"time-sensitive crop care stays ahead of a mature crop blocked by inventory",
	)
	var missing_can_session := FarmingSessionState.new(
		FarmingTransactionState.new(mixed_farm, full_inventory),
		4,
	)
	_expect(
		missing_can_session,
		DailyResourceClaims.create_empty().with_claim(CLAIM_GROUP_ID, 4),
		P2LifeLoopObjective.Stage.REQUIRED_TOOL_MISSING,
		"an accepted restore without a watering can never advertises watering",
	)

	var missing_hoe_inventory := InventoryState.create_empty().with_added(
		&"mistleaf_seed",
		1,
		_catalog,
	).inventory
	_expect(
		_empty_session().with_inventory(missing_hoe_inventory),
		DailyResourceClaims.create_empty().with_claim(CLAIM_GROUP_ID, 1),
		P2LifeLoopObjective.Stage.REQUIRED_TOOL_MISSING,
		"an accepted restore without a hoe never advertises tilling",
	)

	var one_space_stacks: Array[ItemStack] = [
		ItemStack.new(&"mistleaf", 98),
	]
	for _slot_index: int in InventoryState.DEFAULT_CAPACITY - 1:
		one_space_stacks.append(ItemStack.new(&"hoe_basic", 1))
	var one_space_inventory := InventoryState.restore(
		one_space_stacks,
		0,
		_catalog,
	)
	var two_mature_farm := FarmState.restore(
		MAP_ID,
		[
			FarmTileState.new(
				FARM_CELL,
				3,
				CropState.new(&"mistleaf", 1, 3, 3, 3),
			),
			FarmTileState.new(
				FARM_CELL + Vector2i.RIGHT,
				3,
				CropState.new(&"mistleaf", 1, 3, 3, 3),
			),
		],
		_catalog,
	)
	var limited_harvest_session := FarmingSessionState.new(
		FarmingTransactionState.new(two_mature_farm, one_space_inventory),
		4,
	)
	var limited_objective := _guide.present(
		limited_harvest_session,
		DailyResourceClaims.create_empty().with_claim(CLAIM_GROUP_ID, 4),
	)
	_check(
		limited_objective.stage == P2LifeLoopObjective.Stage.HARVEST_CROP
		and limited_objective.text.contains("1 株"),
		"harvest count reflects cumulative inventory capacity instead of per-crop probes",
	)
	_finish()


func _initialize_dependencies() -> bool:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(
		catalog_result.is_valid(),
		"life-loop guide loads the validated game catalog",
	)
	if not catalog_result.is_valid():
		return false
	_catalog = catalog_result.catalog
	var offer_result := TradeOfferCatalogFileLoader.load_catalog(_catalog)
	_check(
		offer_result.is_valid(),
		"life-loop guide loads the validated trade catalog",
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
	_trade_book = TradeBook.new(offer_result.catalog, _catalog)
	_guide = H01LifeLoopGuide.new(_catalog, _trade_book, _sources)
	return _sources != null


func _empty_session() -> FarmingSessionState:
	var inventory := InventoryState.create_empty()
	inventory = inventory.with_added(&"hoe_basic", 1, _catalog).inventory
	inventory = inventory.with_added(
		&"watering_can_basic",
		1,
		_catalog,
	).inventory
	return FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(MAP_ID),
			inventory,
		),
		1,
	)


func _expect(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
	expected_stage: P2LifeLoopObjective.Stage,
	label: String,
) -> void:
	var objective := _guide.present(
		session,
		claims,
	)
	_check(
		objective != null
		and objective.stage == expected_stage
		and not objective.text.strip_edges().is_empty()
		and not objective.stable_id.is_empty(),
		label,
	)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_H01_LIFE_LOOP_GUIDE_OK")
		quit(0)
		return
	push_error("P2 H01 life-loop guide failed: %d check(s)" % _failures)
	quit(1)

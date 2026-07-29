class_name H01LifeLoopGuide
extends RefCounted

const CLAIM_GROUP_ID: StringName = (
	&"home.h01.resource.north_meadow.daily_choice"
)
const SEED_SOURCE_ID: StringName = &"home.h01.resource.north_meadow"
const FORAGE_SOURCE_ID: StringName = (
	&"home.h01.resource.north_meadow.forage"
)
const SELL_OFFER_ID: StringName = &"economy.h01.sell_mistleaf"
const BUY_OFFER_ID: StringName = &"economy.h01.buy_mistleaf_seed"
const TRADE_ENDPOINT_ID: StringName = &"economy.h01.north_meadow_crate"
const SEED_ITEM_ID: StringName = &"mistleaf_seed"
const HOE_ITEM_ID: StringName = &"hoe_basic"
const WATERING_CAN_ITEM_ID: StringName = &"watering_can_basic"

var _catalog: GameCatalog
var _trade_book: TradeBook
var _source_catalog: DailyResourceSourceCatalog


func _init(
	catalog: GameCatalog,
	trade_book: TradeBook,
	source_catalog: DailyResourceSourceCatalog,
) -> void:
	assert(catalog != null, "life-loop guide requires a game catalog")
	assert(trade_book != null, "life-loop guide requires a trade book")
	assert(
		source_catalog != null,
		"life-loop guide requires a daily resource source catalog",
	)
	_catalog = catalog
	_trade_book = trade_book
	_source_catalog = source_catalog


func present(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> P2LifeLoopObjective:
	assert(session != null, "life-loop guide requires a farming session")
	assert(claims != null, "life-loop guide requires daily resource claims")
	var farm_summary := _summarize_farm(session, _catalog)
	if farm_summary.harvestable_mature_count > 0:
		return P2LifeLoopObjective.new(
			P2LifeLoopObjective.Stage.HARVEST_CROP,
			&"p2.h01.guide.harvest",
			"收获 %d 株成熟雾叶" % farm_summary.harvestable_mature_count,
		)
	if farm_summary.needs_water_count > 0:
		if _inventory_quantity(
			session.state.inventory,
			WATERING_CAN_ITEM_ID,
		) == 0:
			return _required_tool_missing_objective(
				&"p2.h01.guide.missing_watering_can",
				"缺少浇水壶；当前作物无法继续照料",
			)
		return P2LifeLoopObjective.new(
			P2LifeLoopObjective.Stage.WATER_CROP,
			&"p2.h01.guide.water",
			"用浇水壶照料 %d 株作物" % farm_summary.needs_water_count,
		)
	var inventory := session.state.inventory
	if farm_summary.blocked_mature_count > 0:
		if _can_execute(inventory, _trade_book, SELL_OFFER_ID):
			return P2LifeLoopObjective.new(
				P2LifeLoopObjective.Stage.SELL_PRODUCE,
				&"p2.h01.guide.sell_for_space",
				"背包已满；先到北草甸物资箱出售雾叶",
			)
		return _inventory_blocked_objective()
	if _can_execute(inventory, _trade_book, SELL_OFFER_ID):
		return P2LifeLoopObjective.new(
			P2LifeLoopObjective.Stage.SELL_PRODUCE,
			&"p2.h01.guide.sell",
			"到北草甸物资箱出售雾叶",
		)
	var seed_quantity := _inventory_quantity(inventory, SEED_ITEM_ID)
	var daily_claim_pending := (
		claims.last_claimed_day(CLAIM_GROUP_ID) != session.world_day
	)
	if (
		daily_claim_pending
		and _can_claim_daily(session, claims)
	):
		return P2LifeLoopObjective.new(
			P2LifeLoopObjective.Stage.CLAIM_DAILY_RESOURCE,
			&"p2.h01.guide.claim_daily",
			"到北草甸物资箱选择今日资源",
		)
	if farm_summary.growing_count > 0:
		return P2LifeLoopObjective.new(
			P2LifeLoopObjective.Stage.REST_FOR_GROWTH,
			&"p2.h01.guide.rest_growth",
			"作物今日已照料；回家门确认休息",
		)
	if seed_quantity > 0:
		if farm_summary.empty_tilled_count > 0:
			return P2LifeLoopObjective.new(
				P2LifeLoopObjective.Stage.PLANT_SEED,
				&"p2.h01.guide.plant",
				"在已耕地上播种雾叶草",
			)
		if _inventory_quantity(inventory, HOE_ITEM_ID) == 0:
			return _required_tool_missing_objective(
				&"p2.h01.guide.missing_hoe",
				"缺少锄头；当前无法开垦新土地",
			)
		return P2LifeLoopObjective.new(
			P2LifeLoopObjective.Stage.TILL_SOIL,
			&"p2.h01.guide.till",
			"选择锄头开垦一格土地",
		)
	if _can_execute(inventory, _trade_book, BUY_OFFER_ID):
		return P2LifeLoopObjective.new(
			P2LifeLoopObjective.Stage.BUY_SEED,
			&"p2.h01.guide.buy_seed",
			"用村社券在北草甸物资箱补充种子",
		)
	if daily_claim_pending:
		return _inventory_blocked_objective()
	return P2LifeLoopObjective.new(
		P2LifeLoopObjective.Stage.REST_FOR_RESOURCES,
		&"p2.h01.guide.rest_resources",
		"今日资源已用尽；回家休息到明天",
	)


func _summarize_farm(
	session: FarmingSessionState,
	catalog: GameCatalog,
) -> FarmSummary:
	var summary := FarmSummary.new()
	var projected_inventory: InventoryState = session.state.inventory
	for tile: FarmTileState in session.state.farm.copy_tiles():
		if tile.crop == null:
			summary.empty_tilled_count += 1
			continue
		var definition := catalog.get_crop(tile.crop.crop_id)
		assert(
			definition != null,
			"validated farming sessions require known crop definitions",
		)
		if CropGrowth.is_mature(tile.crop, definition):
			var addition := projected_inventory.with_added(
				definition.harvest_item_id,
				definition.harvest_quantity,
				catalog,
			)
			if addition.status == InventoryTransactionResult.Status.ADDED:
				summary.harvestable_mature_count += 1
				projected_inventory = addition.inventory
			else:
				summary.blocked_mature_count += 1
			continue
		summary.growing_count += 1
		if (
			definition.requires_water
			and tile.watered_on_day != session.world_day
		):
			summary.needs_water_count += 1
	return summary


func _can_claim_daily(
	session: FarmingSessionState,
	claims: DailyResourceClaims,
) -> bool:
	for source_id: StringName in [SEED_SOURCE_ID, FORAGE_SOURCE_ID]:
		var result := DailyResourceGathering.attempt(
			session,
			claims,
			DailyResourceGatheringCommand.new(source_id, session.world_day),
			_source_catalog,
			_catalog,
		)
		if result.status == DailyResourceGatheringResult.Status.COLLECTED:
			return true
	return false


func _can_execute(
	inventory: InventoryState,
	trade_book: TradeBook,
	offer_id: StringName,
) -> bool:
	return trade_book.execute(
		inventory,
		TradeCommand.new(TRADE_ENDPOINT_ID, offer_id),
	).status == TradeResult.Status.COMPLETED


func _inventory_quantity(
	inventory: InventoryState,
	item_id: StringName,
) -> int:
	var total: int = 0
	for slot_index: int in inventory.capacity():
		var stack: ItemStack = inventory.stack_at(slot_index)
		if stack != null and stack.item_id == item_id:
			total += stack.quantity
	return total


func _required_tool_missing_objective(
	objective_id: StringName,
	objective_text: String,
) -> P2LifeLoopObjective:
	return P2LifeLoopObjective.new(
		P2LifeLoopObjective.Stage.REQUIRED_TOOL_MISSING,
		objective_id,
		objective_text,
	)


func _inventory_blocked_objective() -> P2LifeLoopObjective:
	return P2LifeLoopObjective.new(
		P2LifeLoopObjective.Stage.INVENTORY_BLOCKED,
		&"p2.h01.guide.inventory_blocked",
		"背包空间不足；当前领取或收获无法完成",
	)


class FarmSummary extends RefCounted:
	var harvestable_mature_count: int = 0
	var blocked_mature_count: int = 0
	var needs_water_count: int = 0
	var growing_count: int = 0
	var empty_tilled_count: int = 0

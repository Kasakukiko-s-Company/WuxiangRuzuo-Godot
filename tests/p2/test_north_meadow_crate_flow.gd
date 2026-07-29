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
	_test_normal_daily_claim()
	_test_full_inventory_can_trade_before_claim()
	_test_cost_removal_can_free_reward_slot()
	_test_day_change_and_all_disabled_actions()
	_test_recoverable_failure_keeps_menu_open()
	_finish()


func _initialize_dependencies() -> bool:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(catalog_result.is_valid(), "crate flow loads the validated game catalog")
	if not catalog_result.is_valid():
		return false
	_catalog = catalog_result.catalog
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
	var offer_result := TradeOfferCatalogFileLoader.load_catalog(_catalog)
	_check(
		_sources != null and offer_result.is_valid(),
		"crate flow dependencies satisfy the H01 content contract",
	)
	if _sources == null or not offer_result.is_valid():
		return false
	_book = TradeBook.new(offer_result.catalog, _catalog)
	return true


func _test_normal_daily_claim() -> void:
	var flow := _create_flow()
	var session := _session_with_inventory(InventoryState.create_empty())
	var claims := DailyResourceClaims.create_empty()
	var opened := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		session,
		claims,
	)
	_check(
		opened.outcome == NorthMeadowCrateResult.Outcome.OPENED
		and opened.presentation.is_open
		and opened.presentation.actions.size() == 4
		and opened.presentation.selected_index == 0
		and opened.presentation.selected_action().enabled
		and opened.presentation.actions[0].visual_role
		== NorthMeadowCrateAction.VisualRole.DAILY_SEED
		and opened.presentation.actions[1].visual_role
		== NorthMeadowCrateAction.VisualRole.DAILY_FORAGE
		and opened.presentation.actions[2].visual_role
		== NorthMeadowCrateAction.VisualRole.TRADE_SELL
		and opened.presentation.actions[3].visual_role
		== NorthMeadowCrateAction.VisualRole.TRADE_BUY,
		"an unclaimed normal inventory opens four actions on the seed choice",
	)
	var claimed := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		opened.session,
		opened.claims,
	)
	_check(
		claimed.outcome == NorthMeadowCrateResult.Outcome.CLAIMED
		and not claimed.presentation.is_open
		and _quantity(claimed.session.state.inventory, &"mistleaf_seed") == 3
		and claimed.claims.last_claimed_day(CLAIM_GROUP_ID) == 1
		and claimed.durable_reason == &"resource.claimed",
		"confirming the default action atomically claims three seeds",
	)
	var reopened := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		claimed.session,
		claimed.claims,
	)
	_check(
		reopened.presentation.actions.size() == 2
		and reopened.presentation.actions[0].kind
		== NorthMeadowCrateAction.Kind.TRADE,
		"after a daily claim the same crate exposes only its two trade actions",
	)


func _test_full_inventory_can_trade_before_claim() -> void:
	var stacks: Array[ItemStack] = [
		ItemStack.new(&"hoe_basic", 1),
		ItemStack.new(&"watering_can_basic", 1),
		ItemStack.new(&"mistleaf_seed", 99),
		ItemStack.new(&"mistleaf", 99),
		ItemStack.new(&"village_scrip", 10),
		ItemStack.new(&"hoe_basic", 1),
		ItemStack.new(&"watering_can_basic", 1),
		ItemStack.new(&"hoe_basic", 1),
	]
	var inventory := InventoryState.restore(stacks, 0, _catalog)
	_check(inventory != null, "full-inventory fixture satisfies item stack limits")
	if inventory == null:
		return
	var flow := _create_flow()
	var session := _session_with_inventory(inventory)
	var claims := DailyResourceClaims.create_empty()
	var opened := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		session,
		claims,
	)
	_check(
		opened.presentation.selected_index == 2
		and opened.presentation.selected_action().definition_id
		== &"economy.h01.sell_mistleaf"
		and not opened.presentation.actions[0].enabled
		and not opened.presentation.actions[1].enabled,
		"a full bag skips blocked daily rewards and selects the executable sale",
	)
	var traded := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		opened.session,
		opened.claims,
	)
	_check(
		traded.outcome == NorthMeadowCrateResult.Outcome.TRADED
		and _quantity(traded.session.state.inventory, &"mistleaf") == 98
		and _quantity(traded.session.state.inventory, &"village_scrip") == 40
		and traded.claims.last_claimed_day(CLAIM_GROUP_ID) == 0
		and traded.durable_reason == &"economy.traded",
		"selling from a full bag succeeds without consuming the daily claim",
	)
	var reopened := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		traded.session,
		traded.claims,
	)
	_check(
		reopened.presentation.selected_index == 1
		and reopened.presentation.selected_action().definition_id
		== FORAGE_SOURCE_ID,
		"the sale creates capacity and the next open selects the fitting forage",
	)
	var claimed := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		reopened.session,
		reopened.claims,
	)
	_check(
		claimed.outcome == NorthMeadowCrateResult.Outcome.CLAIMED
		and _quantity(claimed.session.state.inventory, &"mistleaf") == 99
		and claimed.claims.last_claimed_day(CLAIM_GROUP_ID) == 1,
		"the player can still take the daily reward after selling",
	)


func _test_cost_removal_can_free_reward_slot() -> void:
	var inventory := InventoryState.create_empty(1)
	inventory = inventory.with_added(
		&"village_scrip",
		20,
		_catalog,
	).inventory
	var flow := _create_flow()
	var session := _session_with_inventory(inventory)
	var claims := DailyResourceClaims.create_empty()
	var opened := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		session,
		claims,
	)
	_check(
		opened.presentation.selected_index == 3
		and opened.presentation.selected_action().definition_id
		== &"economy.h01.buy_mistleaf_seed",
		"dry-run recognizes that spending the only stack frees its slot",
	)
	var bought := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		opened.session,
		opened.claims,
	)
	_check(
		bought.outcome == NorthMeadowCrateResult.Outcome.TRADED
		and _quantity(bought.session.state.inventory, &"village_scrip") == 0
		and _quantity(bought.session.state.inventory, &"mistleaf_seed") == 1
		and bought.claims == claims,
		"buying atomically reuses the slot released by its exact cost",
	)
	var blocked_inventory := InventoryState.create_empty(1)
	blocked_inventory = blocked_inventory.with_added(
		&"village_scrip",
		21,
		_catalog,
	).inventory
	var blocked_flow := _create_flow()
	var blocked_session := _session_with_inventory(blocked_inventory)
	var blocked_claims := DailyResourceClaims.create_empty()
	var blocked_open := blocked_flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		blocked_session,
		blocked_claims,
	)
	var selected_buy := blocked_flow.advance(
		NorthMeadowCrateFlow.Intent.PREVIOUS,
		blocked_open.session,
		blocked_open.claims,
	)
	var rejected := blocked_flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		selected_buy.session,
		selected_buy.claims,
	)
	_check(
		rejected.outcome == NorthMeadowCrateResult.Outcome.REWARD_CAPACITY
		and rejected.session == blocked_session
		and rejected.claims == blocked_claims
		and _quantity(
			rejected.session.state.inventory,
			&"village_scrip",
		) == 21,
		"a cost that leaves one item cannot lose it when the reward has no slot",
	)


func _test_day_change_and_all_disabled_actions() -> void:
	var flow := _create_flow()
	var session := _session_with_inventory(InventoryState.create_empty())
	var claims := DailyResourceClaims.create_empty()
	var opened := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		session,
		claims,
	)
	var day_two := FarmingSessionState.new(session.state, 2)
	var stale_selection := flow.advance(
		NorthMeadowCrateFlow.Intent.NEXT,
		day_two,
		claims,
	)
	_check(
		opened.presentation.is_open
		and stale_selection.outcome == NorthMeadowCrateResult.Outcome.CLOSED
		and not stale_selection.presentation.is_open
		and stale_selection.session == day_two
		and stale_selection.claims == claims,
		"a day change closes the old cursor instead of applying stale selection",
	)
	var reopened := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		day_two,
		claims,
	)
	_check(
		reopened.outcome == NorthMeadowCrateResult.Outcome.OPENED
		and reopened.presentation.selected_index == 0,
		"an explicit interaction reopens a fresh day on its first enabled action",
	)

	var blocked_inventory := InventoryState.create_empty(1)
	blocked_inventory = blocked_inventory.with_added(
		&"hoe_basic",
		1,
		_catalog,
	).inventory
	var blocked_flow := _create_flow()
	var blocked_session := _session_with_inventory(blocked_inventory)
	var blocked_claims := DailyResourceClaims.create_empty()
	var blocked_open := blocked_flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		blocked_session,
		blocked_claims,
	)
	var blocked_confirm := blocked_flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		blocked_open.session,
		blocked_open.claims,
	)
	_check(
		blocked_open.presentation.selected_index == 0
		and not blocked_open.presentation.selected_action().enabled
		and blocked_confirm.outcome
		== NorthMeadowCrateResult.Outcome.INVENTORY_FULL
		and blocked_confirm.presentation.is_open
		and blocked_confirm.session == blocked_session
		and blocked_confirm.claims == blocked_claims,
		"an all-disabled deck remains inspectable and fails without mutation",
	)


func _test_recoverable_failure_keeps_menu_open() -> void:
	var flow := _create_flow()
	var session := _session_with_inventory(InventoryState.create_empty())
	var claims := DailyResourceClaims.create_empty()
	var result := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		session,
		claims,
	)
	for _step: int in 3:
		result = flow.advance(
			NorthMeadowCrateFlow.Intent.NEXT,
			result.session,
			result.claims,
		)
	_check(
		result.presentation.selected_action().blocked_reason
		== &"insufficient_cost"
		and result.message.contains("所需物品不足"),
		"a selected disabled action exposes its stable reason in the HUD message",
	)
	var failed := flow.advance(
		NorthMeadowCrateFlow.Intent.OPEN_OR_CONFIRM,
		result.session,
		result.claims,
	)
	_check(
		failed.outcome == NorthMeadowCrateResult.Outcome.INSUFFICIENT_COST
		and failed.presentation.is_open
		and failed.presentation.selected_action().definition_id
		== &"economy.h01.buy_mistleaf_seed"
		and failed.session == session
		and failed.claims == claims
		and failed.durable_reason.is_empty(),
		"an unavailable trade keeps the menu open without mutation or autosave",
	)


func _create_flow() -> NorthMeadowCrateFlow:
	return NorthMeadowCrateFlow.new(
		_sources,
		_book,
		_catalog,
		SEED_SOURCE_ID,
		FORAGE_SOURCE_ID,
		ENDPOINT_ID,
	)


func _session_with_inventory(inventory: InventoryState) -> FarmingSessionState:
	return FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(MAP_ID),
			inventory,
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
		print("P2_NORTH_MEADOW_CRATE_FLOW_OK")
		quit(0)
		return
	push_error("P2 north-meadow crate flow failed: %d check(s)" % _failures)
	quit(1)

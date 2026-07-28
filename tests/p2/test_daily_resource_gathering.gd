extends SceneTree

const SOURCE_ID: StringName = &"home.h01.resource.north_meadow"

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog_result := CatalogFileLoader.load_catalog()
	_check(
		catalog_result.is_valid(),
		"daily-resource test loads the validated game catalog",
	)
	if not catalog_result.is_valid():
		_finish()
		return
	var catalog: GameCatalog = catalog_result.catalog
	var source_definitions: Array[DailyResourceSourceDefinition] = [
		DailyResourceSourceDefinition.new(
			SOURCE_ID,
			&"home_h01_open_meadow",
			&"resource_spawn_zone",
			&"resource_north_meadow",
			&"mistleaf_seed",
			3,
		),
	]
	var sources := DailyResourceSourceCatalog.create(
		source_definitions,
		catalog,
	)
	_check(sources != null, "validated resource definitions build a source catalog")
	if sources == null:
		_finish()
		return
	var session := FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(&"home_h01_open_meadow"),
			InventoryState.create_empty(),
		),
		1,
	)
	var claims := DailyResourceClaims.create_empty()
	var command := DailyResourceGatheringCommand.new(
		SOURCE_ID,
		1,
	)

	var collected: DailyResourceGatheringResult = DailyResourceGathering.attempt(
		session,
		claims,
		command,
		sources,
		catalog,
	)
	_check(
		collected.status == DailyResourceGatheringResult.Status.COLLECTED,
		"an available daily source adds its configured item",
	)
	_check(
		_inventory_quantity(collected.session.state.inventory, &"mistleaf_seed") == 3,
		"resource collection adds the whole configured quantity atomically",
	)
	_check(
		collected.claims.last_claimed_day(SOURCE_ID) == 1,
		"successful collection records the source and world day",
	)

	var replayed := DailyResourceGathering.attempt(
		collected.session,
		collected.claims,
		command,
		sources,
		catalog,
	)
	_check(
		replayed.status == DailyResourceGatheringResult.Status.ALREADY_COLLECTED
		and replayed.session == collected.session
		and replayed.claims == collected.claims,
		"the same source cannot be collected twice on one day",
	)

	var next_day_session := FarmingSessionState.new(collected.session.state, 2)
	var next_day := DailyResourceGathering.attempt(
		next_day_session,
		collected.claims,
		DailyResourceGatheringCommand.new(
			SOURCE_ID,
			2,
		),
		sources,
		catalog,
	)
	_check(
		next_day.status == DailyResourceGatheringResult.Status.COLLECTED
		and _inventory_quantity(
			next_day.session.state.inventory,
			&"mistleaf_seed",
		) == 6,
		"a daily source becomes available again on a later world day",
	)

	var full_inventory := InventoryState.create_empty(1)
	full_inventory = full_inventory.with_added(&"hoe_basic", 1, catalog).inventory
	var full_session := FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(&"home_h01_open_meadow"),
			full_inventory,
		),
		1,
	)
	var rejected_full := DailyResourceGathering.attempt(
		full_session,
		DailyResourceClaims.create_empty(),
		command,
		sources,
		catalog,
	)
	_check(
		rejected_full.status == DailyResourceGatheringResult.Status.INVENTORY_FULL
		and rejected_full.session == full_session
		and rejected_full.claims.last_claimed_day(SOURCE_ID) == 0,
		"a full inventory rejects the transaction without consuming the source",
	)

	var wrong_day := DailyResourceGathering.attempt(
		session,
		claims,
		DailyResourceGatheringCommand.new(
			SOURCE_ID,
			2,
		),
		sources,
		catalog,
	)
	_check(
		wrong_day.status == DailyResourceGatheringResult.Status.INVALID_DAY
		and wrong_day.session == session
		and wrong_day.claims == claims,
		"a mismatched world day is rejected without mutation",
	)

	var spoofed_source := DailyResourceGathering.attempt(
		session,
		claims,
		DailyResourceGatheringCommand.new(&"spoofed.resource", 1),
		sources,
		catalog,
	)
	_check(
		spoofed_source.status == DailyResourceGatheringResult.Status.INVALID_SOURCE
		and spoofed_source.session == session,
		"callers cannot invent an unconfigured source or its reward",
	)

	var wrong_map_session := FarmingSessionState.new(
		FarmingTransactionState.new(
			FarmState.create_empty(&"old_mine"),
			InventoryState.create_empty(),
		),
		1,
	)
	var wrong_map := DailyResourceGathering.attempt(
		wrong_map_session,
		claims,
		command,
		sources,
		catalog,
	)
	_check(
		wrong_map.status == DailyResourceGatheringResult.Status.MAP_MISMATCH
		and wrong_map.session == wrong_map_session,
		"a configured source cannot be collected from another map",
	)

	var future_claims := claims.with_claim(SOURCE_ID, 2)
	var rolled_back := DailyResourceGathering.attempt(
		session,
		future_claims,
		command,
		sources,
		catalog,
	)
	_check(
		rolled_back.status == DailyResourceGatheringResult.Status.ALREADY_COLLECTED
		and rolled_back.claims.last_claimed_day(SOURCE_ID) == 2,
		"a later claim blocks collection after a rolled-back world day",
	)

	_finish()


func _inventory_quantity(
	inventory: InventoryState,
	item_id: StringName,
) -> int:
	var quantity: int = 0
	for slot_index: int in inventory.capacity():
		var stack: ItemStack = inventory.stack_at(slot_index)
		if stack != null and stack.item_id == item_id:
			quantity += stack.quantity
	return quantity


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_DAILY_RESOURCE_GATHERING_OK")
		quit(0)
		return
	push_error(
		"P2 daily-resource gathering test failed: %d check(s)" % _failures
	)
	quit(1)

extends SceneTree

var _failures: int = 0
var _catalog: GameCatalog
var _book: TradeBook


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_result := CatalogFileLoader.load_catalog()
	_check(
		game_result.is_valid(),
		"trade-book test loads the validated game catalog",
	)
	if not game_result.is_valid():
		_finish()
		return
	_catalog = game_result.catalog
	var offers := TradeOfferCatalog.create([
		TradeOfferDefinition.new(
			&"economy.h01.sell_mistleaf",
			&"economy.h01.north_meadow_crate",
			&"mistleaf",
			1,
			&"village_scrip",
			30,
		),
		TradeOfferDefinition.new(
			&"economy.h01.buy_mistleaf_seed",
			&"economy.h01.north_meadow_crate",
			&"village_scrip",
			20,
			&"mistleaf_seed",
			1,
		),
	], game_result.catalog)
	_book = TradeBook.new(offers, game_result.catalog)
	var inventory := InventoryState.create_empty()
	inventory = inventory.with_added(&"mistleaf", 1, _catalog).inventory
	var result := _book.execute(
		inventory,
		TradeCommand.new(
			&"economy.h01.north_meadow_crate",
			&"economy.h01.sell_mistleaf",
		),
	)
	_check(
		result.status == TradeResult.Status.COMPLETED
		and _quantity(result.inventory, &"mistleaf") == 0
		and _quantity(result.inventory, &"village_scrip") == 30
		and _quantity(inventory, &"mistleaf") == 1,
		"selling one mistleaf atomically yields thirty village scrip",
	)
	_test_buy_after_sale(result.inventory)
	_test_failures_do_not_mutate_inventory()
	_test_removed_cost_can_free_reward_slot()
	_finish()


func _test_buy_after_sale(inventory: InventoryState) -> void:
	var result := _book.execute(
		inventory,
		TradeCommand.new(
			&"economy.h01.north_meadow_crate",
			&"economy.h01.buy_mistleaf_seed",
		),
	)
	_check(
		result.status == TradeResult.Status.COMPLETED
		and _quantity(result.inventory, &"village_scrip") == 10
		and _quantity(result.inventory, &"mistleaf_seed") == 1,
		"buying one seed consumes twenty of the thirty earned scrip",
	)


func _test_failures_do_not_mutate_inventory() -> void:
	var inventory := InventoryState.create_empty(2)
	inventory = inventory.with_added(&"village_scrip", 30, _catalog).inventory
	inventory = inventory.with_added(&"hoe_basic", 1, _catalog).inventory
	var no_capacity := _book.execute(
		inventory,
		TradeCommand.new(
			&"economy.h01.north_meadow_crate",
			&"economy.h01.buy_mistleaf_seed",
		),
	)
	_check(
		no_capacity.status == TradeResult.Status.REWARD_CAPACITY
		and no_capacity.inventory == inventory
		and _quantity(inventory, &"village_scrip") == 30,
		"a full reward destination leaves the original inventory untouched",
	)
	var insufficient := _book.execute(
		InventoryState.create_empty(),
		TradeCommand.new(
			&"economy.h01.north_meadow_crate",
			&"economy.h01.sell_mistleaf",
		),
	)
	_check(
		insufficient.status == TradeResult.Status.INSUFFICIENT_COST,
		"an unavailable cost is reported without a partial exchange",
	)
	var mismatch := _book.execute(
		inventory,
		TradeCommand.new(
			&"economy.other.endpoint",
			&"economy.h01.buy_mistleaf_seed",
		),
	)
	_check(
		mismatch.status == TradeResult.Status.ENDPOINT_MISMATCH
		and mismatch.inventory == inventory,
		"offer IDs cannot be executed at a different endpoint",
	)
	var unknown := _book.execute(
		inventory,
		TradeCommand.new(
			&"economy.h01.north_meadow_crate",
			&"economy.unknown",
		),
	)
	_check(
		unknown.status == TradeResult.Status.INVALID_OFFER
		and unknown.inventory == inventory,
		"unknown offers are rejected without mutating inventory",
	)


func _test_removed_cost_can_free_reward_slot() -> void:
	var inventory := InventoryState.create_empty(1)
	inventory = inventory.with_added(&"mistleaf", 1, _catalog).inventory
	var result := _book.execute(
		inventory,
		TradeCommand.new(
			&"economy.h01.north_meadow_crate",
			&"economy.h01.sell_mistleaf",
		),
	)
	_check(
		result.status == TradeResult.Status.COMPLETED
		and _quantity(result.inventory, &"village_scrip") == 30,
		"removing the cost can free the only slot for the reward",
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
		print("P2_TRADE_BOOK_OK")
		quit(0)
		return
	push_error("P2 trade-book test failed: %d check(s)" % _failures)
	quit(1)

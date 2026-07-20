extends SceneTree

const InventoryStateScript = preload("res://scripts/domain/inventory/inventory_state.gd")

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := _item_catalog()
	var empty := InventoryStateScript.create_empty(3)
	_check(empty.capacity() == 3, "inventory exposes its fixed capacity")
	_check(empty.selected_slot_index == 0, "new inventory selects the first quickbar slot")
	_check(empty.selected_stack() == null, "new inventory selection is empty")

	var first: InventoryTransactionResult = empty.with_added(&"mistleaf_seed", 60, catalog)
	var second: InventoryTransactionResult = first.inventory.with_added(&"mistleaf_seed", 50, catalog)
	_check(first.status == InventoryTransactionResult.Status.ADDED, "first stack is added")
	_check(second.status == InventoryTransactionResult.Status.ADDED, "overflow is added atomically")
	_check(second.inventory.stack_at(0).quantity == 99, "existing stack fills first")
	_check(second.inventory.stack_at(1).quantity == 11, "overflow uses the next empty slot")

	var rejected: InventoryTransactionResult = second.inventory.with_added(&"mistleaf_seed", 200, catalog)
	_check(rejected.status == InventoryTransactionResult.Status.INVENTORY_FULL, "oversized addition is rejected")
	_check(rejected.inventory == second.inventory, "rejected addition preserves the original state")

	var removed: InventoryTransactionResult = second.inventory.with_removed(&"mistleaf_seed", 105, catalog)
	_check(removed.status == InventoryTransactionResult.Status.REMOVED, "complete quantity can be removed")
	_check(removed.inventory.stack_at(0) == null, "removal consumes lower slots first")
	_check(removed.inventory.stack_at(1).quantity == 5, "removal leaves the known remainder")

	var selected: InventoryTransactionResult = second.inventory.with_selected_slot(1)
	_check(selected.status == InventoryTransactionResult.Status.SELECTED, "valid quickbar slot is selected")
	_check(selected.inventory.selected_stack().quantity == 11, "quickbar selection reads the same inventory slot")
	var invalid_selection: InventoryTransactionResult = selected.inventory.with_selected_slot(9)
	_check(invalid_selection.status == InventoryTransactionResult.Status.INVALID_SLOT, "invalid quickbar slot is rejected")
	_check(invalid_selection.inventory == selected.inventory, "invalid selection preserves state")

	var invalid_item: InventoryTransactionResult = empty.with_added(&"missing_item", 1, catalog)
	_check(invalid_item.status == InventoryTransactionResult.Status.INVALID_ITEM, "unknown item is rejected")
	_check(invalid_item.inventory == empty, "unknown item preserves state")

	_finish()


func _item_catalog() -> GameCatalog:
	var catalog := GameCatalog.new()
	catalog.items.append(CatalogDefinitions.Item.new(
		&"mistleaf_seed",
		&"item.mistleaf_seed.name",
		CatalogDefinitions.Item.Kind.SEED,
		99,
		20,
		10,
		&"mistleaf",
	))
	catalog.rebuild_indexes()
	return catalog


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("G2_INVENTORY_OK")
		quit(0)
		return
	push_error("G2 inventory test failed: %d check(s)" % _failures)
	quit(1)

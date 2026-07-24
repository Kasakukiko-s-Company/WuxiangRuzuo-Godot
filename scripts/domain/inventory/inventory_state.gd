class_name InventoryState
extends RefCounted

const DEFAULT_CAPACITY: int = 8

var selected_slot_index: int:
	get:
		return _selected_slot_index
	set(_attempted_value):
		push_error("InventoryState.selected_slot_index is read-only")

var _selected_slot_index: int = 0
var _slots: Array[ItemStack] = []


static func create_empty(inventory_capacity: int = DEFAULT_CAPACITY) -> InventoryState:
	assert(inventory_capacity > 0, "inventory capacity must be positive")
	var inventory := InventoryState.new()
	inventory._slots.resize(inventory_capacity)
	inventory._slots.fill(null)
	return inventory


static func restore(
	stacks: Array[ItemStack],
	selected_index: int,
	catalog: GameCatalog,
) -> InventoryState:
	if stacks.is_empty() or selected_index < 0 or selected_index >= stacks.size():
		return null
	for stack: ItemStack in stacks:
		if stack == null:
			continue
		var definition: CatalogDefinitions.Item = catalog.get_item(stack.item_id)
		if definition == null or stack.quantity <= 0 or stack.quantity > definition.max_stack:
			return null
	var inventory := InventoryState.new()
	inventory._slots = _copy_stacks(stacks)
	inventory._selected_slot_index = selected_index
	return inventory


func capacity() -> int:
	return _slots.size()


func stack_at(slot_index: int) -> ItemStack:
	if slot_index < 0 or slot_index >= _slots.size():
		return null
	var stack: ItemStack = _slots[slot_index]
	return null if stack == null else stack.copy()


func selected_stack() -> ItemStack:
	return stack_at(selected_slot_index)


func copy_stacks() -> Array[ItemStack]:
	return _copy_stacks(_slots)


func with_added(
	item_id: StringName,
	quantity: int,
	catalog: GameCatalog,
) -> InventoryTransactionResult:
	if quantity <= 0:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_QUANTITY,
			self,
		)
	var definition: CatalogDefinitions.Item = catalog.get_item(item_id)
	if definition == null:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_ITEM,
			self,
		)

	var available_quantity: int = 0
	for stack: ItemStack in _slots:
		if stack == null:
			available_quantity += definition.max_stack
		elif stack.item_id == item_id:
			available_quantity += definition.max_stack - stack.quantity
	if available_quantity < quantity:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVENTORY_FULL,
			self,
		)

	var next_slots: Array[ItemStack] = _copy_stacks(_slots)
	var remaining := quantity
	for index: int in next_slots.size():
		if remaining == 0:
			break
		var stack: ItemStack = next_slots[index]
		if stack == null or stack.item_id != item_id:
			continue
		var moved: int = mini(definition.max_stack - stack.quantity, remaining)
		if moved > 0:
			next_slots[index] = ItemStack.new(item_id, stack.quantity + moved)
			remaining -= moved
	for index: int in next_slots.size():
		if remaining == 0:
			break
		if next_slots[index] != null:
			continue
		var moved: int = mini(definition.max_stack, remaining)
		next_slots[index] = ItemStack.new(item_id, moved)
		remaining -= moved

	return InventoryTransactionResult.new(
		InventoryTransactionResult.Status.ADDED,
		_with_slots(next_slots, selected_slot_index),
	)


func with_removed(
	item_id: StringName,
	quantity: int,
	catalog: GameCatalog,
) -> InventoryTransactionResult:
	if quantity <= 0:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_QUANTITY,
			self,
		)
	if catalog.get_item(item_id) == null:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_ITEM,
			self,
		)

	var available_quantity: int = 0
	for stack: ItemStack in _slots:
		if stack != null and stack.item_id == item_id:
			available_quantity += stack.quantity
	if available_quantity < quantity:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INSUFFICIENT_ITEM,
			self,
		)

	var next_slots: Array[ItemStack] = _copy_stacks(_slots)
	var remaining := quantity
	for index: int in next_slots.size():
		if remaining == 0:
			break
		var stack: ItemStack = next_slots[index]
		if stack == null or stack.item_id != item_id:
			continue
		var moved: int = mini(stack.quantity, remaining)
		var next_quantity: int = stack.quantity - moved
		next_slots[index] = null if next_quantity == 0 else ItemStack.new(item_id, next_quantity)
		remaining -= moved

	return InventoryTransactionResult.new(
		InventoryTransactionResult.Status.REMOVED,
		_with_slots(next_slots, selected_slot_index),
	)


func with_selected_slot(slot_index: int) -> InventoryTransactionResult:
	if slot_index < 0 or slot_index >= _slots.size():
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.INVALID_SLOT,
			self,
		)
	if slot_index == selected_slot_index:
		return InventoryTransactionResult.new(
			InventoryTransactionResult.Status.ALREADY_SELECTED,
			self,
		)
	return InventoryTransactionResult.new(
		InventoryTransactionResult.Status.SELECTED,
		_with_slots(_slots, slot_index),
	)


static func _copy_stacks(stacks: Array[ItemStack]) -> Array[ItemStack]:
	var copies: Array[ItemStack] = []
	copies.resize(stacks.size())
	for index: int in stacks.size():
		var stack: ItemStack = stacks[index]
		copies[index] = null if stack == null else stack.copy()
	return copies


static func _with_slots(stacks: Array[ItemStack], selected_index: int) -> InventoryState:
	var inventory := InventoryState.new()
	inventory._slots = _copy_stacks(stacks)
	inventory._selected_slot_index = selected_index
	return inventory

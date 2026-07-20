class_name ItemStack
extends RefCounted

var item_id: StringName
var quantity: int


func _init(stack_item_id: StringName, stack_quantity: int) -> void:
	item_id = stack_item_id
	quantity = stack_quantity


func copy() -> ItemStack:
	return ItemStack.new(item_id, quantity)

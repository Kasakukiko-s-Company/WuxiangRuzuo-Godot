class_name SafeAreaInsets
extends RefCounted

var top: float
var right: float
var bottom: float
var left: float


func _init(
	inset_top: float = 0.0,
	inset_right: float = 0.0,
	inset_bottom: float = 0.0,
	inset_left: float = 0.0,
) -> void:
	top = maxf(inset_top, 0.0)
	right = maxf(inset_right, 0.0)
	bottom = maxf(inset_bottom, 0.0)
	left = maxf(inset_left, 0.0)


static func zero() -> SafeAreaInsets:
	return SafeAreaInsets.new()


func is_zero() -> bool:
	return top == 0.0 and right == 0.0 and bottom == 0.0 and left == 0.0

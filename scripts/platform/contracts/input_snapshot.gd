class_name InputSnapshot
extends RefCounted

var move: Vector2
var primary_action: bool
var secondary_action: bool
var watering_action: bool
var sleep_action: bool
## Minus one means no absolute slot selection occurred this frame.
var quickbar_slot_index: int
var select_previous: bool
var select_next: bool
var pause: bool


static func neutral() -> InputSnapshot:
	var snapshot := InputSnapshot.new()
	snapshot.move = Vector2.ZERO
	snapshot.quickbar_slot_index = -1
	return snapshot

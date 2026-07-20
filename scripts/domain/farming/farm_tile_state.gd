class_name FarmTileState
extends RefCounted

var coordinate: Vector2i
## Zero means the tile has not been watered; valid world days start at one.
var watered_on_day: int
var crop: CropState


func _init(
	state_coordinate: Vector2i,
	state_watered_on_day: int = 0,
	state_crop: CropState = null,
) -> void:
	coordinate = state_coordinate
	watered_on_day = state_watered_on_day
	crop = state_crop


func copy() -> FarmTileState:
	return FarmTileState.new(
		coordinate,
		watered_on_day,
		null if crop == null else crop.copy(),
	)

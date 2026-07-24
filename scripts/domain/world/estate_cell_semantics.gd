class_name EstateCellSemantics
extends RefCounted

enum Status {
	IN_BOUNDS,
	OUT_OF_BOUNDS,
}

var status: Status
var cell: Vector2i
var colliding: bool
var farmable: bool
var water: bool
var fishable: bool
var buildable_free: bool
var buildable_reserved: bool
var no_build: bool


func _init(
	result_status: Status,
	result_cell: Vector2i,
	result_colliding: bool = false,
	result_farmable: bool = false,
	result_water: bool = false,
	result_fishable: bool = false,
	result_buildable_free: bool = false,
	result_buildable_reserved: bool = false,
	result_no_build: bool = false,
) -> void:
	status = result_status
	cell = result_cell
	colliding = result_colliding
	farmable = result_farmable
	water = result_water
	fishable = result_fishable
	buildable_free = result_buildable_free
	buildable_reserved = result_buildable_reserved
	no_build = result_no_build


static func out_of_bounds(result_cell: Vector2i) -> EstateCellSemantics:
	return EstateCellSemantics.new(Status.OUT_OF_BOUNDS, result_cell)


static func in_bounds(
	result_cell: Vector2i,
	result_colliding: bool,
	result_farmable: bool,
	result_water: bool,
	result_fishable: bool,
	result_buildable_free: bool,
	result_buildable_reserved: bool,
	result_no_build: bool,
) -> EstateCellSemantics:
	return EstateCellSemantics.new(
		Status.IN_BOUNDS,
		result_cell,
		result_colliding,
		result_farmable,
		result_water,
		result_fishable,
		result_buildable_free,
		result_buildable_reserved,
		result_no_build,
	)


func is_in_bounds() -> bool:
	return status == Status.IN_BOUNDS

class_name EstateAnchorResult
extends RefCounted

enum Status {
	FOUND,
	NOT_FOUND,
	DISABLED,
}

var status: Status
var kind: StringName
var id: StringName
var world_position: Vector2
var cell: Vector2i
var facing: StringName


func _init(
	result_status: Status,
	anchor_kind: StringName,
	anchor_id: StringName,
	anchor_world_position: Vector2 = Vector2.ZERO,
	anchor_cell: Vector2i = Vector2i.ZERO,
	anchor_facing: StringName = &"",
) -> void:
	status = result_status
	kind = anchor_kind
	id = anchor_id
	world_position = anchor_world_position
	cell = anchor_cell
	facing = anchor_facing


static func found(
	anchor_kind: StringName,
	anchor_id: StringName,
	anchor_world_position: Vector2,
	anchor_cell: Vector2i,
	anchor_facing: StringName = &"",
) -> EstateAnchorResult:
	return EstateAnchorResult.new(
		Status.FOUND,
		anchor_kind,
		anchor_id,
		anchor_world_position,
		anchor_cell,
		anchor_facing,
	)


static func not_found(
	anchor_kind: StringName,
	anchor_id: StringName,
) -> EstateAnchorResult:
	return EstateAnchorResult.new(Status.NOT_FOUND, anchor_kind, anchor_id)


static func disabled(
	anchor_kind: StringName,
	anchor_id: StringName,
	anchor_world_position: Vector2,
	anchor_cell: Vector2i,
	anchor_facing: StringName = &"",
) -> EstateAnchorResult:
	return EstateAnchorResult.new(
		Status.DISABLED,
		anchor_kind,
		anchor_id,
		anchor_world_position,
		anchor_cell,
		anchor_facing,
	)


func is_found() -> bool:
	return status == Status.FOUND


func is_not_found() -> bool:
	return status == Status.NOT_FOUND


func is_disabled() -> bool:
	return status == Status.DISABLED

class_name EstateMapRuntime
extends Node2D


func get_map_id() -> StringName:
	return &""


func get_world_bounds() -> Rect2:
	return Rect2()


func get_current_state() -> EstateMapState:
	return null


func apply_state(_state: EstateMapState) -> EstateMapApplyResult:
	return EstateMapApplyResult.runtime_error("estate runtime does not implement state application")


func query_anchor(
	kind: StringName,
	id: StringName,
) -> EstateAnchorResult:
	return EstateAnchorResult.not_found(kind, id)


func query_cell(cell: Vector2i) -> EstateCellSemantics:
	return EstateCellSemantics.out_of_bounds(cell)

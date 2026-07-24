class_name EstateMapDefinition
extends RefCounted

var estate_id: StringName
var id: StringName
var candidate_id: StringName
var size_tiles: Vector2i
var tile_size_pixels: int
var safe_spawn_id: StringName
var state_axes: Array[EstateStateAxis]
var state_combination_count: int
var runtime_scene_path: String


func _init(
	definition_estate_id: StringName,
	definition_id: StringName,
	definition_candidate_id: StringName,
	definition_size_tiles: Vector2i,
	definition_tile_size_pixels: int,
	definition_safe_spawn_id: StringName,
	definition_state_axes: Array[EstateStateAxis],
	definition_state_combination_count: int,
	definition_runtime_scene_path: String,
) -> void:
	estate_id = definition_estate_id
	id = definition_id
	candidate_id = definition_candidate_id
	size_tiles = definition_size_tiles
	tile_size_pixels = definition_tile_size_pixels
	safe_spawn_id = definition_safe_spawn_id
	state_axes = definition_state_axes.duplicate()
	state_combination_count = definition_state_combination_count
	runtime_scene_path = definition_runtime_scene_path


func values_for_axis(axis_id: StringName) -> Array[StringName]:
	for axis: EstateStateAxis in state_axes:
		if axis.id == axis_id:
			return axis.values.duplicate()
	return []

class_name H01EstateMapRuntime
extends EstateMapRuntime

signal state_applied(
	season: StringName,
	development: StringName,
	anomaly: StringName,
)

const MAP_ID: StringName = &"home_h01_open_meadow"
const MAP_SIZE_TILES: Vector2i = Vector2i(128, 96)
const TILE_SIZE: Vector2i = Vector2i(32, 32)
const SEASONS: Array[StringName] = [
	&"spring", &"summer", &"autumn", &"winter",
]
const DEVELOPMENT_STATES: Array[StringName] = [
	&"derelict", &"reclaimed", &"expanded", &"mature",
]
const ANOMALY_STATES: Array[StringName] = [
	&"normal", &"light", &"medium",
]
const VISUAL_LAYERS: Array[StringName] = [
	&"Ground",
	&"Ground_Detail",
	&"Water",
	&"Path",
	&"Development_Derelict_PathHint",
	&"Objects_Back",
	&"Development_Derelict_Back",
	&"Development_Reclaimed_Back",
	&"Development_Expanded_Back",
	&"Development_Derelict",
	&"Development_Reclaimed",
	&"Development_Expanded",
	&"Development_Mature",
	&"Characters",
	&"Development_Derelict_Front",
	&"Development_Reclaimed_Front",
	&"Development_Expanded_Front",
	&"Objects_Front",
	&"Effects",
	&"Portal_Future_Region_Locked_Visual",
	&"Anomaly_Light",
	&"Anomaly_Medium",
]
const BASE_VISIBLE_LAYERS: Array[StringName] = [
	&"Ground",
	&"Ground_Detail",
	&"Water",
	&"Path",
	&"Objects_Back",
	&"Characters",
	&"Objects_Front",
	&"Effects",
	&"Portal_Future_Region_Locked_Visual",
]
const DERELICT_LAYERS: Array[StringName] = [
	&"Development_Derelict_PathHint",
	&"Development_Derelict_Back",
	&"Development_Derelict",
	&"Development_Derelict_Front",
]
const RECLAIMED_LAYERS: Array[StringName] = [
	&"Development_Reclaimed_Back",
	&"Development_Reclaimed",
	&"Development_Reclaimed_Front",
]
const EXPANDED_LAYERS: Array[StringName] = [
	&"Development_Expanded_Back",
	&"Development_Expanded",
	&"Development_Expanded_Front",
]
const MATURE_LAYERS: Array[StringName] = [
	&"Development_Mature",
]
const DEVELOPMENT_LAYERS: Array[StringName] = [
	&"Development_Derelict_PathHint",
	&"Development_Derelict_Back",
	&"Development_Derelict",
	&"Development_Derelict_Front",
	&"Development_Reclaimed_Back",
	&"Development_Reclaimed",
	&"Development_Reclaimed_Front",
	&"Development_Expanded_Back",
	&"Development_Expanded",
	&"Development_Expanded_Front",
	&"Development_Mature",
]
const DEVELOPMENT_COLLISION_LAYERS: Array[StringName] = [
	&"Development_Derelict_Back",
	&"Development_Derelict",
	&"Development_Derelict_Front",
	&"Development_Reclaimed_Back",
	&"Development_Reclaimed",
	&"Development_Reclaimed_Front",
	&"Development_Expanded_Back",
	&"Development_Expanded",
	&"Development_Expanded_Front",
	&"Development_Mature",
]
const ANOMALY_LAYERS: Array[StringName] = [
	&"Anomaly_Light",
	&"Anomaly_Medium",
]
const CROSSING_SOURCE_LAYER: StringName = &"Mask_Crossing_Development_Reclaimed"
const CROSSING_TARGET_LAYERS: Array[StringName] = [
	&"Mask_Collision_Water",
	&"Mask_Fishing_Ecology_PondBrook",
	&"Mask_Fishing_Ecology_SouthStream",
]
const TILESET_PATHS: Dictionary[StringName, String] = {
	&"spring": "res://maps/runtime/estate/h01/h01_visual_spring.tres",
	&"summer": "res://maps/runtime/estate/h01/h01_visual_summer.tres",
	&"autumn": "res://maps/runtime/estate/h01/h01_visual_autumn.tres",
	&"winter": "res://maps/runtime/estate/h01/h01_visual_winter.tres",
}
const ANCHOR_LAYER_NAMES: Dictionary[StringName, StringName] = {
	&"spawn": &"Spawn",
	&"portal": &"Portal",
	&"npc_anchor": &"NpcAnchor",
	&"interaction": &"Interaction",
	&"story_trigger": &"StoryTrigger",
	&"occlusion": &"Occlusion",
	&"anomaly_anchor": &"AnomalyStateAnchor",
}

var current_season: StringName = &"spring"
var current_development: StringName = &"derelict"
var current_anomaly: StringName = &"normal"
var _crossing_restore: Dictionary[StringName, Array] = {}
var _crossing_cached: bool = false
var _coordinate_mapper := TileCoordinateMapper.new(TILE_SIZE)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _cache_crossing_cells():
		push_error("H01 crossing cells could not be cached")
		return
	if not _apply_state_values(
		current_season,
		current_development,
		current_anomaly,
	):
		push_error("H01 default state could not be applied")


func get_map_id() -> StringName:
	return MAP_ID


func get_world_bounds() -> Rect2:
	return Rect2(
		Vector2.ZERO,
		Vector2(MAP_SIZE_TILES * TILE_SIZE),
	)


func get_current_state() -> EstateMapState:
	return EstateMapState.new(
		current_season,
		current_development,
		current_anomaly,
	)


func apply_state(state: EstateMapState) -> EstateMapApplyResult:
	if state == null:
		return EstateMapApplyResult.invalid("estate state must be present")
	if not SEASONS.has(state.season):
		return EstateMapApplyResult.invalid("unsupported season: %s" % state.season)
	if not DEVELOPMENT_STATES.has(state.development):
		return EstateMapApplyResult.invalid(
			"unsupported development: %s" % state.development
		)
	if not ANOMALY_STATES.has(state.anomaly):
		return EstateMapApplyResult.invalid("unsupported anomaly: %s" % state.anomaly)
	if not state.extra_axis_values().is_empty():
		return EstateMapApplyResult.invalid(
			"H01 does not support map-specific state axes"
		)
	if not _apply_state_values(state.season, state.development, state.anomaly):
		return EstateMapApplyResult.runtime_error(
			String(get_meta("last_state_error", "H01 state application failed"))
		)
	return EstateMapApplyResult.applied()


func query_anchor(
	kind: StringName,
	id: StringName,
) -> EstateAnchorResult:
	var layer_name: StringName = ANCHOR_LAYER_NAMES.get(kind, &"")
	if layer_name.is_empty():
		return EstateAnchorResult.not_found(kind, id)
	var container := get_node_or_null(
		NodePath("SemanticObjects/" + String(layer_name))
	)
	if container == null:
		return EstateAnchorResult.not_found(kind, id)
	for child: Node in container.get_children():
		if StringName(String(child.get_meta("stable_id", ""))) != id:
			continue
		var world_position := (child as Node2D).global_position
		var properties_value: Variant = child.get_meta("properties", {})
		var facing: StringName = &""
		if properties_value is Dictionary:
			facing = _normalize_facing(StringName(String(
				(properties_value as Dictionary).get("facing", "")
			)))
		var result := EstateAnchorResult.found(
			kind,
			id,
			world_position,
			_coordinate_mapper.world_to_cell(world_position),
			facing,
		)
		if not _semantic_node_enabled(child):
			return EstateAnchorResult.disabled(
				result.kind,
				result.id,
				result.world_position,
				result.cell,
				result.facing,
			)
		return result
	return EstateAnchorResult.not_found(kind, id)


func query_cell(cell: Vector2i) -> EstateCellSemantics:
	if (
		cell.x < 0
		or cell.y < 0
		or cell.x >= MAP_SIZE_TILES.x
		or cell.y >= MAP_SIZE_TILES.y
	):
		return EstateCellSemantics.out_of_bounds(cell)
	var colliding := (
		_layer_has_cell(&"Mask_Collision_Water", cell)
		or _tile_collision_at(cell)
		or _semantic_collision_at(cell)
	)
	return EstateCellSemantics.in_bounds(
		cell,
		colliding,
		_layer_has_cell(&"Mask_Farmable", cell),
		_layer_has_cell(&"Water", cell),
		(
			_layer_has_cell(&"Mask_Fishing_Ecology_PondBrook", cell)
			or _layer_has_cell(&"Mask_Fishing_Ecology_SouthStream", cell)
		),
		_layer_has_cell(&"Mask_Buildable_Free", cell),
		_layer_has_cell(&"Mask_Buildable_Reserved", cell),
		_layer_has_cell(&"Mask_NoBuild", cell),
	)


func _cache_crossing_cells() -> bool:
	if _crossing_cached:
		return true
	var crossing := get_node_or_null(
		NodePath(String(CROSSING_SOURCE_LAYER))
	) as TileMapLayer
	if crossing == null or crossing.get_used_cells().size() != 4:
		return false
	for layer_name: StringName in CROSSING_TARGET_LAYERS:
		var target := get_node_or_null(
			NodePath(String(layer_name))
		) as TileMapLayer
		if target == null:
			return false
		var records: Array[Dictionary] = []
		for coords: Vector2i in crossing.get_used_cells():
			var source_id := target.get_cell_source_id(coords)
			if source_id < 0:
				continue
			records.append({
				"coords": coords,
				"source_id": source_id,
				"atlas": target.get_cell_atlas_coords(coords),
				"alternative": target.get_cell_alternative_tile(coords),
			})
		_crossing_restore[layer_name] = records
	_crossing_cached = true
	return true


func _restore_crossing_base() -> void:
	for layer_name: StringName in CROSSING_TARGET_LAYERS:
		var target := get_node(NodePath(String(layer_name))) as TileMapLayer
		for record_value: Variant in _crossing_restore.get(layer_name, []):
			var record := record_value as Dictionary
			target.set_cell(
				record["coords"],
				int(record["source_id"]),
				record["atlas"],
				int(record["alternative"]),
			)


func _set_crossing_active(active: bool) -> void:
	_restore_crossing_base()
	if not active:
		return
	var crossing := get_node(
		NodePath(String(CROSSING_SOURCE_LAYER))
	) as TileMapLayer
	for layer_name: StringName in CROSSING_TARGET_LAYERS:
		var target := get_node(NodePath(String(layer_name))) as TileMapLayer
		for coords: Vector2i in crossing.get_used_cells():
			target.erase_cell(coords)


func _set_layers_active(
	layer_names: Array[StringName],
	active: bool,
) -> void:
	for layer_name: StringName in layer_names:
		var layer := get_node(NodePath(String(layer_name))) as TileMapLayer
		layer.visible = active
		layer.collision_enabled = (
			active
			and DEVELOPMENT_COLLISION_LAYERS.has(layer_name)
			and not layer.get_used_cells().is_empty()
		)


func _apply_state_values(
	season: StringName,
	development: StringName,
	anomaly: StringName,
) -> bool:
	if not _crossing_cached and not _cache_crossing_cells():
		set_meta("last_state_error", "crossing cache unavailable")
		return false
	var selected_tile_set := load(TILESET_PATHS[season]) as TileSet
	if selected_tile_set == null:
		set_meta("last_state_error", "unable to load H01 visual TileSet: %s" % season)
		return false

	var previous_visibility := visible
	visible = false
	for layer_name: StringName in VISUAL_LAYERS:
		var layer := get_node_or_null(
			NodePath(String(layer_name))
		) as TileMapLayer
		if layer == null:
			set_meta("last_state_error", "missing H01 visual layer: %s" % layer_name)
			visible = previous_visibility
			return false
		layer.tile_set = selected_tile_set
		layer.visible = BASE_VISIBLE_LAYERS.has(layer_name)

	for layer_name: StringName in DEVELOPMENT_LAYERS:
		var layer := get_node(NodePath(String(layer_name))) as TileMapLayer
		layer.visible = false
		layer.collision_enabled = false

	var development_index := DEVELOPMENT_STATES.find(development)
	if development == &"derelict":
		_set_layers_active(DERELICT_LAYERS, true)
	else:
		_set_layers_active(RECLAIMED_LAYERS, development_index >= 1)
		_set_layers_active(EXPANDED_LAYERS, development_index >= 2)
		_set_layers_active(MATURE_LAYERS, development_index >= 3)

	for layer_name: StringName in ANOMALY_LAYERS:
		var anomaly_layer := get_node(
			NodePath(String(layer_name))
		) as TileMapLayer
		anomaly_layer.visible = (
			(anomaly == &"light" and layer_name == &"Anomaly_Light")
			or anomaly == &"medium"
		)
		anomaly_layer.collision_enabled = false

	_set_crossing_active(development_index >= 1)
	current_season = season
	current_development = development
	current_anomaly = anomaly
	remove_meta("last_state_error")
	set_meta("state", {
		"season": String(season),
		"development": String(development),
		"anomaly": String(anomaly),
	})
	set_meta("development_composition", "cumulative_after_derelict")
	set_meta("crossing_active", development_index >= 1)
	set_meta("winter_water_resolution", "open_not_fully_frozen")
	set_meta("mask_state", "stateful_crossing_only")
	visible = previous_visibility
	state_applied.emit(season, development, anomaly)
	return true


func _layer_has_cell(layer_name: StringName, cell: Vector2i) -> bool:
	var layer := get_node_or_null(NodePath(String(layer_name))) as TileMapLayer
	return layer != null and layer.get_cell_source_id(cell) >= 0


func _tile_collision_at(cell: Vector2i) -> bool:
	for layer_name: StringName in VISUAL_LAYERS:
		var layer := get_node_or_null(
			NodePath(String(layer_name))
		) as TileMapLayer
		if layer == null or not layer.collision_enabled:
			continue
		var tile_data := layer.get_cell_tile_data(cell)
		if tile_data == null or layer.tile_set == null:
			continue
		for physics_layer: int in layer.tile_set.get_physics_layers_count():
			if tile_data.get_collision_polygons_count(physics_layer) > 0:
				return true
	return false


func _semantic_collision_at(cell: Vector2i) -> bool:
	var container := get_node_or_null("SemanticObjects/Collision")
	if container == null:
		return false
	var cell_center := _coordinate_mapper.cell_center(cell)
	for body_node: Node in container.get_children():
		var body := body_node as StaticBody2D
		if body == null:
			continue
		for shape_node: Node in body.get_children():
			var shape := shape_node as CollisionShape2D
			if shape == null or shape.disabled:
				continue
			var rectangle := shape.shape as RectangleShape2D
			if rectangle == null:
				continue
			var local_point := shape.to_local(cell_center)
			if (
				absf(local_point.x) <= rectangle.size.x * 0.5
				and absf(local_point.y) <= rectangle.size.y * 0.5
			):
				return true
	return false


func _semantic_node_enabled(node: Node) -> bool:
	var properties_value: Variant = node.get_meta("properties", {})
	if properties_value is Dictionary:
		var properties := properties_value as Dictionary
		if properties.has("availableAtStart"):
			return bool(properties["availableAtStart"])
	var disposition := StringName(String(
		node.get_meta("runtime_disposition", "")
	))
	if disposition == &"runtime_disabled_semantic_area":
		return false
	if node is CanvasItem and not (node as CanvasItem).visible:
		return false
	for child: Node in node.get_children():
		var shape := child as CollisionShape2D
		if shape != null and not shape.disabled:
			return true
	return node.get_child_count() == 0


func _normalize_facing(value: StringName) -> StringName:
	match value:
		&"north":
			return &"up"
		&"east":
			return &"right"
		&"south":
			return &"down"
		&"west":
			return &"left"
		_:
			return value

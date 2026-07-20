class_name CatalogDefinitions
extends RefCounted


class Item extends RefCounted:
	enum Kind {
		TOOL,
		SEED,
		CROP,
		MATERIAL,
	}

	var id: StringName
	var display_name_key: StringName
	var kind: Kind
	var max_stack: int
	var buy_price: int
	var sell_price: int
	var crop_id: StringName
	var tool_id: StringName


	func _init(
		definition_id: StringName,
		definition_display_name_key: StringName,
		definition_kind: Kind,
		definition_max_stack: int,
		definition_buy_price: int,
		definition_sell_price: int,
		definition_crop_id: StringName = &"",
		definition_tool_id: StringName = &"",
	) -> void:
		id = definition_id
		display_name_key = definition_display_name_key
		kind = definition_kind
		max_stack = definition_max_stack
		buy_price = definition_buy_price
		sell_price = definition_sell_price
		crop_id = definition_crop_id
		tool_id = definition_tool_id


class Crop extends RefCounted:
	var id: StringName
	var seed_item_id: StringName
	var harvest_item_id: StringName
	var growth_stages: Array[int]
	var harvest_quantity: int
	var requires_water: bool
	var allowed_seasons: Array[StringName]


	func _init(
		definition_id: StringName,
		definition_seed_item_id: StringName,
		definition_harvest_item_id: StringName,
		definition_growth_stages: Array[int],
		definition_harvest_quantity: int,
		definition_requires_water: bool,
		definition_allowed_seasons: Array[StringName],
	) -> void:
		id = definition_id
		seed_item_id = definition_seed_item_id
		harvest_item_id = definition_harvest_item_id
		growth_stages = definition_growth_stages
		harvest_quantity = definition_harvest_quantity
		requires_water = definition_requires_water
		allowed_seasons = definition_allowed_seasons


class Tool extends RefCounted:
	enum Action {
		TILL,
		WATER,
	}

	var id: StringName
	var display_name_key: StringName
	var action: Action
	var range_tiles: int


	func _init(
		definition_id: StringName,
		definition_display_name_key: StringName,
		definition_action: Action,
		definition_range_tiles: int,
	) -> void:
		id = definition_id
		display_name_key = definition_display_name_key
		action = definition_action
		range_tiles = definition_range_tiles


class Npc extends RefCounted:
	var id: StringName
	var display_name_key: StringName
	var age_at_world_day_one: int
	var content_tier: StringName
	var relationship_boundary: StringName
	var default_anchor_id: StringName


	func _init(
		definition_id: StringName,
		definition_display_name_key: StringName,
		definition_age_at_world_day_one: int,
		definition_content_tier: StringName,
		definition_relationship_boundary: StringName,
		definition_default_anchor_id: StringName,
	) -> void:
		id = definition_id
		display_name_key = definition_display_name_key
		age_at_world_day_one = definition_age_at_world_day_one
		content_tier = definition_content_tier
		relationship_boundary = definition_relationship_boundary
		default_anchor_id = definition_default_anchor_id


class DemoMap extends RefCounted:
	var id: StringName
	var scene_path: String
	var implementation_status: StringName
	var display_name_key: StringName
	var size_tiles: Vector2i
	var tile_size_pixels: int
	var safe_anchor_id: StringName
	var required_anchor_ids: Array[StringName]


	func _init(
		definition_id: StringName,
		definition_scene_path: String,
		definition_implementation_status: StringName,
		definition_display_name_key: StringName,
		definition_size_tiles: Vector2i,
		definition_tile_size_pixels: int,
		definition_safe_anchor_id: StringName,
		definition_required_anchor_ids: Array[StringName],
	) -> void:
		id = definition_id
		scene_path = definition_scene_path
		implementation_status = definition_implementation_status
		display_name_key = definition_display_name_key
		size_tiles = definition_size_tiles
		tile_size_pixels = definition_tile_size_pixels
		safe_anchor_id = definition_safe_anchor_id
		required_anchor_ids = definition_required_anchor_ids


	func has_anchor(anchor_id: StringName) -> bool:
		return required_anchor_ids.has(anchor_id)


class Portal extends RefCounted:
	var id: StringName
	var source_map_id: StringName
	var source_anchor_id: StringName
	var target_map_id: StringName
	var target_anchor_id: StringName
	var condition_id: StringName
	var reciprocal_portal_id: StringName


	func _init(
		definition_id: StringName,
		definition_source_map_id: StringName,
		definition_source_anchor_id: StringName,
		definition_target_map_id: StringName,
		definition_target_anchor_id: StringName,
		definition_condition_id: StringName,
		definition_reciprocal_portal_id: StringName,
	) -> void:
		id = definition_id
		source_map_id = definition_source_map_id
		source_anchor_id = definition_source_anchor_id
		target_map_id = definition_target_map_id
		target_anchor_id = definition_target_anchor_id
		condition_id = definition_condition_id
		reciprocal_portal_id = definition_reciprocal_portal_id


class RuntimeResource extends RefCounted:
	var id: StringName
	var kind: StringName
	var godot_path: String
	var source_status: StringName
	var fallback_id: StringName


	func _init(
		definition_id: StringName,
		definition_kind: StringName,
		definition_godot_path: String,
		definition_source_status: StringName,
		definition_fallback_id: StringName,
	) -> void:
		id = definition_id
		kind = definition_kind
		godot_path = definition_godot_path
		source_status = definition_source_status
		fallback_id = definition_fallback_id


	func has_godot_path() -> bool:
		return not godot_path.is_empty()

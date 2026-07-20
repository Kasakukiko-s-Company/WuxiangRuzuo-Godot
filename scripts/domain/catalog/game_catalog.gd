class_name GameCatalog
extends RefCounted

const SCHEMA_VERSION: int = 1

var items: Array[CatalogDefinitions.Item] = []
var crops: Array[CatalogDefinitions.Crop] = []
var tools: Array[CatalogDefinitions.Tool] = []
var npcs: Array[CatalogDefinitions.Npc] = []
var maps: Array[CatalogDefinitions.DemoMap] = []
var portals: Array[CatalogDefinitions.Portal] = []
var resources: Array[CatalogDefinitions.RuntimeResource] = []
var fallback_map_id: StringName
var default_locale: StringName
var localized_text: Dictionary = {}

var _items_by_id: Dictionary = {}
var _crops_by_id: Dictionary = {}
var _tools_by_id: Dictionary = {}
var _npcs_by_id: Dictionary = {}
var _maps_by_id: Dictionary = {}
var _portals_by_id: Dictionary = {}
var _resources_by_id: Dictionary = {}


func rebuild_indexes() -> void:
	_items_by_id = _index_by_id(items)
	_crops_by_id = _index_by_id(crops)
	_tools_by_id = _index_by_id(tools)
	_npcs_by_id = _index_by_id(npcs)
	_maps_by_id = _index_by_id(maps)
	_portals_by_id = _index_by_id(portals)
	_resources_by_id = _index_by_id(resources)


func get_item(id: StringName) -> CatalogDefinitions.Item:
	return _items_by_id.get(id) as CatalogDefinitions.Item


func get_crop(id: StringName) -> CatalogDefinitions.Crop:
	return _crops_by_id.get(id) as CatalogDefinitions.Crop


func get_tool(id: StringName) -> CatalogDefinitions.Tool:
	return _tools_by_id.get(id) as CatalogDefinitions.Tool


func get_npc(id: StringName) -> CatalogDefinitions.Npc:
	return _npcs_by_id.get(id) as CatalogDefinitions.Npc


func get_map(id: StringName) -> CatalogDefinitions.DemoMap:
	return _maps_by_id.get(id) as CatalogDefinitions.DemoMap


func get_portal(id: StringName) -> CatalogDefinitions.Portal:
	return _portals_by_id.get(id) as CatalogDefinitions.Portal


func get_resource(id: StringName) -> CatalogDefinitions.RuntimeResource:
	return _resources_by_id.get(id) as CatalogDefinitions.RuntimeResource


func has_localized_text(key: StringName) -> bool:
	var locale_value: Variant = localized_text.get(default_locale)
	return locale_value is Dictionary and (locale_value as Dictionary).has(String(key))


func _index_by_id(definitions: Array) -> Dictionary:
	var result: Dictionary = {}
	for definition: Variant in definitions:
		result[definition.id] = definition
	return result

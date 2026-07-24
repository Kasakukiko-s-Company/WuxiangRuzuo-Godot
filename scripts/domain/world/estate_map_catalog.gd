class_name EstateMapCatalog
extends RefCounted

const SCHEMA_VERSION: int = 1

var pack_id: StringName
var maps: Array[EstateMapDefinition]
var _maps_by_id: Dictionary = {}


func _init(catalog_pack_id: StringName, catalog_maps: Array[EstateMapDefinition]) -> void:
	pack_id = catalog_pack_id
	maps = catalog_maps.duplicate()
	for definition: EstateMapDefinition in maps:
		_maps_by_id[definition.id] = definition


func get_map(map_id: StringName) -> EstateMapDefinition:
	return _maps_by_id.get(map_id) as EstateMapDefinition

class_name DailyResourceSourceCatalog
extends RefCounted

var _sources_by_id: Dictionary[StringName, DailyResourceSourceDefinition] = {}


static func create(
	definitions: Array[DailyResourceSourceDefinition],
	game_catalog: GameCatalog,
) -> DailyResourceSourceCatalog:
	var sources: Dictionary[StringName, DailyResourceSourceDefinition] = {}
	for definition: DailyResourceSourceDefinition in definitions:
		if (
			definition == null
			or definition.id.is_empty()
			or definition.map_id.is_empty()
			or definition.anchor_kind.is_empty()
			or definition.anchor_id.is_empty()
			or definition.item_id.is_empty()
			or definition.quantity <= 0
			or game_catalog.get_item(definition.item_id) == null
			or sources.has(definition.id)
		):
			return null
		sources[definition.id] = definition
	return DailyResourceSourceCatalog.new(sources)


func _init(
	sources: Dictionary[StringName, DailyResourceSourceDefinition],
) -> void:
	_sources_by_id = sources.duplicate()


func get_source(source_id: StringName) -> DailyResourceSourceDefinition:
	return _sources_by_id.get(source_id) as DailyResourceSourceDefinition

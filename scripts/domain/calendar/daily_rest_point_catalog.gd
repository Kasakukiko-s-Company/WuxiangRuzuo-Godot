class_name DailyRestPointCatalog
extends RefCounted

var _points_by_id: Dictionary[StringName, DailyRestPointDefinition] = {}


static func create(
	definitions: Array[DailyRestPointDefinition],
) -> DailyRestPointCatalog:
	var points: Dictionary[StringName, DailyRestPointDefinition] = {}
	for definition: DailyRestPointDefinition in definitions:
		if (
			definition == null
			or definition.id.is_empty()
			or definition.map_id.is_empty()
			or definition.anchor_kind.is_empty()
			or definition.anchor_id.is_empty()
			or points.has(definition.id)
		):
			return null
		points[definition.id] = definition
	return DailyRestPointCatalog.new(points)


func _init(
	points: Dictionary[StringName, DailyRestPointDefinition],
) -> void:
	_points_by_id = points.duplicate()


func get_point(rest_point_id: StringName) -> DailyRestPointDefinition:
	return _points_by_id.get(rest_point_id) as DailyRestPointDefinition

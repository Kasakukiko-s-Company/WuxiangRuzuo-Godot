class_name EstateMapState
extends RefCounted

var season: StringName
var development: StringName
var anomaly: StringName
var axis_values: Dictionary[StringName, StringName]


func _init(
	state_season: StringName,
	state_development: StringName,
	state_anomaly: StringName,
	state_axis_values: Dictionary[StringName, StringName] = {},
) -> void:
	season = state_season
	development = state_development
	anomaly = state_anomaly
	axis_values = state_axis_values.duplicate()
	axis_values[&"season"] = season
	axis_values[&"development"] = development
	axis_values[&"anomaly"] = anomaly


func copy() -> EstateMapState:
	return EstateMapState.new(season, development, anomaly, axis_values)


func value_for_axis(axis_id: StringName) -> StringName:
	return axis_values.get(axis_id, &"")


func extra_axis_values() -> Dictionary[StringName, StringName]:
	var result := axis_values.duplicate()
	result.erase(&"season")
	result.erase(&"development")
	result.erase(&"anomaly")
	return result


func equals(other: EstateMapState) -> bool:
	return (
		other != null
		and season == other.season
		and development == other.development
		and anomaly == other.anomaly
		and axis_values == other.axis_values
	)

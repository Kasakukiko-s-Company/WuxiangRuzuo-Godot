class_name P2LifeLoopObjective
extends RefCounted

enum Stage {
	CLAIM_DAILY_RESOURCE,
	TILL_SOIL,
	PLANT_SEED,
	WATER_CROP,
	REST_FOR_GROWTH,
	HARVEST_CROP,
	SELL_PRODUCE,
	BUY_SEED,
	REQUIRED_TOOL_MISSING,
	INVENTORY_BLOCKED,
	REST_FOR_RESOURCES,
}

var stage: Stage:
	get:
		return _stage
	set(_attempted_value):
		push_error("P2LifeLoopObjective.stage is read-only")
var stable_id: StringName:
	get:
		return _stable_id
	set(_attempted_value):
		push_error("P2LifeLoopObjective.stable_id is read-only")
var text: String:
	get:
		return _text
	set(_attempted_value):
		push_error("P2LifeLoopObjective.text is read-only")

var _stage: Stage
var _stable_id: StringName
var _text: String


func _init(
	objective_stage: Stage,
	objective_id: StringName,
	objective_text: String,
) -> void:
	assert(not objective_id.is_empty(), "life-loop objective requires a stable ID")
	assert(
		not objective_text.strip_edges().is_empty(),
		"life-loop objective requires visible guidance",
	)
	_stage = objective_stage
	_stable_id = objective_id
	_text = objective_text.strip_edges()

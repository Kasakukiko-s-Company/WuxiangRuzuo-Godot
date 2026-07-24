class_name CropState
extends RefCounted

var crop_id: StringName
var planted_on_day: int
var growth_progress: int
var stage_index: int
## Historical field name: this is the latest day evaluated, even when dry soil
## prevented growth. Recording every evaluation prevents late watering backfill.
var last_growth_day: int


func _init(
	state_crop_id: StringName,
	state_planted_on_day: int,
	state_growth_progress: int = 0,
	state_stage_index: int = 0,
	state_last_growth_day: int = 0,
) -> void:
	crop_id = state_crop_id
	planted_on_day = state_planted_on_day
	growth_progress = state_growth_progress
	stage_index = state_stage_index
	last_growth_day = state_last_growth_day


func copy() -> CropState:
	return CropState.new(
		crop_id,
		planted_on_day,
		growth_progress,
		stage_index,
		last_growth_day,
	)

class_name P2PacingEvidenceSample
extends RefCounted

var map_id: StringName:
	get:
		return _map_id
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.map_id is read-only")
var world_day: int:
	get:
		return _world_day
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.world_day is read-only")
var objective_id: StringName:
	get:
		return _objective_id
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.objective_id is read-only")
var farm_tile_count: int:
	get:
		return _farm_tile_count
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.farm_tile_count is read-only")
var crop_count: int:
	get:
		return _crop_count
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.crop_count is read-only")
var seed_count: int:
	get:
		return _seed_count
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.seed_count is read-only")
var forage_count: int:
	get:
		return _forage_count
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.forage_count is read-only")
var scrip_count: int:
	get:
		return _scrip_count
	set(_attempted_value):
		push_error("P2PacingEvidenceSample.scrip_count is read-only")

var _map_id: StringName
var _world_day: int
var _objective_id: StringName
var _farm_tile_count: int
var _crop_count: int
var _seed_count: int
var _forage_count: int
var _scrip_count: int


func _init(
	sample_map_id: StringName,
	sample_world_day: int,
	sample_objective_id: StringName,
	sample_farm_tile_count: int,
	sample_crop_count: int,
	sample_seed_count: int,
	sample_forage_count: int,
	sample_scrip_count: int,
) -> void:
	assert(not sample_map_id.is_empty(), "pacing evidence requires a map ID")
	assert(sample_world_day > 0, "pacing evidence requires a positive world day")
	assert(
		not sample_objective_id.is_empty(),
		"pacing evidence requires a stable objective ID",
	)
	for count: int in [
		sample_farm_tile_count,
		sample_crop_count,
		sample_seed_count,
		sample_forage_count,
		sample_scrip_count,
	]:
		assert(count >= 0, "pacing evidence counts cannot be negative")
	_map_id = sample_map_id
	_world_day = sample_world_day
	_objective_id = sample_objective_id
	_farm_tile_count = sample_farm_tile_count
	_crop_count = sample_crop_count
	_seed_count = sample_seed_count
	_forage_count = sample_forage_count
	_scrip_count = sample_scrip_count

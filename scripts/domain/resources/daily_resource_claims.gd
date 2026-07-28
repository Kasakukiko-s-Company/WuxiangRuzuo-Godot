class_name DailyResourceClaims
extends RefCounted

var _last_claimed_days: Dictionary[StringName, int] = {}


static func create_empty() -> DailyResourceClaims:
	var empty: Dictionary[StringName, int] = {}
	return DailyResourceClaims.new(empty)


func _init(
	last_claimed_days: Dictionary[StringName, int],
) -> void:
	_last_claimed_days = last_claimed_days.duplicate()


func last_claimed_day(source_id: StringName) -> int:
	return int(_last_claimed_days.get(source_id, 0))


func with_claim(source_id: StringName, world_day: int) -> DailyResourceClaims:
	assert(not source_id.is_empty(), "daily resource claim requires a source ID")
	assert(world_day >= 1, "daily resource claims start on world day one")
	var next_claims: Dictionary[StringName, int] = _last_claimed_days.duplicate()
	next_claims[source_id] = world_day
	return DailyResourceClaims.new(next_claims)


func snapshot() -> DailyResourceClaims:
	return DailyResourceClaims.new(_last_claimed_days)

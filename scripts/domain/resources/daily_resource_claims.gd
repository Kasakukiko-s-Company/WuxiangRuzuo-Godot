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


func last_claimed_day(resource_claim_key: StringName) -> int:
	return int(_last_claimed_days.get(resource_claim_key, 0))


func with_claim(resource_claim_key: StringName, world_day: int) -> DailyResourceClaims:
	assert(
		not resource_claim_key.is_empty(),
		"daily resource claim requires a claim key",
	)
	assert(world_day >= 1, "daily resource claims start on world day one")
	var next_claims: Dictionary[StringName, int] = _last_claimed_days.duplicate()
	next_claims[resource_claim_key] = world_day
	return DailyResourceClaims.new(next_claims)


func snapshot() -> DailyResourceClaims:
	return DailyResourceClaims.new(_last_claimed_days)

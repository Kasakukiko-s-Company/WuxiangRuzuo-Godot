class_name MovementIntent
extends RefCounted

var direction: Vector2
var facing: Vector2i
var input_locked: bool


static func resolve(raw_direction: Vector2, previous_facing: Vector2i, locked: bool) -> MovementIntent:
	var intent := MovementIntent.new()
	intent.direction = Vector2.ZERO if locked else raw_direction.limit_length(1.0)
	intent.facing = previous_facing
	if not locked and not raw_direction.is_zero_approx():
		if absf(raw_direction.x) > absf(raw_direction.y):
			intent.facing = Vector2i.RIGHT if raw_direction.x > 0.0 else Vector2i.LEFT
		else:
			intent.facing = Vector2i.DOWN if raw_direction.y > 0.0 else Vector2i.UP
	intent.input_locked = locked
	return intent

extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var intent := MovementIntent.resolve(Vector2(1.0, 1.0), Vector2i.DOWN, false)
	_check(intent.direction.is_equal_approx(Vector2(0.707107, 0.707107)), "diagonal movement is normalized")

	var locked_intent := MovementIntent.resolve(Vector2.LEFT, Vector2i.DOWN, true)
	_check(locked_intent.direction == Vector2.ZERO, "locked input cannot leak movement")

	var facing_intent := MovementIntent.resolve(Vector2(-0.8, 0.2), Vector2i.DOWN, false)
	_check(facing_intent.facing == Vector2i.LEFT, "dominant movement axis updates four-direction facing")
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P1_MOVEMENT_INTENT_OK")
		quit(0)
		return
	push_error("P1 movement intent failed: %d check(s)" % _failures)
	quit(1)

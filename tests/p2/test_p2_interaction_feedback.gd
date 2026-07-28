extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var feedback := P2InteractionFeedback.new()
	root.add_child(feedback)
	feedback.play(&"sfx.farm.water", Vector2(64.0, 64.0), true)
	_check(
		feedback.is_feedback_visible(),
		"reduce-motion feedback is a visible static cue rather than no cue",
	)
	await create_timer(0.05).timeout
	_check(
		feedback.is_feedback_visible(),
		"reduce-motion static cue remains visible long enough to render",
	)
	await create_timer(0.1).timeout
	_check(
		not feedback.is_feedback_visible(),
		"reduce-motion static cue clears without a motion tween",
	)
	feedback.play(&"sfx.farm.harvest", Vector2(96.0, 64.0), false)
	_check(
		feedback.is_feedback_visible(),
		"standard feedback starts its short animation",
	)
	_check(
		feedback.get_last_action_id() == &"sfx.farm.harvest"
		and feedback.get_play_count() == 2,
		"feedback keeps typed action identity and deterministic play count",
	)
	feedback.play(&"sfx.unknown", Vector2.ZERO, false)
	_check(
		feedback.get_last_action_id() == &"sfx.farm.harvest"
		and feedback.get_play_count() == 2,
		"unknown feedback IDs are rejected instead of drawing a rest cue",
	)

	feedback.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_INTERACTION_FEEDBACK_OK")
		quit(0)
		return
	push_error("P2 interaction feedback test failed: %d check(s)" % _failures)
	quit(1)

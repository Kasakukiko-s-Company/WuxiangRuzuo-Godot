extends SceneTree

class ScriptedInputService extends InputService:
	var current_snapshot: InputSnapshot = InputSnapshot.neutral()

	func snapshot() -> InputSnapshot:
		return current_snapshot


var _failures: int = 0
var _interaction_requests: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var input_service := ScriptedInputService.new()
	var controller := P1PlayerController.new()
	controller.movement_speed = 96.0
	controller.configure_input_service(input_service)
	controller.interaction_requested.connect(_on_interaction_requested)
	root.add_child(controller)
	await physics_frame

	input_service.current_snapshot.move = Vector2.RIGHT
	for _frame in range(6):
		await physics_frame
	input_service.current_snapshot = InputSnapshot.neutral()
	_check(controller.position.x > 0.0, "semantic movement snapshot moves CharacterBody2D")

	controller.set_input_locked(true)
	var locked_position := controller.position
	input_service.current_snapshot.move = Vector2.LEFT
	for _frame in range(3):
		await physics_frame
	_check(controller.position.is_equal_approx(locked_position), "interaction lock prevents movement leakage")

	controller.set_input_locked(false)
	input_service.current_snapshot = InputSnapshot.neutral()
	input_service.current_snapshot.interact = true
	await physics_frame
	input_service.current_snapshot = InputSnapshot.neutral()
	_check(_interaction_requests == 1, "semantic interact action emits one world interaction request")

	controller.queue_free()
	_finish()


func _on_interaction_requested(_world_position: Vector2, _facing_direction: Vector2i) -> void:
	_interaction_requests += 1


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P1_PLAYER_CONTROLLER_OK")
		quit(0)
		return
	push_error("P1 player controller failed: %d check(s)" % _failures)
	quit(1)

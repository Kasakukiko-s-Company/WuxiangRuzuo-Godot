extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var service := GodotInputService.new()
	var actions: Array[StringName] = [
		&"move_left",
		&"move_right",
		&"move_up",
		&"move_down",
		&"interact",
		&"primary_action",
		&"pause",
		&"prototype_debug",
		&"prototype_reset",
		&"prototype_reduce_motion",
	]
	var all_registered := true
	for action in actions:
		all_registered = all_registered and InputMap.has_action(action)
		all_registered = all_registered and not InputMap.action_get_events(action).is_empty()
	_check(all_registered, "P1 semantic InputMap actions have default keyboard or controller bindings")
	_check(_movement_actions_support_keyboard_and_controller(), "movement actions expose both keyboard and controller bindings")
	_check(_button_action_supports_keyboard_and_controller(&"interact"), "interaction exposes both keyboard and controller bindings")
	_check(service.snapshot() != null, "Godot input adapter returns a typed semantic snapshot")
	_check(
		InputMap.event_is_action(_key_event(KEY_D, true), &"move_right"),
		"physical keyboard input resolves to the semantic movement action",
	)
	_check(
		InputMap.event_is_action(_joy_motion_event(JOY_AXIS_LEFT_X, -1.0), &"move_left"),
		"controller axis input resolves to the same semantic movement action",
	)
	_finish()


func _movement_actions_support_keyboard_and_controller() -> bool:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		var has_keyboard := false
		var has_controller := false
		for event in InputMap.action_get_events(action):
			has_keyboard = has_keyboard or event is InputEventKey
			has_controller = has_controller or event is InputEventJoypadMotion
		if not has_keyboard or not has_controller:
			return false
	return true


func _button_action_supports_keyboard_and_controller(action: StringName) -> bool:
	var has_keyboard := false
	var has_controller := false
	for event in InputMap.action_get_events(action):
		has_keyboard = has_keyboard or event is InputEventKey
		has_controller = has_controller or event is InputEventJoypadButton
	return has_keyboard and has_controller


func _key_event(physical_keycode: int, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	event.keycode = physical_keycode
	event.pressed = pressed
	return event


func _joy_motion_event(axis: int, axis_value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = axis_value
	return event


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P1_INPUT_SERVICE_OK")
		quit(0)
		return
	push_error("P1 input service failed: %d check(s)" % _failures)
	quit(1)

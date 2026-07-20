class_name GodotInputService
extends InputService


func _init() -> void:
	_register_default_actions()


func snapshot() -> InputSnapshot:
	var current := InputSnapshot.neutral()
	current.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	current.interact = Input.is_action_just_pressed(&"interact")
	current.primary_action = Input.is_action_just_pressed(&"primary_action")
	current.pause = Input.is_action_just_pressed(&"pause")
	current.debug_toggle = Input.is_action_just_pressed(&"prototype_debug")
	current.reset = Input.is_action_just_pressed(&"prototype_reset")
	current.reduce_motion_toggle = Input.is_action_just_pressed(&"prototype_reduce_motion")
	return current


func _register_default_actions() -> void:
	_register_action(&"move_left", [_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)], 0.2)
	_register_action(&"move_right", [_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)], 0.2)
	_register_action(&"move_up", [_key(KEY_W), _key(KEY_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)], 0.2)
	_register_action(&"move_down", [_key(KEY_S), _key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)], 0.2)
	_register_action(&"interact", [_key(KEY_E), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A)])
	_register_action(&"primary_action", [_key(KEY_F), _key(KEY_SPACE), _joy_button(JOY_BUTTON_X)])
	_register_action(&"pause", [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_START)])
	_register_action(&"prototype_debug", [_key(KEY_F3), _joy_button(JOY_BUTTON_BACK)])
	_register_action(&"prototype_reset", [_key(KEY_R), _joy_button(JOY_BUTTON_Y)])
	_register_action(&"prototype_reduce_motion", [_key(KEY_M), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)])


func _register_action(action: StringName, events: Array[InputEvent], deadzone: float = 0.5) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, deadzone)
	for event in events:
		InputMap.action_add_event(action, event)


func _key(physical_keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	return event


func _joy_axis(axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


func _joy_button(button_index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	return event

class_name GodotInputService
extends InputService


func _init() -> void:
	_register_default_actions()


func snapshot() -> InputSnapshot:
	var current := InputSnapshot.neutral()
	current.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	current.interact = Input.is_action_just_pressed(&"interact")
	current.primary_action = Input.is_action_just_pressed(&"primary_action")
	current.secondary_action = Input.is_action_just_pressed(&"secondary_action")
	current.watering_action = Input.is_action_just_pressed(&"watering_action")
	current.sleep_action = Input.is_action_just_pressed(&"prototype_advance_day")
	current.select_previous = Input.is_action_just_pressed(&"quickbar_previous")
	current.select_next = Input.is_action_just_pressed(&"quickbar_next")
	for slot_index: int in InputSnapshot.QUICKBAR_SLOT_COUNT:
		if Input.is_action_just_pressed(
			StringName("quickbar_%d" % (slot_index + 1))
		):
			current.quickbar_slot_index = slot_index
			break
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
	_register_action(&"secondary_action", [_key(KEY_V), _joy_button(JOY_BUTTON_B)])
	_register_action(&"watering_action", [_key(KEY_G)])
	_register_action(&"prototype_advance_day", [_key(KEY_N)])
	_register_action(&"quickbar_previous", [_key(KEY_Q), _joy_button(JOY_BUTTON_LEFT_SHOULDER)])
	_register_action(&"quickbar_next", [_key(KEY_TAB), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)])
	for slot_index: int in InputSnapshot.QUICKBAR_SLOT_COUNT:
		_register_action(
			StringName("quickbar_%d" % (slot_index + 1)),
			[_key(KEY_1 + slot_index)],
		)
	_register_action(&"pause", [_key(KEY_ESCAPE), _joy_button(JOY_BUTTON_START)])
	_register_action(&"prototype_debug", [_key(KEY_F3), _joy_button(JOY_BUTTON_BACK)])
	_register_action(&"prototype_reset", [_key(KEY_R), _joy_button(JOY_BUTTON_Y)])
	_register_action(&"prototype_reduce_motion", [_key(KEY_M)])


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

extends SceneTree


class MemorySaveService extends SaveService:
	var payloads: Dictionary[StringName, String] = {}
	var previous_payloads: Dictionary[StringName, String] = {}


	func read(slot_id: StringName) -> SaveReadResult:
		if not payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(payloads[slot_id])


	func read_previous(slot_id: StringName) -> SaveReadResult:
		if not previous_payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(previous_payloads[slot_id])


	func write(slot_id: StringName, payload: String) -> SaveWriteResult:
		if payloads.has(slot_id):
			previous_payloads[slot_id] = payloads[slot_id]
		payloads[slot_id] = payload
		return SaveWriteResult.written()


	func remove(slot_id: StringName) -> SaveWriteResult:
		payloads.erase(slot_id)
		previous_payloads.erase(slot_id)
		return SaveWriteResult.written()


class FailingSaveService extends MemorySaveService:
	var writes_fail: bool = true


	func write(slot_id: StringName, payload: String) -> SaveWriteResult:
		if writes_fail:
			return SaveWriteResult.failed("injected session-exit failure")
		return super.write(slot_id, payload)


class QueuedInputService extends InputService:
	var next_snapshot: InputSnapshot = InputSnapshot.neutral()


	func snapshot() -> InputSnapshot:
		var result := next_snapshot
		next_snapshot = InputSnapshot.neutral()
		return result


class WalkableStep extends RefCounted:
	var source: Vector2i
	var direction: Vector2i


	func _init(source_cell: Vector2i, step_direction: Vector2i) -> void:
		source = source_cell
		direction = step_direction


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var composition_root := AppCompositionRoot.new()
	composition_root.bootstrap()
	var storage := MemorySaveService.new()
	var launch := composition_root.create_h01_launch(
		&"profile-2",
		storage,
	)
	_check(
		launch.is_ready(),
		"pause navigation composes through the validated H01 launch",
	)
	if not launch.is_ready():
		_finish()
		return
	var pilot := launch.pilot
	var queued_input := QueuedInputService.new()
	pilot.configure_input_service(queued_input)
	root.add_child(pilot)
	current_scene = pilot
	await process_frame
	pilot.durable_state_committed.emit(&"test.protected", true)
	_check(
		storage.payloads.has(&"profile-2.protected"),
		"pause navigation fixture owns a protected recovery checkpoint",
	)
	var pause_menu := pilot.get_node_or_null(
		"HUD/PauseMenu"
	) as P2PauseMenu
	_check(
		pause_menu != null,
		"H01 owns a dedicated pause menu Control",
	)
	if pause_menu == null:
		pilot.queue_free()
		current_scene = null
		await process_frame
		_finish()
		return

	var pause_snapshot := InputSnapshot.neutral()
	pause_snapshot.pause = true
	var walkable_step := _find_walkable_step(pilot.get_estate_runtime())
	_check(
		walkable_step != null,
		"pause navigation fixture finds an unobstructed movement step",
	)
	if walkable_step == null:
		pilot.queue_free()
		current_scene = null
		await process_frame
		_finish()
		return
	pilot.get_player().global_position = TileCoordinateMapper.new(
		Vector2i(32, 32)
	).cell_center(walkable_step.source)
	var position_before_pause := pilot.get_player().global_position
	var simultaneous_snapshot := InputSnapshot.neutral()
	simultaneous_snapshot.pause = true
	simultaneous_snapshot.move = Vector2(walkable_step.direction)
	queued_input.next_snapshot = simultaneous_snapshot
	await physics_frame
	await process_frame
	_check(
		paused
		and pause_menu.visible
		and pause_menu.is_open()
		and pilot.get_player().global_position == position_before_pause,
		"real simultaneous pause and movement freezes before gameplay advances",
	)
	var return_button := pause_menu.get_node_or_null(
		"%ReturnToTitleButton"
	) as Button
	_check(
		return_button != null
		and return_button.text.contains("保存"),
		"a writable session labels return as a save operation",
	)
	pilot.configure_input_service(GodotInputService.new())
	_send_pause_key(true)
	await process_frame
	await physics_frame
	_send_pause_key(false)
	await process_frame
	await physics_frame
	_check(
		not paused
		and not pause_menu.visible
		and not pause_menu.is_open(),
		"physical Escape resumes without rebounding open next physics frame",
	)

	pilot.apply_input_snapshot(pause_snapshot)
	await process_frame
	_send_pause_start(true)
	await process_frame
	await physics_frame
	_send_pause_start(false)
	await process_frame
	await physics_frame
	_check(
		not paused
		and not pause_menu.visible
		and not pause_menu.is_open(),
		"physical Start resumes without rebounding open next physics frame",
	)

	pilot.apply_input_snapshot(pause_snapshot)
	await process_frame
	pause_menu.request_return_confirmation()
	await process_frame
	var cancel_button := pause_menu.get_node_or_null(
		"%CancelReturnButton"
	) as Button
	_check(
		paused
		and pause_menu.is_return_confirmation_open()
		and cancel_button != null
		and cancel_button.has_focus(),
		"return-to-title requires a second confirmation focused on cancel",
	)
	_send_pause_key(true)
	await process_frame
	_send_pause_key(false)
	await process_frame
	_check(
		paused
		and pause_menu.is_open()
		and not pause_menu.is_return_confirmation_open(),
		"pause input cancels return confirmation before resuming gameplay",
	)

	var saved_position := Vector2(704.0, 512.0)
	pilot.get_player().global_position = saved_position
	pause_menu.request_return_confirmation()
	var first_confirm := pause_menu.confirm_return_to_title()
	var duplicate_confirm := pause_menu.confirm_return_to_title()
	_check(
		first_confirm and not duplicate_confirm,
		"return confirmation emits at most one navigation request",
	)
	await process_frame
	await process_frame
	_check(
		not paused
		and current_scene != null
		and current_scene.name == "Main",
		"confirmed return unpauses and navigates through the application binding",
	)
	_check(
		storage.payloads.has(&"profile-2"),
		"returning to title saves the selected profile before H01 exits",
	)
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
		await process_frame

	var restored_launch := composition_root.create_h01_launch(
		&"profile-2",
		storage,
	)
	_check(
		restored_launch.is_ready(),
		"the profile saved during return remains loadable",
	)
	if restored_launch.is_ready():
		root.add_child(restored_launch.pilot)
		current_scene = restored_launch.pilot
		await process_frame
		_check(
			restored_launch.pilot.get_player().global_position
			== saved_position,
			"return-to-title persistence restores the last player position",
		)
		restored_launch.pilot.queue_free()
		current_scene = null
		await process_frame

	var failing_storage := FailingSaveService.new()
	var failing_launch := composition_root.create_h01_launch(
		&"profile-1",
		failing_storage,
	)
	_check(
		failing_launch.is_ready(),
		"save-failure navigation fixture composes a writable session",
	)
	if failing_launch.is_ready():
		var failing_pilot := failing_launch.pilot
		root.add_child(failing_pilot)
		current_scene = failing_pilot
		await process_frame
		failing_pilot.apply_input_snapshot(pause_snapshot)
		await process_frame
		var failing_menu := failing_pilot.get_pause_menu()
		failing_menu.request_return_confirmation()
		failing_menu.confirm_return_to_title()
		await process_frame
		await process_frame
		var stayed_in_session := current_scene == failing_pilot
		_check(
			stayed_in_session
			and paused
			and failing_menu.is_return_confirmation_open(),
			"a failed exit save keeps the player in the paused session",
		)
		_check(
			not failing_storage.payloads.has(&"profile-1"),
			"a failed exit save never reports or persists a current checkpoint",
		)
		if stayed_in_session:
			failing_storage.writes_fail = false
			var retry_requested := failing_menu.confirm_return_to_title()
			await process_frame
			await process_frame
			_check(
				retry_requested
				and not paused
				and current_scene != null
				and current_scene.name == "Main"
				and failing_storage.payloads.has(&"profile-1"),
				"a successful retry saves before navigating to Main",
			)
		if current_scene != null:
			current_scene.queue_free()
			current_scene = null
			await process_frame

	var read_only_storage := MemorySaveService.new()
	read_only_storage.payloads[&"profile-2"] = "{corrupt-current"
	read_only_storage.payloads[&"profile-2.protected"] = (
		storage.payloads[&"profile-2.protected"]
	)
	read_only_storage.payloads[
		&"profile-2.quarantine-primary"
	] = "{different-evidence"
	var read_only_launch := composition_root.create_h01_launch(
		&"profile-2",
		read_only_storage,
	)
	_check(
		read_only_launch.is_ready(),
		"pause navigation accepts a verified read-only recovery",
	)
	if read_only_launch.is_ready():
		root.add_child(read_only_launch.pilot)
		current_scene = read_only_launch.pilot
		await process_frame
		read_only_launch.pilot.apply_input_snapshot(pause_snapshot)
		await process_frame
		var read_only_menu := read_only_launch.pilot.get_node(
			"HUD/PauseMenu"
		) as P2PauseMenu
		var read_only_return := read_only_menu.get_node(
			"%ReturnToTitleButton"
		) as Button
		_check(
			read_only_return.text.contains("只读")
			and not read_only_return.text.contains("保存并"),
			"a read-only recovery never promises that return will save",
		)
		read_only_menu.request_return_confirmation()
		read_only_menu.confirm_return_to_title()
		await process_frame
		await process_frame
		_check(
			not paused
			and read_only_storage.payloads[&"profile-2"]
			== "{corrupt-current",
			"returning from read-only recovery preserves unavailable evidence",
		)
		if current_scene != null:
			current_scene.queue_free()
			current_scene = null
			await process_frame
	_finish()


func _send_pause_key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = pressed
	Input.parse_input_event(event)


func _send_pause_start(pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = JOY_BUTTON_START
	event.pressed = pressed
	Input.parse_input_event(event)


func _find_walkable_step(runtime: EstateMapRuntime) -> WalkableStep:
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.UP,
	]
	for y: int in range(20, 80):
		for x: int in range(20, 108):
			var source := Vector2i(x, y)
			var source_semantics := runtime.query_cell(source)
			if (
				not source_semantics.is_in_bounds()
				or source_semantics.colliding
			):
				continue
			for direction: Vector2i in directions:
				var target_semantics := runtime.query_cell(
					source + direction
				)
				if (
					target_semantics.is_in_bounds()
					and not target_semantics.colliding
				):
					return WalkableStep.new(source, direction)
	return null


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	paused = false
	if _failures == 0:
		print("P2_PAUSE_NAVIGATION_OK")
		quit(0)
		return
	push_error("P2 pause navigation failed: %d check(s)" % _failures)
	quit(1)

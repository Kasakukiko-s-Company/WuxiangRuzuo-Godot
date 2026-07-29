extends SceneTree


class MainProfileSaveService extends SaveService:
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


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main := load("res://scenes/Main.tscn") as PackedScene
	var storage := MainProfileSaveService.new()
	var main := packed_main.instantiate()
	main.call("configure_save_service_override", storage)
	root.add_child(main)
	current_scene = main
	await process_frame
	var initial_state := main.call(
		"profile_screen_state",
	) as ProfileScreenState
	_check(
		initial_state != null
		and initial_state.selected_profile_id == &"profile-1"
		and initial_state.roster.profiles.size() == 3
		and initial_state.can_launch()
		and not initial_state.can_delete(),
		"Main exposes three empty profiles with profile-1 selected",
	)

	main.call("select_profile", &"profile-3")
	var selected_state := main.call(
		"profile_screen_state",
	) as ProfileScreenState
	_check(
		selected_state.selected_profile_id == &"profile-3",
		"a player can select profile-3 through Main's semantic interface",
	)
	main.call("activate_selected_profile")
	await process_frame
	await process_frame
	_check(
		current_scene is P2EstatePilot,
		"the selected empty profile launches H01 as a new game",
	)
	if current_scene is P2EstatePilot:
		current_scene.queue_free()
		current_scene = null
		await process_frame
		await physics_frame
	var recent_document: Dictionary = JSON.parse_string(
		storage.payloads.get(&"profile-directory", "{}")
	) as Dictionary
	_check(
		storage.payloads.has(&"profile-3")
		and not storage.payloads.has(&"profile-1")
		and recent_document.get("lastPlayedProfileId") == "profile-3",
		"selected launch binds autosave and recent metadata to profile-3",
	)

	var reopened := packed_main.instantiate()
	reopened.call("configure_save_service_override", storage)
	root.add_child(reopened)
	current_scene = reopened
	await process_frame
	var reopened_state := reopened.call(
		"profile_screen_state",
	) as ProfileScreenState
	_check(
		reopened_state.selected_profile_id == &"profile-3"
		and reopened_state.can_launch()
		and reopened_state.can_delete(),
		"reopening Main preselects the last successfully launched profile",
	)
	var profile_three_before_delete: String = storage.payloads[&"profile-3"]
	reopened.call("request_delete_selected_profile")
	var confirmation_state := reopened.call(
		"profile_screen_state",
	) as ProfileScreenState
	var modal_launch := reopened.get_node_or_null(
		"%LaunchP2Button"
	) as Button
	var modal_p1 := reopened.get_node_or_null("%LaunchP1Button") as Button
	var modal_delete := reopened.get_node_or_null(
		"%DeleteProfileButton"
	) as Button
	var modal_profile_one := reopened.get_node_or_null(
		"%Profile1Button"
	) as Button
	_check(
		confirmation_state.pending_delete_profile_id == &"profile-3"
		and storage.payloads[&"profile-3"] == profile_three_before_delete,
		"requesting deletion opens confirmation without touching storage",
	)
	_check(
		not confirmation_state.can_launch()
		and not confirmation_state.can_delete()
		and modal_launch.disabled
		and modal_p1.disabled
		and modal_delete.disabled
		and modal_profile_one.disabled,
		"delete confirmation locks every action behind the modal layer",
	)
	reopened.call("resolve_delete_confirmation", false)
	_check(
		storage.payloads[&"profile-3"] == profile_three_before_delete,
		"cancelling deletion preserves the selected profile",
	)
	reopened.call("request_delete_selected_profile")
	var delete_result := reopened.call(
		"resolve_delete_confirmation",
		true,
	) as SaveProfileMutationResult
	var deleted_state := reopened.call(
		"profile_screen_state",
	) as ProfileScreenState
	_check(
		delete_result.status == SaveProfileMutationResult.Status.APPLIED
		and not storage.payloads.has(&"profile-3")
		and not storage.payloads.has(&"profile-directory")
		and deleted_state.roster.profile(&"profile-3").is_empty()
		and deleted_state.selected_profile_id == &"profile-1",
		"confirmed deletion clears the selected profile and stale recency",
	)

	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
		await process_frame
	storage.payloads[&"profile-2"] = "{corrupt-recent"
	storage.write(
		&"profile-directory",
		'{"schemaVersion":1,"lastPlayedProfileId":"profile-2"}',
	)
	var damaged_main := packed_main.instantiate()
	damaged_main.call("configure_save_service_override", storage)
	root.add_child(damaged_main)
	current_scene = damaged_main
	await process_frame
	var damaged_state := damaged_main.call(
		"profile_screen_state",
	) as ProfileScreenState
	var damaged_launch := damaged_main.get_node_or_null(
		"%LaunchP2Button"
	) as Button
	var damaged_delete := damaged_main.get_node_or_null(
		"%DeleteProfileButton"
	) as Button
	var damaged_detail := damaged_main.get_node_or_null(
		"%ProfileDetailLabel"
	) as Label
	var damaged_content := damaged_main.get_node_or_null(
		"Margin/Center/Content"
	) as Control
	var delete_layer := damaged_main.get_node_or_null(
		"%DeleteConfirmLayer"
	) as Control
	var cancel_delete := damaged_main.get_node_or_null(
		"%CancelDeleteButton"
	) as Button
	_check(
		damaged_state.selected_profile_id == &"profile-2"
		and damaged_state.selected_profile().status
		== SaveProfileSummary.Status.CORRUPT
		and not damaged_state.can_launch()
		and damaged_state.can_delete()
		and damaged_launch != null
		and damaged_launch.disabled,
		"a damaged recent profile remains selected and cannot silently launch another slot",
	)
	var viewport_rect: Rect2 = damaged_main.get_viewport_rect()
	var content_rect: Rect2 = damaged_content.get_global_rect()
	_check(
		damaged_content != null
		and content_rect.position.y >= 0.0
		and content_rect.end.y <= viewport_rect.end.y,
		"the complete profile screen fits inside the 640x360 logical viewport",
	)
	_check(
		damaged_detail != null
		and damaged_detail.text.contains("原文件不会被覆盖")
		and not damaged_detail.text.contains("current:"),
		"damaged-profile guidance is actionable Chinese instead of codec internals",
	)
	if damaged_delete != null:
		damaged_delete.pressed.emit()
		await process_frame
	_check(
		delete_layer != null
		and delete_layer.visible
		and cancel_delete != null
		and cancel_delete.has_focus(),
		"delete confirmation is modal and defaults focus to cancel",
	)
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"ui_cancel"
	cancel_event.pressed = true
	Input.parse_input_event(cancel_event)
	await process_frame
	var cancelled_state := damaged_main.call(
		"profile_screen_state",
	) as ProfileScreenState
	_check(
		not cancelled_state.is_delete_confirmation_open()
		and not delete_layer.visible
		and storage.payloads.get(&"profile-2", "") == "{corrupt-recent",
		"ui_cancel closes confirmation without deleting damaged evidence",
	)
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
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
		print("P2_SAVE_PROFILE_MAIN_UI_OK")
		quit(0)
		return
	push_error("P2 save-profile Main UI failed: %d check(s)" % _failures)
	quit(1)

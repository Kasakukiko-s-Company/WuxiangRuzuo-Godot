extends SceneTree

const PROFILE_OUTPUT_PATH: String = "res://builds/verification/p2_profile_screen.png"
const DELETE_OUTPUT_PATH: String = "res://builds/verification/p2_profile_delete_confirmation.png"


class CaptureSaveService extends SaveService:
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


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var storage := CaptureSaveService.new()
	storage.payloads[&"profile-2"] = "{corrupt-recent"
	storage.payloads[&"profile-directory"] = (
		'{"schemaVersion":1,"lastPlayedProfileId":"profile-2"}'
	)
	var packed_main := load("res://scenes/Main.tscn") as PackedScene
	var main := packed_main.instantiate()
	main.call("configure_save_service_override", storage)
	root.add_child(main)
	current_scene = main
	for _frame: int in range(5):
		await process_frame
	if not _save_view(PROFILE_OUTPUT_PATH):
		quit(1)
		return
	main.call("request_delete_selected_profile")
	await process_frame
	if not _save_view(DELETE_OUTPUT_PATH):
		quit(1)
		return
	print(
		"P2_PROFILE_SCREEN_CAPTURE_OK: %s, %s"
		% [PROFILE_OUTPUT_PATH, DELETE_OUTPUT_PATH]
	)
	quit(0)


func _save_view(output_path: String) -> bool:
	var image: Image = root.get_texture().get_image()
	var absolute_output := ProjectSettings.globalize_path(output_path)
	var output_directory := absolute_output.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK:
		push_error("Unable to create screenshot directory: %s" % output_directory)
		return false
	var save_error := image.save_png(absolute_output)
	if save_error != OK:
		push_error(
			"Unable to save P2 profile screenshot: %s"
			% error_string(save_error)
		)
		return false
	return true

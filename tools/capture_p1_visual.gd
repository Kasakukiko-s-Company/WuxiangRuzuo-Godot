extends SceneTree

const OUTPUT_DIRECTORY: String = "res://.godot/qa"

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		_fail("Visual capture requires the Compatibility Renderer; run this script without --headless")
		_finish()
		return
	var packed_scene := load("res://scenes/prototypes/p1_experience_probe.tscn") as PackedScene
	if packed_scene == null:
		_fail("P1 scene could not be loaded")
		_finish()
		return
	var probe := packed_scene.instantiate() as P1ExperienceProbe
	root.add_child(probe)
	current_scene = probe
	await process_frame
	await process_frame
	probe.player.set_physics_process(false)

	var output_directory := ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK:
		_fail("Could not create visual QA directory: %s" % error_string(directory_error))
	else:
		var high_image := await _capture_frame()
		_save_image(high_image, "%s/p1_high.png" % output_directory)
		probe.set_quality_level(&"low")
		var low_image := await _capture_frame()
		_save_image(low_image, "%s/p1_low.png" % output_directory)
		probe.set_quality_level(&"high")
		probe.set_debug_visible(true)
		var debug_image := await _capture_frame()
		_save_image(debug_image, "%s/p1_debug.png" % output_directory)
		if high_image != null and low_image != null:
			if high_image.get_data() == low_image.get_data():
				_fail("High and low quality captures are identical")
			else:
				print("PASS: high and low quality captures are visibly distinct")

	current_scene = null
	probe.queue_free()
	await process_frame
	await process_frame
	_finish()


func _capture_frame() -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Viewport capture returned an empty image")
		return null
	var logical_size := Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)),
		int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)),
	)
	var capture_size := image.get_size()
	var scale_x := capture_size.x / logical_size.x if logical_size.x > 0 else 0
	var scale_y := capture_size.y / logical_size.y if logical_size.y > 0 else 0
	if logical_size != Vector2i(640, 360) or scale_x < 1 or scale_x != scale_y:
		_fail("Viewport capture %s does not preserve the 640x360 logical target at integer scale" % capture_size)
	else:
		print("PASS: captured %s physical output from the 640x360 logical viewport at %dx" % [capture_size, scale_x])
	return image


func _save_image(image: Image, output_path: String) -> void:
	if image == null:
		return
	var save_error := image.save_png(output_path)
	if save_error != OK:
		_fail("Could not save %s: %s" % [output_path, error_string(save_error)])
	else:
		print("PASS: saved %s" % output_path)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)


func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("P1_VISUAL_CAPTURE_OK")
	quit(0)

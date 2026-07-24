extends SceneTree

const SCENE_PATH: String = "res://scenes/vertical_slices/p2_estate_pilot.tscn"
const OUTPUT_PATH: String = "res://builds/verification/h01_estate_pilot.png"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var packed_scene := load(SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Unable to load H01 estate pilot")
		quit(1)
		return
	var composition_root := AppCompositionRoot.new()
	var status := composition_root.bootstrap()
	if not composition_root.is_ready():
		push_error("Unable to bootstrap H01 estate pilot capture: %s" % status)
		quit(1)
		return
	var definition := composition_root.get_estate_pilot_definition()
	var scene := packed_scene.instantiate()
	var runtime_scene := load(definition.runtime_scene_path) as PackedScene
	if runtime_scene == null:
		push_error("Unable to load the formal H01 estate runtime")
		quit(1)
		return
	var pilot := scene as P2EstatePilot
	var runtime := runtime_scene.instantiate() as EstateMapRuntime
	if pilot == null or runtime == null:
		push_error("Unable to compose the typed H01 estate pilot")
		quit(1)
		return
	pilot.configure_estate_runtime(runtime)
	pilot.configure_input_service(composition_root.create_input_service())
	root.add_child(scene)
	current_scene = scene
	for _frame in range(5):
		await process_frame
	await create_timer(0.2).timeout
	var image: Image = root.get_texture().get_image()
	var absolute_output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var output_directory := absolute_output.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK:
		push_error("Unable to create screenshot directory: %s" % output_directory)
		quit(1)
		return
	var save_error := image.save_png(absolute_output)
	if save_error != OK:
		push_error("Unable to save H01 estate pilot screenshot: %s" % error_string(save_error))
		quit(1)
		return
	print("H01_ESTATE_PILOT_CAPTURE_OK: %s" % absolute_output)
	quit(0)

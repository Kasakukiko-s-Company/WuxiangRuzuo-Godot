extends SceneTree

const SCENE_PATH: String = "res://scenes/vertical_slices/p2_estate_pilot.tscn"
const FARM_OUTPUT_PATH: String = "res://builds/verification/p2_h01_farming_loop.png"
const RESOURCE_OUTPUT_PATH: String = "res://builds/verification/p2_h01_resource_source.png"
const REST_OUTPUT_PATH: String = "res://builds/verification/p2_h01_rest_confirmation.png"


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
	pilot.configure_game_catalog(composition_root.game_catalog)
	root.add_child(scene)
	current_scene = scene
	for _frame in range(5):
		await process_frame
	var resource_anchor := runtime.query_anchor(
		&"resource_spawn_zone",
		&"resource_north_meadow",
	)
	var resource_approach := _find_anchor_approach(runtime, resource_anchor)
	var rest_anchor := runtime.query_anchor(&"interaction", &"home_door")
	var rest_approach := _find_anchor_approach(runtime, rest_anchor)
	var farm_approach := _find_farmable_approach(runtime)
	if (
		resource_approach.is_empty()
		or rest_approach.is_empty()
		or farm_approach.is_empty()
	):
		push_error("Unable to find all visible H01 interaction approaches")
		quit(1)
		return
	var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
	var player := pilot.get_player()

	_place_for_interaction(player, mapper, resource_approach)
	pilot.get_camera().reset_smoothing()
	await create_timer(0.2).timeout
	if not _save_view(RESOURCE_OUTPUT_PATH):
		quit(1)
		return
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame

	_place_for_interaction(player, mapper, rest_approach)
	pilot.get_camera().reset_smoothing()
	player.interaction_requested.emit(player.global_position, player.facing)
	await create_timer(0.2).timeout
	if not _save_view(REST_OUTPUT_PATH):
		quit(1)
		return

	player.global_position = mapper.cell_center(farm_approach["source"])
	player.facing = farm_approach["direction"]
	player.velocity = Vector2.ZERO
	pilot.get_camera().reset_smoothing()
	pilot.apply_input_snapshot(_action_snapshot(0))
	pilot.apply_input_snapshot(_action_snapshot(2))
	pilot.apply_input_snapshot(_action_snapshot(1))
	await create_timer(0.2).timeout
	if not _save_view(FARM_OUTPUT_PATH):
		quit(1)
		return
	print(
		"H01_ESTATE_PILOT_CAPTURE_OK: %s, %s, %s"
		% [RESOURCE_OUTPUT_PATH, REST_OUTPUT_PATH, FARM_OUTPUT_PATH]
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
		push_error("Unable to save H01 estate pilot screenshot: %s" % error_string(save_error))
		return false
	return true


func _action_snapshot(slot_index: int) -> InputSnapshot:
	var snapshot := InputSnapshot.neutral()
	snapshot.quickbar_slot_index = slot_index
	snapshot.primary_action = true
	return snapshot


func _find_farmable_approach(runtime: EstateMapRuntime) -> Dictionary:
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
			if not source_semantics.is_in_bounds() or source_semantics.colliding:
				continue
			for direction: Vector2i in directions:
				var target := source + direction
				var target_semantics := runtime.query_cell(target)
				if (
					target_semantics.is_in_bounds()
					and target_semantics.farmable
					and not target_semantics.colliding
				):
					return {
						"source": source,
						"direction": direction,
					}
	return {}


func _find_anchor_approach(
	runtime: EstateMapRuntime,
	anchor: EstateAnchorResult,
) -> Dictionary:
	if not anchor.is_found():
		return {}
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.UP,
	]
	for direction: Vector2i in directions:
		var source := anchor.cell - direction
		var semantics: EstateCellSemantics = runtime.query_cell(source)
		if semantics.is_in_bounds() and not semantics.colliding:
			return {
				"source": source,
				"target": anchor.cell,
				"direction": direction,
			}
	return {}


func _place_for_interaction(
	player: P1PlayerController,
	mapper: TileCoordinateMapper,
	approach: Dictionary,
) -> void:
	player.global_position = mapper.cell_center(approach["source"])
	player.facing = approach["direction"]
	player.velocity = Vector2.ZERO

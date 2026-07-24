extends SceneTree

class ScriptedInputService extends InputService:
	var current_snapshot: InputSnapshot = InputSnapshot.neutral()

	func snapshot() -> InputSnapshot:
		return current_snapshot


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load(
		"res://scenes/vertical_slices/p2_estate_pilot.tscn"
	) as PackedScene
	_check(packed_scene != null, "H01 estate pilot scene loads")
	if packed_scene == null:
		_finish()
		return

	var pilot := packed_scene.instantiate() as P2EstatePilot
	_check(pilot != null, "estate pilot exposes its composition-root seam")
	if pilot == null:
		_finish()
		return
	var catalog_result := EstateMapCatalogFileLoader.load_catalog()
	_check(catalog_result.is_valid(), "estate pilot test loads the validated map catalog")
	var definition: EstateMapDefinition = catalog_result.catalog.get_map(
		&"home_h01_open_meadow"
	)
	var runtime_scene := load(definition.runtime_scene_path) as PackedScene
	var injected_runtime := runtime_scene.instantiate() as EstateMapRuntime
	var scripted_input := ScriptedInputService.new()
	pilot.configure_estate_runtime(injected_runtime)
	pilot.configure_input_service(scripted_input)
	root.add_child(pilot)
	await process_frame
	await physics_frame

	var runtime: EstateMapRuntime = pilot.get_estate_runtime()
	var player: P1PlayerController = pilot.get_player()
	var camera: Camera2D = pilot.get_camera()
	_check(
		runtime != null and runtime.get_map_id() == &"home_h01_open_meadow",
		"pilot composes the formal H01 estate runtime",
	)
	_check(player != null, "pilot reuses the verified CharacterBody2D player seam")
	_check(
		player.global_position == Vector2(2032.0, 1008.0)
		and player.facing == Vector2i.DOWN,
		"pilot starts at the audited H01 safe spawn and facing",
	)
	_check(
		camera != null
		and camera.limit_left == 0
		and camera.limit_top == 0
		and camera.limit_right == 4096
		and camera.limit_bottom == 3072,
		"pilot camera is clamped to the formal H01 world bounds",
	)
	_check(
		player.collision_layer == 1 and player.collision_mask == 1,
		"pilot player participates in the H01 physical collision layer",
	)

	_check(
		pilot.get_player_cell() == Vector2i(63, 31),
		"pilot maps the safe world position back to the audited tile cell",
	)
	var before := player.global_position
	scripted_input.current_snapshot.move = Vector2.RIGHT
	for _frame in range(4):
		await physics_frame
	_check(player.global_position.x > before.x, "pilot accepts movement through the injected input service")
	pilot.reset_to_safe_spawn()
	_check(player.global_position == before, "pilot reset returns to the authoritative H01 safe spawn")
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	var status_label := pilot.get_node(
		"HUD/StatusPanel/Margin/StatusLabel"
	) as Label
	_check(
		status_label.text.begins_with("目标格"),
		"pilot interaction presents the typed target-cell semantics",
	)
	var collision_approach := _find_collision_approach(runtime)
	_check(
		not collision_approach.is_empty(),
		"formal H01 exposes a walkable approach to a physically blocked cell",
	)
	if not collision_approach.is_empty():
		var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
		var source_cell: Vector2i = collision_approach["source"]
		var blocked_cell: Vector2i = collision_approach["blocked"]
		var direction: Vector2i = collision_approach["direction"]
		player.global_position = mapper.cell_center(source_cell)
		player.velocity = Vector2.ZERO
		scripted_input.current_snapshot.move = Vector2(direction)
		for _frame in range(30):
			await physics_frame
		scripted_input.current_snapshot = InputSnapshot.neutral()
		_check(
			runtime.query_cell(blocked_cell).colliding,
			"collision probe target is blocked by the formal H01 runtime",
		)
		_check(
			pilot.get_player_cell() != blocked_cell,
			"CharacterBody2D movement cannot enter the formal H01 blocked cell",
		)
		pilot.reset_to_safe_spawn()

	var state_result: EstateMapApplyResult = pilot.apply_estate_state(
		EstateMapState.new(&"summer", &"reclaimed", &"light")
	)
	_check(state_result.is_success(), "pilot forwards typed estate state changes through the runtime seam")
	var restored: EstateMapApplyResult = pilot.apply_estate_state(
		EstateMapState.new(&"spring", &"derelict", &"normal")
	)
	_check(restored.is_success(), "pilot restores the default H01 state")
	pilot.set_reduce_motion(true)
	_check(not camera.position_smoothing_enabled, "pilot supports reduce-motion camera behavior")

	var scene_text := FileAccess.get_file_as_string(
		"res://scenes/vertical_slices/p2_estate_pilot.tscn"
	)
	_check(
		not scene_text.contains("maps/candidates"),
		"pilot scene has no dependency on candidate staging",
	)

	pilot.queue_free()
	await process_frame
	await physics_frame
	_finish()


func _find_collision_approach(runtime: EstateMapRuntime) -> Dictionary:
	var directions: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.UP,
	]
	for y: int in range(1, 95):
		for x: int in range(1, 127):
			var source := Vector2i(x, y)
			var source_semantics := runtime.query_cell(source)
			if not source_semantics.is_in_bounds() or source_semantics.colliding:
				continue
			for direction: Vector2i in directions:
				var blocked := source + direction
				var blocked_semantics := runtime.query_cell(blocked)
				if blocked_semantics.is_in_bounds() and blocked_semantics.colliding:
					return {
						"source": source,
						"blocked": blocked,
						"direction": direction,
					}
	return {}


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("H01_ESTATE_PILOT_OK")
		quit(0)
		return
	push_error("H01 estate pilot test failed: %d check(s)" % _failures)
	quit(1)

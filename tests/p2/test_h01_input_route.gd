extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var composition_root := AppCompositionRoot.new()
	composition_root.bootstrap()
	_check(
		composition_root.is_ready(),
		"real-input route bootstraps the application composition root",
	)
	if not composition_root.is_ready():
		_finish()
		return
	var definition := composition_root.get_estate_pilot_definition()
	var pilot_scene := load(
		"res://scenes/vertical_slices/p2_estate_pilot.tscn"
	) as PackedScene
	var runtime_scene := load(definition.runtime_scene_path) as PackedScene
	var pilot := pilot_scene.instantiate() as P2EstatePilot
	var runtime := runtime_scene.instantiate() as EstateMapRuntime
	pilot.configure_estate_runtime(runtime)
	pilot.configure_input_service(composition_root.create_input_service())
	pilot.configure_game_catalog(composition_root.game_catalog)
	root.add_child(pilot)
	await process_frame
	await physics_frame

	var approach := _find_farmable_approach(runtime)
	_check(
		not approach.is_empty(),
		"real-input route finds a legal H01 farming target",
	)
	if not approach.is_empty():
		var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
		var player := pilot.get_player()
		var target_cell: Vector2i = approach["target"]
		player.global_position = mapper.cell_center(approach["source"])
		player.facing = approach["direction"]
		player.velocity = Vector2.ZERO
		_parse_key(KEY_F, true)
		Input.flush_buffered_events()
		_check(
			Input.is_action_pressed(&"primary_action"),
			"physical F press resolves to the registered primary action",
		)
		await create_timer(0.1).timeout
		_parse_key(KEY_F, false)
		Input.flush_buffered_events()
		await create_timer(0.05).timeout
		_check(
			pilot.get_farming_session().state.farm.tile_at(target_cell) != null,
			"a physical F key event travels through InputMap and GodotInputService to till H01",
		)

	_parse_key(KEY_F, false)
	pilot.queue_free()
	await process_frame
	await physics_frame
	_finish()


func _parse_key(physical_keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	event.keycode = physical_keycode
	event.pressed = pressed
	Input.parse_input_event(event)


func _find_farmable_approach(runtime: EstateMapRuntime) -> Dictionary:
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
				var target := source + direction
				var target_semantics := runtime.query_cell(target)
				if (
					target_semantics.is_in_bounds()
					and target_semantics.farmable
					and not target_semantics.colliding
				):
					return {
						"source": source,
						"target": target,
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
		print("P2_H01_INPUT_ROUTE_OK")
		quit(0)
		return
	push_error("P2 H01 real-input route failed: %d check(s)" % _failures)
	quit(1)

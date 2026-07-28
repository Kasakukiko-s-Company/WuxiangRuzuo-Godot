extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load(
		"res://scenes/world/estate/h01_open_meadow.tscn"
	) as PackedScene
	_check(packed_scene != null, "formal H01 estate scene loads")
	if packed_scene == null:
		_finish()
		return

	var runtime := packed_scene.instantiate() as EstateMapRuntime
	_check(runtime != null, "formal H01 scene implements the estate runtime seam")
	if runtime == null:
		_finish()
		return
	root.add_child(runtime)
	await process_frame
	await physics_frame

	_check(runtime.get_map_id() == &"home_h01_open_meadow", "runtime exposes the audited H01 stable map ID")
	_check(
		runtime.get_world_bounds() == Rect2(Vector2.ZERO, Vector2(4096.0, 3072.0)),
		"runtime exposes the audited H01 world bounds",
	)
	var default_state: EstateMapState = runtime.get_current_state()
	_check(
		default_state != null
		and default_state.season == &"spring"
		and default_state.development == &"derelict"
		and default_state.anomaly == &"normal",
		"runtime starts in the audited spring/derelict/normal state",
	)

	var safe_spawn: EstateAnchorResult = runtime.query_anchor(
		&"spawn",
		&"home_safe_spawn_meadow",
	)
	_check(safe_spawn.is_found(), "runtime resolves the audited H01 safe spawn")
	_check(
		safe_spawn.world_position == Vector2(2032.0, 1008.0)
		and safe_spawn.cell == Vector2i(63, 31),
		"safe spawn preserves the audited cell-center conversion",
	)
	var safe_cell: EstateCellSemantics = runtime.query_cell(safe_spawn.cell)
	_check(
		safe_cell.is_in_bounds() and not safe_cell.colliding,
		"safe spawn resolves to a non-colliding in-bounds cell",
	)
	var outside: EstateCellSemantics = runtime.query_cell(Vector2i(-1, 0))
	_check(not outside.is_in_bounds(), "out-of-bounds cell queries are explicit")
	var unknown_anchor: EstateAnchorResult = runtime.query_anchor(&"spawn", &"missing_anchor")
	_check(unknown_anchor.is_not_found(), "unknown anchors are distinct from disabled anchors")
	var active_portal: EstateAnchorResult = runtime.query_anchor(
		&"portal",
		&"portal_village_west",
	)
	_check(active_portal.is_found(), "available H01 portals remain queryable")
	var disabled_portal: EstateAnchorResult = runtime.query_anchor(
		&"portal",
		&"portal_future_region_south",
	)
	_check(
		disabled_portal.is_disabled(),
		"known but unavailable H01 portals return an explicit disabled result",
	)
	var disabled_story_trigger: EstateAnchorResult = runtime.query_anchor(
		&"story_trigger",
		&"trigger_first_build_zone",
	)
	_check(
		disabled_story_trigger.is_disabled(),
		"story triggers stay explicit but disabled until a story service activates them",
	)
	var resource_zone: EstateAnchorResult = runtime.query_anchor(
		&"resource_spawn_zone",
		&"resource_north_meadow",
	)
	_check(
		resource_zone.is_found()
		and resource_zone.world_position == Vector2(2000.0, 464.0)
		and resource_zone.cell == Vector2i(62, 14),
		"resource systems can query the audited north-meadow placement zone",
	)

	var child_count_before := runtime.get_child_count()
	var reclaimed_result: EstateMapApplyResult = runtime.apply_state(
		EstateMapState.new(&"summer", &"reclaimed", &"light")
	)
	_check(reclaimed_result.is_success(), "runtime applies a valid H01 estate state")
	var restore_result: EstateMapApplyResult = runtime.apply_state(
		EstateMapState.new(&"spring", &"derelict", &"normal")
	)
	_check(restore_result.is_success(), "runtime restores the default H01 state")
	_check(
		runtime.get_child_count() == child_count_before,
		"state changes do not grow the H01 scene tree",
	)
	var state_before_invalid: EstateMapState = runtime.get_current_state()
	var invalid_result: EstateMapApplyResult = runtime.apply_state(
		EstateMapState.new(&"monsoon", &"derelict", &"normal")
	)
	_check(not invalid_result.is_success(), "invalid H01 state is rejected")
	_check(
		runtime.get_current_state().equals(state_before_invalid),
		"invalid state application leaves the previous state unchanged",
	)
	var unsupported_axis_result: EstateMapApplyResult = runtime.apply_state(
		EstateMapState.new(
			&"spring",
			&"derelict",
			&"normal",
			{&"hydrology": &"high_water_story_state"},
		)
	)
	_check(
		not unsupported_axis_result.is_success(),
		"H01 explicitly rejects state axes owned by other estate maps",
	)

	var scene_text := FileAccess.get_file_as_string(
		"res://scenes/world/estate/h01_open_meadow.tscn"
	)
	_check(not scene_text.contains("maps/candidates"), "formal scene has no candidate-staging dependency")
	_check(not scene_text.contains("res://runtime"), "formal scene has no isolated-project runtime path")
	_check(not scene_text.contains("res://tilesets"), "formal scene has no isolated-project tileset path")
	_check(not scene_text.contains("h03_"), "formal H01 scene has no leaked H03 group names")

	runtime.queue_free()
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
		print("H01_ESTATE_RUNTIME_OK")
		quit(0)
		return
	push_error("H01 estate runtime test failed: %d check(s)" % _failures)
	quit(1)

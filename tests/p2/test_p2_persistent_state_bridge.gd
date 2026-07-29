extends SceneTree


class ScriptedInputService extends InputService:
	func snapshot() -> InputSnapshot:
		return InputSnapshot.neutral()


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_result := CatalogFileLoader.load_catalog()
	var estate_result := EstateMapCatalogFileLoader.load_catalog()
	_check(
		game_result.is_valid() and estate_result.is_valid(),
		"persistent-state bridge loads both validated catalogs",
	)
	if not game_result.is_valid() or not estate_result.is_valid():
		_finish()
		return
	var game_catalog: GameCatalog = game_result.catalog
	var definition: EstateMapDefinition = estate_result.catalog.get_map(
		&"home_h01_open_meadow"
	)
	var runtime_scene := load(definition.runtime_scene_path) as PackedScene
	var probe_runtime := runtime_scene.instantiate() as EstateMapRuntime
	root.add_child(probe_runtime)
	await process_frame
	var spawn := probe_runtime.query_anchor(
		&"spawn",
		&"home_safe_spawn_meadow",
	)
	probe_runtime.queue_free()
	await process_frame

	var inventory := InventoryState.create_empty()
	inventory = inventory.with_added(&"hoe_basic", 1, game_catalog).inventory
	inventory = inventory.with_added(
		&"watering_can_basic",
		1,
		game_catalog,
	).inventory
	var initial_state := P2PersistentState.new(
		&"home_h01_open_meadow",
		FarmingSessionState.new(
			FarmingTransactionState.new(
				FarmState.create_empty(&"home_h01_open_meadow"),
				inventory,
			),
			3,
		),
		spawn.world_position,
		Vector2i.LEFT,
		&"home_safe_spawn_meadow",
		5,
		EstateMapState.new(&"spring", &"reclaimed", &"light"),
		DailyResourceClaims.create_empty().with_claim(
			&"home.h01.resource.north_meadow.daily_choice",
			2,
		),
	)
	var pilot_scene := load(
		"res://scenes/vertical_slices/p2_estate_pilot.tscn"
	) as PackedScene
	var pilot := pilot_scene.instantiate() as P2EstatePilot
	var runtime := runtime_scene.instantiate() as EstateMapRuntime
	pilot.configure_estate_runtime(runtime)
	pilot.configure_input_service(ScriptedInputService.new())
	pilot.configure_game_catalog(game_catalog)
	_check(
		pilot.configure_initial_state(initial_state),
		"pilot accepts a matching typed initial state before entering the tree",
	)
	pilot.configure_persistence_status("profile-1 · 本地自动保存")
	var committed_reasons: Array[StringName] = []
	var committed_protection: Array[bool] = []
	pilot.durable_state_committed.connect(
		func(reason: StringName, protect_recovery: bool) -> void:
			committed_reasons.append(reason)
			committed_protection.append(protect_recovery)
	)
	root.add_child(pilot)
	await process_frame
	await physics_frame

	var restored: P2PersistentState = pilot.capture_persistent_state()
	_check(
		restored.farming_session.world_day == 3
		and restored.player_facing == Vector2i.LEFT,
		"pilot restores world day and player facing",
	)
	_check(
		restored.estate_map_state.anomaly == &"light"
		and restored.daily_resource_claims.last_claimed_day(
			&"home.h01.resource.north_meadow.daily_choice"
		) == 2,
		"pilot restores estate and daily resource state",
	)
	var title := pilot.get_node("HUD/TitlePanel/Margin/Title") as Label
	_check(
		title.text.contains("本地自动保存")
		and not title.text.contains("不写存档"),
		"persistent pilot HUD reports the real save mode",
	)

	var approach := _find_farmable_approach(runtime)
	var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
	var player := pilot.get_player()
	player.global_position = mapper.cell_center(approach["source"])
	player.facing = approach["direction"]
	var action := InputSnapshot.neutral()
	action.quickbar_slot_index = 0
	action.primary_action = true
	pilot.apply_input_snapshot(action)
	_check(
		committed_reasons.has(&"farm.tilled")
		and not committed_protection[committed_reasons.find(&"farm.tilled")],
		"a successful farm mutation requests a current autosave",
	)

	pilot.queue_free()
	await process_frame
	await physics_frame
	_finish()


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
		print("P2_PERSISTENT_STATE_BRIDGE_OK")
		quit(0)
		return
	push_error(
		"P2 persistent-state bridge failed: %d check(s)" % _failures
	)
	quit(1)

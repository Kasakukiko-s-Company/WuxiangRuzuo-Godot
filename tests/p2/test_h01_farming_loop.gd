extends SceneTree

class ScriptedInputService extends InputService:
	var current_snapshot: InputSnapshot = InputSnapshot.neutral()

	func snapshot() -> InputSnapshot:
		return current_snapshot


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_catalog_result := CatalogFileLoader.load_catalog()
	var estate_catalog_result := EstateMapCatalogFileLoader.load_catalog()
	_check(
		game_catalog_result.is_valid() and estate_catalog_result.is_valid(),
		"farming loop loads both validated catalogs",
	)
	if not game_catalog_result.is_valid() or not estate_catalog_result.is_valid():
		_finish()
		return
	var game_catalog: GameCatalog = game_catalog_result.catalog
	var definition: EstateMapDefinition = estate_catalog_result.catalog.get_map(
		&"home_h01_open_meadow"
	)
	var pilot_scene := load(
		"res://scenes/vertical_slices/p2_estate_pilot.tscn"
	) as PackedScene
	var runtime_scene := load(definition.runtime_scene_path) as PackedScene
	var pilot := pilot_scene.instantiate() as P2EstatePilot
	var runtime := runtime_scene.instantiate() as EstateMapRuntime
	var scripted_input := ScriptedInputService.new()
	pilot.configure_estate_runtime(runtime)
	pilot.configure_input_service(scripted_input)
	pilot.configure_game_catalog(game_catalog)
	root.add_child(pilot)
	await process_frame
	await physics_frame

	var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
	var player := pilot.get_player()
	var initial_session: FarmingSessionState = pilot.get_farming_session()
	_check(
		_inventory_quantity(initial_session.state.inventory, &"mistleaf_seed") == 0,
		"the playable loop starts without fixed prototype seed freebies",
	)
	var debug_sleep := InputSnapshot.neutral()
	debug_sleep.sleep_action = true
	_send_snapshot(pilot, debug_sleep)
	_check(
		pilot.get_farming_session().world_day == 1,
		"the legacy N debug action cannot advance the playable calendar",
	)

	var resource_anchor: EstateAnchorResult = runtime.query_anchor(
		&"resource_spawn_zone",
		&"resource_north_meadow",
	)
	var resource_approach := _find_anchor_approach(runtime, resource_anchor)
	_check(
		resource_anchor.is_found() and not resource_approach.is_empty(),
		"H01 exposes a walkable approach to its north-meadow resource source",
	)
	if resource_approach.is_empty():
		pilot.queue_free()
		await process_frame
		_finish()
		return
	_place_for_interaction(player, mapper, resource_approach)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	var gathered: FarmingSessionState = pilot.get_farming_session()
	_check(
		_inventory_quantity(gathered.state.inventory, &"mistleaf_seed") == 3,
		"interacting with the resource source obtains the first seed supply",
	)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	_check(
		_inventory_quantity(
			pilot.get_farming_session().state.inventory,
			&"mistleaf_seed",
		) == 3,
		"the H01 source cannot be collected twice on the same day",
	)

	var approach := _find_farmable_approach(runtime)
	_check(
		not approach.is_empty(),
		"H01 provides a walkable approach to a farmable target cell",
	)
	if approach.is_empty():
		pilot.queue_free()
		await process_frame
		_finish()
		return
	var source_cell: Vector2i = approach["source"]
	var target_cell: Vector2i = approach["target"]
	player.global_position = mapper.cell_center(source_cell)
	player.facing = approach["direction"]
	player.velocity = Vector2.ZERO

	_send_snapshot(
		pilot,
		_action_snapshot(0, true),
	)
	var tilled: FarmingSessionState = pilot.get_farming_session()
	_check(
		tilled.state.farm.tile_at(target_cell) != null,
		"selected hoe tills the facing farmable H01 cell",
	)

	_send_snapshot(
		pilot,
		_action_snapshot(2, true),
	)
	var planted: FarmingSessionState = pilot.get_farming_session()
	_check(
		planted.state.farm.tile_at(target_cell).crop != null,
		"selected mistleaf seed plants on the tilled facing cell",
	)
	_check(
		planted.state.inventory.stack_at(2).quantity == 2,
		"planting consumes one seed obtained from the map resource source",
	)

	_send_snapshot(
		pilot,
		_action_snapshot(1, true),
	)
	var watered_day_one: FarmingSessionState = pilot.get_farming_session()
	_check(
		watered_day_one.state.farm.tile_at(target_cell).watered_on_day == 1,
		"selected watering can waters the planted tile on day one",
	)

	var rest_anchor: EstateAnchorResult = runtime.query_anchor(
		&"interaction",
		&"home_door",
	)
	var rest_approach := _find_anchor_approach(runtime, rest_anchor)
	_check(
		rest_anchor.is_found() and not rest_approach.is_empty(),
		"H01 home door provides a walkable formal rest interaction",
	)
	_place_for_interaction(player, mapper, rest_approach)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	var movement := InputSnapshot.neutral()
	movement.move = Vector2.RIGHT
	_send_snapshot(pilot, movement)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	_check(
		pilot.get_farming_session().world_day == 1,
		"movement cancels rest confirmation before the next interaction",
	)
	pilot.reset_to_safe_spawn()
	_place_for_interaction(player, mapper, rest_approach)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	pilot.reset_to_safe_spawn()
	_place_for_interaction(player, mapper, rest_approach)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	_check(
		pilot.get_farming_session().world_day == 1,
		"reset cancels rest confirmation before the next interaction",
	)
	pilot.reset_to_safe_spawn()
	_place_for_interaction(player, mapper, rest_approach)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	_place_for_interaction(player, mapper, resource_approach)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	_place_for_interaction(player, mapper, rest_approach)
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	_check(
		pilot.get_farming_session().world_day == 1,
		"another target interaction cancels rest confirmation",
	)
	pilot.reset_to_safe_spawn()
	for expected_day: int in [2, 3, 4]:
		_place_for_interaction(player, mapper, rest_approach)
		player.interaction_requested.emit(player.global_position, player.facing)
		await process_frame
		_check(
			pilot.get_farming_session().world_day == expected_day - 1,
			"first home-door interaction requests rest confirmation",
		)
		player.interaction_requested.emit(player.global_position, player.facing)
		await process_frame
		var advanced: FarmingSessionState = pilot.get_farming_session()
		_check(
			advanced.world_day == expected_day,
			"confirmed home-door rest reaches day %d" % expected_day,
		)
		if expected_day < 4:
			player.global_position = mapper.cell_center(source_cell)
			player.facing = approach["direction"]
			player.velocity = Vector2.ZERO
			_send_snapshot(
				pilot,
				_action_snapshot(1, true),
			)

	var mature_session: FarmingSessionState = pilot.get_farming_session()
	var mature_crop: CropState = mature_session.state.farm.tile_at(
		target_cell
	).crop
	_check(
		mature_crop != null and mature_crop.stage_index == 3,
		"three watered transitions produce a mature visible crop",
	)
	player.global_position = mapper.cell_center(source_cell)
	player.facing = approach["direction"]
	player.velocity = Vector2.ZERO
	player.interaction_requested.emit(player.global_position, player.facing)
	await process_frame
	var harvested: FarmingSessionState = pilot.get_farming_session()
	_check(
		harvested.state.farm.tile_at(target_cell).crop == null,
		"interaction harvests a mature crop from the facing cell",
	)
	_check(
		_inventory_quantity(harvested.state.inventory, &"mistleaf") == 1,
		"harvest places one mistleaf in the in-memory inventory",
	)
	var overlay: FarmPlotOverlay = pilot.get_farm_overlay()
	_check(
		overlay.get_rendered_tile_count() == harvested.state.farm.tile_count(),
		"farm overlay mirrors every authoritative tilled tile",
	)
	var title := pilot.get_node("HUD/TitlePanel/Margin/Title") as Label
	_check(
		title.text.contains("不写存档"),
		"pilot HUD explicitly discloses that farming state is not persisted",
	)

	pilot.queue_free()
	await process_frame
	await physics_frame
	_finish()


func _send_snapshot(
	pilot: P2EstatePilot,
	next_snapshot: InputSnapshot,
) -> void:
	pilot.apply_input_snapshot(next_snapshot)


func _action_snapshot(slot_index: int, use_primary: bool) -> InputSnapshot:
	var snapshot := InputSnapshot.neutral()
	snapshot.quickbar_slot_index = slot_index
	snapshot.primary_action = use_primary
	return snapshot


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


func _inventory_quantity(
	inventory: InventoryState,
	item_id: StringName,
) -> int:
	var quantity: int = 0
	for slot_index: int in inventory.capacity():
		var stack: ItemStack = inventory.stack_at(slot_index)
		if stack != null and stack.item_id == item_id:
			quantity += stack.quantity
	return quantity


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_H01_FARMING_LOOP_OK")
		quit(0)
		return
	push_error("P2 H01 farming loop test failed: %d check(s)" % _failures)
	quit(1)

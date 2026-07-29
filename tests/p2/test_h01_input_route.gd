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
	pilot.configure_trade_book(TradeBook.new(
		composition_root.trade_offer_catalog,
		composition_root.game_catalog,
	))
	root.add_child(pilot)
	await process_frame
	await physics_frame

	var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
	var player := pilot.get_player()
	var daily_overlay := pilot.get_daily_interaction_overlay()
	await _tap_key(KEY_N)
	_check(
		pilot.get_farming_session().world_day == 1,
		"physical N no longer advances the playable calendar",
	)

	var resource_anchor: EstateAnchorResult = runtime.query_anchor(
		&"resource_spawn_zone",
		&"resource_north_meadow",
	)
	var resource_approach := _find_anchor_approach(runtime, resource_anchor)
	_check(
		not resource_approach.is_empty(),
		"real-input route finds the H01 resource-source approach",
	)
	if not resource_approach.is_empty():
		_place_for_interaction(player, mapper, resource_approach)
		await _tap_key(KEY_E)
		_check(
			_inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf_seed",
			) == 0
			and daily_overlay.is_resource_choice_pending()
			and daily_overlay.get_resource_choice_index() == 0,
			"first physical E opens the daily resource choice without collecting",
		)
		await _tap_key(KEY_Q)
		_check(
			daily_overlay.is_resource_choice_pending()
			and daily_overlay.get_resource_choice_index() == 1,
			"Q moves the visible resource choice to the second offer",
		)
		await _tap_key(KEY_E)
		_check(
			_inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf",
			) == 1
			and _inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf_seed",
			) == 0
			and not daily_overlay.is_resource_choice_pending()
			and not daily_overlay.is_resource_available(),
			"Q switches to the immediate forage offer and E confirms it",
		)
		await _tap_key(KEY_E)
		_check(
			daily_overlay.is_trade_choice_pending()
			and daily_overlay.get_trade_choice_index() == 0,
			"physical E opens the distinct trade choice after daily collection",
		)
		await _tap_key(KEY_D)
		_check(
			not daily_overlay.is_trade_choice_pending(),
			"physical movement cancels an unconfirmed trade",
		)
		_place_for_interaction(player, mapper, resource_approach)
		await _tap_key(KEY_E)
		await _tap_key(KEY_E)
		_check(
			_inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf",
			) == 0
			and _inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"village_scrip",
			) == 30,
			"physical E confirms the default mistleaf sale",
		)
		await _tap_key(KEY_E)
		await _tap_key(KEY_Q)
		_check(
			daily_overlay.is_trade_choice_pending()
			and daily_overlay.get_trade_choice_index() == 1,
			"physical Q selects the seed purchase offer",
		)
		await _tap_key(KEY_E)
		_check(
			_inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"village_scrip",
			) == 10
			and _inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf_seed",
			) == 1,
			"physical E buys a seed with the earned village scrip",
		)

	var rest_anchor: EstateAnchorResult = runtime.query_anchor(
		&"interaction",
		&"home_door",
	)
	var rest_approach := _find_anchor_approach(runtime, rest_anchor)
	_check(
		not rest_approach.is_empty(),
		"real-input route finds the H01 home-door rest approach",
	)
	if not rest_approach.is_empty():
		_place_for_interaction(player, mapper, rest_approach)
		await _tap_key(KEY_E)
		_check(
			pilot.get_farming_session().world_day == 1,
			"first physical E requests rest confirmation without advancing",
		)
		await _tap_key(KEY_E)
		_check(
			pilot.get_farming_session().world_day == 2,
			"second physical E confirms home rest and advances one day",
		)
		_place_for_interaction(player, mapper, resource_approach)
		await _tap_key(KEY_E)
		_check(
			_inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf",
			) == 0
			and _inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf_seed",
			) == 1
			and daily_overlay.is_resource_choice_pending()
			and daily_overlay.is_resource_available(),
			"the daily choice reopens without collecting when day two begins",
		)
		await _tap_key(KEY_E)
		_check(
			_inventory_quantity(
				pilot.get_farming_session().state.inventory,
				&"mistleaf_seed",
			) == 4,
			"day two can confirm the default seed offer after day one forage",
		)

	var approach := _find_farmable_approach(runtime)
	_check(
		not approach.is_empty(),
		"real-input route finds a legal H01 farming target",
	)
	if not approach.is_empty():
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


func _tap_key(physical_keycode: int) -> void:
	_parse_key(physical_keycode, true)
	Input.flush_buffered_events()
	await create_timer(0.1).timeout
	_parse_key(physical_keycode, false)
	Input.flush_buffered_events()
	await create_timer(0.05).timeout


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
		print("P2_H01_INPUT_ROUTE_OK")
		quit(0)
		return
	push_error("P2 H01 real-input route failed: %d check(s)" % _failures)
	quit(1)

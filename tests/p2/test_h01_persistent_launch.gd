extends SceneTree


class MemorySaveService extends SaveService:
	var payloads: Dictionary[StringName, String] = {}
	var previous_payloads: Dictionary[StringName, String] = {}
	var failed_writes_remaining: int = 0


	func read(slot_id: StringName) -> SaveReadResult:
		if not payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(payloads[slot_id])


	func read_previous(slot_id: StringName) -> SaveReadResult:
		if not previous_payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(previous_payloads[slot_id])


	func write(slot_id: StringName, payload: String) -> SaveWriteResult:
		if failed_writes_remaining > 0:
			failed_writes_remaining -= 1
			return SaveWriteResult.failed("injected transient failure")
		payloads[slot_id] = payload
		return SaveWriteResult.written()


	func remove(slot_id: StringName) -> SaveWriteResult:
		payloads.erase(slot_id)
		return SaveWriteResult.written()


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var composition_root := AppCompositionRoot.new()
	_check(
		not composition_root.bootstrap().contains("failed"),
		"persistent launch bootstraps the validated game and estate catalogs",
	)
	if not composition_root.is_ready():
		_finish()
		return

	var new_storage := MemorySaveService.new()
	var new_launch: H01LaunchResult = composition_root.create_h01_launch(
		&"profile-1",
		new_storage,
	)
	_check(
		new_launch.is_ready() and new_launch.pilot != null,
		"an empty profile creates a playable H01 session",
	)
	if new_launch.is_ready():
		var committed_reasons: Array[StringName] = []
		new_launch.pilot.durable_state_committed.connect(
			func(reason: StringName, _protect: bool) -> void:
				committed_reasons.append(reason)
		)
		root.add_child(new_launch.pilot)
		current_scene = new_launch.pilot
		await process_frame
		var runtime := new_launch.pilot.get_estate_runtime()
		var resource_anchor := runtime.query_anchor(
			&"resource_spawn_zone",
			&"resource_north_meadow",
		)
		var resource_approach := _find_anchor_approach(
			runtime,
			resource_anchor,
		)
		_check(
			not resource_approach.is_empty(),
			"persistent launch can reach the H01 exchange endpoint",
		)
		if not resource_approach.is_empty():
			var player := new_launch.pilot.get_player()
			var mapper := TileCoordinateMapper.new(Vector2i(32, 32))
			_place_for_interaction(player, mapper, resource_approach)
			player.interaction_requested.emit(
				player.global_position,
				player.facing,
			)
			await process_frame
			var select_forage := InputSnapshot.neutral()
			select_forage.select_next = true
			new_launch.pilot.apply_input_snapshot(select_forage)
			player.interaction_requested.emit(
				player.global_position,
				player.facing,
			)
			await process_frame
			player.interaction_requested.emit(
				player.global_position,
				player.facing,
			)
			await process_frame
			player.interaction_requested.emit(
				player.global_position,
				player.facing,
			)
			await process_frame
			_check(
				committed_reasons.has(&"resource.claimed")
				and committed_reasons.has(&"economy.traded")
				and new_storage.payloads[&"profile-1"].contains(
					"village_scrip"
				),
				"real claim and trade mutations both autosave the resulting inventory",
			)
		new_launch.pilot.durable_state_committed.emit(
			&"test.current",
			false,
		)
		_check(
			new_storage.payloads.has(&"profile-1")
			and not new_storage.payloads.has(&"profile-1.protected"),
			"a normal durable mutation writes only the current checkpoint",
		)
		new_launch.pilot.durable_state_committed.emit(
			&"test.rest",
			true,
		)
		_check(
			new_storage.payloads.has(&"profile-1.protected"),
			"a confirmed rest also updates the protected recovery checkpoint",
		)
		new_launch.pilot.queue_free()
		current_scene = null
		await process_frame

	var recovered_launch: H01LaunchResult = composition_root.create_h01_launch(
		&"profile-1",
		new_storage,
	)
	_check(
		recovered_launch.is_ready(),
		"a new H01 launch restores a previously written current checkpoint",
	)
	if recovered_launch.is_ready():
		root.add_child(recovered_launch.pilot)
		current_scene = recovered_launch.pilot
		await process_frame
		var restored: P2PersistentState = (
			recovered_launch.pilot.capture_persistent_state()
		)
		_check(
			restored.map_id == &"home_h01_open_meadow"
			and restored.farming_session.world_day == 1
			and _inventory_quantity(
				restored.farming_session.state.inventory,
				&"village_scrip",
			) == 30,
			"the composition root restores the inventory produced by a real trade",
		)
		_check(
			not recovered_launch.pilot.get_daily_interaction_overlay().is_crate_open(),
			"restoring a profile never persists the transient crate menu",
		)
		recovered_launch.pilot.queue_free()
		current_scene = null
		await process_frame

	var retry_storage := MemorySaveService.new()
	retry_storage.failed_writes_remaining = 1
	var retry_launch: H01LaunchResult = composition_root.create_h01_launch(
		&"profile-1",
		retry_storage,
	)
	if retry_launch.is_ready():
		root.add_child(retry_launch.pilot)
		current_scene = retry_launch.pilot
		await process_frame
		retry_launch.pilot.durable_state_committed.emit(
			&"test.transient-failure",
			false,
		)
		retry_launch.pilot.durable_state_committed.emit(
			&"test.retry",
			false,
		)
		_check(
			retry_storage.payloads.has(&"profile-1"),
			"a transient storage failure does not disable later autosave retries",
		)
		retry_launch.pilot.queue_free()
		current_scene = null
		await process_frame

	var recovery_storage := MemorySaveService.new()
	recovery_storage.payloads[&"profile-1.protected"] = (
		new_storage.payloads[&"profile-1.protected"]
	)
	recovery_storage.payloads[&"profile-1"] = "{corrupt"
	var recovery_launch: H01LaunchResult = composition_root.create_h01_launch(
		&"profile-1",
		recovery_storage,
	)
	_check(
		recovery_launch.is_ready(),
		"a valid protected checkpoint recovers an unavailable current checkpoint",
	)
	if recovery_launch.is_ready():
		recovery_launch.pilot.free()

	var read_only_storage := MemorySaveService.new()
	read_only_storage.payloads[&"profile-1"] = "{new-corrupt-current"
	read_only_storage.payloads[&"profile-1.protected"] = (
		new_storage.payloads[&"profile-1.protected"]
	)
	read_only_storage.payloads[
		&"profile-1.quarantine-primary"
	] = "{older-corrupt-current"
	var read_only_launch: H01LaunchResult = composition_root.create_h01_launch(
		&"profile-1",
		read_only_storage,
	)
	_check(
		read_only_launch.is_ready(),
		"a protected recovery can launch read-only when evidence archive is full",
	)
	if read_only_launch.is_ready():
		root.add_child(read_only_launch.pilot)
		current_scene = read_only_launch.pilot
		await process_frame
		read_only_launch.pilot.durable_state_committed.emit(
			&"test.read-only",
			false,
		)
		_check(
			read_only_storage.payloads[&"profile-1"]
			== "{new-corrupt-current",
			"a read-only recovery never overwrites the unavailable current",
		)
		read_only_launch.pilot.queue_free()
		current_scene = null
		await process_frame

	var blocked_storage := MemorySaveService.new()
	blocked_storage.payloads[&"profile-1"] = "{corrupt-current"
	blocked_storage.payloads[&"profile-1.protected"] = "{corrupt-protected"
	var blocked_launch: H01LaunchResult = composition_root.create_h01_launch(
		&"profile-1",
		blocked_storage,
	)
	_check(
		not blocked_launch.is_ready()
		and blocked_storage.payloads[&"profile-1"] == "{corrupt-current"
		and blocked_storage.payloads[&"profile-1.protected"] == "{corrupt-protected",
		"two unavailable checkpoints block launch without overwriting evidence",
	)

	_finish()


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
		var semantics := runtime.query_cell(source)
		if semantics.is_in_bounds() and not semantics.colliding:
			return {
				"source": source,
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
		var stack := inventory.stack_at(slot_index)
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
		print("P2_H01_PERSISTENT_LAUNCH_OK")
		quit(0)
		return
	push_error("P2 H01 persistent launch failed: %d check(s)" % _failures)
	quit(1)

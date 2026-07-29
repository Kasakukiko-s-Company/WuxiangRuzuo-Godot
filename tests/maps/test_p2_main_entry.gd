extends SceneTree


class MainEntrySaveService extends SaveService:
	var payloads: Dictionary[StringName, String] = {}


	func read(slot_id: StringName) -> SaveReadResult:
		if not payloads.has(slot_id):
			return SaveReadResult.missing()
		return SaveReadResult.found(payloads[slot_id])


	func read_previous(_slot_id: StringName) -> SaveReadResult:
		return SaveReadResult.missing()


	func write(slot_id: StringName, payload: String) -> SaveWriteResult:
		payloads[slot_id] = payload
		return SaveWriteResult.written()


	func remove(slot_id: StringName) -> SaveWriteResult:
		payloads.erase(slot_id)
		return SaveWriteResult.written()


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = packed_main.instantiate()
	var storage := MainEntrySaveService.new()
	main.call("configure_save_service_override", storage)
	root.add_child(main)
	current_scene = main
	await process_frame
	var launch_button := main.get_node_or_null(
		"Margin/Center/Content/LaunchP2Button"
	) as Button
	_check(launch_button != null, "Main exposes an explicit H01 estate pilot entry")
	if launch_button != null:
		launch_button.pressed.emit()
		await process_frame
		await process_frame
		_check(current_scene is P2EstatePilot, "H01 entry loads the estate pilot scene")
		if current_scene is P2EstatePilot:
			_check(
				current_scene.get_node_or_null("PersistenceBinding") != null,
				"H01 entry owns a profile-scoped persistence binding",
			)
	if current_scene != null:
		var expected_exit_position := Vector2(640.0, 480.0)
		if current_scene is P2EstatePilot:
			current_scene.get_player().global_position = expected_exit_position
		current_scene.queue_free()
		current_scene = null
		await process_frame
		await physics_frame
		var game_result := CatalogFileLoader.load_catalog()
		var estate_result := EstateMapCatalogFileLoader.load_catalog()
		var decoded := SaveCodec.decode(
			storage.payloads.get(&"profile-1", ""),
			game_result.catalog,
			estate_result.catalog,
		)
		_check(
			decoded.status == SaveCodecResult.Status.DECODED
			and decoded.snapshot.player.position == expected_exit_position,
			"leaving H01 saves the last player position to isolated test storage",
		)
	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)


func _finish() -> void:
	if _failures == 0:
		print("P2_MAIN_ENTRY_OK")
		quit(0)
		return
	push_error("P2 main entry test failed: %d check(s)" % _failures)
	quit(1)

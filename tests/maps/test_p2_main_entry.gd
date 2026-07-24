extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main := load("res://scenes/Main.tscn") as PackedScene
	var main: Node = packed_main.instantiate()
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
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
		await process_frame
		await physics_frame
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

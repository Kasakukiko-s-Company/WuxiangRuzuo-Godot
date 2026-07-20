extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 640, "viewport width is 640")
	_check(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 360, "viewport height is 360")
	_check(String(ProjectSettings.get_setting("display/window/stretch/mode")) == "canvas_items", "stretch mode is canvas_items")
	_check(String(ProjectSettings.get_setting("display/window/stretch/aspect")) == "keep", "stretch aspect is keep")
	_check(String(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility", "renderer is Compatibility")

	var packed_scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	_check(packed_scene != null, "Main.tscn loads")
	if packed_scene != null:
		var main: Node = packed_scene.instantiate()
		root.add_child(main)
		await process_frame
		_check(main.get_node_or_null("Margin/Center/Content/StatusLabel") != null, "composition-root status node exists")
		main.queue_free()

	if _failures == 0:
		print("G1_SMOKE_OK")
		quit(0)
	else:
		push_error("G1 smoke test failed: %d check(s)" % _failures)
		quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
		return
	_failures += 1
	push_error("FAIL: %s" % label)

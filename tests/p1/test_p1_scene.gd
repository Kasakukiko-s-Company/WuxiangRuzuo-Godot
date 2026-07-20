extends SceneTree

class ScriptedInputService extends InputService:
	var current_snapshot: InputSnapshot = InputSnapshot.neutral()

	func snapshot() -> InputSnapshot:
		return current_snapshot


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load("res://scenes/prototypes/p1_experience_probe.tscn") as PackedScene
	_check(packed_scene != null, "P1 experience probe scene loads")
	if packed_scene != null:
		var probe: Node = packed_scene.instantiate()
		root.add_child(probe)
		await process_frame
		_check(probe.call("get_prototype_id") == &"prototype_mist_edge", "scene exposes the non-production prototype map ID")
		_check(probe.get_node_or_null("Player") is P1PlayerController, "scene owns the playable CharacterBody2D seam")
		var camera := probe.get_node_or_null("Player/Camera2D") as Camera2D
		_check(
			camera != null and camera.limit_left == 0 and camera.limit_top == 0 and camera.limit_right == 1280 and camera.limit_bottom == 896,
			"Camera2D limits cover the 40x28 prototype grid",
		)
		_check(probe.get_node_or_null("WorldCollision/OuterWalls") is StaticBody2D, "prototype world provides authoritative physical boundaries")

		var player := probe.get_node("Player") as P1PlayerController
		var scripted_input := ScriptedInputService.new()
		player.configure_input_service(scripted_input)
		player.position = Vector2(20.0, 400.0)
		scripted_input.current_snapshot.move = Vector2(-1.0, 1.0)
		for _frame in range(20):
			await physics_frame
		_check(player.position.x >= 8.9 and player.position.y > 410.0, "CharacterBody2D collides and slides along the world boundary")
		_check(get_nodes_in_group(&"prototype_inspectable").size() >= 6, "prototype provides enough inspectable landmarks to test facing interactions")
		var one_shot_inspectable := probe.get_node("Inspectables/GateRibbon") as PrototypeInspectable
		var first_inspection := one_shot_inspectable.take_inspection_text()
		var repeated_inspection := one_shot_inspectable.take_inspection_text()
		_check(first_inspection != repeated_inspection, "one-shot inspectables expose a distinct repeated response")
		probe.call("reset_prototype")
		_check(one_shot_inspectable.take_inspection_text() == first_inspection, "prototype reset restores one-shot interaction state")
		var repeatable_inspectable := probe.get_node("Inspectables/StoneWell") as PrototypeInspectable
		_check(
			repeatable_inspectable.take_inspection_text() == repeatable_inspectable.take_inspection_text(),
			"repeatable inspectables preserve their response",
		)
		_check(
			probe.get_node_or_null("Terrain") is P1PrototypeTerrain and player.get_node_or_null("Visual") is P1PrototypePlayerView,
			"prototype renders a replaceable terrain and player visual sample",
		)
		_check(probe.get_node_or_null("Foreground") is P1PrototypeForeground, "prototype provides a distinct foreground occlusion layer")
		probe.call("set_quality_level", &"low")
		_check(
			(probe.get_node("Terrain") as P1PrototypeTerrain).get_quality_level() == &"low"
			and (probe.get_node("Foreground") as P1PrototypeForeground).get_quality_level() == &"low",
			"low quality disables optional terrain and foreground accents through one public seam",
		)
		probe.call("set_reduce_motion", true)
		_check(not camera.position_smoothing_enabled, "reduce-motion mode disables camera smoothing without changing gameplay")
		probe.call("set_debug_visible", true)
		_check((probe.get_node("HUD/DebugPanel") as PanelContainer).visible, "debug state overlay can be enabled through one public seam")
		probe.call("set_debug_visible", false)
		var prototype_audio := probe.get_node_or_null("PrototypeAudio") as P1PrototypeAudio
		_check(prototype_audio != null and prototype_audio.get_generated_sample_count() > 20000, "prototype owns an original generated ambient and feedback audio sample")

		probe.call("present_inspection", "测试交互", 0.05)
		_check(player.is_input_locked(), "inspection feedback locks world movement")
		await create_timer(0.1).timeout
		_check(not player.is_input_locked(), "inspection feedback always restores world movement")
		probe.queue_free()
		await process_frame
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
		print("P1_SCENE_OK")
		quit(0)
		return
	push_error("P1 scene failed: %d check(s)" % _failures)
	quit(1)

extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var summary := P2DayTransitionSummary.new(3, 4, 1)
	_check(
		summary.completed_day_text() == "第 3 天结束",
		"day transition identifies the completed day",
	)
	_check(
		summary.growth_text() == "雾露滋养了 1 株作物",
		"day transition reports overnight crop growth",
	)
	_check(
		summary.dawn_text() == "第 4 天 · 清晨",
		"day transition identifies the new playable day",
	)

	var overlay_scene := load(
		"res://scenes/ui/p2_day_transition_overlay.tscn"
	) as PackedScene
	_check(
		overlay_scene != null,
		"day transition overlay is a reusable packed scene",
	)
	if overlay_scene == null:
		_finish()
		return
	var overlay := overlay_scene.instantiate() as P2DayTransitionOverlay
	root.add_child(overlay)
	await process_frame
	overlay.present(summary, true)
	_check(
		overlay.is_open()
		and overlay.current_summary() == summary
		and is_equal_approx(overlay.modulate.a, 1.0),
		"reduced-motion presentation opens immediately without a fade",
	)
	_check(
		(overlay.get_node("Center/Panel/Margin/Content/CompletedDay") as Label).text
		== "第 3 天结束"
		and (overlay.get_node("Center/Panel/Margin/Content/Growth") as Label).text
		== "雾露滋养了 1 株作物"
		and (overlay.get_node("Center/Panel/Margin/Content/Dawn") as Label).text
		== "第 4 天 · 清晨",
		"overlay renders the typed summary rather than reading gameplay state",
	)
	overlay.dismiss()
	_check(
		not overlay.is_open(),
		"dismissing the transition returns control to gameplay",
	)
	var quiet_summary := P2DayTransitionSummary.new(4, 5, 0)
	overlay.present(quiet_summary, true)
	_check(
		(overlay.get_node("Center/Panel/Margin/Content/Growth") as Label).text
		== "今夜田地静静休息",
		"zero-growth nights receive an intentional non-error message",
	)

	overlay.queue_free()
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
		print("P2_DAY_TRANSITION_OK")
		quit(0)
		return
	push_error("P2 day transition test failed: %d check(s)" % _failures)
	quit(1)

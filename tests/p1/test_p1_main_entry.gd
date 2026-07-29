extends SceneTree

const InvalidTradeCatalogSource = preload(
	"res://tests/support/invalid_trade_catalog_source.gd"
)


var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	var p1_blocked_root := AppCompositionRoot.new()
	p1_blocked_root.platform_descriptor = null
	var p1_blocked_main: Node = packed_main.instantiate()
	p1_blocked_main.configure_composition_root_override(p1_blocked_root)
	root.add_child(p1_blocked_main)
	current_scene = p1_blocked_main
	await process_frame
	var blocked_p1_button := p1_blocked_main.get_node_or_null(
		"Margin/Center/Content/LaunchP1Button"
	) as Button
	var available_h01_button := p1_blocked_main.get_node_or_null(
		"Margin/Center/Content/LaunchP2Button"
	) as Button
	var blocked_status := p1_blocked_main.get_node_or_null(
		"Margin/Center/Content/StatusLabel"
	) as Label
	_check(
		blocked_p1_button != null and blocked_p1_button.disabled,
		"P1 entry is disabled when its own platform dependency is unavailable",
	)
	_check(
		available_h01_button != null and not available_h01_button.disabled,
		"H01 remains enabled when only the P1 entry is unavailable",
	)
	_check(
		blocked_status != null
		and blocked_status.text.contains("P1 blocked")
		and blocked_status.text.contains(
			"entry.p1.platform: platform descriptor is unavailable"
		),
		"P1-only failure is visible as a stable human-readable diagnostic",
	)
	p1_blocked_main.queue_free()
	current_scene = null
	await process_frame

	var main: Node = packed_main.instantiate()
	main.configure_composition_root_override(AppCompositionRoot.new(
		InvalidTradeCatalogSource.new(),
	))
	root.add_child(main)
	current_scene = main
	await process_frame
	var launch_button := main.get_node_or_null("Margin/Center/Content/LaunchP1Button") as Button
	var p2_button := main.get_node_or_null("Margin/Center/Content/LaunchP2Button") as Button
	_check(launch_button != null, "Main exposes an explicit P1 prototype entry")
	_check(
		launch_button != null and not launch_button.disabled,
		"P1 entry stays enabled when only H01 trade data is invalid",
	)
	_check(
		p2_button != null and p2_button.disabled,
		"H01 entry is disabled when its trade data is invalid",
	)
	if launch_button != null:
		launch_button.pressed.emit()
		await process_frame
		await process_frame
		_check(current_scene is P1ExperienceProbe, "P1 entry loads the experience probe scene")
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
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
		print("P1_MAIN_ENTRY_OK")
		quit(0)
		return
	push_error("P1 main entry failed: %d check(s)" % _failures)
	quit(1)

extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var composition_root := AppCompositionRoot.new()
	var status: String = composition_root.bootstrap()
	_check(composition_root.is_ready(), "composition root publishes a ready state")
	_check(composition_root.game_catalog != null, "composition root owns the validated catalog")
	_check(
		composition_root.estate_map_catalog != null,
		"composition root owns the validated estate map catalog",
	)
	if composition_root.game_catalog != null:
		_check(composition_root.game_catalog.items.size() == 4, "runtime bootstrap loads four items")
		_check(composition_root.game_catalog.maps.size() == 4, "runtime bootstrap loads four maps")
		_check(composition_root.game_catalog.npcs.size() == 15, "runtime bootstrap loads fifteen NPC identities")
	if composition_root.estate_map_catalog != null:
		_check(
			composition_root.estate_map_catalog.maps.size() == 8,
			"runtime bootstrap loads all eight audited estate candidates",
		)
		var h01: EstateMapDefinition = composition_root.estate_map_catalog.get_map(
			&"home_h01_open_meadow"
		)
		_check(
			h01 != null
			and h01.runtime_scene_path
			== "res://scenes/world/estate/h01_open_meadow.tscn",
			"runtime bootstrap exposes H01 as the only integrated estate scene",
		)
		_check(
			composition_root.get_estate_pilot_definition() == h01,
			"composition root resolves the P2 runtime through the validated catalog",
		)
	_check(
		composition_root.create_input_service() is GodotInputService,
		"composition root owns the Godot input adapter selection",
	)
	_check(status.contains("G2"), "bootstrap status identifies the current milestone")
	_check(
		composition_root.platform_descriptor.runtime_id() == &"windows-native",
		"default runtime environment is explicit",
	)
	_check(
		composition_root.platform_descriptor.distribution_id() == &"standalone",
		"default distribution channel is explicit",
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
		print("G2_BOOTSTRAP_OK")
		quit(0)
		return
	push_error("G2 bootstrap test failed: %d check(s)" % _failures)
	quit(1)

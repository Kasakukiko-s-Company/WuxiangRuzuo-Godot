extends SceneTree

const TITLE_ART_PATH: String = (
	"res://assets/art/title/a_cyan_mist_homestead_title_dev.jpg"
)
const THEME_PATH: String = (
	"res://assets/ui/themes/wuxiang_paper_lantern_dev.tres"
)
const H01_SCENE_PATH: String = (
	"res://scenes/world/estate/h01_open_meadow.tscn"
)
const PLAYER_VIEW_SCRIPT_PATH: String = (
	"res://scripts/gameplay/prototypes/p1_prototype_player_view.gd"
)

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_title_visual_contract()
	_check_h01_visual_contract()
	_finish()


func _check_title_visual_contract() -> void:
	var packed_main := load("res://scenes/Main.tscn") as PackedScene
	_check(packed_main != null, "visual integration loads the title scene")
	if packed_main == null:
		return
	var main := packed_main.instantiate() as Control
	var background := main.get_node_or_null("Background") as TextureRect
	_check(
		background != null
		and background.texture != null
		and background.texture.resource_path == TITLE_ART_PATH,
		"title screen uses the registered A homestead development artwork",
	)
	_check(
		background != null
		and background.texture != null
		and background.texture.get_size() == Vector2(640.0, 360.0),
		"title artwork matches the 640 by 360 logical canvas",
	)
	_check(
		main.theme != null
		and main.theme.resource_path == THEME_PATH
		and main.theme.has_stylebox(&"panel", &"PanelContainer"),
		"title screen uses the shared A/B paper-lantern theme",
	)
	var mist := main.get_node_or_null("AmbientMist") as AmbientMistOverlay
	_check(mist != null, "title screen owns a lightweight ambient layer")
	if mist != null:
		mist.set_quality_level(&"low")
		_check(
			mist.get_quality_level() == &"low"
			and not mist.are_optional_effects_enabled()
			and not mist.is_processing(),
			"ambient title effects can be disabled by the low quality tier",
		)
		mist.set_quality_level(&"high")
		_check(
			mist.are_optional_effects_enabled()
			and mist.is_processing(),
			"high quality restores the optional mist and warm-mote pass",
		)
	var content := main.get_node_or_null("Margin/Center/Content") as Control
	var side_scrim := main.get_node_or_null("SideScrim") as Control
	var margin := main.get_node_or_null("Margin") as Control
	_check(
		content != null
		and content.custom_minimum_size.x <= 346.0
		and side_scrim != null
		and side_scrim.offset_right <= 390.0
		and margin != null
		and margin.offset_right <= -262.0,
		"title UI remains in its compact left column and preserves the art view",
	)
	main.free()


func _check_h01_visual_contract() -> void:
	var packed_pilot := load(
		"res://scenes/vertical_slices/p2_estate_pilot.tscn"
	) as PackedScene
	_check(packed_pilot != null, "visual integration loads the H01 pilot")
	if packed_pilot != null:
		var pilot := packed_pilot.instantiate() as P2EstatePilot
		var mist := pilot.get_node_or_null(
			"HUD/H01Atmosphere"
		) as AmbientMistOverlay
		_check(
			mist != null,
			"H01 gameplay owns a quality-gated ambient layer below its HUD",
		)
		var player_view := pilot.get_node_or_null(
			"Player/Visual"
		) as P1PrototypePlayerView
		_check(
			player_view != null
			and player_view.get_visual_profile_id()
			== &"visual.a_cyan_mist_player_dev_v1",
			"player presentation keeps the A cyan-mist development profile",
		)
		_check_player_draw_source_contract()
		pilot.set_quality_level(&"low")
		_check(
			pilot.get_quality_level() == &"low"
			and mist != null
			and not mist.are_optional_effects_enabled()
			and not mist.is_processing(),
			"P2 quality forwarding disables optional ambient passes",
		)
		pilot.set_quality_level(&"high")
		_check(
			mist != null
			and mist.are_optional_effects_enabled()
			and mist.is_processing(),
			"P2 quality forwarding restores optional ambient passes",
		)
		_check_h01_hud_theme(pilot)
		_check_h01_hud_geometry(pilot)
		pilot.free()

	var packed_runtime := load(H01_SCENE_PATH) as PackedScene
	_check(packed_runtime != null, "visual integration loads the formal H01 map")
	if packed_runtime == null:
		return
	var runtime := packed_runtime.instantiate() as EstateMapRuntime
	var used_texture_cells := _used_texture_cell_counts(runtime)
	_check(
		used_texture_cells.get(
			"res://assets/art/maps/estate/h01/h01_layout_terrain.png",
			0,
		) > 0
		and used_texture_cells.get(
			"res://assets/art/maps/estate/h01/h01_layout_objects.png",
			0,
		) > 0
		and used_texture_cells.get(
			"res://assets/art/maps/estate/h01/h01_layout_architecture.png",
			0,
		) > 0,
		"formal H01 gameplay uses the generated terrain, object, and architecture atlases",
	)
	runtime.free()


func _check_h01_hud_theme(pilot: P2EstatePilot) -> void:
	var themed_paths: Array[String] = [
		"HUD/TitlePanel",
		"HUD/FarmingPanel",
		"HUD/StatusPanel",
		"HUD/CrateChoicePanel",
		"HUD/DayTransition",
		"HUD/PauseMenu",
	]
	var all_match := true
	for node_path: String in themed_paths:
		var control := pilot.get_node_or_null(node_path) as Control
		if (
			control == null
			or control.theme == null
			or control.theme.resource_path != THEME_PATH
		):
			all_match = false
			break
	_check(
		all_match,
		"H01 HUD and every modal use the shared paper-lantern theme",
	)


func _check_player_draw_source_contract() -> void:
	var file := FileAccess.open(PLAYER_VIEW_SCRIPT_PATH, FileAccess.READ)
	var source := "" if file == null else file.get_as_text()
	var draw_start := source.find("func _draw() -> void:")
	var draw_end := source.find("\n\nfunc _draw_shadow()", draw_start)
	var draw_body := ""
	if draw_start >= 0 and draw_end > draw_start:
		draw_body = source.substr(draw_start, draw_end - draw_start)
	var shadow_index := draw_body.find("\n\t_draw_shadow()\n")
	var legs_index := draw_body.find("\n\t_draw_legs(walk)\n")
	var body_index := draw_body.find("\n\t_draw_body(walk)\n")
	var head_index := draw_body.find("\n\t_draw_head()\n")
	_check(
		not source.is_empty()
		and draw_body.count("_draw_shadow()") == 1
		and draw_body.count("_draw_legs(walk)") == 1
		and draw_body.count("_draw_body(walk)") == 1
		and draw_body.count("_draw_head()") == 1
		and shadow_index >= 0
		and shadow_index < legs_index
		and legs_index < body_index
		and body_index < head_index
		and not source.contains("DRAW_LAYER_IDS")
		and not source.contains("get_draw_layer_ids"),
		"player draw path retains shadow, legs, body, and head composition",
	)


func _check_h01_hud_geometry(pilot: P2EstatePilot) -> void:
	var panel_paths: Array[String] = [
		"HUD/TitlePanel",
		"HUD/FarmingPanel",
		"HUD/StatusPanel",
	]
	var occupied_area := 0.0
	var geometry_valid := true
	for node_path: String in panel_paths:
		var panel := pilot.get_node_or_null(node_path) as Control
		if panel == null:
			geometry_valid = false
			break
		var width := panel.offset_right - panel.offset_left
		var height := panel.offset_bottom - panel.offset_top
		if width <= 0.0 or height <= 0.0:
			geometry_valid = false
			break
		occupied_area += width * height
	_check(
		geometry_valid
		and occupied_area <= 640.0 * 360.0 * 0.26,
		"H01 persistent HUD panels stay below 26 percent of the logical canvas",
	)


func _used_texture_cell_counts(
	runtime: EstateMapRuntime,
) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	for layer_name: StringName in H01EstateMapRuntime.VISUAL_LAYERS:
		var layer := runtime.get_node_or_null(
			NodePath(String(layer_name))
		) as TileMapLayer
		if layer == null or layer.tile_set == null:
			continue
		for cell: Vector2i in layer.get_used_cells():
			var source_id := layer.get_cell_source_id(cell)
			if source_id < 0 or not layer.tile_set.has_source(source_id):
				continue
			var atlas := layer.tile_set.get_source(
				source_id
			) as TileSetAtlasSource
			if atlas == null or atlas.texture == null:
				continue
			var texture_path := atlas.texture.resource_path
			counts[texture_path] = counts.get(texture_path, 0) + 1
	return counts


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures += 1
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures == 0:
		print("P2_VISUAL_INTEGRATION_OK")
		quit(0)
	else:
		push_error("P2 visual integration failures: %d" % _failures)
		quit(1)

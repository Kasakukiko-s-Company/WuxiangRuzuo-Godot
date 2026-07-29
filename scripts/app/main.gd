extends Control

const ACTIVE_PROFILE_ID: StringName = &"profile-1"

@onready var status_label: Label = %StatusLabel
@onready var launch_p1_button: Button = $Margin/Center/Content/LaunchP1Button
@onready var launch_p2_button: Button = $Margin/Center/Content/LaunchP2Button

var _composition_root: AppCompositionRoot
var _composition_root_override: AppCompositionRoot
var _save_service_override: SaveService


func _ready() -> void:
	launch_p1_button.pressed.connect(_on_launch_p1_pressed)
	launch_p2_button.pressed.connect(_on_launch_p2_pressed)
	_composition_root = (
		_composition_root_override
		if _composition_root_override != null
		else AppCompositionRoot.new()
	)
	status_label.text = _composition_root.bootstrap()
	var p1_available := _composition_root.entry_status(
		AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
	).is_available()
	var p2_available := _composition_root.entry_status(
		AppCompositionRoot.ENTRY_P2_H01,
	).is_available()
	launch_p1_button.disabled = not p1_available
	launch_p2_button.disabled = not p2_available
	if not p1_available and not p2_available:
		var p1_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
		)
		var p2_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P2_H01,
		)
		push_error(
			"[WuxiangRuzuo] bootstrap failed: P1: %s; H01: %s"
			% [p1_status.describe_issues(), p2_status.describe_issues()]
		)
		return
	if not p1_available:
		var p1_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
		)
		var p1_diagnostic := p1_status.describe_issues()
		status_label.text = "%s · P1 blocked · %s" % [
			status_label.text,
			p1_diagnostic,
		]
		push_warning(
			"[WuxiangRuzuo] P1 entry unavailable; H01 remains usable: %s"
			% p1_diagnostic
		)
	if not p2_available:
		var h01_status := _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P2_H01,
		)
		push_warning(
			"[WuxiangRuzuo] H01 entry unavailable; P1 remains usable: %s"
			% h01_status.describe_issues()
		)
	print("[WuxiangRuzuo] main scene started: %s" % status_label.text)


func configure_composition_root_override(root_override: AppCompositionRoot) -> void:
	assert(
		not is_node_ready(),
		"Main composition root override must be configured before entering the tree",
	)
	assert(
		root_override != null,
		"Main composition root override requires an AppCompositionRoot",
	)
	_composition_root_override = root_override


func configure_save_service_override(service: SaveService) -> void:
	assert(
		not is_node_ready(),
		"Main save override must be configured before entering the tree",
	)
	assert(service != null, "Main save override requires a SaveService")
	_save_service_override = service


func _on_launch_p1_pressed() -> void:
	if (
		_composition_root == null
		or not _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P1_EXPERIENCE_PROBE,
		).is_available()
	):
		push_error("[WuxiangRuzuo] P1 scene transition blocked: entry is unavailable")
		return
	var result := get_tree().change_scene_to_file(
		AppCompositionRoot.P1_PROTOTYPE_SCENE
	)
	if result != OK:
		push_error(
			"[WuxiangRuzuo] P1 scene transition failed: %s"
			% error_string(result)
		)


func _on_launch_p2_pressed() -> void:
	if (
		_composition_root == null
		or not _composition_root.entry_status(
			AppCompositionRoot.ENTRY_P2_H01,
		).is_available()
	):
		push_error("[WuxiangRuzuo] P2 scene transition blocked: bootstrap is not ready")
		return
	var launch := _composition_root.create_h01_launch(
		ACTIVE_PROFILE_ID,
		_save_service_override,
	)
	if not launch.is_ready():
		status_label.text = "H01 档位不可用（原文件未被覆盖）"
		push_error(
			"[WuxiangRuzuo] P2 scene transition blocked: %s"
			% launch.message
		)
		return
	_replace_current_scene(launch.pilot)


func _replace_current_scene(next_scene: Node) -> void:
	var tree := get_tree()
	var previous_scene := tree.current_scene
	tree.root.add_child(next_scene)
	tree.current_scene = next_scene
	if previous_scene != null:
		previous_scene.queue_free()

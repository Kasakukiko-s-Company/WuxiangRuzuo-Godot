extends Control

const P1_PROTOTYPE_SCENE: String = "res://scenes/prototypes/p1_experience_probe.tscn"
const ACTIVE_PROFILE_ID: StringName = &"profile-1"

@onready var status_label: Label = %StatusLabel
@onready var launch_p1_button: Button = $Margin/Center/Content/LaunchP1Button
@onready var launch_p2_button: Button = $Margin/Center/Content/LaunchP2Button

var _composition_root: AppCompositionRoot
var _save_service_override: SaveService


func _ready() -> void:
	launch_p1_button.pressed.connect(_on_launch_p1_pressed)
	launch_p2_button.pressed.connect(_on_launch_p2_pressed)
	_composition_root = AppCompositionRoot.new()
	status_label.text = _composition_root.bootstrap()
	if not _composition_root.is_ready():
		_set_launch_buttons_disabled(true)
		push_error(
			"[WuxiangRuzuo] bootstrap failed: %s"
			% _composition_root.bootstrap_issues
		)
		return
	print("[WuxiangRuzuo] main scene started: %s" % status_label.text)


func configure_save_service_override(service: SaveService) -> void:
	assert(
		not is_node_ready(),
		"Main save override must be configured before entering the tree",
	)
	assert(service != null, "Main save override requires a SaveService")
	_save_service_override = service


func _on_launch_p1_pressed() -> void:
	var result := get_tree().change_scene_to_file(P1_PROTOTYPE_SCENE)
	if result != OK:
		push_error(
			"[WuxiangRuzuo] P1 scene transition failed: %s"
			% error_string(result)
		)


func _on_launch_p2_pressed() -> void:
	if _composition_root == null or not _composition_root.is_ready():
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


func _set_launch_buttons_disabled(disabled: bool) -> void:
	launch_p1_button.disabled = disabled
	launch_p2_button.disabled = disabled

extends Control

const P1_PROTOTYPE_SCENE: String = "res://scenes/prototypes/p1_experience_probe.tscn"

@onready var status_label: Label = %StatusLabel
@onready var launch_p1_button: Button = $Margin/Center/Content/LaunchP1Button

var _composition_root: AppCompositionRoot


func _ready() -> void:
	launch_p1_button.pressed.connect(_on_launch_p1_pressed)
	_composition_root = AppCompositionRoot.new()
	status_label.text = _composition_root.bootstrap()
	if not _composition_root.is_ready():
		push_error("[WuxiangRuzuo] G2 bootstrap failed: %s" % _composition_root.bootstrap_issues)
		return
	print("[WuxiangRuzuo] G2 main scene started: %s" % status_label.text)


func _on_launch_p1_pressed() -> void:
	var result := get_tree().change_scene_to_file(P1_PROTOTYPE_SCENE)
	if result != OK:
		push_error("[WuxiangRuzuo] P1 scene transition failed: %s" % error_string(result))

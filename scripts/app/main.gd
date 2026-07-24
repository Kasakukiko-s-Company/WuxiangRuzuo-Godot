extends Control

const P1_PROTOTYPE_SCENE: String = "res://scenes/prototypes/p1_experience_probe.tscn"
const P2_ESTATE_PILOT_SCENE: String = (
	"res://scenes/vertical_slices/p2_estate_pilot.tscn"
)

@onready var status_label: Label = %StatusLabel
@onready var launch_p1_button: Button = $Margin/Center/Content/LaunchP1Button
@onready var launch_p2_button: Button = $Margin/Center/Content/LaunchP2Button

var _composition_root: AppCompositionRoot


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
	var pilot_scene := load(P2_ESTATE_PILOT_SCENE) as PackedScene
	var definition: EstateMapDefinition = (
		_composition_root.get_estate_pilot_definition()
	)
	if pilot_scene == null or definition == null:
		push_error("[WuxiangRuzuo] P2 scene transition failed: pilot contract is missing")
		return
	var runtime_scene := load(definition.runtime_scene_path) as PackedScene
	if runtime_scene == null:
		push_error(
			"[WuxiangRuzuo] P2 scene transition failed: %s"
			% definition.runtime_scene_path
		)
		return
	var pilot := pilot_scene.instantiate() as P2EstatePilot
	var runtime := runtime_scene.instantiate() as EstateMapRuntime
	if pilot == null or runtime == null:
		push_error(
			"[WuxiangRuzuo] P2 scene transition failed: typed scene contract mismatch"
		)
		if pilot != null:
			pilot.free()
		if runtime != null:
			runtime.free()
		return
	pilot.configure_estate_runtime(runtime)
	pilot.configure_input_service(_composition_root.create_input_service())
	_replace_current_scene(pilot)


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

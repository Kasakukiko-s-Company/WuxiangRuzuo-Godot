class_name P1ExperienceProbe
extends Node2D

const PROTOTYPE_ID: StringName = &"prototype_mist_edge"
const SPAWN_POSITION: Vector2 = Vector2(240.0, 560.0)

@onready var player: P1PlayerController = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var terrain: P1PrototypeTerrain = $Terrain
@onready var foreground: P1PrototypeForeground = $Foreground
@onready var prototype_audio: P1PrototypeAudio = $PrototypeAudio
@onready var prompt_label: Label = $HUD/PromptPanel/PromptMargin/PromptLabel
@onready var message_label: Label = $HUD/MessagePanel/MessageMargin/MessageLabel
@onready var debug_panel: PanelContainer = $HUD/DebugPanel
@onready var debug_label: Label = $HUD/DebugPanel/DebugMargin/DebugLabel

var _input_service: GodotInputService
var _coordinate_mapper := TileCoordinateMapper.new(Vector2i(32, 32))
var _interaction_generation: int = 0
var _quality_level: StringName = &"high"
var _reduce_motion: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_input_service = GodotInputService.new()
	player.configure_input_service(_input_service)
	player.interaction_requested.connect(_on_interaction_requested)
	reset_prototype()
	print("[WuxiangRuzuo] P1 prototype started: %s" % PROTOTYPE_ID)


func _process(_delta: float) -> void:
	var snapshot := _input_service.snapshot()
	if snapshot.reset:
		reset_prototype()
	if snapshot.debug_toggle:
		set_debug_visible(not debug_panel.visible)
	if snapshot.primary_action:
		set_quality_level(&"low" if _quality_level == &"high" else &"high")
	if snapshot.reduce_motion_toggle:
		set_reduce_motion(not _reduce_motion)
	if snapshot.pause:
		get_tree().paused = not get_tree().paused
	prototype_audio.set_walking(player.velocity.length_squared() > 1.0 and not player.is_input_locked())
	_update_prompt()
	_update_debug()


func get_prototype_id() -> StringName:
	return PROTOTYPE_ID


func reset_prototype() -> void:
	_interaction_generation += 1
	get_tree().paused = false
	player.set_input_locked(false)
	player.position = SPAWN_POSITION
	player.velocity = Vector2.ZERO
	player.facing = Vector2i.UP
	for node in get_tree().get_nodes_in_group(&"prototype_inspectable"):
		var inspectable := node as PrototypeInspectable
		if inspectable != null:
			inspectable.reset_inspection()
	message_label.visible = false
	message_label.text = ""


func set_quality_level(level: StringName) -> void:
	assert(level == &"low" or level == &"high", "P1 quality must be low or high")
	_quality_level = level
	terrain.set_quality_level(level)
	foreground.set_quality_level(level)


func set_reduce_motion(enabled: bool) -> void:
	_reduce_motion = enabled
	camera.position_smoothing_enabled = not enabled
	if enabled:
		camera.reset_smoothing()


func set_debug_visible(enabled: bool) -> void:
	debug_panel.visible = enabled
	terrain.set_debug_grid_visible(enabled)


func present_inspection(text: String, duration: float = 1.4) -> void:
	_interaction_generation += 1
	var generation := _interaction_generation
	player.set_input_locked(true)
	message_label.text = text
	message_label.visible = true
	prototype_audio.play_interaction()
	await get_tree().create_timer(duration, true, false, true).timeout
	if generation != _interaction_generation or not is_instance_valid(player):
		return
	message_label.visible = false
	message_label.text = ""
	player.set_input_locked(false)


func _on_interaction_requested(world_position: Vector2, facing_direction: Vector2i) -> void:
	var target_cell := _coordinate_mapper.facing_cell(world_position, facing_direction)
	var inspectable := _find_inspectable(target_cell)
	if inspectable == null:
		present_inspection("雾中没有可检查的东西。", 0.7)
		return
	present_inspection(inspectable.take_inspection_text())


func _find_inspectable(cell: Vector2i) -> PrototypeInspectable:
	for node in get_tree().get_nodes_in_group(&"prototype_inspectable"):
		var inspectable := node as PrototypeInspectable
		if inspectable != null and inspectable.matches_cell(cell):
			return inspectable
	return null


func _update_prompt() -> void:
	if player.is_input_locked():
		prompt_label.text = ""
		return
	var target_cell := _coordinate_mapper.facing_cell(player.global_position, player.facing)
	var inspectable := _find_inspectable(target_cell)
	prompt_label.text = "E / A · %s" % inspectable.prompt_text if inspectable != null else ""


func _update_debug() -> void:
	var player_cell := _coordinate_mapper.world_to_cell(player.global_position)
	var target_cell := _coordinate_mapper.facing_cell(player.global_position, player.facing)
	debug_label.text = "P1 PROTOTYPE\nmap: %s\npos: %.1f, %.1f\ncell: %s\ntarget: %s\nfacing: %s\nlocked: %s\nquality: %s\nreduce motion: %s" % [
		PROTOTYPE_ID,
		player.global_position.x,
		player.global_position.y,
		player_cell,
		target_cell,
		player.facing,
		player.is_input_locked(),
		_quality_level,
		_reduce_motion,
	]

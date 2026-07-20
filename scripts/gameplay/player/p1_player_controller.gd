class_name P1PlayerController
extends CharacterBody2D

signal interaction_requested(world_position: Vector2, facing_direction: Vector2i)

@export var movement_speed: float = 96.0

var facing: Vector2i = Vector2i.DOWN
var _input_service: InputService
var _input_locked: bool = false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func configure_input_service(service: InputService) -> void:
	_input_service = service


func set_input_locked(locked: bool) -> void:
	_input_locked = locked
	if locked:
		velocity = Vector2.ZERO


func is_input_locked() -> bool:
	return _input_locked


func _physics_process(_delta: float) -> void:
	if _input_service == null:
		velocity = Vector2.ZERO
		return
	var snapshot := _input_service.snapshot()
	var intent := MovementIntent.resolve(snapshot.move, facing, _input_locked)
	facing = intent.facing
	velocity = intent.direction * movement_speed
	move_and_slide()
	if snapshot.interact and not _input_locked:
		interaction_requested.emit(global_position, facing)

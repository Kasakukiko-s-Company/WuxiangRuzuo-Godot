class_name P2InteractionFeedback
extends Node2D

const DURATION_SECONDS: float = 0.34
const SUPPORTED_ACTION_IDS: Array[StringName] = [
	&"sfx.farm.till",
	&"sfx.farm.plant",
	&"sfx.farm.water",
	&"sfx.farm.harvest",
	&"sfx.resource.gather",
	&"sfx.trade.exchange",
	&"sfx.rest.confirm",
	&"sfx.rest.complete",
]

var _action_id: StringName = &""
var _origin: Vector2 = Vector2.ZERO
var _progress: float = 1.0
var _play_count: int = 0
var _play_serial: int = 0
var _active_tween: Tween


func play(
	action_id: StringName,
	world_position: Vector2,
	reduce_motion: bool,
) -> void:
	if not SUPPORTED_ACTION_IDS.has(action_id):
		push_warning("Unknown P2 interaction feedback ID: %s" % action_id)
		return
	_action_id = action_id
	_origin = world_position
	_play_count += 1
	_play_serial += 1
	var current_serial := _play_serial
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if reduce_motion:
		_progress = 0.58
		queue_redraw()
		get_tree().create_timer(0.12).timeout.connect(
			func() -> void: _finish_if_current(current_serial)
		)
		return
	_progress = 0.0
	queue_redraw()
	_active_tween = create_tween()
	_active_tween.set_trans(Tween.TRANS_CUBIC)
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.tween_method(_set_progress, 0.0, 1.0, DURATION_SECONDS)
	_active_tween.tween_callback(
		func() -> void: _finish_if_current(current_serial)
	)


func get_last_action_id() -> StringName:
	return _action_id


func get_play_count() -> int:
	return _play_count


func is_feedback_visible() -> bool:
	return _action_id != &"" and _progress < 1.0


func _set_progress(value: float) -> void:
	_progress = value
	queue_redraw()


func _finish_if_current(serial: int) -> void:
	if serial != _play_serial:
		return
	_progress = 1.0
	queue_redraw()


func _draw() -> void:
	if _action_id == &"" or _progress >= 1.0:
		return
	var alpha := 1.0 - _progress
	var radius := lerpf(5.0, 18.0, _progress)
	if _action_id == &"sfx.farm.till":
		_draw_till(radius, alpha)
	elif _action_id == &"sfx.farm.plant":
		_draw_plant(radius, alpha)
	elif _action_id == &"sfx.farm.water":
		_draw_water(radius, alpha)
	elif _action_id == &"sfx.farm.harvest":
		_draw_harvest(radius, alpha)
	elif _action_id == &"sfx.resource.gather":
		_draw_gather(radius, alpha)
	elif _action_id == &"sfx.trade.exchange":
		_draw_exchange(radius, alpha)
	elif (
		_action_id == &"sfx.rest.confirm"
		or _action_id == &"sfx.rest.complete"
	):
		_draw_rest(radius, alpha)


func _draw_till(radius: float, alpha: float) -> void:
	var color := Color(0.72, 0.48, 0.29, alpha)
	draw_arc(_origin, radius, PI * 0.1, PI * 0.9, 12, color, 2.0)
	draw_line(
		_origin + Vector2(-radius * 0.55, 3.0),
		_origin + Vector2(radius * 0.55, -3.0),
		color,
		2.0,
	)


func _draw_plant(radius: float, alpha: float) -> void:
	var color := Color(0.68, 0.9, 0.47, alpha)
	draw_circle(_origin + Vector2(-radius * 0.25, 1.0), 2.0, color)
	draw_circle(_origin + Vector2(radius * 0.22, -2.0), 1.6, color)
	draw_line(
		_origin + Vector2(0.0, 4.0),
		_origin + Vector2(0.0, -radius * 0.5),
		color,
		2.0,
	)


func _draw_water(radius: float, alpha: float) -> void:
	var color := Color(0.39, 0.75, 0.92, alpha)
	for offset: float in [-0.55, 0.0, 0.55]:
		var center := _origin + Vector2(radius * offset, radius * 0.18)
		draw_circle(center, 2.2, color)
		draw_line(center, center + Vector2(0.0, radius * 0.35), color, 1.5)


func _draw_harvest(radius: float, alpha: float) -> void:
	var color := Color(0.86, 0.94, 0.59, alpha)
	draw_arc(_origin, radius, 0.0, TAU, 16, color, 2.0)
	for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var direction := Vector2.from_angle(angle)
		draw_line(
			_origin + direction * (radius * 0.45),
			_origin + direction * radius,
			color,
			2.0,
		)


func _draw_gather(radius: float, alpha: float) -> void:
	var color := Color(0.58, 0.86, 0.49, alpha)
	draw_arc(_origin, radius, PI * 0.05, PI * 0.95, 14, color, 2.0)
	draw_circle(_origin + Vector2(-radius * 0.35, -2.0), 2.0, color)
	draw_circle(_origin + Vector2(radius * 0.28, -4.0), 1.7, color)


func _draw_exchange(radius: float, alpha: float) -> void:
	var color := Color(0.94, 0.78, 0.34, alpha)
	draw_arc(_origin, radius, -PI * 0.8, PI * 0.15, 12, color, 2.0)
	draw_arc(_origin, radius, PI * 0.2, PI * 1.15, 12, color, 2.0)
	draw_circle(_origin + Vector2(-radius * 0.62, -2.0), 2.0, color)
	draw_circle(_origin + Vector2(radius * 0.62, 2.0), 2.0, color)


func _draw_rest(radius: float, alpha: float) -> void:
	var color := Color(1.0, 0.82, 0.46, alpha)
	draw_arc(_origin, radius, 0.0, TAU, 18, color, 2.0)
	draw_arc(_origin, radius * 0.58, 0.0, TAU, 14, color, 1.0)

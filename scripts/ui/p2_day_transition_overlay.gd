class_name P2DayTransitionOverlay
extends Control

signal dismissed

@onready var _completed_day_label: Label = (
	$Center/Panel/Margin/Content/CompletedDay
)
@onready var _growth_label: Label = $Center/Panel/Margin/Content/Growth
@onready var _dawn_label: Label = $Center/Panel/Margin/Content/Dawn

var _summary: P2DayTransitionSummary
var _fade_tween: Tween


func _ready() -> void:
	visible = false


func present(
	summary: P2DayTransitionSummary,
	reduce_motion: bool,
) -> void:
	assert(summary != null, "day transition requires a typed summary")
	_stop_fade()
	_summary = summary
	_completed_day_label.text = summary.completed_day_text()
	_growth_label.text = summary.growth_text()
	_dawn_label.text = summary.dawn_text()
	visible = true
	modulate = Color.WHITE
	if reduce_motion:
		return
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	_fade_tween = create_tween()
	_fade_tween.tween_property(
		self,
		"modulate",
		Color.WHITE,
		0.24,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func dismiss() -> void:
	if not is_open():
		return
	_stop_fade()
	visible = false
	modulate = Color.WHITE
	_summary = null
	dismissed.emit()


func is_open() -> bool:
	return visible


func current_summary() -> P2DayTransitionSummary:
	return _summary


func finish_motion() -> void:
	if not is_open():
		return
	_stop_fade()
	modulate = Color.WHITE


func _stop_fade() -> void:
	if _fade_tween == null:
		return
	if _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null

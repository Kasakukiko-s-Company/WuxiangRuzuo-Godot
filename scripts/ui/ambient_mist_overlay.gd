class_name AmbientMistOverlay
extends Control

const QUALITY_LEVELS: Array[StringName] = [&"low", &"high"]
const MIST_COLOR := Color(0.43, 0.72, 0.68, 0.055)
const WARM_LIGHT := Color(0.95, 0.68, 0.31, 0.44)

@export var drift_speed: float = 4.0
@export var title_mode: bool = false

var _quality_level: StringName = &"high"
var _reduce_motion: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_processing()
	queue_redraw()


func _process(delta: float) -> void:
	if _quality_level == &"low" or _reduce_motion:
		return
	_elapsed = fmod(_elapsed + delta, 120.0)
	queue_redraw()


func set_quality_level(level: StringName) -> void:
	assert(
		QUALITY_LEVELS.has(level),
		"ambient mist quality must be low or high",
	)
	if _quality_level == level:
		return
	_quality_level = level
	_sync_processing()
	queue_redraw()


func get_quality_level() -> StringName:
	return _quality_level


func are_optional_effects_enabled() -> bool:
	return _quality_level == &"high"


func set_reduce_motion(enabled: bool) -> void:
	if _reduce_motion == enabled:
		return
	_reduce_motion = enabled
	_sync_processing()
	queue_redraw()


func _sync_processing() -> void:
	set_process(are_optional_effects_enabled() and not _reduce_motion)


func _draw() -> void:
	_draw_edge_depth()
	if not are_optional_effects_enabled():
		return
	_draw_mist_ribbons()
	_draw_warm_motes()


func _draw_edge_depth() -> void:
	var width := size.x
	var height := size.y
	var edge := 28.0 if title_mode else 18.0
	draw_rect(
		Rect2(0.0, 0.0, width, edge),
		Color(0.02, 0.035, 0.03, 0.22),
	)
	draw_rect(
		Rect2(0.0, height - edge, width, edge),
		Color(0.02, 0.028, 0.025, 0.3),
	)
	draw_rect(
		Rect2(0.0, 0.0, edge, height),
		Color(0.02, 0.03, 0.026, 0.18),
	)
	draw_rect(
		Rect2(width - edge, 0.0, edge, height),
		Color(0.02, 0.03, 0.026, 0.2),
	)


func _draw_mist_ribbons() -> void:
	var motion := 0.0 if _reduce_motion else _elapsed * drift_speed
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)
	for index: int in 3:
		var phase := float(index) * 117.0
		var x := fposmod(motion + phase, width + 210.0) - 105.0
		var y := height * (0.2 + float(index) * 0.27)
		draw_polyline(
			PackedVector2Array([
				Vector2(x - 110.0, y + 7.0),
				Vector2(x - 55.0, y - 5.0),
				Vector2(x + 18.0, y + 2.0),
				Vector2(x + 105.0, y - 8.0),
			]),
			MIST_COLOR,
			9.0,
			true,
		)


func _draw_warm_motes() -> void:
	var motion := 0.0 if _reduce_motion else _elapsed * 0.8
	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)
	var mote_count := 8 if title_mode else 5
	for index: int in mote_count:
		var seed := float(index * 83 + 19)
		var x := fposmod(seed * 3.7 + motion * (0.7 + index * 0.05), width)
		var y := fposmod(seed * 1.9 - motion * 0.35, height)
		var pulse := 0.7 + sin(_elapsed * 2.0 + seed) * 0.3
		var color := WARM_LIGHT
		color.a *= pulse
		draw_circle(Vector2(x, y), 1.0 + pulse, color)

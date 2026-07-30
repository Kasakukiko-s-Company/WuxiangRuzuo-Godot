class_name P1PrototypePlayerView
extends Node2D

const VISUAL_PROFILE_ID: StringName = &"visual.a_cyan_mist_player_dev_v1"
const OUTLINE := Color("182322")
const HAIR := Color("172120")
const SKIN := Color("c69f79")
const SKIN_SHADOW := Color("9f765b")
const TUNIC := Color("405d62")
const TUNIC_LIGHT := Color("55777a")
const TROUSERS := Color("293b40")
const LINEN := Color("b4aa8c")
const SCARF := Color("84664a")
const BELT := Color("5c422d")
const MIST_ACCENT := Color("79c8bd")

var _walk_phase: float = 0.0
var _last_facing: Vector2i = Vector2i.DOWN


func _process(delta: float) -> void:
	var controller := get_parent() as P1PlayerController
	if controller == null:
		return
	if controller.velocity.length_squared() > 1.0:
		_walk_phase += delta * 11.0
	else:
		_walk_phase = 0.0
	position.y = -2.0 + sin(_walk_phase) * 1.2
	if controller.facing != _last_facing:
		_last_facing = controller.facing
	queue_redraw()


func get_visual_profile_id() -> StringName:
	return VISUAL_PROFILE_ID


func _draw() -> void:
	var walk := sin(_walk_phase)
	_draw_shadow()
	_draw_legs(walk)
	_draw_body(walk)
	_draw_head()


func _draw_shadow() -> void:
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-13.0, 17.0),
			Vector2(-8.0, 13.0),
			Vector2(9.0, 13.0),
			Vector2(14.0, 17.0),
			Vector2(8.0, 20.0),
			Vector2(-8.0, 20.0),
		]),
		Color(0.015, 0.025, 0.022, 0.5),
	)


func _draw_legs(walk: float) -> void:
	var left_step := walk * 1.8
	var right_step := -walk * 1.8
	draw_rect(
		Rect2(Vector2(-8.0, 7.0 + left_step), Vector2(6.0, 10.0)),
		TROUSERS,
	)
	draw_rect(
		Rect2(Vector2(2.0, 7.0 + right_step), Vector2(6.0, 10.0)),
		TROUSERS,
	)
	draw_rect(
		Rect2(Vector2(-8.0, 13.0 + left_step), Vector2(6.0, 3.0)),
		LINEN.darkened(0.12),
	)
	draw_rect(
		Rect2(Vector2(2.0, 13.0 + right_step), Vector2(6.0, 3.0)),
		LINEN.darkened(0.12),
	)
	draw_rect(
		Rect2(Vector2(-9.0, 16.0 + left_step), Vector2(8.0, 3.0)),
		OUTLINE,
	)
	draw_rect(
		Rect2(Vector2(1.0, 16.0 + right_step), Vector2(8.0, 3.0)),
		OUTLINE,
	)


func _draw_body(walk: float) -> void:
	var torso := PackedVector2Array([
		Vector2(-9.0, -8.0),
		Vector2(9.0, -8.0),
		Vector2(12.0, 10.0),
		Vector2(-12.0, 10.0),
	])
	draw_colored_polygon(torso, OUTLINE)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-7.5, -7.0),
			Vector2(7.5, -7.0),
			Vector2(9.5, 8.0),
			Vector2(-9.5, 8.0),
		]),
		TUNIC,
	)
	var arm_swing := walk * 1.3
	draw_rect(
		Rect2(Vector2(-13.0, -5.0 + arm_swing), Vector2(5.0, 12.0)),
		LINEN,
	)
	draw_rect(
		Rect2(Vector2(8.0, -5.0 - arm_swing), Vector2(5.0, 12.0)),
		LINEN,
	)
	draw_circle(Vector2(-10.5, 7.0 + arm_swing), 2.5, SKIN_SHADOW)
	draw_circle(Vector2(10.5, 7.0 - arm_swing), 2.5, SKIN)
	draw_rect(Rect2(Vector2(-9.5, 3.0), Vector2(19.0, 3.0)), BELT)
	draw_rect(Rect2(Vector2(-1.5, 2.5), Vector2(3.0, 4.0)), SCARF)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-8.0, -7.0),
			Vector2(7.0, -7.0),
			Vector2(5.0, -2.0),
			Vector2(-5.0, -1.0),
		]),
		SCARF,
	)
	if _last_facing != Vector2i.UP:
		draw_line(
			Vector2(-6.0, -1.0),
			Vector2(7.0, 7.0),
			TUNIC_LIGHT,
			1.5,
		)
	draw_rect(Rect2(Vector2(8.5, 4.0), Vector2(5.0, 7.0)), BELT)
	draw_circle(Vector2(11.0, 6.0), 1.0, MIST_ACCENT.darkened(0.2))


func _draw_head() -> void:
	var head_center := Vector2(0.0, -15.0)
	draw_circle(head_center, 9.5, OUTLINE)
	draw_circle(head_center, 8.0, SKIN)
	draw_circle(Vector2(1.0, -24.0), 4.5, OUTLINE)
	if _last_facing == Vector2i.UP:
		draw_circle(Vector2(0.0, -16.0), 8.0, HAIR)
		draw_arc(
			Vector2(0.0, -14.0),
			6.0,
			0.15,
			PI - 0.15,
			12,
			Color("2f3a36"),
			2.0,
		)
		return
	if _last_facing.x != 0:
		var side := float(_last_facing.x)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-8.0, -19.0),
				Vector2(7.0, -22.0),
				Vector2(8.0, -13.0),
				Vector2(2.0 * side, -16.0),
				Vector2(-7.0, -12.0),
			]),
			HAIR,
		)
		draw_circle(Vector2(side * 4.0, -14.0), 1.3, OUTLINE)
	else:
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-8.0, -18.0),
				Vector2(-4.0, -23.0),
				Vector2(7.0, -21.0),
				Vector2(8.0, -15.0),
				Vector2(3.0, -18.0),
				Vector2(0.0, -14.0),
				Vector2(-4.0, -18.0),
				Vector2(-8.0, -13.0),
			]),
			HAIR,
		)
		draw_circle(Vector2(-3.0, -13.5), 1.15, OUTLINE)
		draw_circle(Vector2(3.0, -13.5), 1.15, OUTLINE)
		draw_line(
			Vector2(-2.0, -10.0),
			Vector2(2.0, -10.0),
			SKIN_SHADOW,
			1.0,
		)
